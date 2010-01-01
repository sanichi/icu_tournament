# :enddoc:

icu_tournament_files = Array.new
icu_tournament_files.concat %w{util name federation}
icu_tournament_files.concat %w{player result team tournament}
icu_tournament_files.concat %w{fcsv krause}.map{ |f| "tournament_#{f}"}

icu_tournament_files.each { |file| require "icu_tournament/#{file}" }
