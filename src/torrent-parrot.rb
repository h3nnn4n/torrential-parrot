require 'bencode'
require 'socket'
require 'pry'
require 'uri'

require_relative 'torrent'
require_relative 'tracker'


data = File.read('torrent.torrent')
torrent_info = BEncode.load(data)

torrent = Torrent.new(torrent_info)

torrent.tracker.connect

nil
