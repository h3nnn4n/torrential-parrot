# frozen_string_literal: true

require 'tracker_factory'

RSpec.describe TrackerFactory do
  describe '#build' do
    it 'returns a list of Trackers' do
      skip('Until I find a way to stub udp calls')

      factory = described_class.new(torrent2)

      expect(factory.build).to all(be_a(Tracker))
    end

    it 'returns all elements' do
      skip('Until I find a way to stub udp calls')

      factory = described_class.new(torrent2)

      expect(factory.build.size).to eq(3)
    end
  end
end
