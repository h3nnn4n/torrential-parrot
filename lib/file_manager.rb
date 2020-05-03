# frozen_string_literal: true

require 'fileutils'

require_relative 'config'

class FileManager
  def initialize(torrent, chunks)
    @torrent = torrent
    @chunks = chunks.dup

    validate!
  end

  def build_files!
    if @torrent.single_file?
      build_single_file
    else
      build_multiple_files
    end
  end

  private

  def validate!
    bytes_missing = @torrent.size - @chunks.flatten.join.size
    raise "#{bytes_missing} are missing" if bytes_missing.positive?
  end

  def build_single_file
    File.open(@torrent.file_name, 'wb') do |f|
      @chunks.each do |chunk|
        f.write(chunk)
      end
    end
  end

  def build_multiple_files
    FileUtils.mkdir(@torrent.file_name) unless File.directory?(@torrent.file_name)

    @torrent.files.each do |file|
      write_file(file['length'], file['path'])
    end
  end

  def write_file(length, path)
    file_path = File.join(@torrent.file_name, path)

    ensure_filepath_exists(file_path)

    File.open(file_path, 'wb') do |f|
      file_data(length) do |data|
        f.write(data)
      end
    end
  end

  def ensure_filepath_exists(file_path)
    dirname = File.dirname(file_path)

    FileUtils.mkdir_p(dirname) unless File.directory?(dirname)
  end

  def file_data(number_of_bytes)
    bytes_left = number_of_bytes

    while bytes_left.positive?
      chunk = @chunks.first

      if chunk.size >= bytes_left
        wanted_part = chunk[0..bytes_left - 1]
        rest = chunk[bytes_left..-1]
        @chunks[0] = rest

        bytes_left = 0
        yield wanted_part
      else
        bytes_left -= chunk.size
        @chunks.shift

        yield chunk
      end
    end
  end
end
