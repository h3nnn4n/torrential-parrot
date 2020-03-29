# frozen_string_literal: true

require 'tracker'

RSpec.describe Tracker do
  info_hash = 'cdae19ff30af2e5f6f71ecbab8155f384a300148'

  describe '#scheme' do
    it 'returns udp' do
      tracker = described_class.new('udp://tracker.opentrackr.org:1337/announce', info_hash)

      expect(tracker.scheme).to eq('udp')
    end

    it 'returns https' do
      tracker = described_class.new('https://tracker.opentrackr.org:1337/announce', info_hash)

      expect(tracker.scheme).to eq('https')
    end

    it 'returns http' do
      tracker = described_class.new('http://tracker.opentrackr.org:1337/announce', info_hash)

      expect(tracker.scheme).to eq('http')
    end

    it 'raises exception for tcp' do
      uri = 'tcp://tracker.opentrackr.org:1337/announce'

      expect { described_class.new(uri, info_hash) }.to raise_exception(RuntimeError)
    end
  end
end
