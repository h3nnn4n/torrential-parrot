# frozen_string_literal: true

require_relative 'ninja_logger'

class PeerManager
  MAX_CONNECTIONS = 8

  def initialize
    @peers = []
    @msg_count = 0
  end

  def add_peer(peer)
    @peers << peer
  end

  def read_and_dispatch_messages
    if connected.count < MAX_CONNECTIONS && uninitialized.size.positive?
      peer = uninitialized.first
      peer.send_handshake
    end

    return if sockets.nil?
    return if sockets.empty?

    ready_to_read, = IO.select(sockets, nil, nil, 0.5)
    # logger.info "#{ready_to_read.size} messages to read #{ready_to_read}"

    return if ready_to_read.nil?

    ready_to_read.each do |socket|
      read_and_delegate(socket)
    end
  end

  def send_messages
    unchoked.each(&:send_messages)
  end

  def print_status
    data = [
      "u: #{uninitialized.count} ",
      "c: #{connected.count}/#{unchoked.count}/#{MAX_CONNECTIONS}",
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

    return unless data.size.positive?

    delegate_message(socket, data) if data.size.positive?
  end

  def delegate_message(socket, payload)
    peer = find_peer_from_socket(socket)

    peer.process_message(payload)
  end

  def find_peer_from_socket(socket)
    @peers.find do |peer|
      peer.connection.socket_open? && peer.connection.socket == socket
    end
  end

  def unchoked
    @peers
      .map(&:connection)
      .select { |a| a.state == :handshaked && a.chocked == false }
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
