# -*- encoding: utf-8 -*-
# stub: di-ruby-lvm 0.1.3 ruby lib

Gem::Specification.new do |s|
  s.name = "di-ruby-lvm"
  s.version = "0.1.3"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib"]
  s.authors = ["Greg Symons", "Matthew Kent"]
  s.date = "2012-06-05"
  s.description = "This is a fork of the ruby-lvm gem found at git://rubyforge.org/ruby-lvm.git.\nThe primary difference from upstream is that it depends on\ndi-ruby-lvm-attributes instead of ruby-lvm-attributes. This adds support for lvm\nversion 2.02.66(2).\n\n\nThis is a wrapper for the LVM2 administration utility, lvm. Its primary\nfunction it to convert physical volumes, logical volumes and volume groups\ninto easy to use ruby objects. It also provides a simple wrapper for typical\ncreate/delete/etc operations.\n\nDue to a lack of LVM2 api this is a best effort attempt at ruby integration but\nsubject to complete replacement in the future."
  s.email = ["gsymons@drillinginfo.com", "mkent@magoazul.com"]
  s.extra_rdoc_files = ["History.txt", "Manifest.txt", "README.txt", "Todo.txt"]
  s.files = ["History.txt", "Manifest.txt", "README.txt", "Todo.txt"]
  s.homepage = "http://ruby-lvm.rubyforge.org"
  s.rdoc_options = ["--main", "README.txt"]
  s.rubyforge_project = "di-ruby-lvm"
  s.rubygems_version = "2.4.5"
  s.summary = "This is a fork of the ruby-lvm gem found at git://rubyforge.org/ruby-lvm.git"

  s.installed_by_version = "2.4.5" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<open4>, [">= 0.9.6"])
      s.add_runtime_dependency(%q<di-ruby-lvm-attrib>, ["~> 0.0.3"])
      s.add_development_dependency(%q<rdoc>, ["~> 3.10"])
      s.add_development_dependency(%q<hoe>, ["~> 3.0"])
    else
      s.add_dependency(%q<open4>, [">= 0.9.6"])
      s.add_dependency(%q<di-ruby-lvm-attrib>, ["~> 0.0.3"])
      s.add_dependency(%q<rdoc>, ["~> 3.10"])
      s.add_dependency(%q<hoe>, ["~> 3.0"])
    end
  else
    s.add_dependency(%q<open4>, [">= 0.9.6"])
    s.add_dependency(%q<di-ruby-lvm-attrib>, ["~> 0.0.3"])
    s.add_dependency(%q<rdoc>, ["~> 3.10"])
    s.add_dependency(%q<hoe>, ["~> 3.0"])
  end
end
