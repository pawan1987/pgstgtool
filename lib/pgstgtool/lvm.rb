require 'lvm'
require_relative 'helper'

module Pgstgtool
  class Lvm
    
    include Pgstgtool::Helper
    attr_accessor :lvmobj
    attr_accessor :options
    
    def initialize(options={})
      @lvmobj = LVM::LVM.new
      @options = options
    end
    
    def create_snapshot(lvpath, snapshotname, size)
      raise "lvname should be complete lv path => #{lvpath}" if lvpath !~ /^\/dev\/(.*?)\/(.*?)/
      raise "Size should be in multiple of bytes (\d(G|M|g|m)) => #{size}" if size.to_s !~ /^\d+(G|M|g|m)/
      command = "#{lvcreate} -L#{size} -s -n #{snapshotname} #{lvpath}"
      status, out = Pgstgtool::Command.run_as_user('root',command)
      unless status
        if snapshotname =~ /_pgstg$/
            logger.error "LV #{snapshotname} already exist. Deleting snapshot"
            delete_snapshot(snapshotname)
            command = "#{lvcreate} -L#{size} -s -n #{snapshotname} #{lvpath}"
            status, out = Pgstgtool::Command.run_as_user('root',command)
            if status
                return [status,out]
            end
            
        end
        raise "Failed to create snapshot #{out}"
      end
    end
    
    def lvcreate
      options['lvcreate'] || '/usr/sbin/lvcreate'
    end
    
    def lvremove
      options['lvremove'] || '/usr/sbin/lvremove'
    end
    
    def remove_lv(lvpath)
      raise "Provide complete snapshot lv path => #{lvpath}" if lvpath !~ /^\/dev\/(.*?)\/(.*?)/
      command = "#{lvremove} --force #{lvpath}"
      status, out = Pgstgtool::Command.run_as_user('root',command)
      log_error status, out
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
    
    def snapshot_status(lvpath)
        lvobj = get_lv_attributes(lvpath)    
        output = {}
        volume_type = lvobj['volume_type']
        if volume_type =~ /snapshot/
          output['data_percent'] = lvobj['data_percent']
          output['snapshot_invalid'] = lvobj['snapshot_invalid']
          return [true, output]
        else
          return [false, "#{lvpath} is not snapshot volume"]
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
#puts obj.snapshot_status('/dev/testvg/lvtest_test_1443125113_pgstg').inspect



  