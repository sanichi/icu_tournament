# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib/', __FILE__)
$:.unshift lib unless $:.include?(lib)
require 'icu_tournament/version'

Gem::Specification.new do |s|
  s.name = %q{icu_tournament}

  s.authors = ["Mark Orr"]
  s.email = %q{mark.j.l.orr@googlemail.com}
  s.description = %q{Convert files of chess tournament data in different formats to ruby classes and vice-versa.}
  s.homepage = %q{http://github.com/sanichi/icu_tournament}
  s.summary = %q{For reading and writing files of chess tournament data.}
  s.version = ICU::Tournament::VERSION
  s.rubyforge_project = "icu_tournament"

  s.extra_rdoc_files = %w(LICENCE README.rdoc)
  s.files = Dir.glob("lib/**/*.rb") + Dir.glob("spec/*.rb") + %w(LICENCE README.rdoc)
  s.rdoc_options = ["--charset=utf-8"]
  s.require_paths = ["lib"]
  s.test_files = Dir.glob("spec/*.rb")

  s.add_runtime_dependency("dbf", "~> 1.2.5")        # for SwissPerfect trn/sco files
  s.add_runtime_dependency("rubyzip", "~> 0.9.4")    # for zipped-up SwissPerfect files
  s.add_runtime_dependency("icu_name", ">=0.1.4")    # for name canonicalisation

  s.add_development_dependency("rspec", "~> 2.5")
  s.add_development_dependency("ZenTest", "~> 4.4.2")
  s.add_development_dependency("autotest-growl", "~> 0.2.9")
  s.add_development_dependency("autotest-fsevent", "~> 0.2.4")
end
