# frozen_string_literal: true

require 'tracker_factory'
require 'peer_factory'

RSpec.describe PeerFactory do
  def trackers
    factory = TrackerFactory.new(torrent2)
    factory.build
  end

  describe '#build' do
    it 'returns a list of Peers' do
      factory = PeerFactory.new(trackers, torrent2)

      expect(factory.build.size).to eq(1)
      expect(factory.build).to all(be_a(Peer))
    end
  end
end
