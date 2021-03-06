# frozen_string_literal: true

require 'httparty'
require 'retriable'
require 'timeout'

require_relative 'base_tracker'

class HttpTracker < BaseTracker
  attr_reader :connection_id

  def connect
    true
  end

  def announce(torrent)
    query = {
      info_hash: torrent.info_hash_packed,
      compact: 1,
      peer_id: [peer_id].pack('a20'),
      numwant: wanted_peers,
      port: listen_port
    }

    response =
      Retriable.retriable do
        HTTParty.get(tracker_s, query: query, timeout: 1)
      end

    return false unless (200..299).cover?(response.code)

    data = response.body.bdecode

    # n_peers = data['complete']
    # n_leechers = data['incomplete']
    # n_done = data['downloaded']
    # announce_interval = data['interval']
    peers = data['peers']

    decode_peers(peers)
  rescue Net::OpenTimeout, OpenSSL::SSL::SSLError, Net::ReadTimeout,
         Errno::ECONNREFUSED, SocketError
    false
  end
end
