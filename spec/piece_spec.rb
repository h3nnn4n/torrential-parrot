# frozen_string_literal: true

require 'piece'

RSpec.describe Piece do
  describe '#initialize' do
    it 'initializes without exploding' do
      described_class.new(16_384, 0)
    end
  end

  describe '#unrequested_chunk?' do
    it 'returns true if all chunks are empty' do
      piece = described_class.new(16_384, 0)

      expect(piece.unrequested_chunk?).to be(true)
    end

    it 'returns true with only one chunk empty' do
      piece = described_class.new(16_384 * 4, 0)

      (0..2).each do |i|
        piece.request_chunk(16_384 * i)
        piece.receive_chunk(16_384 * i)
      end

      expect(piece.unrequested_chunk?).to be(true)
    end

    it 'returns false when all chunks are requested' do
      piece = described_class.new(16_384 * 4, 0)

      (0..3).each do |i|
        piece.request_chunk(16_384 * i)
      end

      expect(piece.unrequested_chunk?).to be(false)
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

  describe '#request_chunk' do
    it 'raises if an invalid chunk is requested' do
      piece = described_class.new(16_384 * 2, 0)

      expect { piece.request_chunk(16_384 * 2) }.to raise_exception(RuntimeError)
    end
  end

  describe '#next_chunk_to_request' do
    it 'returns 0 if it is the first request' do
      piece = described_class.new(16_384 * 3, 0)

      expect(piece.next_chunk_to_request).to be(0)
    end

    it 'returns second if it is the second request' do
      piece = described_class.new(16_384 * 4, 0)
      piece.request_chunk(0)

      expect(piece.next_chunk_to_request).to be(16_384)
    end

    it 'returns third if it is the third request' do
      piece = described_class.new(16_384 * 4, 0)
      piece.request_chunk(0)
      piece.request_chunk(16_384)

      expect(piece.next_chunk_to_request).to be(16_384 * 2)
    end
  end
end
