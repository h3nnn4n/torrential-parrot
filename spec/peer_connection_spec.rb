# frozen_string_literal: true

require 'peer'
require 'peer_connection'

RSpec.describe PeerConnection do
  peer_id = '00000000000000000000'

  def build_peer
    peer_id = '00000000000000000000'
    message = File.read('spec/files/peer_messages/receive_handshake/10_2_receive_handshake.dat')[0..67]
    connection = described_class.new('127.0.0.1', 6881, torrent_debian, peer_id)
    connection.process_message(message)

    connection
  end

  describe '#initialize' do
    it 'initializes without exploding' do
      described_class.new('127.0.0.1', 6881, torrent, peer_id)
    end

    it 'sets state to :uninitialized' do
      connection = described_class.new('127.0.0.1', 6881, torrent, peer_id)

      expect(connection.state).to be(:uninitialized)
    end
  end

  describe '#send_handshake' do
    it 'sets state to handshake_sent' do
      connection = described_class.new('127.0.0.1', 6881, torrent_debian, peer_id)

      mock_socket = instance_double('TCPSocket', write: nil)
      allow(connection).to receive(:socket).and_return(mock_socket)
      connection.send_handshake

      expect(connection.state).to be(:handshake_sent)
    end

    it 'returns true on success' do
      connection = described_class.new('127.0.0.1', 6881, torrent_debian, peer_id)

      mock_socket = instance_double('TCPSocket', write: nil)
      allow(connection).to receive(:socket).and_return(mock_socket)

      expect(connection.send_handshake).to be(true)
    end

    it 'returns false on failure' do
      connection = described_class.new('127.0.0.1', 6881, torrent_debian, peer_id)

      allow(connection).to receive(:socket).and_raise(Errno::ECONNREFUSED)

      expect(connection.send_handshake).to be(false)
    end
  end

  describe '#process_handshake' do
    def message
      File.read('spec/files/peer_messages/receive_handshake/10_2_receive_handshake.dat')[0..67]
    end

    it 'sets state to :handshaked' do
      connection = described_class.new('127.0.0.1', 6881, torrent_debian, peer_id)
      connection.process_message(message)

      expect(connection.state).to be(:handshaked)
    end
  end

  describe '#process_bitfield' do
    it 'sets the number of parts from a valid bitfield message' do
      payload = File.read('spec/files/peer_messages/receive_bitfield/pi6_bitfield.dat')

      connection = build_peer
      connection.process_message(payload)

      expect(connection.part_count).to be(34)
    end

    it 'sets state to :handshaked' do
      payload = File.read('spec/files/peer_messages/receive_bitfield/corrupt_bitfield.dat')

      connection = build_peer
      connection.process_message(payload)

      expect(connection.part_count).to be(0)
    end
  end

  describe '#message_type' do
    it 'returns :handshake' do
      message = File.read('spec/files/peer_messages/receive_handshake/10_2_receive_handshake.dat')[0..67]
      connection = described_class.new('127.0.0.1', 6881, torrent_debian, peer_id)

      expect(connection.message_type(message)).to be(:handshake)
    end
  end

  describe '#valid_message?' do
    it 'returns false for a invalid handshake' do
      message = File.read('spec/files/peer_messages/receive_handshake/10_2_receive_handshake.dat')[0..30]
      connection = described_class.new('127.0.0.1', 6881, torrent_debian, peer_id)

      expect(connection.valid_message?(message)).to be(false)
    end

    it 'returns true for a valid handshake' do
      message = File.read('spec/files/peer_messages/receive_handshake/10_2_receive_handshake.dat')[0..67]
      connection = described_class.new('127.0.0.1', 6881, torrent_debian, peer_id)

      expect(connection.valid_message?(message)).to be(true)
    end

    it 'returns false for a invalid piece' do
      message = File.read('spec/files/peer_messages/receive_piece/invalid_piece.dat')
      connection = described_class.new('127.0.0.1', 6881, torrent_debian, peer_id)

      expect(connection.valid_message?(message)).to be(false)
    end
  end

  describe '#process_piece WIP' do
    it 'processes piece' do
      message = File.read('spec/files/peer_messages/receive_piece/receive_piece_0_16384.dat')

      connection = described_class.new('127.0.0.1', 6881, torrent_debian, peer_id)
      connection.process_message(message)

      expect(connection.state).not_to be(:dead)
    end

    it 'proceses piece 2' do
      message = File.read('spec/files/peer_messages/receive_piece/receive_piece_0_32768.dat')

      connection = described_class.new('127.0.0.1', 6881, torrent_debian, peer_id)
      connection.process_message(message)

      expect(connection.state).not_to be(:dead)
    end
  end
end
