# frozen_string_literal: true

require 'digest'

require_relative 'piece_manager'

class Torrent
  attr_reader :piece_manager

  def initialize(bdata, raw_data)
    @bdata = bdata
    @raw_data = raw_data
    @piece_manager = PieceManager.new(self)
  end

  def main_tracker
    @bdata['announce']
  end

  def trackers
    @trackers ||=
      @bdata['announce-list']&.flatten || [main_tracker]
  end

  def hash_for_piece(piece_index)
    pieces[piece_index]
  end

  def pieces
    @pieces ||= begin
      data = []
      tmp = @bdata.dig('info', 'pieces')
      data << tmp.slice!(0, 20) until tmp.empty?
      data
    end
  end

  def size
    @size ||= begin
                @bdata['info']['length'] ||
                  @bdata['info']['files'].map { |file| file['length'] }.sum
              end
  end

  def piece_size
    @bdata['info']['piece length']
  end

  def info_hash
    @info_hash ||= begin
      starter_index = @raw_data.index('4:info') + 6
      end_index = @raw_data.size - 2

      info_data = @raw_data[starter_index..end_index]

      Digest::SHA1.hexdigest(info_data)
    end
  end

  def info_hash_packed
    [info_hash].pack('H*')
  end
end
