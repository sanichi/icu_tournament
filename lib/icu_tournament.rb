# :enddoc:

require 'icu_name'
require 'icu_utils'

icu_tournament_files = Array.new
icu_tournament_files.concat %w{util tie_break}
icu_tournament_files.concat %w{player result team tournament}
icu_tournament_files.concat %w{fcsv krause sp spx}.map{ |f| "tournament_#{f}"}

icu_tournament_files.each { |file| require "icu_tournament/#{file}" }
