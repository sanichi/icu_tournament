require 'rubygems'
require 'rake'
require 'rake/rdoctask'
require 'spec/rake/spectask'

begin
  require 'jeweler'
  Jeweler::Tasks.new do |gem|
    gem.name             = "icu_tournament"
    gem.summary          = "For reading and writing files of chess tournament data."
    gem.description      = "Convert files of chess tournament data in different formats to ruby classes and vice-versa."
    gem.homepage         = "http://github.com/sanichi/icu_tournament"
    gem.authors          = ["Mark Orr"]
    gem.email            = "mark.j.l.orr@googlemail.com"
    gem.files            = FileList['{lib,spec}/**/*', 'README.rdoc', 'LICENCE', 'VERSION.yml']
    gem.has_rdoc         = true
    gem.extra_rdoc_files = ['README.rdoc', 'LICENCE'],
    gem.rdoc_options     = "--charset=utf-8"
    gem.add_dependency('fastercsv', '>= 1.4.0')
  end
  Jeweler::GemcutterTasks.new
rescue LoadError
  puts "Jeweler not available. Install it with: sudo gem install jeweler."
end

task :default => :spec

Spec::Rake::SpecTask.new(:spec) do |spec|
  spec.libs << 'lib' << 'spec'
  spec.spec_files = FileList['spec/**/*_spec.rb']
  spec.spec_opts = ['--colour --format nested --loadby mtime --reverse']
end

Spec::Rake::SpecTask.new(:fcsv) do |spec|
  spec.libs << 'lib' << 'spec'
  spec.spec_files = FileList['spec/tournament_fcsv_spec.rb']
  spec.spec_opts = ['--colour --format nested']
end

Spec::Rake::SpecTask.new(:krs) do |spec|
  spec.libs << 'lib' << 'spec'
  spec.spec_files = FileList['spec/tournament_krause_spec.rb']
  spec.spec_opts = ['--colour --format nested']
end

Rake::RDocTask.new(:rdoc) do |rdoc|
  if File.exist?('VERSION.yml')
    config  = YAML.load(File.read('VERSION.yml'))
    version = "#{config[:major]}.#{config[:minor]}.#{config[:patch]}"
  else
    version = ""
  end

  rdoc.title    = "ChessIcu #{version}"
  rdoc.rdoc_dir = 'rdoc'
  rdoc.options  = ["--charset=utf-8"]
  rdoc.rdoc_files.include('lib/**/*.rb', 'README.rdoc', 'LICENCE')
end
