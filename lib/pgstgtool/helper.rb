require 'open3'
require 'timeout'
require 'etc'
module Pgstgtool
  module Helper
    
    def logger
      return @logger if @logger
      @logger = Pgstgtool::CustomLogger.new
    end
    
    def is_dir(dir='')
      return "#{dir} doesn't exist" if not File.directory? dir
    end
    
    def is_valid_port(port='')
      raise "Invalid port #{port}" if port.to_s !~ /^\d+$/
      raise "port #{port} already in use" if system("lsof -i:#{port}", out: '/dev/null')
    end
    
    def empty_mount_point(dir='')
      raise "Could not figure out stage mount directory #{dir}" unless dir
      if Dir.exist?(dir) and not (Dir.entries(dir.to_s) - %w{ . .. }).empty?
        return false
      elsif not Dir.exist?(dir)
        FileUtils.mkdir_p(dir)
      end
      return true
    end

    def is_lvm(lv)
      begin
        command="/usr/sbin/lvdisplay #{lv}"
        Pgstgtool::Command.run(command)
      rescue
        raise "#{lv} is not an lvm partition}"
      end
    end
    
    def mapper_to_lv(lv)
      if lv =~ /\/dev\/mapper\/(.*?)-(.*)/
        lv = '/dev/' + $1 + '/' + $2
	lv = lv.gsub('--','-')
      end
	lv
    end
    
    def lv_to_mapper(lv)
      if lv =~ /^\/dev\/(.*)\/(.*)$/
        vg = $1
        lv = $2
        if vg !~ /mapper/
            return "/dev/mapper/#{vg}-#{lv}"
        else
          return lv
        end
      else
        raise "#{lv} is not complete path"
      end
    end
    
    def pid_exist(pid)
      begin
        Process.getpgid( pid )
        true
      rescue Errno::ESRCH
        false
      end
    end
    
    def release_file_handles(file)
      command = "/usr/sbin/lsof #{file}|awk \'{print \$2}\'|grep -v PID"
      out,err,status = Open3.capture3(command)
      if status.success?
          out.split.each do |k|
            if pid_exist(k.to_i) and not (k.to_s.eql?(Process.pid.to_s))
              begin
                  Process.kill("TERM", k.to_i)
                  Timeout::timeout(30) do
                      begin
                        sleep 1
                      end while !!(`ps -p #{k}`.match k)
                  end
              rescue Timeout::Error
                  Process.kill("KILL", k.to_i)
              end 
            end
          end
       elsif err == ''
         logger.info"#{file} => Good to umount !!"
       else
         raise "Failed to find processes using #{file} => #{err}"
      end
    end
    
    def release_dir(dir)
      release_file_handles(dir)
      release_file_handles(dir)
    end
    
    
    def umount(dir)
      is_dir(dir)
      release_dir(dir)
      command="/usr/bin/umount #{dir} "
      Pgstgtool::Command.run(command)
    end
    
    def as_user(user, &block)
	  # Find the user in the password database.
	  begin
		u = (user.is_a? Integer) ? Etc.getpwuid(user) : Etc.getpwnam(user)
	  
		# Fork the child process. Process.fork will run a given block of code
		# in the child process.
		Process.fork do
		   # We're in the child. Set the process's user ID.
		   Process.uid = u.uid
	  
		  # Invoke the caller's block of code.
		  begin
			block.call(user)
		  rescue Exception => e
			msg = e.message + e.backtrace.inspect
			logger.error(msg)
		  end
		  exit 0
		end
	  rescue Exception => e
        msg = e.message + e.backtrace.inspect
        logger.error(msg)
	  end
    end
    
  end
end
  
