# frozen_string_literal: true

require 'bit_field'

RSpec.describe BitField do
  def payload
    File.read('spec/files/bitfield.dat')
  end

  describe '#set?' do
    it 'has bit #0 set' do
      bitfield = described_class.new(payload)
      expect(bitfield.set?(0)).to be(true)
    end

    it 'has bit #221 not set' do
      bitfield = described_class.new(payload)
      expect(bitfield.set?(221)).to be(false)
    end
  end

  describe '#random_unset_bit_index' do
    it 'returns the index of a unset bit' do
      bitfield = described_class.new(payload)
      index = bitfield.random_unset_bit_index

      expect(bitfield.set?(index)).to be(false)
    end
  end

  describe '#random_set_bit_index' do
    it 'returns the index of a set bit' do
      bitfield = described_class.new(payload)
      index = bitfield.random_set_bit_index

      expect(bitfield.set?(index)).to be(true)
    end
  end

  describe '#set' do
    it 'sets a bit' do
      bitfield = described_class.new(payload)
      index = bitfield.random_unset_bit_index
      bitfield.set(index)
      expect(bitfield.set?(index)).to be(true)
    end
  end

  describe '#unset' do
    it 'unsets a bit' do
      bitfield = described_class.new(payload)
      index = bitfield.random_set_bit_index
      bitfield.unset(index)
      expect(bitfield.set?(index)).to be(false)
    end
  end

  describe '#length' do
    it 'has the correct length' do
      bitfield = described_class.new(payload)
      expect(bitfield.length).to eq(1425)
    end
  end

  describe '#payload_length' do
    it 'has the correct payload length' do
      bitfield = described_class.new(payload)
      expect(bitfield.payload_length).to eq(179)
    end
  end
end
