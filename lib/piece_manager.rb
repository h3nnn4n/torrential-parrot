# frozen_string_literal: true

require_relative 'piece'
require_relative 'ninja_logger'

class PieceManager
  def initialize(torrent)
    @torrent = torrent
    @pieces = {}
  end

  def piece_size
    @torrent.piece_size
  end

  def torrent_size
    @torrent.size
  end

  def number_of_pieces
    torrent_size / piece_size
  end

  def started_piece_missing_chunks
    missing_chunks = @pieces.values.select do |piece|
      piece.at_least_one_request? && piece.missing_chunk?
    end

    missing_chunks.first
  end

  def incomplete_piece(bitfield)
    bitfield.all_bits_set_index.each do |piece_index|
      @pieces[piece_index] ||= Piece.new(piece_size, piece_index)
      @pieces[piece_index].tap do |piece|
        next piece unless piece.missing_chunk?
        next piece unless piece.unrequested_chunk?

        return piece
      end
    end
  end

  def request_chunk(piece_index, chunk_offset)
    @pieces[piece_index] ||= Piece.new(piece_size, piece_index)
    @pieces[piece_index].tap do |piece|
      piece.request_chunk(chunk_offset)
    end
  end

  def receive_chunk(piece_index, chunk_offset)
    @pieces[piece_index].tap do |piece|
      piece.receive_chunk(chunk_offset)
    end
  end

  def completed_count
    @pieces.values.select(&:completed?).count
  end

  def missing_count
    number_of_pieces - @pieces.values.select(&:completed?).count
  end

  def print_status
    data = [
      '[TRANSFER_STATUS]',
      "completed: #{completed_count} ",
      "missing: #{missing_count} ",
      "progress: #{completed_count.to_f / number_of_pieces * 100.0}% "
    ]

    msg = data.join(' ')
    logger.info msg
  end

  def logger
    NinjaLogger.logger
  end
end
