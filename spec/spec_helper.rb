require 'rubygems'
require 'rspec'
require File.expand_path(File.dirname(__FILE__) + '/../lib/icu_tournament')

RSpec.configure do |c|
  c.filter_run :focus => true
  c.run_all_when_everything_filtered = true
end
