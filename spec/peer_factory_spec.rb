# frozen_string_literal: true

require 'tracker_factory'
require 'peer_factory'

RSpec.describe PeerFactory do
  def trackers
    factory = TrackerFactory.new(torrent2)
    factory.build
  end

  describe '#build' do
    it 'returns a list with all Peers' do
      skip('Until I find a way to stub udp calls')

      factory = described_class.new(trackers, torrent2)

      expect(factory.build.size).to eq(1)
    end

    it 'returns a list of Peers' do
      skip('Until I find a way to stub udp calls')

      factory = described_class.new(trackers, torrent2)

      expect(factory.build).to all(be_a(Peer))
    end
  end
end
