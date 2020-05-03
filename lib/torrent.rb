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
    pieces_hash[piece_index]
  end

  def pieces_hash
    @pieces_hash ||= begin
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

  def single_file?
    files.nil?
  end

  def files
    @bdata.dig('info', 'files')
  end

  def file_name
    @bdata['info']['name']
  end

  def piece_size
    @bdata['info']['piece length']
  end

  def number_of_pieces
    pieces_hash.count
  end

  def info_hash
    @info_hash ||= begin
      # HACK: The correct way to calculate the hash is to read directly from
      # the torrent file. However, this leads to some issues with file
      # encodings, which for now I am simply skipping. Parsing the torrent
      # file, extracting the data for hashing, reencoding it and applying sha1
      # is easier

      info_data = @bdata['info'].bencode
      Digest::SHA1.hexdigest(info_data)
    end
  end

  def info_hash_packed
    [info_hash].pack('H*')
  end
end
