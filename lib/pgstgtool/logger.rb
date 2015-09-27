require_relative 'mq'
require 'colorize'

module Pgstgtool
  class CustomLogger
    
    def initialize
    end
    
    def write(type, msg)
      mq.write encode(type,msg)
    end
    
    def encode(type,msg)
      type + '|' + msg
    end
    
    def mq
      Pgstgtool::Mq.new('/pgstgtool_mq')
    end
    
    def decode(msg)
      if msg =~ /^(info|debug|error|warning|i|d|e|w)\|(.*)$/i
        return [$1,$2]
      else
        return ['Info','']
      end
    end
    
    def debug(msg)
      write('Debug',msg)
    end
    
    def warning(msg)
      write('Warning',msg)
    end
    
    def info(msg)
      write('Info',msg)
    end
    
    def error(msg)
      write('Error',msg)
    end
    
    def format(msg)
      message = msg
      severity,msg = decode message
      case severity
      when "Info"
        "#{severity}: #{msg}\n".blue
      when "Error"
        "#{severity}: #{msg}\n".red
      when "Warn"
        "#{severity}: #{msg}\n".yellow
      else
        "#{severity}: #{msg}\n".white
      end
    end
    
    def read
      mq.read
    end
    
    def read_stream
      #mq.nonblock = true
      begin
        while(msg=mq.read)
          puts format(msg)
        end
      rescue Errno::EAGAIN
      end
    end
    
  end
end