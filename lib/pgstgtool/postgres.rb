require_relative 'version.rb'
require_relative 'logger.rb'
require_relative 'app_api.rb'
require_relative 'app_config.rb'
require_relative 'apps.rb'
require_relative 'command.rb'
require_relative 'config.rb'
require_relative 'helper.rb'
require_relative 'log_writer.rb'
require_relative 'lvm.rb'
require_relative 'mq.rb'
require_relative 'postgres.rb'
require_relative 'validate.rb'
require_relative 'create.rb'
require_relative 'delete.rb'
require_relative 'status.rb'

module Pgstgtool
  class Postgres
    
    attr_accessor :app
    
    def initialize(app)
      @app = app
      #check_tmp_dir
    end
    
    def check_tmp_dir
      logdir = "/tmp/pgstgtool"
      run 'postgres', "mkdir #{logdir}" unless File.exists?(logdir)
    end
    
    def run(user,command,dir)
      olddir = Dir.pwd
      Dir.chdir dir
      status,out = Pgstgtool::Command.run_as_user(user,command)
      Dir.chdir olddir
      [status,out]
    end
    
    def app_dbs
      command = "#{psql} -c \"SELECT datname FROM pg_database\" -p #{port}"
      status, out = run(user,command, datadir)
      if status
        out = out.gsub("\n",' ')
        if out.gsub("\n",' ').to_s =~ /--- (.*)\(/
            arr = $1.split(' ')
            return [true, arr]
        end
      end
      return [false,out]
    end
    
    def check_db_read
      command = "#{psql} -c \"\\\l\" -p #{port}"
      run(user,command, datadir)
    end
    
    def check_db_write
      command = "#{psql} -c \'create database pgstgtool\' -p #{port}"
      run(user, command, datadir)
    end
    
    
    
    def psql
      return "/usr/pgsql-#{version}/bin/psql"
    end
    
    def pg_resetxlog
      return "/usr/pgsql-#{version}/bin/pg_resetxlog"
    end
    
    def logfile
      return "/tmp/pgstgtool/#{name}_log"
    end
    
    def name
      return app['name']
    end
    
    def datadir
      return app['datadir']
    end
    
    def version
      return app['version'] || '9.4'
    end
    
    def port
      return app['port'] 
    end

    def logger
      Pgstgtool::CustomLogger.new
    end
    
    def user
      return app['user'] || 'postgres'
    end
    
    def pg_ctl
      "/usr/pgsql-#{version}/bin/pg_ctl"
    end
    
    def create_check_point(dir)
      puts dir
      if File.exists?("#{dir}/postmaster.pid")
        prod_port = `awk '{ if (NR==4) print $0 }' #{dir}/postmaster.pid`
        prod_version = `cat #{dir}/PG_VERSION`
        raise "version not compatible" if version != prod_version.chomp
        if File.exists?("#{dir}/backup_label")
          puts "inside backup_label"
          command = "#{psql} -c \\\"SELECT pg_stop_backup()\\\" -p #{prod_port.chomp}"
          run('postgres',command, dir)
        end
        command = "#{psql} -c \\\"SELECT pg_start_backup('pgstgtool')\\\" -p #{prod_port.chomp}"
        run('postgres',command, dir)
      end
    end
    
    def delete_check_point(dir)
      logger.info "Delete backup check point #{dir}"
      if File.exists?("#{dir}/postmaster.pid")
        prod_port = `awk '{ if (NR==4) print $0 }' #{dir}/postmaster.pid`
        prod_version = `cat #{dir}/PG_VERSION`
        raise "version not compatible" if version != prod_version.chomp
        if File.exists?("#{dir}/backup_label")
          command = "#{psql} -c \\\"SELECT pg_stop_backup()\\\" -p #{prod_port.chomp}"
          run('postgres',command, dir)
        end
      elsif File.exists?("#{dir}/backup_label")
         run('postgres',"rm #{dir}/backup_label", dir)
      end
    end
    
        #tail last n lines of log
    def tail_pglog(n)
      log_dir =  datadir + '/pg_log'
      status, out = run 'root', "ls -t #{log_dir}|head -1", datadir
      if out !~ /(No such file)|^$/
        log_file = log_dir + '/' + out
        command = "tail -#{n} #{log_file}"
        status, out = run 'root', command, datadir
        if status
          logger.info out
        end
      end
    end
    

    
    def start
      command = "#{pg_ctl} start -D #{datadir} -o \'-p #{port}\' -l #{logfile}"
      run user,command, datadir
    end
    
    def stop
      command = "#{pg_ctl} stop -m immediate -D #{datadir}"
      run user,command, datadir
    end
    
    def reset_pgxlog
      Dir.chdir datadir
      command = "#{pg_resetxlog} -f #{datadir}"
      run user,command, datadir
    end
    
  end
end

#obj = Pgstgtool::Postgres.new({'datadir' => '/mnt/postgres/9.4/test', 'pgversion' => '9.4'}).service_state(5480)
#puts Pgstgtool::Postgres.new({}).create_check_point('/var/lib/pgsql/9.4/data/').inspect
#puts obj.inspect