# frozen_string_literal: true

require 'piece'

RSpec.describe Piece do
  def fake_payload
    [0, 1, 2, 3].pack('C*')
  end

  describe '#initialize' do
    it 'initializes without exploding' do
      described_class.new(16_384, 0)
    end
  end

  describe '#timedout_chunks?' do
    it 'returns false when nothing was ever requested' do
      piece = described_class.new(16_384 * 2, 0)

      expect(piece.timedout_chunks?).to be(false)
    end

    it 'returns false when there is nothing pending' do
      piece = described_class.new(16_384 * 3, 0)
      piece.request_chunk(0)

      expect(piece.timedout_chunks?).to be(false)
    end

    it 'returns true when a chunk timed out' do
      now = Time.now

      piece = described_class.new(16_384 * 3, 0)

      Timecop.freeze(now) do
        piece.request_chunk(0)
      end

      Timecop.freeze(now + Config.chunk_request_timeout + 0.5) do
        expect(piece.timedout_chunks?).to be(true)
      end
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
        piece.receive_chunk(16_384 * i, fake_payload)
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
        piece.receive_chunk(16_384 * i, fake_payload)
      end

      expect(piece.missing_chunk?).to be(true)
    end

    it 'returns false when all chunks were received' do
      piece = described_class.new(16_384 * 4, 0)

      (0..3).each do |i|
        piece.request_chunk(16_384 * i)
        piece.receive_chunk(16_384 * i, fake_payload)
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

    it 'raises if too many chunks are requested' do
      piece = described_class.new(16_384 * 4, 0)
      (0..3).each do |index|
        piece.request_chunk(16_384 * index)
      end

      expect { piece.next_chunk_to_request }.to raise_exception(RuntimeError)
    end

    it 'returns timeout out chunk' do
      now = Time.now
      piece = described_class.new(16_384 * 4, 0)

      Timecop.freeze(now) do
        (0..3).each do |index|
          piece.request_chunk(16_384 * index)
        end
      end

      Timecop.freeze(now + Config.chunk_request_timeout + 0.5) do
        expect(piece.next_chunk_to_request).to be(0)
      end
    end
  end

  describe '#completed?' do
    it 'is not completed on creation' do
      piece = described_class.new(16_384 * 2, 0)

      expect(piece.completed?).to be(false)
    end

    it 'returns false if there is a chunk missing' do
      piece = described_class.new(16_384 * 4, 0)

      (0..2).each do |i|
        piece.request_chunk(16_384 * i)
        piece.receive_chunk(16_384 * i, fake_payload)
      end

      expect(piece.completed?).to be(false)
    end

    it 'returns false if everything is pending' do
      piece = described_class.new(16_384 * 4, 0)

      (0..3).each do |i|
        piece.request_chunk(16_384 * i)
      end

      expect(piece.completed?).to be(false)
    end

    it 'returns false if there is a chunk missing and another pending' do
      piece = described_class.new(16_384 * 4, 0)

      (0..2).each do |i|
        piece.request_chunk(16_384 * i)
        piece.receive_chunk(16_384 * i, fake_payload)
      end

      expect(piece.completed?).to be(false)

      piece.request_chunk(16_384 * 3)

      expect(piece.completed?).to be(false)
    end

    it 'returns true if all chunks are present' do
      piece = described_class.new(16_384 * 4, 0)

      (0..3).each do |i|
        piece.request_chunk(16_384 * i)
        piece.receive_chunk(16_384 * i, fake_payload)
      end

      expect(piece.completed?).to be(true)
    end

    it 'returns false if piece is reset' do
      piece = described_class.new(16_384 * 4, 0)

      (0..3).each do |i|
        piece.request_chunk(16_384 * i)
        piece.receive_chunk(16_384 * i, fake_payload)
      end

      piece.reset_chunks

      expect(piece.completed?).to be(false)
    end
  end

  describe '#integrity_check' do
    describe 'single chunk file' do
      def file_chunks
        file = File.read('spec/files/downloads/potato.txt')

        data = []
        data << file.slice!(0, 16_384) until file.empty?
        data
      end

      it 'passes integrity check' do
        piece = described_class.new(16_384 * 4, 0)
        piece.piece_hash = torrent.hash_for_piece(0)
        piece.request_chunk(0)
        piece.receive_chunk(0, file_chunks.first)

        expect(piece.integrity_check).to be(true)
      end

      it 'fails integrity check' do
        piece = described_class.new(16_384 * 4, 0)
        piece.piece_hash = torrent.hash_for_piece(0)
        piece.request_chunk(0)
        piece.receive_chunk(0, 'totally the wrong piece')

        expect(piece.integrity_check).to be(false)
      end
    end

    describe 'multiple chunks and pieces file' do
      def file_chunks
        file = File.read('spec/files/downloads/pi6.txt')

        data = []
        data << file.slice!(0, 16_384) until file.empty?
        data
      end

      it 'passes integrity check' do
        hash = torrent_pi6.hash_for_piece(0)
        piece = described_class.new(16_384 * 2, 0, piece_hash: hash)
        piece.request_chunk(0)
        piece.receive_chunk(0, file_chunks[0])
        piece.request_chunk(16_384)
        piece.receive_chunk(16_384, file_chunks[1])

        expect(piece.integrity_check).to be(true)
      end

      it 'fails integrity check' do
        hash = torrent_pi6.hash_for_piece(0)
        piece = described_class.new(16_384 * 2, 0, piece_hash: hash)
        piece.request_chunk(0)
        piece.receive_chunk(0, 'dummy')
        piece.request_chunk(16_384)
        piece.receive_chunk(16_384, file_chunks[1])

        expect(piece.integrity_check).to be(false)
      end

      it 'fails on an empty piece' do
        hash = torrent_pi6.hash_for_piece(0)
        piece = described_class.new(16_384 * 2, 0, piece_hash: hash)

        expect(piece.integrity_check).to be(false)
      end

      it 'fails on a chunk piece' do
        hash = torrent_pi6.hash_for_piece(0)
        piece = described_class.new(16_384 * 2, 0, piece_hash: hash)
        piece.request_chunk(0)

        expect(piece.integrity_check).to be(false)
      end
    end
  end
end
