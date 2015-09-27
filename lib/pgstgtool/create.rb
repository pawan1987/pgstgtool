require 'fileutils'
require 'etc'
require_relative 'logger'
require_relative 'command'
require_relative 'postgres'

module Pgstgtool
  class Create

    attr_accessor :app
    attr_accessor :prod_lvm
    attr_accessor :stage_lvm
    attr_accessor :count
    include Pgstgtool::Helper

    def initialize(app)
      @app = app
      @count = 1
    end

    def create
      status = postgres.check_db_read[0]
      if status
        logger.info "DB is already running"
        return true
      else
        unless empty_mount_point(datadir)
           logger.error("Running delete command on #{app['name']} as #{datadir} is not empty}")
           Pgstgtool::Delete.new(app).delete 
        end
      end
      
      begin
        prod_mount
        create_snapshot
        mount_snapshot
        pre_start_setup
        start
        run_rake_task
      rescue Exception => e
        msg = e.message + e.backtrace.inspect
        logger.error(msg)
        #roll_back
        return false
      end          
    end
    
    #given prod mount dir, it fetches lvpath from /proc/mounts file
    def prod_mount
      mline = open('/proc/mounts').grep(/\ #{app['proddir']}\ /)[0]
      raise "#{app['proddir']} is not a mountpoint" if not mline
      @prod_lvm = mapper_to_lv(mline.split()[0])
      logger.info prod_lvm
      is_lvm prod_lvm
    end

    def create_snapshot
      unless @stage_lvm
        @stage_lvm = @prod_lvm + '_' + app['name'] + '_pgstg'
      end
      lvm.create_snapshot(@prod_lvm, @stage_lvm, size)
      logger.info("Snapshot created: #{@stage_lvm}")
    end
    
    def size
      s = app['size'] || '10'
      if s.to_s =~ /^\d+$/ and s.to_i < 90
        s = lvm.cal_percent_size_mb(@prod_lvm, s.to_i)
      elsif s.to_s !~ /^\d+(G|M|g|m)$/
        raise "Could not figure out the size of snapshot volume to be created (#{s})"
      end
    end
    
    def datadir
      app['datadir']
    end
    
    def port
      app['port']
    end
    
    def version
      app['version']
    end

    def mount_snapshot
      run 'root', "/usr/bin/mount #{stage_lvm} #{datadir} "
      logger.info("Snapshot #{stage_lvm} is mounted on #{datadir}")
    end
    
    def fix_perm
      Dir.chdir datadir
      sleep 2
      FileUtils.chmod_R 0700, Dir.glob('*')
      FileUtils.chmod_R 0700, Dir.glob('.')
      FileUtils.chown_R 'postgres', 'postgres', Dir.glob('.')
      FileUtils.chown_R 'postgres', 'postgres', Dir.glob('*')
    end
    
    def delete_conf_files
      files_to_rm = ['postgresql.conf','pg_hba.conf','recovery.conf','postmaster.pid']
      dir_to_rm = ['pg_log', 'pg_xlog']
      Dir.chdir datadir
      files_to_rm.each do |file|
        run 'postgres', "rm #{file}"
      end
      dir_to_rm.each do |dir|
        run 'postgres', "rm -rf #{datadir}/#{dir}"
      end
    end
    
    def copy_conf_files
      src = '/etc/pgstgtool/config/' + version + '/.'
      run 'postgres', "cp -pr #{src} #{datadir}"
      xlog_dir = datadir + '/pg_xlog/archive_status'
      unless File.exists?(xlog_dir)
        run 'postgres', "mkdir -p #{xlog_dir}"
      end
    end
    
    def pre_start_setup
     delete_conf_files
     copy_conf_files
     fix_perm
    end

    def run_rake_task
      if app['task']
        Pgstgtool::RakeTask.new(app)
      end
    end
    
    def roll_back
      logger.error "-------"
      logger.error "Rolling back !!"
      postgres.tail_pglog(10)
      logger.error "-------".red
      begin
        Dir.chdir
        umount(datadir)
      rescue Exception => e
        msg = e.message + e.backtrace.inspect
        logger.error(msg)
      end
      begin
        lvm.remove_lv(stage_lvm)
      rescue Exception => e
        msg = e.message + e.backtrace.inspect
        logger.error(msg)
      end
    end
    
    def lvm
      return @lvm if @lvm
      Pgstgtool::Lvm.new
    end
    

    
    def postgres
      return @postgres if @postgres
      @postgres = Pgstgtool::Postgres.new(app)
    end
    
    def logger
      return @logger if @logger
      @logger = Pgstgtool::CustomLogger.new
    end
    
    def run(user,command)
      Pgstgtool::Command.run_as_user(user,command)
    end
    
    def start
        postgres.reset_pgxlog
        postgres.start
        sleep 2
        status, out = postgres.check_db_write
        if (not status) and (@count < 3)
            logger.error "Creating tmp db failed\n" + out
            @count = @count + 1
            sleep 10
            create
        end
        logger.info "postgres started on port #{port} for app:#{app['name']}"
    end
  end
end

#app = {'name' => 'test', 'datadir' => '/mnt/postgres/9.4/test', 'version' => '9.4', 'port' => '5433', 'prod_dir' => '/var/lib/pgsql/9.4/test'}
#Pgstgtool::Create.new(app).start