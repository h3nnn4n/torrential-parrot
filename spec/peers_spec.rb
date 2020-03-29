# frozen_string_literal: true

require 'peer'

RSpec.describe Peer do
  peer_id = '00000000000000000000'

  describe '#initialize' do
    it 'initializes' do
      described_class.new('127.0.0.1', 6881, torrent, peer_id)
    end
  end
end
