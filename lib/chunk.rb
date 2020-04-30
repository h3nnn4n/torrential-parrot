# frozen_string_literal: true

class Chunk
  attr_reader :payload

  MAX_WAIT_TIME = 10.0 # seconds

  def initialize
    @requested_at = nil
    @requested = false
    @received = false
    @pending = false
    @payload = nil
  end

  def request
    @requested_at = Time.now
    @requested = true
    @pending = true
  end

  def receive(payload)
    @received = true
    @pending = false
    @payload = payload
  end

  def pending?
    @pending && !timeout_out?
  end

  def requested?
    @requested
  end

  def timeout_out?
    requested? && Time.now - @requested_at > MAX_WAIT_TIME
  end

  def received?
    @received
  end
end
