# frozen_string_literal: true

require 'logger'
require 'set'
require 'socket'

require_relative 'bit_field'
require_relative 'ninja_logger'
require_relative 'peer_messages'
require_relative 'request_manager'

class PeerConnection
  include PeerMessages

  # FIXME
  # For now requesting more than one chunk at a time can cause a piece to be
  # processed midway through, which causes all kinds of mayhem
  MAX_REQUESTS = 20
  REQUEST_TIMEOUT = 10.0

  attr_reader :info_hash, :my_peer_id, :remote_peer_id, :host, :port,
              :state, :chocked

  def initialize(host, port, torrent, peer_id, peer_n: nil)
    @host = host
    @port = port
    @info_hash = torrent.info_hash
    @torrent = torrent
    @my_peer_id = peer_id
    @remote_peer_id = nil
    @peer_n = peer_n || rand(65_535)
    @reserved = nil
    @state = :uninitialized
    @keepalive_timer = Time.now.to_i
    @interested = false
    @chocked = true
    @keepalive_count = 0
    @drops_count = 0
    @message_recv_count = 0
    @message_sent_count = 0
    @bitfield = BitField.new(torrent.size)
    @request_manager = RequestManager.new(max_requests: MAX_REQUESTS, timeout: REQUEST_TIMEOUT)

    # logger.info "[PEER_CONNECTION] Created for #{host}:#{port}"
  end

  def socket_open?
    !@socket.nil?
  end

  def socket
    @socket ||= TCPSocket.new(@host, @port)
  rescue Errno::ECONNREFUSED
    @state = :dead
    @socket = nil
  end

  # private

  def keepalive
    now = Time.now.to_i
    delta = now - @keepalive_timer
    return false unless delta >= 60

    logger.debug "[#{@peer_n}] stage: #{@state}  interested: #{@interested}  " \
                 "chocked: #{@chocked}  part_count: #{part_count}"
    logger.info "[PEER_CONNECTION][#{@peer_n}] sending keepalive after #{delta}"

    send_msg(keepalive_message)
    dump(keepalive_message, info: 'send_keepalive')
    @keepalive_timer = now
    @keepalive_count += 1
    true
  end

  def process_message(payload)
    @message_recv_count += 1
    payload_type = message_type(payload)

    # logger.info "[PEER_CONNECTION][#{@peer_n}] got #{payload_type} #{payload.unpack('NC')}"

    case payload_type
    when :keep_alive
      process_keepalive(payload)
    when :choke
      process_choke(payload)
    when :unchoke
      process_unchoke(payload)
    when :bitfield
      process_bitfield(payload)
    when :have
      process_have(payload)
    when :piece
      process_piece(payload)
    when :cancel, :interested, :uninterested
      # FIXME: Do nothing
      # This was added just so the app doesnt die because it recieved an unexpected message.
      # For now there is nothing being done wiht these messages
      nil
    when :handshake
      # HACK: this just helps debuging when a message is missparsed. Remove this later
      @message_recv_count -= 1
      process_handshake(payload)
    when :unknown, :invalid
      logger.info "[PEER_CONNECTION][#{@peer_n}] sent an #{payload_type} message!"
      dump(payload, info: "receive_unknown_type_#{payload_type}")
      # terminate
    when nil
      @message_recv_count -= 1
      nil
    else
      logger.info "[PEER_CONNECTION][#{@peer_n}] message #{payload_type} was not expected!"
      dump(payload, info: "receive_unknown_type_#{payload_type}")
      raise "Received unexpected message type #{payload_type}. Aborting"
    end
  end

  def send_interested
    logger.info "[PEER_CONNECTION][#{@peer_n}] sending INTERESTED"
    send_msg(interested_message)
    dump(interested_message, info: 'send_interested')
    @interested = true
  end

  def send_handshake
    @state = :sending_handshake

    logger.info "[PEER_CONNECTION][#{@peer_n}] attemping to connect to peer at #{host} #{port}"

    Timeout.timeout(2) do
      if socket.nil?
        @state = :dead
        return false
      end

      send_msg(handshake_message)
      dump(handshake_message, info: 'send_handshake')
      # send_msg(keepalive_message)

      logger.info "[PEER_CONNECTION][#{@peer_n}] sent hanshake"
      @state = :handshake_sent
    end

    true
  rescue Errno::ECONNRESET, Errno::ECONNREFUSED, Errno::ENETUNREACH,
         Errno::EHOSTUNREACH, Errno::ETIMEDOUT, Errno::EADDRNOTAVAIL,
         Timeout::Error
    @state = :dead
    false
  end

  def send_messages
    return send_interested if !@interested && part_count.positive?
    return if keepalive
    return request_pieces if !@chocked && @interested
  rescue Errno::ECONNRESET, Errno::ENETUNREACH, Errno::ETIMEDOUT,
         Errno::EPIPE
    @state = :dead
  end

  def message_type(payload)
    length, id = payload.unpack('NC')

    return if length.nil?
    return :keep_alive if length.zero?
    return :invalid unless valid_message?(payload)

    case id
    when 0 then :choke
    when 1 then :unchoke
    when 2 then :interested
    when 3 then :uninterested
    when 4 then :have
    when 5 then :bitfield
    when 6 then :request
    when 7 then :piece
    when 8 then :cancel
    else
      pname_len, pname = payload.unpack('Ca19')

      if pname_len == pstrlen && pname == pstr
        :handshake
      else
        logger.info "[PEER_CONNECTION][#{@peer_n}] got unkown id #{id}"
        dump(payload, info: 'receive_unknown')
        :unknown
      end
    end
  end

  def valid_message?(payload)
    pnamelen, pname = payload.unpack('Ca19')

    if pnamelen == pstrlen && pname == pstr
      return false if payload.size < 68

      return true
    end

    length = payload.unpack1('N')

    return false if payload.length < (length + 4)

    true
  end

  def request_pieces
    while @request_manager.can_request? && @state == :handshaked
      piece_requested = request_piece
      break unless piece_requested
    end
  end

  def request_piece
    piece = piece_manager.incomplete_piece(@bitfield)
    if piece_manager.download_finished?
      @state = :finished_download
      return false
    end

    if piece.nil?
      piece_index, chunk_offset = piece_manager.pending_chunks.sample
    else
      piece_index = piece.index
      chunk_offset = piece.next_chunk_to_request
    end

    is_last_chunk = piece_manager.last_chunk?(piece_index, chunk_offset)
    chunk_size = is_last_chunk ? piece_manager.last_chunk_size : Piece::CHUNK_SIZE
    message = request_message(piece_index, chunk_offset, chunk_size)
    piece_manager.request_chunk(piece_index, chunk_offset)

    logger.info "[PEER_CONNECTION][#{@peer_n}] requesting piece #{piece_index} #{chunk_offset} #{chunk_size}"

    send_msg(message)
    dump(message, info: 'send_request_piece')

    @request_manager.register_request

    true
  end

  def process_handshake(payload)
    dump(payload, info: 'receive_handshake')

    protocol_length = payload.unpack1('C')
    protocol = payload[1..protocol_length].unpack1('a*')

    raise "#{protocol} is not known!" if protocol != pstr

    payload = payload[(protocol_length + 1)..payload.length]
    decoded = payload.unpack('C8H40a20')

    @reserved = decoded[0..7]
    remote_info_hash, @remote_peer_id = decoded[8..-1]

    raise "#{remote_info_hash} is not #{info_hash} quiting" unless remote_info_hash == info_hash

    logger.info "[PEER_CONNECTION][#{@peer_n}] handshake successful! #{payload.size}"

    @state = :handshaked

    dump(payload, info: 'receive_handshake_piece') if payload.size > 46
    process_message(payload[48..-1]) if payload.size > 46
  end

  def process_bitfield(payload)
    dump(payload, info: 'receive_bitfield')
    length = payload.unpack1('N')
    bitfield_length = 4 + length

    @bitfield.populate(payload[0..bitfield_length])

    logger.info "[PEER_CONNECTION][#{@peer_n}] sent bitfield of size #{length}"

    process_message(payload[bitfield_length..-1]) if payload.size > bitfield_length
  end

  def process_choke(payload)
    length = payload.unpack1('N')
    return if length != 1

    dump(payload, info: 'receive_choke')
    @chocked = true
    logger.info "[PEER_CONNECTION][#{@peer_n}] sent choke"

    process_message(payload[5..-1]) if payload.size > 5
  end

  def process_unchoke(payload)
    length = payload.unpack1('N')
    return if length != 1

    dump(payload, info: 'receive_unchoke')
    @chocked = false
    logger.info "[PEER_CONNECTION][#{@peer_n}] sent UNCHOKE ( ͡° ͜ʖ ͡°) ( ͡° ͜ʖ ͡°) ( ͡° ͜ʖ ͡°) ( ͡° ͜ʖ ͡°)"

    process_message(payload[5..-1]) if payload.size > 5
  end

  def process_have(payload)
    length = payload.unpack1('N')
    return if length != 1

    dump(payload, info: 'receive_have')
    _, _, piece = payload.unpack('NCN')
    @bitfield.set(piece)

    # logger.info "[PEER_CONNECTION][#{@peer_n}] has piece #{piece}"

    process_message(payload[9..-1]) if payload.size > 9
  end

  def process_keepalive(payload)
    # dump(payload, info: 'receive_keepalive')
    # logger.info "[PEER_CONNECTION][#{@peer_n}] sent keeplive"

    process_message(payload[4..-1]) if payload.size > 4
  end

  def process_piece(payload)
    dump(payload, info: 'receive_piece')
    payload_size, _message_id, piece_index, chunk_offset = payload.unpack('NCNN')
    piece_size = payload_size - 9
    chunk_data = payload[13..(payload_size + 3)]
    logger.info(
      "[PEER_CONNECTION][#{@peer_n}] got piece #{piece_index}" \
      "#{chunk_offset / Piece::CHUNK_SIZE} #{chunk_offset} of size #{piece_size}"
    )

    piece_manager.receive_chunk(piece_index, chunk_offset, chunk_data)
    @request_manager.relive_request

    process_message(payload[(payload_size + 4)..-1]) if payload.size > payload_size
  end

  def send_msg(payload)
    socket.write(payload)
    @message_sent_count += 1
  end

  def piece_manager
    @torrent.piece_manager
  end

  def part_count
    @bitfield.bit_set_count
  end

  def reopen_socket
    @socket = TCPSocket.new(@host, @port)
  end

  def terminate
    socket.close unless @socket.nil?
    @socket = nil
    @state = :dead
  end

  def logger
    NinjaLogger.logger
  end

  def dump(data, info: '')
    filename = "#{@peer_n}_#{@message_recv_count + @message_sent_count}_#{info}.dat"
    File.open(filename, 'wb') do |f|
      f.write(data)
    end
  end
end
