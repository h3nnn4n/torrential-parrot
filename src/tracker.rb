class Tracker
  def initialize(tracker_s)
    @uri = URI(tracker_s)
    @socket = UDPSocket.new
    @socket.connect(
      host,
      port
    )
    @connection_id = nil

    puts "peer_id: #{peer_id}"
    puts "tracker: #{host}:#{port}"
  end

  def connect
    transaction_id = rand(2**16)
    puts "sending connect package with transaction_id #{transaction_id}"

    @socket.send(connection_message(transaction_id)transaction_id, 0)
    response = @socket.recvfrom(1024)
    action_r, transaction_id_r, conn_0, conn_1 = response.first.unpack('NNNN')

    @connection_id = conn_0 << 32 | conn_0

    puts "connection_id is #{@connection_id}"

    raise 'invalid transaction_id' unless transaction_id == transaction_id_r
    raise 'invalid action' unless action_r == 0

    true
  rescue => e
    binding.pry
  end

  def connection_message(transaction_id = nil)
    transaction_id = rand(2**32) if transaction_id.nil?

    magic_number = 0x41727101980
    [
      magic_number >> 32,
      magic_number & 0xffffffff,
      0, # Action 0 is connect
      transaction_id
    ].pack('NNNN')
  end

  def peer_id
    @peer_id ||= '-PC0001-' + (0..12).map { rand(10) }.join('')
  end

  def host
    @uri.host
  end

  def scheme
    @uri.scheme
  end

  def port
    @uri.port
  end
end
