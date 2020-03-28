# frozen_string_literal: true

require 'bencode'
require 'torrent'

RSpec.describe Torrent do
  describe '#main_tracker' do
    it 'returns the main treacker' do
      tracker_uri = 'udp://tracker.opentrackr.org:1337/announce'
      expect(torrent.main_tracker).to eq(tracker_uri)
    end
  end

  describe '#info_hash' do
    it 'returns the info_hash' do
      info_hash = '04c24ad70a7f1bbefe347297bedc1475e6b2daf1'
      expect(torrent.info_hash).to eq(info_hash)
    end
  end
end

def torrent
  filepath = 'files/potato.torrent'

  data = File.read(filepath)
  torrent_info = BEncode.load(data)

  Torrent.new(torrent_info, data)
end
