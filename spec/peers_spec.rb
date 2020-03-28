# frozen_string_literal: true

require 'peer'

RSpec.describe Peer do
  describe '#initialize' do
    it 'initializes' do
      Peer.new('127.0.0.1', 6881, '123', '456')
    end
  end
end
