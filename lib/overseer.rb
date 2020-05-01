# frozen_string_literal: true

require 'config'
require 'overseer'
require 'peer'
require 'peer_factory'
require 'peer_manager'
require 'torrent'
require 'torrent_manager'
require 'tracker'
require 'tracker_factory'

class Overseer
  def initialize(torrent)
    @torrent = torrent
    @peers = []
  end

  def run!
    fetch_new_peers_from_tracker
    add_peers_to_peer_manager

    loop do
      peer_manager.print_status
      @torrent.piece_manager.print_status

      break if @peers.size.zero?
      break if @torrent.piece_manager.download_finished?

      peer_manager.update_peers
      peer_manager.read_and_dispatch_messages
      peer_manager.send_messages

      sleep Config.main_loop_sleep_amount
    end

    write_torrent_to_disk
  end

  private

  def torrent_manager
    @torrent_manager ||= TorrentManager.new
  end

  def tracker_factory
    @tracker_factory ||= TrackerFactory.new(@torrent)
  end

  def peer_factory
    @peer_factory ||= PeerFactory.new(@trackers, @torrent)
  end

  def peer_manager
    @peer_manager ||= PeerManager.new
  end

  def add_peers_to_peer_manager
    @peers.each { |peer| peer_manager.add_peer(peer) }
  end

  def fetch_new_peers_from_tracker
    @trackers = tracker_factory.build
    @peers += peer_factory.build
  end

  def write_torrent_to_disk
    raw_chunks = @torrent.piece_manager.all_chunks
    file_manager = FileManager.new(@torrent, raw_chunks)
    file_manager.build_files!
  end
end
