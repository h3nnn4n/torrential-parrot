# frozen_string_literal: true

require_relative 'chunk'

class Piece
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

  def at_least_one_request?
    @chunks.size.positive?
  end

  def request_chunk(chunk_offset, chunk_size)
    chunk_index = chunk_offset / chunk_size
    @chunks[chunk_index] ||= Chunk.new
    @chunks[chunk_index].request
  end

  def receive_chunk(chunk_offset, chunk_size)
    chunk_index = chunk_offset / chunk_size
    @chunks[chunk_index].receive
  end
end
