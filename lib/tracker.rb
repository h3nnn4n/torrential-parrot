# frozen_string_literal: true

require 'forwardable'
require 'logger'
require 'socket'
require 'uri'

require_relative 'udp_tracker'

class Tracker
  extend Forwardable

  def_delegators :middleware, :connect, :announce

  def initialize(tracker_s)
    @tracker_s = tracker_s
    @uri = URI(tracker_s)
  end

  def scheme
    @uri.scheme
  end

  private

  def middleware
    return @middleware unless @middleware.nil?

    case scheme
    when 'udp'
      @middleware = UdpTracker.new(@tracker_s)
    end
  end
end
