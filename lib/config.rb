# frozen_string_literal: true

class Config
  # How many piece requests we can have pending at once, per peer
  def self.max_peer_requests
    5
  end

  # How log we wait before considering a request as failed and retrying
  def self.peer_request_timeout
    10
  end

  # This is how long it takes for a chunk request to be timedout If this value
  # is less than peer_request_timeout, then the same chunk will get
  # re-requested from another peer before the original peer times out
  def self.chunk_request_timeout
    5
  end

  def self.chunk_size
    16_384
  end

  def self.main_loop_sleep_amount
    0.5
  end

  # How many peers should we be connecting at once
  def self.max_peer_connetions
    8
  end

  # Socket read timeout for peer the peer protocol
  def self.peer_read_timeout
    1.0
  end

  # Block size when reading from sockets
  def self.block_read_size
    1_024
  end
end
