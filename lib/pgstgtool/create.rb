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
    
    def del_files
      pid_file = @options['stage_mount'] + '/postmaster.pid'
      recovery_file = @options['stage_mount'] + '/recovery.conf'
      hba_file = @options['stage_mount'] + '/pg_hba.conf'
      conf_file = @options['stage_mount'] + '/postgresql.conf'
      pg_log = @options['stage_mount'] + '/pg_log'
      pg_xlog = @options['stage_mount'] + '/pg_xlog'
      File.delete(pid_file) if File.exist?(pid_file)
      File.delete(recovery_file) if File.exist?(recovery_file)
      File.delete(hba_file) if File.exist?(hba_file)
      File.delete(conf_file) if File.exist?(conf_file)
      File.delete(pg_log) if File.exist?(pg_log)
      File.delete(pg_xlog) if File.exist?(pg_xlog)
    end
    
    def copy_files
      `cp -pr /etc/pgstgtool/config/* #{@options['stage_mount']}`
      Dir.chdir(@options['stage_mount'])
      `mkdir -p pg_xlog/archive_status`
      `mkdir -p pg_log`
    end
    
    def correct_perm
      Dir.chdir(@options['stage_mount'])
      `chmod 0700 -R .`
      `chown postgres. -R .`
    end
    
    def reset_xlog
      if @options['pgversion'] == '9.3'
          command = "sudo -u postgres /usr/pgsql-9.3/bin/pg_resetxlog -f #{@options['stage_mount']}"
        else
          command = "sudo -u postgres /usr/pgsql-9.4/bin/pg_resetxlog -f #{@options['stage_mount']}"
      end
      Pgstgtool::Command.run(command)
    end
    
    def pre_start_setup
     del_files
     copy_files
     correct_perm
     reset_xlog
    end

    def run_task
      if @options['task']
        Pgstgtool::RakeTask.new('rake_dir'=>@options['task_dir']).run_task(@options['task'],@options['stage_mount'],@options['stage_port'])
      end
    end

    def start_stage
      logfile = "/tmp/#{@options['app']}" + '_' + "#{Time.now.to_i}"
      pgobj = Pgstgtool::Postgres.new({'pgctlcmd' =>@options['pgctlcmd']})
      if not pgobj.start(@options['stage_mount'],@options['stage_port'],logfile)
        puts "-------"
        puts pgobj.tail_pglog(@options['stage_mount'],10)
        puts "-------"
        puts "Rolling back !!"
        umount(@options['stage_mount'])
        Pgstgtool::Lvm.new.remove_lv(@options['snapshot_name'])
        raise "Postgres failed to start !!"
      end
      puts "postgres started on port #{@options['stage_port']}"
    end

    def create
      prod_lv
      create_snapshot
      mount_snapshot
      pre_start_setup
      start_stage
      run_task
    end

  end
end
