# frozen_string_literal: true

require 'tracker'

RSpec.describe Tracker do
  describe '#scheme' do
    it 'it returns udp' do
      tracker = Tracker.new('udp://tracker.opentrackr.org:1337/announce')

      expect(tracker.scheme).to eq('udp')
    end

    it 'it returns https' do
      tracker = Tracker.new('https://tracker.opentrackr.org:1337/announce')

      expect(tracker.scheme).to eq('https')
    end

    it 'it returns http' do
      tracker = Tracker.new('http://tracker.opentrackr.org:1337/announce')

      expect(tracker.scheme).to eq('http')
    end

    it 'it raises exception for tcp' do
      uri = 'tcp://tracker.opentrackr.org:1337/announce'

      expect { Tracker.new(uri) }.to raise_exception(RuntimeError)
    end
  end
end
