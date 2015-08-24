require 'open3'
require 'lvm'
module Pgstgtool
  module Command
    def run(command)
      LVM::External.cmd(command)
    end
    module_function :run
  end
end