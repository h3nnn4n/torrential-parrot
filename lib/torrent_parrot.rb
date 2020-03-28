# frozen_string_literal: true

require 'bencode'
require 'pry'

require_relative 'peer'
require_relative 'peer_factory'
require_relative 'torrent'
require_relative 'tracker'
require_relative 'tracker_factory'

filename = ARGV[0]

data = File.read(filename)
torrent_info = BEncode.load(data)

torrent = Torrent.new(torrent_info, data)

tracker_factory = TrackerFactory.new(torrent)
trackers = tracker_factory.build

puts 'finished tracker exchange'

peer_factory = PeerFactory.new(trackers, torrent)
peers = peer_factory.build

# raw_peers = [
#   ['94.154.214.24', 61707],
#   ['2.50.238.161', 4989],
#   ['50.34.37.71', 34217],
#   ['192.131.44.101', 57991],
#   ['187.41.141.120', 8999],
#   ['88.91.171.29', 63640],
#   ['60.152.205.82', 6881],
#   ['177.156.240.173', 64587],
#   ['109.63.209.123', 4950],
#   ['69.10.35.12', 63047]
# ]
#
# peers = raw_peers.map do |host, port|
#   Peer.new(host, port, torrent.info_hash, trackers.first.peer_id)
# end

puts 'finished peer exchange'

peers.map(&:connect).map(&:join)

nil
