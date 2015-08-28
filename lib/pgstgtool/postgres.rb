
module Pgstgtool
  class Postgres
    
    attr_accessor :user
    attr_accessor :pgctlcmd
    
    def initialize(options={})
      @user = options['user'] || 'postgres'
      @pgctlcmd = options['pgctlcmd'] || '/usr/bin/pg_ctl'
    end
    
    def start(datadir,port,logfile)
      raise "#{datadir} doesn't exist" if not File.directory? datadir 
      command = "/usr/bin/su #{user} -c \'#{@pgctlcmd} start -D #{datadir} -o \"-p #{port}\" -l #{logfile} \'"
      Pgstgtool::Command.run(command)
      sleep 2
      #raise "Failed to start postgres. command => \n #{command}\n"
      if verify_postgres(port) !~ /^\d+$/
        return false
      else
        return true
      end
    end
    
    def verify_postgres(port)
      #to be reworked out
      command = "/usr/bin/netstat -plan|/usr/bin/egrep \':#{port.to_s} \'|/usr/bin/egrep \'tcp \'|/usr/bin/egrep postgres|awk \'{print \$7}\'|cut -d\'/\' -f1"
      output = Pgstgtool::Command.run(command)
      output.to_s.chomp
    end
    
    def stop(datadir)
      raise "#{datadir}/postgres.pid file missing" if not File.directory? datadir
      command = "/usr/bin/su #{user} -c \'#{@pgctlcmd} stop -D #{datadir}\'"
      Pgstgtool::Command.run(command)
    end
    
    #tail last n lines of log
    def tail_pglog(datadir,n)
      log_dir =  datadir + '/pg_log'
      log_file = `ls -t #{log_dir}|head -1`
      log_file = log_dir + '/' + log_file
      message = `tail -#{n} #{log_file}`
      message
    end
    
  end
end