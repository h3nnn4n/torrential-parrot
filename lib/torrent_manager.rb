# frozen_string_literal: true

class TorrentManager
  @torrents = []
  @torrent_hash = {}

  def self.add_torrent(torrent)
    @torrents << torrent

    info_hash = torrent.info_hash
    @torrent_hash[info_hash] = torrent
  end

  def self.get_torrent(hash)
    @torrent_hash[hash]
  end
end
