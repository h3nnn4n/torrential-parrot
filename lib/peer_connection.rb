# frozen_string_literal: true

require 'logger'
require 'set'
require 'socket'

require_relative 'bit_field'
require_relative 'peer_messages'

class PeerConnection
  include PeerMessages

  attr_reader :info_hash, :my_peer_id, :remote_peer_id, :host, :port

  def initialize(host, port, info_hash, peer_id, peer_n: nil)
    @host = host
    @port = port
    @info_hash = info_hash
    @my_peer_id = peer_id
    @remote_peer_id = nil
    @peer_n = peer_n || rand(65_535)
    @reserved = nil
    @state = :uninitialized
    @have = Set.new
    @keepalive_timer = Time.now.to_i
    @interested = false
    @chocked = true
    @keepalive_count = 0
    @drops_count = 0
    @message_count = 0

    logger.info "[PEER_CONNECTION] Created for #{host}:#{port}"
  end

  def connect
    Thread.new do
      client_init

      # event_loop
      listen
    end
  end

  private

  def client_init
    Thread.exit unless send_handshake

    loop do
      ready = IO.select([socket], nil, nil)

      next unless ready

      response = socket.gets

      next if response.nil? || response.empty?

      if @state == :handshake_sent
        process_handshake(response)
        break
      end
    rescue Errno::ECONNRESET, Errno::ECONNREFUSED, Errno::ETIMEDOUT,
           Errno::EHOSTUNREACH, Errno::ENETUNREACH, Errno::EADDRNOTAVAIL,
           Errno::EPIPE
      logger.info "[PEER_CONNECTION][#{@peer_n}] died during handshake RIP"
      Thread.exit
    end
  end

  def listen
    loop do
      ready = IO.select([socket], nil, nil, 2)

      response = socket.gets unless ready.nil?

      if ready.nil? || response.nil? || response.empty?
        send_interested if !@interested && @have.size.positive?
        keepalive

        next
      end

      next if response.nil?
      next if response.empty?

      process_message(response)
    rescue Errno::ECONNRESET, Errno::ECONNREFUSED, Errno::ETIMEDOUT,
           Errno::EHOSTUNREACH, Errno::ENETUNREACH, Errno::EADDRNOTAVAIL,
           Errno::EPIPE => e

      if @have.size.positive? && @drops_count <= 3
        logger.warn "[PEER_CONNECTION][#{@peer_n}] dropped #{@drops_count} times, reconnecting. cause: #{e.class}"
        reopen_socket
        @drops_count += 1
      else
        logger.warn "[PEER_CONNECTION][#{@peer_n}] died RIP"
        break
      end
    end
  end

  def keepalive
    now = Time.now.to_i
    delta = now - @keepalive_timer
    return unless delta >= 10

    logger.info "[#{@peer_n}] #{@state} #{@interested} #{@chocked} #{@have.size}"
    logger.info "[PEER_CONNECTION][#{@peer_n}] sending keepalive after #{delta}"

    socket.puts(keepalive_message)
    @keepalive_timer = now
    @keepalive_count += 1
  end

  def process_message(payload)
    @message_count += 1
    # logger.info "[PEER_CONNECTION][#{@peer_n}] got #{message_type(payload)} -> #{payload}"

    case message_type(payload)
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
    when nil
      nil
    else
      logger.info "[PEER_CONNECTION][#{@peer_n}] message #{message_type(payload)} not supported yet"
      dump(payload, info: "unknown_type_#{message_type(payload)}")
    end
  end

  def send_interested
    logger.info "[PEER_CONNECTION][#{@peer_n}] sending INTERESTED"
    socket.puts(interested_message)
    @interested = true
  end

  def send_handshake
    @state = :sending_handshake

    logger.info "[PEER_CONNECTION][#{@peer_n}] attemping to connect to peer at #{host} #{port}"
    socket.puts(handshake_message)
    socket.puts(keepalive_message)

    logger.info "[PEER_CONNECTION][#{@peer_n}] sent hanshake"
    @state = :handshake_sent

    true
  rescue Errno::ECONNRESET, Errno::ECONNREFUSED, Errno::ENETUNREACH,
         Errno::EHOSTUNREACH, Errno::ETIMEDOUT, Errno::EADDRNOTAVAIL
    false
  end

  def message_type(raw_payload)
    length, id = raw_payload.unpack('NC')

    return if length.nil?
    return :keep_alive if length.zero?

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
      logger.info "[PEER_CONNECTION][#{@peer_n}] got unkown id #{id}"
      -10
    end
  end

  def process_handshake(payload)
    dump(payload, info: 'handshake')

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

    dump(payload, info: 'handshake_piece') if payload.size > 46
    process_message(payload[48..-1]) if payload.size > 46
  end

  def process_bitfield(payload)
    dump(payload, info: 'bitfield')
    length = payload.unpack1('N')
    bitfield_length = 4 + length

    @bitfield = BitField.new(payload[0..bitfield_length])

    logger.info "[PEER_CONNECTION][#{@peer_n}] sent bitfield of size #{length}"

    process_message(payload[bitfield_length..-1]) if payload.size > bitfield_length
  end

  def process_choke(payload)
    dump(payload, info: 'choke')
    @chocked = true
    logger.info "[PEER_CONNECTION][#{@peer_n}] sent choke"

    process_message(payload[5..-1]) if payload.size > 5
  end

  def process_unchoke(payload)
    dump(payload, info: 'unchoke')
    @chocked = false
    logger.info "[PEER_CONNECTION][#{@peer_n}] sent unchoke"

    process_message(payload[5..-1]) if payload.size > 5
  end

  def process_have(payload)
    dump(payload, info: 'have')
    _, _, piece = payload.unpack('NCN')
    @have << piece

    # logger.info "[PEER_CONNECTION][#{@peer_n}] has piece #{piece}"

    process_message(payload[9..-1]) if payload.size > 9
  end

  def process_keepalive(payload)
    dump(payload, info: 'keepalive')
    logger.info "[PEER_CONNECTION][#{@peer_n}] sent keeplive"

    process_message(payload[4..-1]) if payload.size > 4
  end

  def socket
    @socket ||= TCPSocket.new(@host, @port)
  end

  def reopen_socket
    @socket = TCPSocket.new(@host, @port)
  end

  def logger
    @logger ||= Logger.new(STDOUT)
  end

  def dump(data, info: '')
    File.open("#{@peer_n}_#{@message_count}_#{info}.dat", 'wb') do |f|
      f.write(data)
    end
  end
end
