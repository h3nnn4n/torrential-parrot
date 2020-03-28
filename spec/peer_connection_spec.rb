# frozen_string_literal: true

require 'peer_connection'

RSpec.describe PeerConnection do
  describe '#initialize' do
    it 'initializes' do
      PeerConnection.new('127.0.0.1', 6881, '123', '456')
    end
  end

  describe '#handshake_message' do
    it 'is 68 bytes long' do
      c = PeerConnection.new('127.0.0.1', 6881, '123', '456')

      expect(c.send(:handshake_message).size).to eq(68)
    end
  end
end
