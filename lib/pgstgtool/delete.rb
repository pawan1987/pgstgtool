require_relative 'logger'
require_relative 'command'
require_relative 'postgres'
require_relative 'helper'

module Pgstgtool
  class Delete
    
    attr_accessor :app
    attr_accessor :stage_lvm
    include Pgstgtool::Helper
    
    def initialize(app)
      @app = app
    end
    
    #given prod mount dir, it fetches lvpath from /proc/mounts file
    def stage_lv
      mline = open('/proc/mounts').grep(/\ #{datadir}\ /)[0]
      raise "#{datadir} is not a mountpoint" if not mline
      @stage_lvm = mapper_to_lv(mline.split()[0])
      is_lvm @stage_lvm
    end
    
    def datadir
      app['datadir']
    end
    
    def postgres
      return @postgres if @postgres
      @postgres = Pgstgtool::Postgres.new(app)
    end
    
    def delete_snapshot
      umount(datadir)
      lvm.remove_lv(stage_lvm)
      logger.info "Snapshot deleted with lv #{stage_lvm}"
    end
    
    def stop
        postgres.stop
        logger.info("Postgres stopped")
    end
    
    def logger
      return @logger if @logger
      @logger = Pgstgtool::CustomLogger.new
    end
    
    def lvm
      return @lvm if @lvm
      Pgstgtool::Lvm.new
    end
    
    def delete
      begin
        stage_lv
        stop
        delete_snapshot
      rescue Exception => e
        msg = e.message + e.backtrace.inspect
        logger.error(msg) 
        return false
      end 
    end
    
  end
end



#test module


  
