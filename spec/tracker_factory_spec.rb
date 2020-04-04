# frozen_string_literal: true

require 'tracker_factory'

RSpec.describe TrackerFactory do
  describe '#build' do
    it 'returns a list of Trackers' do
      factory = described_class.new(torrent2)

      expect(factory.build).to all(be_a(Tracker))
    end

    it 'returns all elements' do
      factory = described_class.new(torrent2)

      expect(factory.build.size).to eq(3)
    end
  end
end
