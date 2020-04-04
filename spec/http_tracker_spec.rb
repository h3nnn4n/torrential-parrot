# frozen_string_literal: true

require 'http_tracker'

RSpec.describe HttpTracker do
  describe 'stats' do
    it 'tracks number of peers' do
      tracker = described_class.new('http://tracker.opentrackr.org:1337/announce')
      tracker.n_peers = 5
      expect(tracker.n_peers).to eq(5)
    end

    it 'tracks number of leechers' do
      tracker = described_class.new('http://tracker.opentrackr.org:1337/announce')
      tracker.n_leechers = 6
      expect(tracker.n_leechers).to eq(6)
    end

    it 'tracks number of done' do
      tracker = described_class.new('http://tracker.opentrackr.org:1337/announce')
      tracker.n_done = 20
      expect(tracker.n_done).to eq(20)
    end
  end

  describe '#announce' do
    it 'returns a list of peers on success' do
      tracker_url = 'http://bttracker.debian.org:6969/announce'
      tracker = described_class.new(tracker_url)

      allow(tracker).to receive(:peer_id).and_return('-PC0001-200367928925')

      VCR.use_cassette 'http_tracker/announce_debian' do
        expect(tracker.announce(torrent_debian)).to include(['180.150.6.209', 56_734])
      end
    end

    it 'returns false on failure' do
      tracker_url = 'http://bttracker.debian.org:6969/announce'
      tracker = described_class.new(tracker_url)

      allow(HTTParty).to receive(:get).and_raise(Net::ReadTimeout)

      expect(tracker.announce(torrent_debian)).to be(false)
    end
  end
end
