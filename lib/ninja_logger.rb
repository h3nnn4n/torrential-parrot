# frozen_string_literal: true

require 'forwardable'
require 'logger'

class NinjaLogger
  extend Forwardable

  def_delegators :logger, :info, :warn, :error, :debug, :fatal

  def self.set_logger_to_file
    @logger = begin
      l = Logger.new(file)
      l.formatter = proc do |_severity, datetime, _progname, msg|
        "#{datetime}: #{msg}\n"
      end
      l
    end
  end

  def self.set_logger_to_stdout
    @logger = begin
      l = Logger.new(STDOUT)
      l.formatter = proc do |_severity, datetime, _progname, msg|
        "#{datetime}: #{msg}\n"
      end
      l
    end
  end

  def self.file
    File.open('parrot.log', 'wt')
  end

  def self.logger
    @logger ||= begin
      l = Logger.new(file)
      l.formatter = proc do |_severity, datetime, _progname, msg|
        "#{datetime}: #{msg}\n"
      end
      l
    end
  end
end
