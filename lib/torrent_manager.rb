# frozen_string_literal: true

class TorrentManager
  def initialize
    @torrents = []
    @torrent_hash = {}
  end

  def add_torrent(torrent)
    @torrents << torrent

    info_hash = torrent.info_hash
    @torrent_hash[info_hash] = torrent
  end

  def get_torrent(hash)
    @torrent_hash[hash]
  end
end
