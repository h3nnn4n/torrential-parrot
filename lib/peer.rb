# frozen_string_literal: true

require 'forwardable'
require 'logger'

require_relative 'ninja_logger'
require_relative 'peer_connection'

class Peer
  extend Forwardable

  def_delegators :connection, :connect, :socket, :process_message, :terminate,
                 :idle_timeout?

  attr_reader :peer_n

  def initialize(host, port, torrent, peer_id, peer_n: nil)
    @host = host
    @port = port
    @info_hash = torrent.info_hash
    @peer_id = peer_id
    @torrent = torrent

    @peer_n = peer_n || rand(65_535)

    # logger.info "[PEER] Created peer #{host}:#{port}"
  end

  def connection
    @connection ||= build_connection
  end

  def recycle
    @connection = build_connection
  end

  private

  def build_connection
    PeerConnection.new(
      @host,
      @port,
      @torrent,
      @peer_id,
      peer_n: @peer_n
    )
  end

  def logger
    NinjaLogger.logger
  end
end
