require 'posix_mq'

module Pgstgtool
  class Mq
  
    attr_reader :name, :max_msg, :msg_size
    
    def initialize(name = '/pgstgtool_mq')
      @name = name
      @max_msg = 20
      @msg_size = 20000
    end
    
    def delete
      POSIX_MQ.unlink(name)
    end
    
    def write(msg)
      mq << msg[0..5000]
    end
    
    def mq
      POSIX_MQ.new(name,:rw, 0700, attr)
    end
    
    def read
      mq.receive.shift
    end
    
    def attr
      ::POSIX_MQ::Attr.new(0,max_msg,msg_size)
    end
    
  end
end
