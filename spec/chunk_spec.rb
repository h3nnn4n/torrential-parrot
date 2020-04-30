# frozen_string_literal: true

require 'chunk'

RSpec.describe Chunk do
  describe '#initialize' do
    it 'initializes without exploding' do
      described_class.new
    end
  end

  describe '#timedout?' do
    it 'doesnt time out if it is fast enough' do
      chunk = described_class.new
      chunk.request

      expect(chunk.timedout?).to be(false)
    end

    it 'times out if it takes too long' do
      now = Time.now
      chunk = described_class.new

      Timecop.freeze(now) do
        chunk.request
      end

      Timecop.freeze(now + Chunk::MAX_WAIT_TIME + 0.5) do
        expect(chunk.timedout?).to be(true)
      end
    end
  end

  describe '#request' do
    it 'initializes as false' do
      chunk = described_class.new

      expect(chunk.requested?).to be(false)
    end

    it 'register request' do
      chunk = described_class.new
      chunk.request

      expect(chunk.requested?).to be(true)
    end

    it 'marks as pending' do
      chunk = described_class.new
      chunk.request

      expect(chunk.pending?).to be(true)
    end
  end

  describe '#receive' do
    it 'initializes as false' do
      chunk = described_class.new

      expect(chunk.received?).to be(false)
    end

    it 'register request' do
      chunk = described_class.new
      chunk.request
      chunk.receive([1, 2, 3].pack('CCC'))

      expect(chunk.received?).to be(true)
    end

    it 'marks as not pending' do
      chunk = described_class.new
      chunk.request
      chunk.receive([1, 2, 3].pack('CCC'))

      expect(chunk.pending?).to be(false)
    end
  end
end
