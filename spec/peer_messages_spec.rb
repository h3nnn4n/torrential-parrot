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
end
