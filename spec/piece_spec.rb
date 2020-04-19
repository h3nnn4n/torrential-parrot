# frozen_string_literal: true

require 'piece'

RSpec.describe Piece do
  describe '#initialize' do
    it 'initializes without exploding' do
      described_class.new(16_384, 0)
    end
  end

  describe '#missing_chunk?' do
    it 'returns true if all chunks are empty' do
      piece = described_class.new(16_384, 0)

      expect(piece.missing_chunk?).to be(true)
    end

    it 'returns true with only one chunk empty' do
      piece = described_class.new(16_384 * 4, 0)

      (0..2).each do |i|
        piece.request_chunk(16_384 * i)
        piece.receive_chunk(16_384 * i)
      end

      expect(piece.missing_chunk?).to be(true)
    end

    it 'returns false when all chunks were received' do
      piece = described_class.new(16_384 * 4, 0)

      (0..3).each do |i|
        piece.request_chunk(16_384 * i)
        piece.receive_chunk(16_384 * i)
      end

      expect(piece.missing_chunk?).to be(false)
    end
  end
end
