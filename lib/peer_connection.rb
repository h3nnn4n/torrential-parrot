# frozen_string_literal: true

require 'logger'
require 'set'
require 'socket'

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

  def event_loop
    Thread.new do
      loop do
        logger.info "[#{@peer_n}] #{@state} #{@interested} #{@chocked}"
        keepalive

        send_interested if @state == :handshaked && !@interested && @chocked

        sleep 2
      end
    rescue Errno::EPIPE
      logger.info "[PEER_CONNECTION][#{@peer_n}] dropped"
    end
  end

  def client_init
    Thread.exit unless send_handshake

    loop do
      ready = IO.select([socket], nil, nil)

      next unless ready

      response = socket.gets

      next if response.nil? || response.empty?

      if @state == :handshake_sent
        validate_handshake(response)
        break
      end
    rescue Errno::ECONNRESET, Errno::ECONNREFUSED, Errno::ETIMEDOUT,
           Errno::EHOSTUNREACH, Errno::ENETUNREACH, Errno::EADDRNOTAVAIL,
           Errno::EPIPE
      logger.info "[PEER_CONNECTION][#{@peer_n}] died"
      Thread.exit
    end
  end

  def listen
    loop do
      ready = IO.select([socket], nil, nil, 2)

      response = socket.gets unless ready.nil?

      if ready.nil? || response.nil? || response.empty?
        if !@interested && @chocked
          send_interested
        else
          keepalive
        end

        next
      end

      next if response.nil?
      next if response.empty?

      logger.info "[PEER_CONNECTION][#{@peer_n}] got #{message_type(response)} -> #{response}"

      case message_type(response)
      when :have
        process_have(response)
      else
        logger.info "[PEER_CONNECTION][#{@peer_n}] message #{message_type(response)} not supported yet"
        File.open("#{@peer_n}.dat", 'wt') do |f|
          f.write(response)
        end
      end
    rescue Errno::ECONNRESET, Errno::ECONNREFUSED, Errno::ETIMEDOUT,
           Errno::EHOSTUNREACH, Errno::ENETUNREACH, Errno::EADDRNOTAVAIL,
           Errno::EPIPE
      logger.info "[PEER_CONNECTION][#{@peer_n}] died"
      break
    end
  end

  def keepalive
    now = Time.now.to_i
    delta = now - @keepalive_timer
    return unless delta > 10

    logger.info "[PEER_CONNECTION][#{@peer_n}] sending keepalive after #{delta}"

    socket.puts(keepalive_message)
    @keepalive_timer = now
  end

  def send_interested
    @interested = true
    logger.info "[PEER_CONNECTION][#{@peer_n}] sending INTERESTED"
    socket.puts(interested_message)
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
    _, id = raw_payload.unpack('NC')

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

  def validate_handshake(payload)
    protocol_length = payload.unpack1('C')
    protocol = payload[1..protocol_length].unpack1('a*')

    raise "#{protocol} is not known!" if protocol != pstr

    payload = payload[(protocol_length + 1)..payload.length]
    decoded = payload.unpack('C8H20a20')

    @reserved = decoded[0..7]
    remote_info_hash, @remote_peer_id = decoded[8..-1]

    # TODO: Fix this it stinks
    raise "#{remote_info_hash} is not #{info_hash[0..19]} quiting" unless remote_info_hash == info_hash[0..19]

    logger.info "[PEER_CONNECTION][#{@peer_n}] handshake successful!"

    @state = :handshaked
  end

  def process_have(payload)
    pieces = payload.unpack('NCN*')[2..-1]

    logger.info "[PEER_CONNECTION][#{@peer_n}] recieved #{pieces.count} pieces in a have message"

    pieces.each do |piece|
      @have << piece
    end
  end

  def socket
    @socket ||= TCPSocket.new(@host, @port)
  end

  def logger
    @logger ||= Logger.new(STDOUT)
  end
end
