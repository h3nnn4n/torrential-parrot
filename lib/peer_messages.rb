# frozen_string_literal: true

module PeerMessages
  def handshake_message
    message = [pstrlen].pack('C')
    message << [pstr].pack('a19')
    message << [0, 0, 0, 0, 0, 0, 0, 0].pack('C8')
    message << [info_hash].pack('H*')
    message << [my_peer_id].pack('a20')
    message
  end

  def keepalive_message
    [0].pack('N')
  end

  def interested_message
    message = [1].pack('N')
    message << [2].pack('C')
  end

  def pstr
    'BitTorrent protocol'
  end

  def pstrlen
    pstr.length
  end

  def reserved
    [0, 0, 0, 0, 0, 0, 0, 0]
  end
end
