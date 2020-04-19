# frozen_string_literal: true

require_relative 'chunk'

class Piece
  CHUNK_SIZE = 16_384

  attr_reader :completed

  def initialize(piece_size, piece_index)
    @piece_size = piece_size
    @piece_index = piece_index
    @completed = false
    @chunks = {}
    @number_of_chunks = piece_size / 16_384
  end

  def index
    @piece_index
  end

  def missing_chunk?
    return true if @chunks.size.zero?
    return true if @chunks.size < @number_of_chunks

    @chunks.values.none?(&:received?)
  end

  def unrequested_chunk?
    return true if @chunks.size.zero?
    return true if @chunks.size < @number_of_chunks

    @chunks.values.none?(&:requested?)
  end

  def at_least_one_request?
    @chunks.size.positive?
  end

  def next_chunk_to_request
    # FIXME: This logic doenst account for gaps
    # It assumes all chunks are requested in a row
    return 0 if @chunks.empty?

    last_chunk = @chunks.keys.max
    next_chunk = (last_chunk + 1) * CHUNK_SIZE

    raise 'Requesting too many chunks for this piece!' if (last_chunk + 1) >= @number_of_chunks

    next_chunk
  end

  def request_chunk(chunk_offset)
    chunk_index = chunk_offset / CHUNK_SIZE
    @chunks[chunk_index] ||= Chunk.new
    @chunks[chunk_index].request

    raise 'Requested too many chunks for this piece!' if chunk_index >= @number_of_chunks
  end

  def receive_chunk(chunk_offset)
    chunk_index = chunk_offset / CHUNK_SIZE
    @chunks[chunk_index].receive

    raise 'This chunk cant possibly exist!' if chunk_index >= @number_of_chunks
  end
end
