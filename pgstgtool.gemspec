# Ensure we require the local version and not one we might have installed already
require File.join([File.dirname(__FILE__),'lib','pgstgtool','version.rb'])
spec = Gem::Specification.new do |s| 
  s.name = 'pgstgtool'
  s.version = Pgstgtool::VERSION
  s.author = 'pawan pandey'
  s.email = 'pawan.pandey@housing.com'
  s.platform = Gem::Platform::RUBY
  s.summary = 'Gem for creating staging end point for postgres on standby using lvm snapshot feature'
  s.files = `git ls-files`.split("
")
  s.require_paths << 'lib'
  s.bindir = 'bin'
  s.executables << 'pgstgtool'
  s.add_development_dependency('rake')
  s.add_development_dependency('aruba')
  s.add_runtime_dependency('gli','2.13.1')
  s.add_runtime_dependency('di-ruby-lvm','0.1.3')
  s.add_runtime_dependency('colorize')
  s.add_runtime_dependency('posix_mq', '2.2.0')
end
