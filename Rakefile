require 'rubygems'
require 'rake'
require 'rake/rdoctask'
require 'spec/rake/spectask'

begin
  require 'jeweler'
  Jeweler::Tasks.new do |gem|
    gem.name         = "chess_icu"
    gem.summary      = "For parsing files of chess tournament data into ruby classes."
    gem.homepage     = "http://github.com/sanichi/chess_icu"
    gem.authors      = ["Mark Orr"]
    gem.email        = "mark.j.l.orr@googlemail.com"
    gem.files        = FileList['[A-Z]*', '{lib,spec}/**/*', '.gitignore']
    gem.has_rdoc     = true
    gem.rdoc_options = "--charset=UTF-8"
    gem.add_dependency('fastercsv', '>= 1.4.0')
  end
rescue LoadError
  puts "Jeweler not available. Install it with: sudo gem install technicalpickles-jeweler -s http://gems.github.com"
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
    config = YAML.load(File.read('VERSION.yml'))
    version = "#{config[:major]}.#{config[:minor]}.#{config[:patch]}"
  else
    version = ""
  end

  rdoc.rdoc_dir = 'rdoc'
  rdoc.title = "ChessIcu #{version}"
  rdoc.rdoc_files.include('README*')
  rdoc.rdoc_files.include('lib/**/*.rb')
end
