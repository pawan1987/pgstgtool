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

    def check_stuck_postgres
      pid=`ps aux|grep "bin/postgres -D #{datadir} -p #{port}"|grep -v grep|awk '{print \$2}'`
      if pid =~ /^\d+(\n)?$/
        logger.error "stuck process is #{pid}"
        `kill -15 #{pid}`
        sleep 3
      end
    end
    
	def acquire_lock
	  lock_file = "/tmp/.#{app['name']}.lock"
	  if File.exists? lock_file
		puts "inside acquire_lock"
		age = (Time.now - File.stat(lock_file).mtime).to_i
		if age > 3600 #1h
		  File.delete lock_file
		else
		  return false
		end
		
	  end
	  return false if not File.new(lock_file, 'w').flock( File::LOCK_NB | File::LOCK_EX )
	  return true
	end
	
	def delete_lock
	  lock_file = "/tmp/.#{app['name']}.lock"
	  File.delete lock_file if File.exists? lock_file
	end


    def create
	  
	  if not acquire_lock
		logger.info "Another process is already running. Delete lock file /tmp/.#{app['name']}.lock if you still want to continue"
		return 
	  end
	  
      status = postgres.app_dbs[0]
      if status
        logger.info "DB is already running"
        return true
      else
        unless empty_mount_point(datadir)
           logger.error("snapshot dir #{datadir} is not empty. Running delete command on \'#{app['name']}\'")
           Pgstgtool::Delete.new(app).delete 
        end
	  check_stuck_postgres
      end
      
      begin
        prod_mount_point
        postgres_create_check_point
        create_db_snapshot
        mount_snapshot
        pre_start_setup
        start
        postgres_delete_check_point
        run_rake_task
        delete_lock
      rescue Exception => e
        msg = e.message + e.backtrace.inspect
        logger.error(msg)
        roll_back
        return false
      end
      
    end
    
    #given prod mount dir, it fetches lvpath from /proc/mounts file
    def prod_mount_point
      mline = open('/proc/mounts').grep(/\ #{app['proddir']}\ /)[0]
      raise "#{app['proddir']} is not a mountpoint" if not mline
      @prod_lvm = mapper_to_lv(mline.split()[0])
      logger.info prod_lvm
      is_lvm prod_lvm
    end

	def postgres_create_check_point
		postgres.create_check_point app['proddir']
	end
	
	def postgres_delete_check_point
		postgres.delete_check_point app['proddir']
	end
	
    def create_db_snapshot
      unless @stage_lvm
        @stage_lvm = @prod_lvm + '_' + app['name'] + '_pgstg'
      end
      lvm.create_snapshot(@prod_lvm, @stage_lvm, size, app['snapshot_size_min'])
      logger.info("Snapshot created: #{@stage_lvm}")
    end
    
    def size
      s = app['size'] || '10'
      if s.to_s =~ /^\d+$/ and s.to_i <= 100
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
      olddir = Dir.pwd
      Dir.chdir datadir
      sleep 2
      FileUtils.chmod_R 0700, Dir.glob('*')
      FileUtils.chmod_R 0700, Dir.glob('.')
      FileUtils.chown_R 'postgres', 'postgres', Dir.glob('.')
      FileUtils.chown_R 'postgres', 'postgres', Dir.glob('*')
      Dir.chdir olddir
    end
    
    def delete_conf_files
      files_to_rm = ['postgresql.conf','pg_hba.conf','recovery.conf','postmaster.pid']
      dir_to_rm = ['pg_log', 'pg_xlog']
      oldir = Dir.pwd
      Dir.chdir datadir
      files_to_rm.each do |file|
        run 'postgres', "rm #{file}"
      end
      dir_to_rm.each do |dir|
        run 'postgres', "rm -rf #{datadir}/#{dir}"
      end
      Dir.chdir oldir
    end
    
    def copy_conf_files
      olddir = Dir.pwd
      Dir.chdir datadir
      src = '/etc/pgstgtool/config/' + version + '/.'
      run 'postgres', "cp -pr #{src} #{datadir}"
      status, out = run 'postgres', "/usr/bin/readlink #{app['proddir']}/pg_xlog"
      
      prod_xlog_dir = ''
      
	  if status and out.chomp =~ /pg_xlog/
		prod_xlog_dir = out.chomp
	 else
	    raise "Couldn't copy pg_xlog symlink" 
	  end
      
      if File.directory?(prod_xlog_dir.chomp)
        run 'postgres', "cp -pr #{prod_xlog_dir.chomp} #{datadir}"
	  else
		raise "Failed copying pg_xlog dir"
      end
      Dir.chdir olddir
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
        postgres_delete_check_point
        delete_lock
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
      status, out = Pgstgtool::Command.run_as_user(user,command)
      log_error status, out
    end
 
    def wait_for_pg
      counter = 2
      while counter < 40 do
        sleep 2
        logger.info "Waiting for server to start accepting connection: counter #{counter} sec (Max Wait 40sec)"
        out = `cat #{datadir}/pg_log/*|grep 'database system is ready to accept connections'`
        if out =~ /ready/
          break
        end
        counter = counter + 2
      end
    end
    
    def start
        #postgres.reset_pgxlog
        postgres.start
        wait_for_pg
        status, out = postgres.check_db_write
        if (not status) and (@count < 3)
            logger.error "Creating tmp db failed. Failed attempt #{@count} to create staging end point. #{out}"
            @count = @count + 1
            sleep 10
            delete_lock
            create
          elsif status
            logger.info "Postgres started on port #{port} for #{app['name']}"
            return true
        end
        logger.error "Postgres failed to start for #{app['name']} on port #{port} "
        roll_back
        return false
    end
  end
end

#app = {'name' => 'test', 'datadir' => '/mnt/postgres/9.4/test', 'version' => '9.4', 'port' => '5433', 'prod_dir' => '/var/lib/pgsql/9.4/test'}
#Pgstgtool::Create.new(app).start
