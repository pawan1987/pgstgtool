require 'colorize'
require_relative 'logger'
module Pgstgtool
  class LogWriter
    
    attr_accessor :file
    attr_accessor :logfile
    attr_accessor :loglevel
    
    def initialize(logfile = nil, loglevel = nil)
      @logfile  = logfile || '/tmp/pgstgtool_log'
      @loglevel = loglevel || 'Error'
    end
    
    def logger
      return @logger if @logger
      @logger = Pgstgtool::CustomLogger.new
    end
    
    def file
      return @file if @file
      @file = File.open(logfile, 'a+')
    end
    
    def write(msg)
        if logfile =~ /stdout/
            puts msg
          else
            file.write msg
        end
    end
    
    def timestamp
      Time.now.to_i
    end
    
    def format_msg(severity, msg)
      case severity
      when "Info"
        "#{timestamp} #{severity}: #{msg}\n".blue
      when "Error"
        "#{timestamp} #{severity}: #{msg}\n".red
      when "Warn"
        "#{timestamp} #{severity}: #{msg}\n".yellow
      else
        "#{timestamp} #{severity}: #{msg}\n".white
      end
    end
    
    def read
      while (message =logger.read)
        severity, msg = logger.decode message
        case loglevel
        when "Info"
          if severity =~ /(Info|Error|Warning)/
            write(format_msg(severity,msg))
          end
        when "Warning"
          if severity =~ /(Error|Warning)/
            write(format_msg(severity,msg))
          end
        when "Error"
          if severity =~ /(Error)/
            write(format_msg(severity,msg))
          end
        else
          write(format_msg(severity,msg))
        end
      end
    end
    
  end
end
