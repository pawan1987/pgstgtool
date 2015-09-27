require 'posix_mq'

module Pgstgtool
  module Logger
  
    attr_accessor :name
    
    def initialize(name = '/pgstgtool_mq')
      @name = name
    end
    
    def self.delete
      POSIX_MQ.unlink('/pgstgtool_mq')
    end
    
    def write(type, msg)
      mq << "#{type}|#{msg}"
    end
    
    def mq
      POSIX_MQ.new(name,:rw)
    end
    
    def read
      if mq.receive.shift =~ /(Info|Debug|Warning|Error)|(.*)/
        [$1,$2]
      end
    end
    
  end
end