# frozen_string_literal: true

require 'peer_messages'

class Messages
  include PeerMessages

  attr_accessor :pstrlen, :pstr, :my_peer_id, :info_hash

  def initialize
    @pstr = 'BitTorrent protocol'
    @pstrlen = 19
    @info_hash = 'efe401d7d70e799809b11b6a00664fdffc0191bb'
    @my_peer_id = '-ZZ0007-000000000000'
  end
end

describe PeerMessages do
  def messager
    Messages.new
  end

  describe '#handshake_message' do
    def handshake_message
      File.read('spec/files/peer_messages/handshake.dat', encoding: 'iso-8859-1')
    end

    it 'has the expected length' do
      message = messager.handshake_message

      expect(message.size).to be(68)
    end

    it 'unpacks correctly' do
      message = messager.handshake_message
      unpacker = 'Ca19C8H40a20'

      # expect(message).to eq(handshake_message)
      expect(message.unpack(unpacker)).to eq(handshake_message.unpack(unpacker))
    end
  end

  describe '#request_message' do
    it 'has the correct length' do
      message = messager.request_message(0, 0, 2**14)

      expect(message.length).to eq(17)
    end

    it 'has the correct payload size' do
      message = messager.request_message(0, 0, 2**14)

      expect(message.unpack1('N')).to eq(13)
    end

    it 'has the correct message id' do
      message = messager.request_message(0, 0, 2**14)

      _, message_id = message.unpack('NC')

      expect(message_id).to eq(6)
    end

    it 'has the correct piece specification' do
      message = messager.request_message(1387, 2 * 2**14, 2**14)

      _, _, piece_index, block_offset, block_length = message.unpack('NCNNN')

      expect([piece_index, block_offset, block_length]).to eq([1387, 2 * 2**14, 2**14])
    end
  end
end
