require 'open3'
require_relative 'logger'
module Pgstgtool
  module Command
    
    def self.run(command)
      out,err,status = Open3.capture3(command)
      if status.success?
        return [true,out]
      else
        return [false,err]
      end
    end
    
    def self.logger
      Pgstgtool::CustomLogger.new
    end
    
    def self.run_as_user(user,cmd)
      command = "/usr/bin/su #{user} -c \'#{cmd}\'"
      logger.debug(command)
      begin
        status,out = Pgstgtool::Command.run(command)
        if status and ( out != '')
            logger.debug(out.gsub("\n",' '))
          elsif out != ''
            logger.debug(out.gsub("\n",' '))
        end
        [status,out]
      rescue Exception => e
        msg = e.message + e.backtrace.inspect
        logger.error(msg) 
        [false,e.message]
      end 
    end
  end
end

#run_as_user('postgres',"delete /root/tesfdfdf.dfd").inspect
#run_as_user('root',"rm /root/tesfdfdf.dfd").inspect
