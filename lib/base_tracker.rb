# frozen_string_literal: true

require 'logger'
require 'socket'
require 'uri'

class BaseTracker
  attr_accessor :bytes_downloaded, :bytes_uploaded, :bytes_left,
                :announce_interval, :n_peers, :n_leechers, :n_done
  attr_reader :info, :listen_port, :tracker_s

  def initialize(tracker_s)
    @tracker_s = tracker_s
    @uri = URI(tracker_s)
    @bytes_downloaded = 0
    @bytes_uploaded = 0
    @bytes_left = 0
    @listen_port = 6881
    @wanted_peers = 10

    @announce_interval = nil

    logger.info "peer_id: #{peer_id}"
    logger.info "tracker: #{tracker_s}"

    raise "invalid scheme #{scheme}" unless %w[http https udp].include?(scheme)
  end

  def peer_id
    @peer_id ||= '-PC0001-' + (0..12).map { rand(10) }.join('')
  end

  def host
    @uri.host
  end

  def scheme
    @uri.scheme
  end

  def port
    @uri.port
  end

  def uri
    @uri.to_s
  end

  def logger
    @logger ||= Logger.new(STDOUT)
  end

  def decode_peers(peers)
    return [] if peers.nil?

    n_peers = peers.size / 6
    unpacker = 'CCCCn'

    (0..n_peers - 1).map do |index|
      data = peers[(index * 6)..((index * 6) + 5)].unpack(unpacker)
      ip = data[0..3].join('.')
      port = data.last

      logger.info "[UDP_TRACKER] found peer #{index} #{ip} on port #{port}"

      [ip, port]
    end
  end
end
