require 'rake'
require 'fileutils'
module Pgstgtool
  class RakeTask
    
    attr_accessor :rakedir
    attr_accessor :rake
    attr_accessor :options
    
    def initialize(options={})
      @options = options
      @rakedir = options['rakedir'] || '/etc/pgstgtool/tasks'
      @rake = Rake.application
      @rake.init
    end
    
    #opt should be passed as a url string. e.g. opt='datadir=/mnt/pgstgtool/buy/&location=mumbai'
    def run_task(task,postgresdir,port)
      #set environment variable
      puts "Running rake task #{task}"
      ENV['PGDATA'] = postgresdir
      ENV['PORT'] = port.to_s
      raise "Rakedir (#{@rakedir}) missing doesn't exist" if not File.directory? @rakedir
      cwd = Dir.pwd
      Dir.chdir(@rakedir)
      #touch Rakefile if it doesn't exist. Required by rake task
      FileUtils.touch('Rakefile') if not File.exist?('Rakefile')
      Dir.glob('*.rake').each { |r| @rake.add_import r }
      @rake.load_rakefile
      @rake.invoke_task("#{task}")
      Dir.chdir(cwd)
    end
    
  end
end
