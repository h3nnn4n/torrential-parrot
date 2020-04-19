# frozen_string_literal: true

class Chunk
  def initialize
    @requested = false
    @received = false
    @pending = false
    @payload = nil
  end

  def request
    @requested = true
    @pending = true
  end

  def receive(payload)
    @received = true
    @pending = false
    @payload = payload
  end

  def pending?
    @pending
  end

  def requested?
    @requested
  end

  def received?
    @received
  end
end
