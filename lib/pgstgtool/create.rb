require 'fileutils'
require 'etc'
module Pgstgtool
  class Create

    attr_accessor :options
    include Pgstgtool::Helper

    def initialize(config={})
      @options = config
      validate_params
    end

    def validate_params
      #validate port
      is_valid_port(@options['stage_port'])

      #valid prod dir
      is_dir(@options['prod_mount'])

      #check stage mount point
      mount_point(@options['stage_mount'])
    end

    #given prod mount dir, it fetches lvpath from /proc/mounts file
    def prod_lv
      mline = open('/proc/mounts').grep(/\ #{@options['prod_mount']}\ /)[0]
      raise "#{@options['prod_mount']} is not a mountpoint" if not mline
      @options['prod_lv'] = mapper_to_lv(mline.split()[0])
      is_lvm(@options['prod_lv'])
    end

    def create_snapshot
      @lvm = Pgstgtool::Lvm.new

      if not (@options['snapshot_name']) or @options['snapshot_name'] == ''
        #snapshot name from app name and lvpath and timestamp if name is not provided explicitly
        @options['snapshot_name'] = @options['prod_lv'] + '_' + @options['app'] + '_' + "#{Time.now.to_i}" + '_pgstg'
      end

      size = @options['size'] || '10'

      if size.to_s =~ /^\d+$/ and size.to_i < 90
        size = @lvm.cal_percent_size_mb(@options['prod_lv'], size.to_i)
      elsif size.to_s !~ /^\d+(G|M|g|m)$/
        raise "Could not figure out the size of snapshot volume to be created (#{size})"
      end

      size=@lvm.create_snapshot(@options['prod_lv'], @options['snapshot_name'],size)
      puts "Snapshot created with lv #{@options['snapshot_name']}"
    end

    def mount_snapshot
      command="/usr/bin/mount #{@options['snapshot_name']} #{@options['stage_mount']} "
      Pgstgtool::Command.run(command)
      puts "Snapshot #{@options['snapshot_name']} mounted on #{@options['stage_mount']}"
    end
    
    def fix_perm
      Dir.chdir options['stage_mount']
      FileUtils.chmod_R 0700, options['stage_mount'] + '/.'
      FileUtils.chown_R 'postgres', 'postgres', options['stage_mount'] + '/.'
    end
    
    def delete_conf_files
      as_user 'postgres' do
        Dir.chdir options['stage_mount']
        files_to_rm = ['postgresql.conf','pg_log','pg_xlog','pg_hba.conf','recovery.conf','postmaster.pid']
        FileUtils.rm files_to_rm
      end
    end
    
    def copy_conf_files
      as_user 'postgres' do
        src = '/etc/pgstgtool/config/' + options['pgversion'] + '/.'
        FileUtils.cp_r src, options['stage_mount']
        xlog_dir = options['stage_mount'] + 'pg_xlog/archive_status'
        FileUtils.mkdir_p xlog_dir unless File.exists?(xlog_dir)
      end
    end
    
    def pre_start_setup
     delete_conf_files
     copy_conf_files
     fix_perm
    end

    def run_task
      if @options['task']
        Pgstgtool::RakeTask.new('rake_dir'=>@options['task_dir']).run_task(@options['task'],@options['stage_mount'],@options['stage_port'])
      end
    end
    
    def roll_back
      pgobj = Pgstgtool::Postgres.new({'pgversion' => options['pgversion'], 'datadir' => options['stage_mount']})
      puts "-------"
      puts pgobj.tail_pglog(10)
      puts "-------"
      puts "Rolling back !!"
      begin
        #Dir.chdir
        umount(options['stage_mount'])
      rescue
        puts "#{options['stage_mount']} not mounted"
      end
      Pgstgtool::Lvm.new.remove_lv(options['snapshot_name'])
      raise "Postgres failed to start !!"
    end

    def start_stage
      logfile = "/tmp/#{@options['app']}" + '_' + "#{Time.now.to_i}"
      pgobj = Pgstgtool::Postgres.new({'pgversion' => options['pgversion'], 'datadir' => options['stage_mount']})
      pgobj.reset_pgxlog
      pgobj.start(options['stage_port'],logfile)
      puts "postgres started on port #{@options['stage_port']}"
    end

    def create
      prod_lv
      create_snapshot
      begin
        mount_snapshot
        pre_start_setup
        start_stage
        run_task
      rescue Exception => msg
        roll_back
        puts msg
        exit 2
      end
    end

  end
end
