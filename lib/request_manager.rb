# frozen_string_literal: true

class RequestManager
  attr_reader :max_requests, :timeout

  def initialize(max_requests: 20, timeout: 2.0)
    @timeout = timeout
    @max_requests = max_requests
    @pending = []
  end

  def register_request
    @pending << Time.now
  end

  def relive_request
    update_request_status
    @pending.shift
  end

  def can_request?
    update_request_status
    @pending.count < max_requests
  end

  private

  def update_request_status
    @pending.select! do |timestamp|
      Time.now - timestamp < timeout
    end
  end
end
