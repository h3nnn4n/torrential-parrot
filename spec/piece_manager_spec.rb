# frozen_string_literal: true

require 'piece_manager'
require 'bit_field'
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

    it 'returns a piece' do
      manager = described_class.new(torrent)
      manager.request_chunk(0, 0)

      expect(manager.started_piece_missing_chunks).to be_a(Piece)
    end
  end

  describe '#incomplete_piece' do
    it 'returns an incomplete piece' do
      manager = described_class.new(torrent)

      fake_payload = [2, 5, 15].pack('NCC')
      bitfield = BitField.new(8)
      bitfield.populate(fake_payload)

      expect(manager.incomplete_piece(bitfield)).to be_a(Piece)
    end

    it 'returns the only incomplete piece' do
      manager = described_class.new(torrent)

      fake_payload = [2, 5, 16].pack('NCC')
      bitfield = BitField.new(8)
      bitfield.populate(fake_payload)
      piece = manager.incomplete_piece(bitfield)

      expect(piece.index).to eq(4)
    end
  end
end
