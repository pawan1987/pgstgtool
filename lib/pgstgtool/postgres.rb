require 'fileutils'
module Pgstgtool
  class Postgres
    
    attr_accessor :user
    attr_accessor :pgversion
    attr_accessor :datadir
    
    def initialize(options={})
      @user = options['user'] || 'postgres'
      @pgversion = options['pgversion'] || '9.4'
      @datadir = options['datadir']
    end
    
    def start(port,logfile)
      raise "#{datadir} doesn't exist" if not File.directory? datadir
      pgctlcmd = "/usr/pgsql-#{pgversion}/bin/pg_ctl"
      raise "command #{pgctlcmd} not found" if not File.exists? pgctlcmd
      command = "/usr/bin/su #{user} -c \'#{pgctlcmd} start -D #{datadir} -o \"-p #{port}\" -l #{logfile} \'"
      Pgstgtool::Command.run(command)
      sleep 2
      #raise "Failed to start postgres. command => \n #{command}\n"
      if verify_postgres(port) !~ /^\d+$/
        return false
      else
        return true
      end
    end
    
    def reset_pgxlog
      raise "#{datadir} doesn't exist" if not File.directory? datadir
      Dir.chdir datadir
      pgresetxlogcmd = "/usr/pgsql-#{pgversion}/bin/pg_resetxlog"
      xlog_dir = 'pg_xlog/archive_status'
      FileUtils.mkdir_p xlog_dir unless File.exists?(xlog_dir)
      command = "/usr/bin/su #{user} -c \'#{pgresetxlogcmd} -f datadir\'"
      Pgstgtool::Command.run(command)
    end
    
    def verify_postgres(port)
      #to be reworked out
      command = "/usr/bin/netstat -plan|/usr/bin/egrep \':#{port.to_s} \'|/usr/bin/egrep \'tcp \'|/usr/bin/egrep postgres|awk \'{print \$7}\'|cut -d\'/\' -f1"
      output = Pgstgtool::Command.run(command)
      output.to_s.chomp
    end
    
    def stop
      raise "#{datadir}/postgres.pid file missing" if not File.directory? datadir
      pgctlcmd = "/usr/pgsql-#{pgversion}/bin/pg_ctl"
      command = "/usr/bin/su #{user} -c \'#{pgctlcmd} stop -D #{datadir}\'"
      Pgstgtool::Command.run(command)
    end
    
    #tail last n lines of log
    def tail_pglog(n)
      log_dir =  datadir + '/pg_log'
      log_file = `ls -t #{log_dir}|head -1`
      log_file = log_dir + '/' + log_file
      message = `tail -#{n} #{log_file}`
      message
    end
    
  end
end