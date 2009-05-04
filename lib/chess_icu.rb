# :enddoc:

chess_icu_files = Array.new
chess_icu_files.concat %w{util name federation}
chess_icu_files.concat %w{player result tournament}
chess_icu_files.concat %w{fcsv krause}.map{ |f| "tournament_#{f}"}

dir = File.dirname(__FILE__)
chess_icu_files.each { |file| require "#{dir}/#{file}" }
