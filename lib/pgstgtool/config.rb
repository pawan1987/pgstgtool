require_relative 'app_config'

module Pgstgtool
  class Config
    
    attr_accessor :config_file
    attr_accessor :apps_config
    attr_accessor :global_config
    attr_accessor :init_once
    
    def initialize(config_file = nil) 
      @config_file = config_file
      @apps_config = {}
      @global_config = {}
      @init_once = false
    end
    
    def config_file
      @config_file ||= "/etc/pgstgtool/config.rb"
    end
    
    def app(app_name, &block)
      app_config = Pgstgtool::AppConfig.new.create(&block)
      app_config['name'] = app_name
      apps_config[app_name] = app_config
    end
    
    def global
      if block_given?
        yield
      else
        raise "#{config_file}: global variable is not correctly defined"
      end
    end
    
    def read_from_file
      return if not File.readable? config_file
      instance_eval(File.read(config_file), config_file)
    rescue NoMethodError => e
      puts "invalid option used in config: #{e.name}"
    end
    
    def init
        return if @init_once
        read_from_file
        @init_once = true
    end
    
    private
    
    def datadir_pattern(str)
      global_config['datadir_pattern'] = str
    end
 
    def proddir_pattern(str)
      global_config['proddir_pattern'] = str
    end   
    
    def task_dir(str)
      global_config['task_dir'] = str
    end

    def logfile(str)
      global_config['logfile'] = str
    end   
    
    def loglevel(str)
      global_config['loglevel'] = str
    end
  
  end
end

#obj = Pgstgtool::Config.new
#obj.init
#puts obj.global_config.inspect
#puts "------"
#puts obj.apps_config.inspect
  
