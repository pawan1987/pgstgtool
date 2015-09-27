# -*- encoding: utf-8 -*-
# stub: posix_mq 2.2.0 ruby lib
# stub: ext/posix_mq/extconf.rb

Gem::Specification.new do |s|
  s.name = "posix_mq"
  s.version = "2.2.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib"]
  s.authors = ["Ruby POSIX MQ hackers"]
  s.date = "2015-01-16"
  s.description = "POSIX message queues allow local processes to exchange data in the form\nof messages.  This API is distinct from that provided by System V\nmessage queues, but provides similar functionality."
  s.email = "ruby-posix-mq@bogomips.org"
  s.executables = ["posix-mq-rb"]
  s.extensions = ["ext/posix_mq/extconf.rb"]
  s.extra_rdoc_files = ["README", "LICENSE", "NEWS", "lib/posix_mq.rb", "ext/posix_mq/posix_mq.c", "posix-mq-rb_1"]
  s.files = ["LICENSE", "NEWS", "README", "bin/posix-mq-rb", "ext/posix_mq/extconf.rb", "ext/posix_mq/posix_mq.c", "lib/posix_mq.rb", "posix-mq-rb_1"]
  s.homepage = "http://bogomips.org/ruby_posix_mq/"
  s.licenses = ["GPL-2.0", "LGPL-3.0+"]
  s.rubygems_version = "2.4.5.1"
  s.summary = "POSIX Message Queues for Ruby"

  s.installed_by_version = "2.4.5.1" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 4

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_development_dependency(%q<olddoc>, ["~> 1.0"])
    else
      s.add_dependency(%q<olddoc>, ["~> 1.0"])
    end
  else
    s.add_dependency(%q<olddoc>, ["~> 1.0"])
  end
end
