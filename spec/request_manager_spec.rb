# frozen_string_literal: true

require 'request_manager'

RSpec.describe RequestManager do
  describe '#initialize' do
    it 'initializes without exploding' do
      described_class.new
    end
  end

  describe '#can_request?' do
    it 'can request if there is nothing pending' do
      manager = described_class.new

      expect(manager.can_request?).to be(true)
    end

    it 'cannot request if there max_requests is reached' do
      manager = described_class.new(max_requests: 3)
      manager.register_request
      manager.register_request
      manager.register_request

      expect(manager.can_request?).to be(false)
    end

    it 'can request if an old request is relived and frees a slow' do
      manager = described_class.new(max_requests: 3)
      manager.register_request
      manager.register_request
      manager.register_request
      manager.relive_request

      expect(manager.can_request?).to be(true)
    end

    it 'can request if a request times out and frees a slot' do
      now = Time.now
      manager = described_class.new(max_requests: 3, timeout: 2.0)

      Timecop.freeze(now) do
        manager.register_request
      end

      Timecop.freeze(now + 1.0) do
        manager.register_request
        manager.register_request
      end

      Timecop.freeze(now + 3.0) do
        expect(manager.can_request?).to be(true)
      end
    end
  end
end
