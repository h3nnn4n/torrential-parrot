# frozen_string_literal: true

class BitField
  attr_reader :payload, :payload_length

  def initialize(payload)
    @payload = payload
    @bits = []

    populate
  end

  def length
    @bits.length
  end

  def set?(index)
    @bits[index]
  end

  def set(index)
    @bits[index] = true
  end

  def unset(index)
    @bits[index] = false
  end

  def random_set_bit_index
    bits_set = @bits.map.with_index do |bit, index|
      index if bit
    end

    bits_set.compact!

    bits_set.sample
  end

  def random_unset_bit_index
    bits_set = @bits.map.with_index do |bit, index|
      index unless bit
    end

    bits_set.compact!

    bits_set.sample
  end

  def any_bit_set?
    @bits.any? { |bit| bit }
  end

  def bit_set_count
    @bits.map { |bit| bit ? 1 : 0 }.sum
  end

  private

  def populate
    converter = { '1' => true, '0' => false }

    @payload_length = payload.unpack1('N')
    bitfield_length = 4 + @payload_length
    bytes = payload[4..bitfield_length].unpack('C*')

    bytes.each do |byte|
      byte_bits = byte.to_s(2).split('').reverse
      byte_bits.each do |bit|
        @bits << converter[bit]
      end
    end
  end
end
