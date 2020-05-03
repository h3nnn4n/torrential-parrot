# frozen_string_literal: true

require 'file_manager'

describe FileManager do
  describe '#build_files!' do
    context 'single file torrent' do
      let(:manager) { described_class.new(torrent_pi6, chunks) }
      let(:file) { File.read('spec/files/downloads/pi6.txt') }
      let(:chunks) do
        tmp = file.dup
        data = []
        data << tmp.slice!(0, 16_384) until tmp.empty?
        data
      end

      it 'builds file properly' do
        manager.build_files!

        data = File.read(torrent_pi6.file_name).unpack('H*')

        expect(data).to eq(file.unpack('H*'))
      end
    end

    context 'multiple file torrent' do
      let(:manager) { described_class.new(torrent2, chunks) }
      let(:chunks) do
        [[
          0x75, 0x6c, 0x74, 0x72, 0x61, 0x20, 0x66, 0x61,
          0x73, 0x74, 0x20, 0x70, 0x61, 0x72, 0x72, 0x6f,
          0x74, 0x0a, 0x65, 0x78, 0x63, 0x65, 0x70, 0x74,
          0x69, 0x6f, 0x6e, 0x61, 0x6c, 0x6c, 0x79, 0x20,
          0x66, 0x61, 0x73, 0x74, 0x20, 0x70, 0x61, 0x72,
          0x72, 0x6f, 0x74, 0x0a
        ].pack('C*')]
      end

      it 'builds file properly' do
        manager.build_files!
      end
    end
  end
end
