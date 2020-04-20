# frozen_string_literal: true

class FileManager
  def initialize(torrent, chunks)
    @torrent = torrent
    @chunks = chunks
  end

  def build_files!
    if @torrent.single_file?
      build_single_file
    else
      build_multiple_files
    end
  end

  private

  def build_single_file
    File.open(@torrent.file_name, 'wb') do |f|
      @chunks.each do |chunk|
        f.write(chunk)
      end
    end
  end

  def build_multiple_files
    raise NotImplemented
  end
end
