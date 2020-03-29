# frozen_string_literal: true

require 'bit_field'

RSpec.describe BitField do
  def payload
    [5, 5, 0, 255, 0, 63].pack('NCCCCC')
  end

  def build_bitfield
    bitfield = described_class.new(30)
    bitfield.populate(payload)
    bitfield
  end

  describe '#set?' do
    it 'has bit #0 set' do
      bitfield = build_bitfield
      expect(bitfield.set?(8)).to be(true)
    end

    it 'has bit #221 not set' do
      bitfield = build_bitfield
      expect(bitfield.set?(0)).to be(false)
    end
  end

  describe '#any_bit_set?' do
    it 'has at least one set bit' do
      bitfield = build_bitfield
      expect(bitfield.any_bit_set?).to be(true)
    end

    it 'has no set bits' do
      fake_payload = [2, 5, 0].pack('NCC')
      bitfield = described_class.new(8)
      bitfield.populate(fake_payload)
      expect(bitfield.any_bit_set?).to be(false)
    end
  end

  describe '#random_unset_bit_index' do
    it 'returns the index of a unset bit' do
      bitfield = build_bitfield
      index = bitfield.random_unset_bit_index

      expect(bitfield.set?(index)).to be(false)
    end
  end

  describe '#random_set_bit_index' do
    it 'returns the index of a set bit' do
      bitfield = build_bitfield
      index = bitfield.random_set_bit_index

      expect(bitfield.set?(index)).to be(true)
    end
  end

  describe '#set' do
    it 'sets a bit' do
      bitfield = build_bitfield
      index = bitfield.random_unset_bit_index
      bitfield.set(index)
      expect(bitfield.set?(index)).to be(true)
    end
  end

  describe '#unset' do
    it 'unsets a bit' do
      bitfield = build_bitfield
      index = bitfield.random_set_bit_index
      bitfield.unset(index)
      expect(bitfield.set?(index)).to be(false)
    end
  end

  describe '#length' do
    it 'has the correct length' do
      bitfield = build_bitfield
      expect(bitfield.length).to eq(30)
    end
  end

  describe '#bit_set_count' do
    it 'has the correct number of bits set' do
      bitfield = build_bitfield
      expect(bitfield.bit_set_count).to eq(14)
    end
  end
end
