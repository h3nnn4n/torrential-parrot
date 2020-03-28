# frozen_string_literal: true

require 'tracker_factory'

RSpec.describe TrackerFactory do
  describe '#build' do
    it 'returns a list of Trackers' do
      skip('Until I find a way to stub udp calls')

      factory = TrackerFactory.new(torrent2)

      expect(factory.build.size).to eq(3)
      expect(factory.build).to all(be_a(Tracker))
    end
  end
end
