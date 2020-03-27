class Torrent
  attr_reader :tracker

  def initialize(bdata)
    @bdata = bdata
    @tracker = Tracker.new(bdata['announce'])
  end
end
