# frozen_string_literal: true

require 'bencode'
require 'pry'

require_relative 'torrent'
require_relative 'tracker'

filename = ARGV[0]

data = File.read(filename)
torrent_info = BEncode.load(data)

torrent = Torrent.new(torrent_info, data)
tracker = Tracker.new(torrent.main_tracker)

tracker.connect
tracker.announce(torrent)

nil
