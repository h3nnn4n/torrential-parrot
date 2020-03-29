# frozen_string_literal: true

require 'bit_field'

RSpec.describe BitField do
  def payload
    File.read('spec/files/bitfield.dat')
  end

  def bitfield
    described_class.new(payload)
  end

  describe '#set?' do
    it 'has bit #0 set' do
      expect(bitfield.set?(0)).to be(true)
    end

    it 'has bit #221 not set' do
      expect(bitfield.set?(221)).to be(false)
    end
  end

  describe '#random_set_bit_index' do
    it 'returns the index of a set bit' do
      index = bitfield.random_set_bit_index

      expect(bitfield.set?(index)).to be(true)
    end
  end

  describe '#length' do
    it 'has the correct length' do
      expect(bitfield.length).to eq(1425)
    end
  end

  describe '#payload_length' do
    it 'has the correct payload length' do
      expect(bitfield.payload_length).to eq(179)
    end
  end
end
