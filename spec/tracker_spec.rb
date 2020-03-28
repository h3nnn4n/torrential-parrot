# frozen_string_literal: true

require 'tracker'

RSpec.describe Tracker do
  describe '#scheme' do
    it 'it returns udp' do
      tracker = Tracker.new('udp://tracker.opentrackr.org:1337/announce')

      expect(tracker.scheme).to eq('udp')
    end

    it 'it raises exception for http' do
      uri = 'http://tracker.opentrackr.org:1337/announce'

      expect { Tracker.new(uri) }.to raise_exception(RuntimeError)
    end

    it 'it raises exception for tcp' do
      uri = 'tcp://tracker.opentrackr.org:1337/announce'

      expect { Tracker.new(uri) }.to raise_exception(RuntimeError)
    end
  end
end
