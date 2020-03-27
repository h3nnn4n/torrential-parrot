require 'bencode'
require 'socket'
require 'pry'
require 'uri'

require_relative 'torrent'
require_relative 'tracker'


filename = ARGV[0]

data = File.read(filename)
torrent_info = BEncode.load(data)

torrent = Torrent.new(torrent_info, data)
tracker = Tracker.new(torrent.main_tracker)

tracker.connect
tracker.announce(torrent.info_hash)

nil
