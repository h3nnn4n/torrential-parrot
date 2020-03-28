# frozen_string_literal: true

require 'bencode'
require 'pry'

require_relative 'torrent'
require_relative 'tracker'
require_relative 'peer'

filename = ARGV[0]

data = File.read(filename)
torrent_info = BEncode.load(data)

torrent = Torrent.new(torrent_info, data)
tracker = Tracker.new(torrent.main_tracker)

tracker.connect
peer_address = tracker.announce(torrent)
peers = []

peer_address.each do |peer|
  host = peer.first
  port = peer.last

  peers << Peer.new(host, port, torrent.info_hash, tracker.peer_id)
end

peers.map(&:connect)

nil
