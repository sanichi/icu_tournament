require 'rake'
require 'rake/rdoctask'
require 'rspec/core/rake_task'
require File.expand_path(File.dirname(__FILE__) + '/lib/icu_tournament/version')

version = ICU::Tournament::VERSION

task :default => :spec

desc "Build a new gem for version #{version}"
task :build do
  system "gem build icu_tournament.gemspec"
  system "mv {,pkg/}icu_tournament-#{version}.gem"
end

desc "Release version #{version} of the gem to rubygems.org"
task :release => :build do
  system "gem push pkg/icu_tournament-#{version}.gem"
end

desc "Create a tag for version #{version}"
task :tag do
  system "git tag v#{version} -m 'Tagging version #{version}'"
end

desc "Push the master branch to github"
task :push do
  system "git push origin master"
end

RSpec::Core::RakeTask.new do |t|
  t.rspec_opts = ['--colour --format nested']
end

RSpec::Core::RakeTask.new(:fcsv) do |t|
  t.pattern    = 'spec/tournament_fcsv_spec.rb'
  t.rspec_opts = ['--colour --format nested']
end

RSpec::Core::RakeTask.new(:krs) do |t|
  t.pattern = 'spec/tournament_krause_spec.rb'
  t.rspec_opts = ['--colour --format nested']
end

RSpec::Core::RakeTask.new(:sp) do |t|
  t.pattern = 'spec/tournament_sp_spec.rb'
  t.rspec_opts = ['--colour --format nested']
end

Rake::RDocTask.new(:rdoc) do |t|
  t.title    = "ICU Tournament #{version}"
  t.rdoc_dir = 'rdoc'
  t.options  = ["--charset=utf-8"]
  t.rdoc_files.include('lib/**/*.rb', 'README.rdoc', 'LICENCE')
end
