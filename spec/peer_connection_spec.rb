# frozen_string_literal: true

require 'peer_connection'

RSpec.describe PeerConnection do
  info_hash = '9fc6c0759cf7f7614ae25f5293d6bf7638115321'
  peer_id = '00000000000000000000'

  describe '#initialize' do
    it 'initializes without exploding' do
      described_class.new('127.0.0.1', 6881, info_hash, peer_id)
    end
  end

  describe '#handshake_message' do
    it 'is 68 bytes long #message' do
      c = described_class.new('127.0.0.1', 6881, info_hash, peer_id)

      expect(c.send(:handshake_message).size).to eq(68)
    end
  end
end
