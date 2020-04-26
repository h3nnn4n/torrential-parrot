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
    (torrent_size.to_f / piece_size).ceil
  end

  def hash_for_piece(index)
    @torrent.hash_for_piece(index)
  end

  def started_piece_missing_chunks
    missing_chunks = @pieces.values.select do |piece|
      piece.at_least_one_request? && piece.missing_chunk?
    end

    missing_chunks.first
  end

  def download_finished?
    completed_count == number_of_pieces && piece_indexes_failing_hash.size.zero?
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

    nil
  end

  def request_chunk(piece_index, chunk_offset)
    @pieces[piece_index] ||= Piece.new(piece_size, piece_index)
    @pieces[piece_index].tap do |piece|
      piece.request_chunk(chunk_offset)
    end
  end

  def receive_chunk(piece_index, chunk_offset, payload)
    return if @pieces[piece_index].nil?

    @pieces[piece_index].tap do |piece|
      piece.receive_chunk(chunk_offset, payload)
      break unless piece.completed?

      piece.piece_hash = hash_for_piece(piece_index)
      break if piece.integrity_check

      piece.reset_chunks
    end
  end

  def last_chunk?(piece_index, chunk_offset)
    chunk_index = chunk_offset / Piece::CHUNK_SIZE
    piece_index == number_of_pieces - 1 && chunk_index == number_of_chunks - 1
  end

  def number_of_chunks
    piece_size / Piece::CHUNK_SIZE
  end

  def last_chunk_size
    torrent_size % Piece::CHUNK_SIZE
  end

  def all_chunks
    chunks =
      (0..(number_of_pieces - 1)).map do |piece_index|
        (0..(number_of_chunks - 1)).map do |chunk_index|
          @pieces[piece_index].chunks[chunk_index].payload
        end
      end

    chunks.flatten
  end

  def pending_chunks
    pending = []

    @pieces.each do |piece_index, piece|
      piece.chunks.each do |chunk_index, chunk|
        pending << [piece_index, chunk_index * Piece::CHUNK_SIZE] if chunk.pending?
      end
    end

    pending
  end

  def pending_chunks_count
    pending_chunks.count
  end

  def completed_count
    @pieces.values.select(&:completed?).count
  end

  def missing_count
    number_of_pieces - @pieces.values.select(&:completed?).count
  end

  def piece_indexes_failing_hash
    indexes = []

    @pieces.each_value do |piece|
      indexes << piece.index unless piece.integrity_check
    end

    indexes
  end

  def print_status
    data = [
      '[TRANSFER_STATUS]',
      "t: #{number_of_pieces} ",
      "c: #{completed_count} ",
      "m: #{missing_count} ",
      "p: #{pending_chunks_count} ",
      "%: #{(completed_count.to_f / number_of_pieces * 100.0).round(2)}% ",
      "f: #{piece_indexes_failing_hash} "
    ]

    msg = data.join(' ')
    logger.info msg
  end

  def logger
    NinjaLogger.logger
  end
end
