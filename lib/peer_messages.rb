# frozen_string_literal: true

module PeerMessages
  def handshake_message
    message = [pstrlen].pack('C')
    message << [pstr].pack('a19')
    message << reserved.pack('C8')
    message << [info_hash].pack('H*')
    message << [my_peer_id].pack('a20')
    message
  end

  def keepalive_message
    [0].pack('N')
  end

  def choke_message
    [1, 0].pack('NC')
  end

  def unchoke_message
    [1, 1].pack('NC')
  end

  def interested_message
    [1, 2].pack('NC')
  end

  def uninterested_message
    [1, 3].pack('NC')
  end

  def request_message(piece_index, block_offset, block_length)
    message = [13, 1].pack('NC')
    message << [piece_index, block_offset, block_length].pack('NNN')
    message
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
