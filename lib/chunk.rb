# frozen_string_literal: true

require_relative 'config'

class Chunk
  attr_reader :payload

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
    @pending && !timedout?
  end

  def requested?
    @requested
  end

  def timedout?
    return false if received?

    requested? && Time.now - @requested_at > Config.chunk_request_timeout
  end

  def received?
    @received
  end
end
