# frozen_string_literal: true

require 'set'

require_relative 'peer'

class PeerFactory
  def initialize(trackers, torrent)
    @trackers = trackers
    @torrent = torrent

    @peer_ips = Set.new
  end

  def build
    peers = []

    @trackers.each do |tracker|
      next unless tracker.connect

      peer_address = tracker.announce(@torrent)
      next if peer_address == false

      peer_address.each do |peer|
        host = peer.first
        port = peer.last

        next if @peer_ips.include?(host)

        @peer_ips << host
        peers << Peer.new(
          host,
          port,
          @torrent.info_hash,
          tracker.peer_id,
          peer_n: @peer_ips.size - 1
        )
      end
    end

    peers.compact!

    peers
  end
end
