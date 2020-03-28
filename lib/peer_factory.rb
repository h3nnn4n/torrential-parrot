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
      tracker.connect
      peer_address = tracker.announce(@torrent)

      peer_address.each do |peer|
        host = peer.first
        port = peer.last

        next if @peer_ips.include?(host)

        @peer_ips << host
        peers << Peer.new(host, port, @torrent.info_hash, tracker.peer_id)
      end
    end

    peers
  end
end
