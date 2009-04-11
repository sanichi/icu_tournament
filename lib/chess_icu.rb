dir = File.dirname(__FILE__)
%w{util name player result tournament tournament_fcsv}.each do |file|
  require "#{dir}/#{file}"
end
