# frozen_string_literal: true

require 'logger'
require 'socket'

class PeerConnection
  attr_reader :info_hash, :peer_id, :host, :port

  def initialize(host, port, info_hash, peer_id)
    @host = host
    @port = port
    @info_hash = info_hash
    @peer_id = peer_id

    logger.info "[PEER_CONNECTION] Created for #{host}:#{port}"
  end

  def connect
    logger.info "[PEER_CONNECTION] attemping to connect to peer at #{host} #{port}"
    socket.puts(handshake_message)
    a = socket.gets

    puts a
  end

  private

  def handshake_message
    [
      pstrlen,
      pstr,
      reserved,
      info_hash,
      peer_id
    ].flatten.pack('Ca19CCCCCCCCa20a20')
  end

  def pstrlen
    19
  end

  def pstr
    'BitTorrent protocol'
  end

  def reserved
    [0, 0, 0, 0, 0, 0, 0, 0]
  end

  def socket
    @socket ||= TCPSocket.new(@host, @port)
  end

  def logger
    @logger ||= Logger.new(STDOUT)
  end
end
