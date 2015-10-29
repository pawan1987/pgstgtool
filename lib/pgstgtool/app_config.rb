module Pgstgtool
  class AppConfig
    
    attr_accessor :config
    
    def initialize
      @config = {}
    end
    
    
    def set(key, value)
      config[key] = value
    end
    
    def port(port)
      set 'port', port
    end
    
    def size(size)
      set 'size', size
    end

    def version(version)
      set 'version', version
    end
    
    def datadir(datadir)
      set 'datadir', datadir
    end
    
    def proddir(proddir)
      set 'proddir', proddir
    end
    
    def rake_task(rake_task)
      set 'rake_task', rake_task
    end
    
    def create(&block)
      instance_eval(&block)
      config
    end
    
  end
end
