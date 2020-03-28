# frozen_string_literal: true

require_relative 'tracker'

class TrackerFactory
  def initialize(torrent)
    @torrent = torrent
  end

  def build
    trackers = @torrent.trackers.map do |tracker_uri|
      uri = URI(tracker_uri)

      next unless %w[http https].include?(uri.scheme)

      Tracker.new(tracker_uri)
    end

    trackers.compact!
    trackers
  end
end
