# frozen_string_literal: true

class Chunk
  def initialize
    @requested = false
    @received = false
    @pending = false
  end

  def request
    @requested = true
    @pending = true
  end

  def receive
    @received = true
    @pending = false
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
