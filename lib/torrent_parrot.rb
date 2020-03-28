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

peer_factory = PeerFactory.new(trackers, torrent)
peers = peer_factory.build

peers.map(&:connect)

nil
