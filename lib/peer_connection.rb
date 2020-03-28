# frozen_string_literal: true

require 'logger'
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

    logger.info "[PEER_CONNECTION] Created for #{host}:#{port}"
  end

  def connect
    Thread.new do
      Thread.exit unless send_handshake

      loop do
        ready = IO.select([socket], nil, nil)

        next unless ready

        response = socket.gets

        next if response.nil?
        next if response.empty?

        if @state == :handshake_sent
          validate_handshake(response)
          next
        end

        logger.info "[PEER_CONNECTION][#{@peer_n}] got #{response}"

        case message_type(response)
        when :handshake
          validate_handshake(response)
        else
          logger.info "[PEER_CONNECTION][#{@peer_n}] message #{message_type(response)} not supported yet"
        end
      rescue Errno::ECONNRESET, Errno::ECONNREFUSED, Errno::ETIMEDOUT,
             Errno::EHOSTUNREACH, Errno::ENETUNREACH, Errno::EADDRNOTAVAIL
        break
      end
    end
  end

  private

  def send_handshake
    @state = :sending_handshake

    logger.info "[PEER_CONNECTION][#{@peer_n}] attemping to connect to peer at #{host} #{port}"
    socket.puts(handshake_message)
    socket.puts(keepalive_message)

    logger.info "[PEER_CONNECTION][#{@peer_n}] sent hanshake"
    @state = :handshake_sent

    true
  rescue Errno::ECONNRESET, Errno::ECONNREFUSED, Errno::ENETUNREACH,
         Errno::EHOSTUNREACH, Errno::ETIMEDOUT
    false
  end

  def message_type(raw_payload)
    _, id = raw_payload.unpack('CN')

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

  def socket
    @socket ||= TCPSocket.new(@host, @port)
  end

  def logger
    @logger ||= Logger.new(STDOUT)
  end
end
