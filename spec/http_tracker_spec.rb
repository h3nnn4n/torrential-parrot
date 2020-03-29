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
end
