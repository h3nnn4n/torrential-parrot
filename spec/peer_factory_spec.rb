# frozen_string_literal: true

require 'tracker_factory'
require 'peer_factory'

RSpec.describe PeerFactory do
  def trackers
    factory = TrackerFactory.new(torrent2)
    tracker_list = factory.build

    tracker_list.each do |tracker|
      allow(tracker).to receive(:connect).and_return(true)
      allow(tracker).to receive(:announce).and_return([['186.232.38.137', 6_881]])
    end

    tracker_list
  end

  describe '#build' do
    it 'returns a list with all Peers' do
      factory = described_class.new(trackers, torrent2)

      expect(factory.build.size).to eq(1)
    end

    it 'returns a list of Peers' do
      factory = described_class.new(trackers, torrent2)

      expect(factory.build).to all(be_a(Peer))
    end
  end
end
