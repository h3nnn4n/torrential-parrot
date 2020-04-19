# frozen_string_literal: true

require 'piece_manager'
require 'piece'

RSpec.describe PieceManager do
  describe '#initialize' do
    it 'initializes without exploding' do
      described_class.new(torrent)
    end
  end

  describe '#started_piece_missing_chunks' do
    it 'returns nil if all pieces are empty' do
      manager = described_class.new(torrent)

      expect(manager.started_piece_missing_chunks).to be_nil
    end

    it 'returns a piece missing at least a chunk' do
      manager = described_class.new(torrent)
      manager.request_chunk(0, 0, 16_384)

      expect(manager.started_piece_missing_chunks).to be_a(Piece)
    end
  end
end
