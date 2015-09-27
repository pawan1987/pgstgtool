module Pgstgtool
  class Postgres
    
    attr_accessor :app
    
    def initialize(app)
      @app = app
      check_tmp_dir
    end
    
    def check_tmp_dir
      logdir = "/tmp/pgstgtool"
      run 'postgres', "mkdir #{logdir}" unless File.exists?(logdir)
    end
    
    def run(user,command)
      Pgstgtool::Command.run_as_user(user,command)
    end
    
    def app_dbs
      command = "#{psql} -c \"SELECT datname FROM pg_database\" -p #{port}"
      status, out = run(user,command)
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
      run(user,command)
    end
    
    def check_db_write
      command = "#{psql} -c \"create database pgstgtool\" -p #{port}"
      run(user, command)
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
    
        #tail last n lines of log
    def tail_pglog(n)
      log_dir =  datadir + '/pg_log'
      status, out = run 'root', "ls -t #{log_dir}|head -1"
      if out !~ /(No such file)|^$/
        log_file = log_dir + '/' + out
        command = "tail -#{n} #{log_file}"
        status, out = run 'root', command
        if status
          logger.info out
        end
      end
    end
    
    def start
      command = "#{pg_ctl} start -D #{datadir} -o \"-p #{port}\" -l #{logfile}"
      run user,command
    end
    
    def stop
      command = "#{pg_ctl} stop -m immediate -D #{datadir}"
      run user,command
    end
    
    def reset_pgxlog
      Dir.chdir datadir
      command = "#{pg_resetxlog} -f #{datadir}"
      run user,command
    end
    
  end
end

#obj = Pgstgtool::Postgres.new({'datadir' => '/mnt/postgres/9.4/test', 'pgversion' => '9.4'}).service_state(5480)
#puts obj.inspect