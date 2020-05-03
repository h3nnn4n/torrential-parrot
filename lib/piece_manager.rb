# frozen_string_literal: true

require_relative 'config'
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
      lazy_build_piece(piece_index)
      @pieces[piece_index].tap do |piece|
        next piece unless piece.missing_chunk? || piece.timedout_chunks?
        next piece unless piece.unrequested_chunk? || piece.timedout_chunks?

        return piece
      end
    end

    nil
  end

  def request_chunk(piece_index, chunk_offset)
    lazy_build_piece(piece_index)
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
    chunk_index = chunk_offset / Config.chunk_size
    last_piece?(piece_index) && chunk_index == last_piece_number_of_chunks - 1
  end

  def last_piece_number_of_chunks
    total_chunks = (torrent_size / Config.chunk_size.to_f).ceil
    n = total_chunks % number_of_chunks
    n = number_of_chunks if n.zero?
    n
  end

  def last_piece?(piece_index)
    piece_index == number_of_pieces - 1
  end

  def number_of_chunks
    piece_size / Config.chunk_size
  end

  def last_chunk_size
    size = torrent_size % Config.chunk_size
    return size unless size.zero?

    Config.chunk_size
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
        pending << [piece_index, chunk_index * Config.chunk_size] if chunk.pending?
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

  def lazy_build_piece(piece_index)
    this_number_of_chunks =
      if last_piece?(piece_index)
        last_piece_number_of_chunks
      else
        number_of_chunks
      end

    @pieces[piece_index] ||= Piece.new(piece_size,
                                       piece_index,
                                       number_of_chunks: this_number_of_chunks)
  end

  def chunk_status
    piece_index = piece_indexes_failing_hash.first
    return if piece_index.nil?

    piece = @pieces[piece_index]

    status = piece.chunks.values.map do |chunk|
      if chunk.pending?
        'P'
      elsif chunk.timedout?
        'T'
      elsif chunk.received?
        '.'
      else
        '?'
      end
    end

    status.join
  end

  def print_status
    data = [
      '[TRANSFER_STATUS]',
      "t: #{number_of_pieces} ",
      "c: #{completed_count} ",
      "m: #{missing_count} ",
      "p: #{pending_chunks_count} ",
      "f: #{piece_indexes_failing_hash.count} ",
      "%: #{(completed_count.to_f / number_of_pieces * 100.0).round(2)}% ",
      "#{piece_indexes_failing_hash.first} #{chunk_status}"
    ]

    msg = data.join(' ')
    logger.info msg
  end

  def logger
    NinjaLogger.logger
  end
end
