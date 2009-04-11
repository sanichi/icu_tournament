dir = File.dirname(__FILE__)
%w{util name player result tournament}.each { |file| require "#{dir}/#{file}" }
%w{fcsv}.each                               { |file| require "#{dir}/tournament_#{file}" }
