# frozen_string_literal: true

require 'bencode'
require 'pry'

require_relative 'ninja_logger'
require_relative 'peer'
require_relative 'peer_factory'
require_relative 'peer_manager'
require_relative 'torrent'
require_relative 'tracker'
require_relative 'tracker_factory'
require_relative 'torrent_manager'

NinjaLogger.set_logger_to_stdout

filename = ARGV[0]

data = File.read(filename)
torrent_info = BEncode.load(data)

torrent = Torrent.new(torrent_info, data)

TorrentManager.add_torrent(torrent)

tracker_factory = TrackerFactory.new(torrent)
trackers = tracker_factory.build

peer_factory = PeerFactory.new(trackers, torrent)
peers = peer_factory.build

peer_manager = PeerManager.new
peers.each { |peer| peer_manager.add_peer(peer) }

loop do
  peer_manager.print_status
  break if peers.size.zero?

  peer_manager.read_and_dispatch_messages
  peer_manager.send_messages
  sleep 0.2
end

nil
