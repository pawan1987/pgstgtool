
module Pgstgtool
  class Delete
    
    attr_accessor :options
    include Pgstgtool::Helper
    
    def initialize(config={})
      @options = config
      raise "stage_mount not defined #{@options['stage_mount']}" if not @options['stage_mount']
    end
    
    #given prod mount dir, it fetches lvpath from /proc/mounts file
    def stage_lv
      mline = open('/proc/mounts').grep(/\ #{@options['stage_mount']}\ /)[0]
      raise "#{@options['stage_mount']} is not a mountpoint" if not mline
      @options['stage_lv'] = mapper_to_lv(mline.split()[0])
      is_lvm(@options['stage_lv'])
    end
    
    def delete_snapshot
      umount(@options['stage_mount'])
      @lvm = Pgstgtool::Lvm.new
      @lvm.remove_lv(@options['stage_lv'])
      puts "Snapshot deleted with lv #{@options['stage_lv']}"
    end
    
    def stop_stage
      Pgstgtool::Postgres.new({'pgversion' => @options['pgversion'],'datadir' => options['stage_mount']}).stop
      puts "postgres stopped"
    end
    
    def delete
      stage_lv
      stop_stage
      delete_snapshot
    end
    
  end
end
  
