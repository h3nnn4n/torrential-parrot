# frozen_string_literal: true

class BitField
  attr_reader :payload, :bits, :payload_length

  def initialize(payload)
    @payload = payload
    @bits = []

    populate
  end

  def length
    @bits.length
  end

  def set?(index)
    bits[index]
  end

  private

  def populate
    converter = { '1' => true, '0' => false }

    @payload_length = payload.unpack1('N')
    bitfield_length = 4 + @payload_length
    bytes = payload[5..bitfield_length].unpack('C*')

    bytes.each do |byte|
      bits = byte.to_s(2).split('').reverse
      bits.each do |bit|
        @bits << converter[bit]
      end
    end
  end
end
