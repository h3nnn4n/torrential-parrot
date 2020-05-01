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

  def everything_set?
    return false if @bits.size.zero?

    @bits.values.all?
  end

  def set(index)
    @bits[index] = true
  end

  def unset(index)
    @bits[index] = false
  end

  def all_bits_set_index
    bits_set = @bits.map { |index, bit| index if bit }
    bits_set.compact!
    bits_set
  end

  def random_set_bit_index
    all_bits_set_index.sample
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

    @payload_length = payload.unpack1('N')
    bitfield_length = 4 + @payload_length

    raise 'Bitfield size does not match torrent!' if (@payload_length.to_f / 8).ceil > @length

    bytes = payload[5..bitfield_length].unpack('C*')

    last_set_bit = 0
    bit_count = -1
    bytes.each do |byte|
      byte_bits = byte_to_bits(byte)
      byte_bits.each do |bit|
        bit_count += 1
        next unless bit

        @bits[bit_count] = true
        last_set_bit = bit_count if bit_count > last_set_bit

        next unless last_set_bit > @length - 1

        raise "Bitfield bits count doesnt match torrent number of pieces! #{last_set_bit} #{@length}"
      end
    end

    return unless last_set_bit > @length - 1

    raise "Bitfield bits count doesnt match torrent number of pieces! #{last_set_bit} #{@length}"
  end

  def byte_to_bits(byte)
    converter = { '1' => true, '0' => false }

    data = byte.to_s(2).split('')
    data = (['0'] * (8 - data.size) + data).reverse if data.size < 8
    data.map { |a| converter[a] }
  end
end
