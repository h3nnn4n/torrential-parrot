# frozen_string_literal: true

require_relative 'ninja_logger'

class PeerManager
  MAX_CONNECTIONS = 4

  def initialize
    @peers = []
  end

  def add_peer(peer)
    @peers << peer
  end

  def read_and_dispatch_messages
    if connected.count < MAX_CONNECTIONS
      peer = uninitialized.first
      peer.send_handshake
    end

    return if sockets.nil?
    return if sockets.empty?

    ready_to_read, = IO.select(sockets, nil, nil)
    logger.info "#{ready_to_read.size} messages to read #{ready_to_read}"

    ready_to_read.each do |socket|
      read_and_delegate(socket)
    end
  end

  def print_status
    data = [
      "u: #{uninitialized.count} ",
      "c: #{connected.count}/#{MAX_CONNECTIONS}",
      "dead: #{dead_peers.count}",
      "a:#{@peers.count}"
    ]

    msg = data.join(' ')
    logger.info msg
  end

  private

  def read_and_delegate(socket)
    data = ''
    read_len = 1024

    loop do
      buff = socket.recv_nonblock(read_len)

      break if buff.size <= 0

      data += buff

      break if buff.size < read_len
    rescue Errno::ECONNRESET
      break
    end

    delegate_message(socket, data) if data.size.positive?
  end

  def delegate_message(socket, payload)
    peer = find_peer_from_socket(socket)

    logger.info "recieved #{payload.size} bytes for #{peer.peer_n}"

    peer.process_message(payload)
  end

  def find_peer_from_socket(socket)
    @peers.find do |peer|
      peer.connection.socket_open? && peer.connection.socket == socket
    end
  end

  def connected
    @peers
      .map(&:connection)
      .select { |a| a.state == :handshaked }
  end

  def dead_peers
    @peers
      .map(&:connection)
      .select { |a| a.state == :dead }
  end

  def uninitialized
    @peers
      .map(&:connection)
      .select { |a| a.state == :uninitialized }
  end

  def sockets
    @peers
      .map(&:connection)
      .select { |a| a.state == :handshaked || a.state == :handshake_sent }
      .map(&:socket)
  end

  def logger
    NinjaLogger.logger
  end
end