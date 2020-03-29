# frozen_string_literal: true

require 'forwardable'
require 'logger'

class NinjaLogger
  extend Forwardable

  def_delegators :logger, :info, :warn, :error, :debug, :fatal

  def self.set_logger_to_file
    @logger = Logger.new(file)
  end

  def self.set_logger_to_stdout
    @logger = Logger.new(STDOUT)
  end

  def self.file
    File.open('parrot.log', 'wt')
  end

  def self.logger
    @logger ||= Logger.new(file)
  end
end
