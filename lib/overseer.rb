# frozen_string_literal: true

require 'config'
require 'file_manager'
require 'ninja_logger'
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

    # This is only temporary and will be deprecated when ncurses interface is
    # implemented
    @message_timer = Time.now
    @message_interval = Config.status_update_interval

    @local_debug = Config.local_debug
  end

  def run!
    if @local_debug
      add_local_peers
    else
      fetch_new_peers_from_tracker
      add_peers_to_peer_manager
    end

    loop do
      if Time.now - @message_timer > @message_interval
        @message_timer = Time.now
        peer_manager.print_status
        @torrent.piece_manager.print_status
      end

      break if @peers.size.zero?
      break if @torrent.piece_manager.download_finished?

      if peer_manager.needs_more_peers? && !@local_debug
        # recycle_dead_peers
        remove_dead_peers
        fetch_new_peers_from_tracker
        add_peers_to_peer_manager
      end

      peer_manager.update_peers
      peer_manager.read_and_dispatch_messages
      peer_manager.send_messages

      sleep Config.main_loop_sleep_amount
    end

    peer_manager.print_status
    @torrent.piece_manager.print_status

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

  def remove_dead_peers
    peer_manager.remove_dead_peers
  end

  def recycle_dead_peers
    peer_manager.recycle_dead_peers
  end

  def write_torrent_to_disk
    raw_chunks = @torrent.piece_manager.all_chunks
    file_manager = FileManager.new(@torrent, raw_chunks)
    file_manager.build_files!
  end

  def add_local_peers
    @trackers = tracker_factory.build

    peer_id = @trackers.first.peer_id
    peer = Peer.new('127.0.0.1', 51_413, @torrent, peer_id, peer_n: 1)
    peer_manager.add_peer(peer)
    @peers << peer
  end
end
