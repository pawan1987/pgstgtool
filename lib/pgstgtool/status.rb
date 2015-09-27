module Pgstgtool
    class Status
        
        attr_accessor :app
        attr_accessor :postgres
        attr_accessor :lvm
        attr_accessor :output
        attr_accessor :stage_lvm
        include Pgstgtool::Helper
        
        def initialize(app)
            @app = app
        end
        
        def postgres
            return @postgres if @postgres
            @postgres = Pgstgtool::Postgres.new(app)
        end
        
        def logger
          return @logger if @logger
          @logger = Pgstgtool::CustomLogger.new
        end
        
        def lvm
            return @lvm if @lvm
            @lvm = Pgstgtool::Lvm.new
        end
        
        def init_stage_lvm
          return @stage_lvm if @stage_lvm
          mline = open('/proc/mounts').grep(/\ #{datadir}\ /)[0]
          raise "#{datadir} is not a mountpoint" if not mline
          @stage_lvm = mapper_to_lv(mline.split()[0])
          is_lvm @stage_lvm
        end
        
        def datadir
          return app['datadir']
        end
        
        def snapshot_status
            h = {}
            h['desc'] = ''
            h['status'] = false
            h['lvpath_invalid'] = true
            begin
              init_stage_lvm
              status, obj = lvm.snapshot_status stage_lvm
            rescue Exception => e
              msg = e.message + e.backtrace.inspect
              logger.error(msg)
              h['desc'] = e.message
            end 
            if status and obj['data_percent']
              h['lvpath_invalid'] = false
              h['data_percent'] = obj['data_percent']
              h['snapshot_invalid'] = obj['snapshot_invalid']
              if obj['snapshot_invalid'] == nil
                h['status'] = true
              else
                h['status'] = false
              end
            end
            @output['lvm'] = h
        end
        
        def service_status
            status, out = postgres.app_dbs
            if status
                @output['service'] = {'status' => status, 'desc' => out.join(",")}
              else
                @output['service'] = {'status' => status, 'desc' => out}
            end
        end
        
        def status
            @output = {
                'name' => app['name'],
                'service' => {
                    'status' => false,
                    'desc' => '',
                },
                'lvm' => {
                    'status' => false,
                    'snapshot_invalid' => nil,
                    'lvpath_invalid' => true,
                    'data_percent' => '',
                    'desc' => ''
                }
            }
            service_status
            snapshot_status
            return @output
        end
        
    end
end