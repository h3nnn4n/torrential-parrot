# frozen_string_literal: true

require 'logger'
require 'socket'
require 'uri'

class BaseTracker
  attr_reader :bytes_downloaded, :bytes_uploaded, :bytes_left,
              :info, :listen_port

  def initialize(tracker_s)
    @uri = URI(tracker_s)
    @bytes_downloaded = 0
    @bytes_uploaded = 0
    @bytes_left = 0
    @listen_port = 6888
    @wanted_peers = 4

    logger.info "peer_id: #{peer_id}"
    logger.info "tracker: #{host}:#{port}"
    logger.info "scheme: #{scheme}"

    raise "invalid scheme #{scheme}" unless ['udp'].include?(scheme)
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

  def logger
    @logger ||= Logger.new(STDOUT)
  end
end
