module Pgstgtool
  class Validate
    
    attr_accessor :app
    attr_accessor :global
    include Pgstgtool::Helper
    def initialize(app, global)
      @app = app
      @global = global
    end
    
    def check
      port
      datadir
      proddir
      snapshot_size_min
      return @app
    end
    
    def is_defined (name)
      raise "#{name} is not defined" unless app[name]
      app[name]
    end
    
    def datadir_pattern
      raise "datadir_pattern is not defined" if (not global['datadir_pattern']) || (global['datadir_pattern'] !~ /VERSION\/APP/)
      global['datadir_pattern']
    end
    
    def snapshot_size_min
      raise "snapshot_size_min not defined" if (not global['snapshot_size_min']) || (global['snapshot_size_min'] !~ /^\d+(G|g|M|m|K|k)/)
      global['snapshot_size_min']
    end
    
    def proddir_pattern
      raise "datadir_pattern is not defined" if (not global['proddir_pattern']) || (global['proddir_pattern'] !~ /VERSION\/APP/)
      global['proddir_pattern']
    end
    
    def port
      @port = is_defined 'port'
      raise "Invalid port #{@port}" if @port.to_s !~ /^\d+$/
      @port
    end
    
    def name
      is_defined 'name'
    end
    
    def datadir
      unless app['datadir']
        app['datadir'] = datadir_pattern.sub(/\/APP/,"\/#{name}").sub(/\/VERSION/,"\/#{version}")
      end
      is_dir(app['datadir'])
      app['datadir']
    end
    
    def proddir
      unless app['proddir']
        app['proddir'] = proddir_pattern.sub(/\/APP/,"\/#{name}").sub(/\/VERSION/,"\/#{version}")
      end
      is_dir app['proddir']
      app['datadir']
    end
    
    def version
      app['version'] = '9.4' unless app['version']
      raise "Only 9.3 or 9.4 version of postgres is supported" unless app['version'] =~ /^(9\.3|9\.4)$/
      app['version']
    end
    
    
  end
end