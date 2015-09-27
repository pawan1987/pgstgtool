module Pgstgtool
  class Apps
    
    attr_accessor :override_apps
    attr_accessor :override_global
    attr_accessor :apps
    attr_accessor :global
    attr_accessor :app
    attr_accessor :name

    
    def initialize(opt = {})
      @override_apps = opt['override_apps'] || {}
      @override_global = opt['override_global'] || {}
      @name = opt['name']
      POSIX_MQ.unlink('/pgstgtool_mq')
    end
    
    def logger
      return @logger if @logger
      @logger = Pgstgtool::CustomLogger.new
    end
    
    def config
      return @config if @config
      @config = Pgstgtool::Config.new(@config_file)
      @config.init
      @config
    end
    
    def config_file
      @config_file = override_global['config_file'] || '/etc/pgstgtool/config.rb'
    end
    
    def init_global_config
      return @global if @global
      @global = config.global_config
      logger.debug("global config(before override) =>" + @global.inspect )
      logger.debug("global override paramteres =>" + @override_global.inspect )
      override_global.keys.each do |i|
        global[i] = override_global[i]
      end
    end
    
    def override_apps_config
      if name != nil
        override_app_config(name)
      else
        override_apps.keys.each do |key|
          override_app_config(key)
        end
      end
    end
    
    def init_apps_config
      return @apps if @apps
      @apps = config.apps_config
      logger.debug("apps config(before override)" + @apps.inspect )
      logger.debug("apps override parameters =>" + @override_apps.inspect )
      override_apps_config
    end
    
    def override_app_config(name)
      @apps[name] = {} unless @apps[name]
      if @override_apps[name]
        @override_apps[name].each do |key, value|
          @apps[name][key] = value
        end
      end
    end
    
    def create_app(app)
      @app = Pgstgtool::Validate.new(app, global).check
      logger.info "_______________"
      logger.info "Running create on app:#{app['name']}"
      logger.debug 'Calling create on ' + @app['name'] + ' => ' + @app.inspect
      Pgstgtool::Create.new(@app).create
    end
    
    def create
      init_apps_config
      init_global_config
      log_writer
      if name != nil
        create_app(@apps[name])
      else
        begin
          @apps.each do |key,value|
            create_app(value)
          end
        rescue Exception => e
          msg = e.message
          logger.error e.backtrace.inspect
          logger.error(msg)
        end
      end
    end
    
    
    def delete_app(app)
      @app = Pgstgtool::Validate.new(app, global).check
      logger.info "_______________"
      logger.info "Running delete on app:#{app['name']}"
      logger.debug 'Calling delete on ' + @app['name'] + ' => ' + @app.inspect
      Pgstgtool::Delete.new(@app).delete
    end
    
    def delete
      init_apps_config
      init_global_config
      log_writer
      if name != nil
        delete_app(@apps[name])
      else
        begin
          @apps.each do |key,value|
            delete_app(value)
          end
        rescue Exception => e
          msg = e.message
          logger.error(msg)
        end
      end
    end
    
    def status_app(app)
      @app = Pgstgtool::Validate.new(app, global).check
      logger.info "_______________"
      logger.info "Running status on app:#{app['name']}"
      logger.debug 'Calling status on ' + @app['name'] + ' => ' + @app.inspect
      out = Pgstgtool::Status.new(@app).status
      logger.info out.inspect
      out
    end
    
    def log_writer
      Thread.new do
        Pgstgtool::LogWriter.new(global['logfile'],global['loglevel']).read
      end
    end
    
    
    def status
      init_apps_config
      init_global_config
      log_writer
      output = Array.new
      if name != nil
        output << status_app(@apps[name])
      else
        begin
          @apps.each do |key,value|
            output.push << status_app(value)
          end
        rescue Exception => e
          msg = e.message
          logger.error e.backtrace.inspect
          logger.error(msg)
        end
        output
      end
    end
    
  end
end
