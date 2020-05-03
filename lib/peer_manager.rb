# frozen_string_literal: true

require_relative 'config'
require_relative 'ninja_logger'

class PeerManager
  def initialize
    @peers = []
    @msg_count = 0
  end

  def add_peer(peer)
    @peers << peer
  end

  def update_peers
    @peers.each do |peer|
      if peer.idle_timeout?
        peer.terminate
        logger.info "[PEER_MANAGER] Timing out idle peer ##{peer.peer_n}"
      end
    end
  end

  def read_and_dispatch_messages
    if connected.count < Config.max_peer_connetions && uninitialized.size.positive?
      peer = uninitialized.first
      peer.send_handshake
    end

    return if sockets.nil?
    return if sockets.empty?

    ready_to_read, = IO.select(sockets, nil, nil, Config.peer_read_timeout)
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
      "c: #{connected.count}/#{unchoked.count}/#{Config.max_peer_connetions}",
      "dead: #{dead.count}",
      "a:#{@peers.count}"
    ]

    msg = data.join(' ')
    logger.info msg
  end

  def needs_more_peers?
    uninitialized.count.zero? && connected.count < Config.max_peer_connetions
  end

  def remove_dead_peers
    @peers.reject! do |peer|
      peer.connection.state == :dead
    end
  end

  def recycle_dead_peers
    @peers.each do |peer|
      next if peer.connection.state != :dead

      peer.recycle
    end
  end

  private

  def read_and_delegate(socket)
    data = ''
    read_len = Config.block_read_size

    loop do
      buff = socket.recv_nonblock(read_len)

      break if buff.size <= 0

      data += buff

      break if buff.size < read_len
    rescue Errno::ECONNRESET, Errno::ENETUNREACH, IO::EAGAINWaitReadable
      # FIXME: I think the correct way to treat the IO exception is to call
      # IO.select again For now lets just ignore it and discart any partial
      # messages that we get from it
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

  def dead
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
