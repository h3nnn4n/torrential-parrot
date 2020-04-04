# frozen_string_literal: true

require 'udp_tracker'

RSpec.describe UdpTracker do
  def connect_payload
    [File.read('spec/files/udp_tracker/udp_connect_response.dat'), nil]
  end

  describe 'connect' do
    it 'receives a connection_id' do
      tracker_url = 'udp://tracker.opentrackr.org:1337/announce'
      tracker = described_class.new(tracker_url)

      socket = double(send: true, recvfrom: connect_payload)
      allow(tracker).to receive(:socket).and_return(socket)
      allow(tracker).to receive(:transaction_id).and_return(63_040) # Random

      tracker.connect

      expect(tracker.connection_id).to eq(0x92804b684d0725d8)
    end

    it 'returns true on success' do
      tracker_url = 'udp://tracker.opentrackr.org:1337/announce'
      tracker = described_class.new(tracker_url)

      socket = double(send: true, recvfrom: connect_payload)
      allow(tracker).to receive(:socket).and_return(socket)
      allow(tracker).to receive(:transaction_id).and_return(63_040) # Random

      expect(tracker.connect).to be(true)
    end

    it 'returns false on ECONNREFUSED' do
      tracker_url = 'udp://tracker.opentrackr.org:1337/announce'
      tracker = described_class.new(tracker_url)

      allow(tracker).to receive(:socket).and_raise(SocketError)

      expect(tracker.connect).to be(false)
    end

    it 'returns false on SocketError' do
      tracker_url = 'udp://tracker.opentrackr.org:1337/announce'
      tracker = described_class.new(tracker_url)

      allow(tracker).to receive(:socket).and_raise(Errno::ECONNREFUSED)

      expect(tracker.connect).to be(false)
    end

    it 'returns false if transaction_id doesnt match' do
      tracker_url = 'udp://tracker.opentrackr.org:1337/announce'
      tracker = described_class.new(tracker_url)

      socket = double(send: true, recvfrom: connect_payload)
      allow(tracker).to receive(:socket).and_return(socket)
      allow(tracker).to receive(:transaction_id).and_return(43_702) # Random

      expect(tracker.connect).to be(false)
    end
  end
end
