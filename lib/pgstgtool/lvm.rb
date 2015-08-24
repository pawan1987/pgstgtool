
#require di-ruby-lvm
#expects lvpath in the format /dev/{vol_group_name}/{logical_volume_name}
require 'lvm'

module Pgstgtool
  class Lvm
    
    include Pgstgtool::Helper
    attr_accessor :lvmobj
    attr_accessor :lvcreate
    attr_accessor :lvremove
    
    def initialize(options={})
      @lvmobj = LVM::LVM.new
      @lvcreatecmd = options['lvcreatecmd'] || '/usr/sbin/lvcreate'
      @lvremovecmd = options['lvremovecmd'] || '/usr/sbin/lvremove'
    end
    
    def create_snapshot(lvpath, snapshotname, size)
      raise "lvname should be complete lv path => #{lvpath}" if lvpath !~ /^\/dev\/(.*?)\/(.*?)/
      raise "Size should be in multiple of bytes (\d(G|M|g|m)) => #{size}" if size.to_s !~ /^\d+(G|M|g|m)/
      command = "#{@lvcreatecmd} -L#{size} -s -n #{snapshotname} #{lvpath}"
      Pgstgtool::Command.run(command)
    end
    
    def remove_lv(lvpath)
      raise "Provide complete snapshot lv path => #{lvpath}" if lvpath !~ /^\/dev\/(.*?)\/(.*?)/
      command = "#{@lvremovecmd} --force #{lvpath}"
      puts command
      Pgstgtool::Command.run(command)
    end
    
    def get_lv_attributes(lvpath)
      @lvmobj.logical_volumes.each do |lvm|
        if lvm['path'] == lvpath
            return lvm
          else
            nil
        end
      end
    end

    def get_lv_snapshots(lvpath)     
      snapshots = {}
      vg = ''
      lv = ''
      if lvpath =~ /^\/dev\/(.*)\/(.*)$/
        vg = $1
        lv = $2
      else
        raise "lvname should be complete lv path"
      end 
      @lvmobj.logical_volumes.each do |lvm|
        if lvm.volume_type =~ /snapshot/ and lvm.origin.to_s.eql?(lv.to_s)
            snapshots[lvm.path] = lvm
        end
      end
      snapshots 
    end
    
    def get_all_snapshots
      snapshots = {}
      @lvmobj.logical_volumes.each do |lvm|
        if lvm.volume_type =~ /snapshot/
            snapshots[lvm.path] = lvm
        end
      end
      snapshots
    end
    
    def delete_snapshot(lvpath)
      dir = open('/proc/mounts').grep(/^#{lv_to_mapper(lvpath)}\ /)[0]
      if dir
        dir = dir.split[0]
        umount(dir) if File.exists? dir
      end
      remove_lv(lvpath)
    end
   
    def cal_percent_size_mb(lvpath,pct)
        origin_size = get_lv_attributes(lvpath)['size']
        size = origin_size.to_i*pct/1024/1024/100
        size = size.to_s + 'm'
        size
    end
    
  end
end

#test code
#obj = Pgstgtool::Lvm.new
#puts obj.getLvmAttributes('/dev/vg2/postgres').inspect
#puts obj.createSnapshot('/dev/vg2/postgres','pawan','10m')

#puts "snapshot created"
#obj.getLvmSnapshots('/dev/vg2/postgres').keys.each {|i| obj.removeLvm i }

  