# frozen_string_literal: true

class BitField
  attr_reader :payload, :length

  def initialize(length)
    @bits = {}
    @length = length
  end

  def set?(index)
    return false unless @bits.key?(index)

    @bits[index]
  end

  def set(index)
    @bits[index] = true
  end

  def unset(index)
    @bits[index] = false
  end

  def random_set_bit_index
    bits_set = @bits.map { |index, bit| index if bit }
    bits_set.compact!
    bits_set.sample
  end

  def random_unset_bit_index
    bits_set = @bits.map { |index, bit| index unless bit }
    bits_set.compact!
    bits_set.sample
  end

  def any_bit_set?
    @bits.values.any? { |bit| bit }
  end

  def bit_set_count
    @bits.values.map { |bit| bit ? 1 : 0 }.sum
  end

  def populate(payload)
    @payload = payload

    converter = { '1' => true, '0' => false }

    @payload_length = payload.unpack1('N')
    bitfield_length = 4 + @payload_length
    bytes = payload[5..bitfield_length].unpack('C*')

    bit_count = -1
    bytes.each do |byte|
      byte_bits = byte.to_s(2).split('').reverse
      byte_bits.each do |bit|
        bit_count += 1
        next unless converter[bit]

        @bits[bit_count] = true
      end
    end
  end
end
