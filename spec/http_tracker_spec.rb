# frozen_string_literal: true

require 'http_tracker'

RSpec.describe HttpTracker do
  describe 'stats' do
    it 'tracks number of peers' do
      tracker = HttpTracker.new('http://tracker.opentrackr.org:1337/announce')

      expect(tracker.n_peers).to eq(nil)
      expect(tracker.n_leechers).to eq(nil)
      expect(tracker.n_done).to eq(nil)

      tracker.n_peers = 5
      tracker.n_leechers = 6
      tracker.n_done = 20

      expect(tracker.n_peers).to eq(5)
      expect(tracker.n_leechers).to eq(6)
      expect(tracker.n_done).to eq(20)
    end
  end
end
