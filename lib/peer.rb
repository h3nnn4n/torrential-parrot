# frozen_string_literal: true

require 'forwardable'
require 'logger'

require_relative 'ninja_logger'
require_relative 'peer_connection'

class Peer
  extend Forwardable

  def_delegators :connection, :connect

  def initialize(host, port, info_hash, peer_id, peer_n: nil)
    @host = host
    @port = port
    @info_hash = info_hash
    @peer_id = peer_id

    @peer_n = peer_n || rand(65_535)

    logger.info "[PEER] Created peer #{host}:#{port}"
  end

  private

  def connection
    @connection ||= PeerConnection.new(
      @host,
      @port,
      @info_hash,
      @peer_id,
      peer_n: @peer_n
    )
  end

  def logger
    NinjaLogger.logger
  end
end
