require 'open3'
require 'timeout'
module Pgstgtool
  module Helper
    
    def is_dir(dir='')
      return "#{dir} doesn't exist" if not File.directory? dir
    end
    
    def is_valid_port(port='')
      raise "Invalid port #{port}" if port.to_s !~ /^\d+$/
      raise "port #{port} already in use" if system("lsof -i:#{port}", out: '/dev/null')
    end
    
    def mount_point(dir='')
      raise "Could not figure out stage mount directory #{dir}" if not dir
      if Dir.exist?(dir) and not (Dir.entries(dir.to_s) - %w{ . .. }).empty?
        raise "stage mount point (#{dir}) is not empty"
      elsif not Dir.exist?(dir)
        FileUtils.mkdir_p(dir)
      end
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
            if pid_exist(k.to_i)
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
         puts "#{file} => Good to umount !!"
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
    
  end
end
  