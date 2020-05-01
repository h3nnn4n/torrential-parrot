# frozen_string_literal: true

require 'yaml'

class Config
  CONFIG_PATH = './config.yml'

  # If a peer doesnt send any valid piece in X amount of time terminate it
  def self.peer_idle_timeout
    config_from_file[__method__.to_s] || 180
  end

  # How many piece requests we can have pending at once, per peer
  def self.max_peer_requests
    config_from_file[__method__.to_s] || 5
  end

  # How log we wait before considering a request as failed and retrying
  def self.peer_request_timeout
    config_from_file[__method__.to_s] || 10
  end

  # This is how long it takes for a chunk request to be timedout If this value
  # is less than peer_request_timeout, then the same chunk will get
  # re-requested from another peer before the original peer times out
  def self.chunk_request_timeout
    config_from_file[__method__.to_s] || 5
  end

  def self.chunk_size
    config_from_file[__method__.to_s] || 16_384
  end

  def self.main_loop_sleep_amount
    config_from_file[__method__.to_s] || 0.5
  end

  # How many peers should we be connecting at once
  def self.max_peer_connetions
    config_from_file[__method__.to_s] || 8
  end

  # Socket read timeout for peer the peer protocol
  def self.peer_read_timeout
    config_from_file[__method__.to_s] || 1.0
  end

  # Block size when reading from sockets
  def self.block_read_size
    config_from_file[__method__.to_s] || 1_024
  end

  def self.config_from_file
    @config_from_file ||= begin
      if File.file?(CONFIG_PATH)
        data = File.read(CONFIG_PATH)
        YAML.safe_load(data)
      else
        {}
      end
    end
  end
end
