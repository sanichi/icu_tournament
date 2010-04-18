require 'rubygems'
require 'rake'
require 'rake/rdoctask'
require 'spec/rake/spectask'
require 'lib/icu_tournament/version'

task :default => :spec

task :build do
  system "gem build icu_tournament.gemspec"
  system "mv icu_tournament-#{ICU::Tournament::VERSION}.gem pkg"
end
 
task :release => :build do
  system "ls -l pkg/icu_tournament-#{ICU::Tournament::VERSION}.gem"
end

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
