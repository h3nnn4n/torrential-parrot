require 'bencode'
require 'torrent'


RSpec.describe Torrent do
  describe '#main_tracker' do
    it 'returns the main treacker' do
      expect(torrent.main_tracker).to eq('udp://tracker.opentrackr.org:1337/announce')
    end
  end

  describe '#info_hash' do
    it 'returns the info_hash' do
      expect(torrent.info_hash).to eq('04c24ad70a7f1bbefe347297bedc1475e6b2daf1')
    end
  end
end


def torrent
  filepath = 'files/potato.torrent'

  data = File.read(filepath)
  torrent_info = BEncode.load(data)

  Torrent.new(torrent_info, data)
end
