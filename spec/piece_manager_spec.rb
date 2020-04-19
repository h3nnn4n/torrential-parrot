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

  describe '#incomplete_piece' do
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
        manager = torrent.piece_manager

        manager.request_chunk(0, 0)
        manager.receive_chunk(0, 0, file_chunks[0])
      end
    end
  end
end
