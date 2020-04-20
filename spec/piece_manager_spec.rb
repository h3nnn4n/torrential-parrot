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

  describe '#number_of_pieces' do
    it 'is 1_340 for debian' do
      manager = described_class.new(torrent_debian)

      expect(manager.number_of_pieces).to eq(torrent_debian.number_of_pieces)
    end

    it 'is 34 for pi6' do
      manager = described_class.new(torrent_pi6)

      expect(manager.number_of_pieces).to eq(torrent_pi6.number_of_pieces)
    end
  end

  describe '#last_chunk?' do
    it 'returns false for the first chunk' do
      manager = described_class.new(torrent_pi6)

      expect(manager.last_chunk?(0, 0)).to be(false)
    end

    it 'returns false for the second chunk of the first piece' do
      manager = described_class.new(torrent_pi6)

      expect(manager.last_chunk?(1, 16_384)).to be(false)
    end

    it 'returns false for the first chunk of the last piece' do
      manager = described_class.new(torrent_pi6)

      expect(manager.last_chunk?(33, 0)).to be(false)
    end

    it 'returns true for the last chunk of the last piece' do
      manager = described_class.new(torrent_pi6)

      expect(manager.last_chunk?(33, 16_384)).to be(true)
    end
  end

  describe '#last_chunk_size' do
    it 'returns the correct value' do
      manager = described_class.new(torrent_pi6)

      expect(manager.last_chunk_size).to eq(13_375)
    end
  end

  describe '#torrent_size' do
    it 'is 351_272_960 for debian' do
      manager = described_class.new(torrent_debian)

      expect(manager.torrent_size).to eq(351_272_960)
    end

    it 'is 42 for pi6' do
      manager = described_class.new(torrent_pi6)

      expect(manager.torrent_size).to eq(1_111_103)
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
    def file_chunks
      file = File.read('spec/files/downloads/pi6.txt')

      data = []
      data << file.slice!(0, 16_384) until file.empty?
      data
    end

    it 'returns nil if there is nothing left to do' do
      manager = torrent.piece_manager

      fake_payload = [2, 5, 1].pack('NCC')
      bitfield = BitField.new(torrent.number_of_pieces)
      bitfield.populate(fake_payload)

      piece_payload = File.read('spec/files/downloads/potato.txt')
      manager.request_chunk(0, 0)
      manager.receive_chunk(0, 0, piece_payload)

      expect(manager.incomplete_piece(bitfield)).to be(nil)
    end

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

    it 'retries pieces that failed integrity check' do
      manager = torrent_pi6.piece_manager

      manager.request_chunk(0, 0)
      manager.request_chunk(0, 16_384)
      manager.receive_chunk(0, 0, file_chunks[0])
      manager.receive_chunk(0, 16_384, 'wrong payload')

      manager.request_chunk(1, 0)
      manager.request_chunk(1, 16_384)
      manager.receive_chunk(1, 0, file_chunks[2])
      manager.receive_chunk(1, 16_384, file_chunks[3])

      payload = File.read('spec/files/peer_messages/pi6_bitfield.dat')
      bitfield = BitField.new(torrent_pi6.number_of_pieces)
      bitfield.populate(payload)
      piece = manager.incomplete_piece(bitfield)

      expect(piece.index).to eq(0)
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
        manager = torrent.piece_manager

        manager.request_chunk(0, 0)
        manager.receive_chunk(0, 0, file_chunks[0])
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
        manager = torrent_pi6.piece_manager

        manager.request_chunk(0, 0)
        manager.request_chunk(0, 16_384)
        manager.receive_chunk(0, 0, file_chunks[0])
        manager.receive_chunk(0, 16_384, file_chunks[1])

        expect(manager.completed_count).to eq(1)
      end

      it 'fails integrity check and piece is reset' do
        manager = torrent_pi6.piece_manager

        manager.request_chunk(0, 0)
        manager.request_chunk(0, 16_384)
        manager.receive_chunk(0, 0, file_chunks[0])
        manager.receive_chunk(0, 16_384, 'this is totally the wrong payload')

        expect(manager.completed_count).to eq(0)
      end
    end
  end
end
