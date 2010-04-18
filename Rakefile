require 'rubygems'
require 'rake'
require 'rake/rdoctask'
require 'spec/rake/spectask'
require 'lib/icu_tournament/version'

task :default => :spec

desc "Build a new gem"
task :build do
  system "gem build icu_tournament.gemspec"
end

desc "Release the latest gem to rubygems.org then back it up"
task :release do
  name = "icu_tournament-#{ICU::Tournament::VERSION}.gem"
  system "gem push #{name}"
  system "mv {,pkg/}#{name}"
end

desc "Push the master branch to github"
task :push do
  system "git push origin master"
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
  rdoc.title    = "ICU Tournament #{ICU::Tournament::VERSION}"
  rdoc.rdoc_dir = 'rdoc'
  rdoc.options  = ["--charset=utf-8"]
  rdoc.rdoc_files.include('lib/**/*.rb', 'README.rdoc', 'LICENCE')
end
