module ICU
  class Tournament
    #
    # This is a format ({specification}[http://www.icu.ie/articles/display.php?id=172]) used by the ICU[http://icu.ie]
    # for players to submit their individual results in foreign tournaments for domestic rating.
    #
    # Suppose, for example, that the following data is the file <em>tournament.csv</em>:
    #
    #   Event,"Isle of Man Masters, 2007"
    #   Start,2007-09-22
    #   Rounds,9
    #   Website,http://www.bcmchess.co.uk/monarch2007/
    #
    #   Player,456,Fox,Anthony
    #   1,0,B,Taylor,Peter P.,2209,,ENG
    #   2,=,W,Nadav,Egozi,2205,,ISR
    #   3,=,B,Cafolla,Peter,2048,,IRL
    #   4,1,W,Spanton,Tim R.,1982,,ENG
    #   5,1,B,Grant,Alan,2223,,SCO
    #   6,0,-
    #   7,=,W,Walton,Alan J.,2223,,ENG
    #   8,0,B,Bannink,Bernard,2271,FM,NED
    #   9,=,W,Phillips,Roy,2271,,MAU
    #   Total,4
    #
    # This file can be parsed as follows.
    #
    #   parser = ICU::Tournament::ForeignCSV.new
    #   tournament = parser.parse_file('tournament.csv')
    #
    # If the file is correctly specified, the return value from the <em>parse_file</em> method is an instance of
    # ICU::Tournament (rather than <em>nil</em>, which indicates an error). In this example the file is valid, so:
    #
    #   tournament.name                                     # => "Isle of Man Masters, 2007"
    #   tournament.start                                    # => "2007-09-22"
    #   tournament.rounds                                   # => 9
    #   tournament.website                                  # => "http://www.bcmchess.co.uk/monarch2007/"
    #
    # The main player (the ICU player whose results are being reported for rating) played 9 rounds
    # but only 8 other players (he had a bye in round 6), so the total number of players is 9.
    #
    #   tournament.players.size                             # => 9
    #
    # Each player has a unique number for the tournament, starting at 1 for the first ICU player.
    #
    #   player = tournament.player(1)
    #   player.name                                         # => "Fox, Anthony"
    #
    # In the example, this player has 4 points from 9 rounds but only 8 of his results are are rateable (because of the bye).
    #
    #   player.points                                       # => 4.0
    #   player.results.size                                 # => 9
    #   player.results.find_all{ |r| r.rateable }.size      # => 8
    #
    # The other players all have numbers greater than 1.
    #
    #   opponents = tournamnet.players.reject { |o| o.num == 1 }
    #
    # There are 8 opponents (of the main player) each with exactly one game.
    #
    #   opponents.size                                      # => 8
    #   opponents.find_all{ |o| o.results.size == 1 }.size  # => 8
    #
    # If the file contains errors, then the return value from <em>parse_file</em> is <em>nil</em> and
    # an error message is returned by the <em>error</em> method of the parser object. The method
    # <em>parse_file!</em> is similar except that it raises errors, and the methods <em>parse</em>
    # and <em>parse!</em> are similar except their inputs are strings rather than file names.
    #
    # A tournament can be serialized back to CSV format (the reverse of parsing) with the _serialize_ method
    # of the parser object.
    #
    #   csv = parser.serialize(tournament)
    #
    # Or equivalently, the _serialize_ instance method of the tournament, if the appropriate parser name is supplied.
    #
    #   csv = tournament.serialize('ForeignCSV')
    #
    # Extra condtions, over and above the normal validation rules, apply before any tournament validates or can be serialized in this format.
    #
    # * the tournament must have a _site_ attribute
    # * there must be at least one player with an _id_ (ICU ID number)
    # * all foreign players (those without an ICU ID) must have a _fed_ attribute (federation)
    # * all ICU players must have a result in every round (even if it is just bye or is unrateable)
    # * all the opponents of each ICU player must have a federation (this could include other ICU players with federation _IRL_)
    # * at least one of each ICU player's opponents must have a rating
    #
    # If any of these are not satisfied, then the following method calls will all raise an exception:
    #
    #   tournament.validate!(:type => 'ForeignCSV')
    #   tournament.serialize('ForeignCSV')
    #   ICU::Tournament::ForeignCSV.new.serialize(tournament)
    #
    # You can also build the tournament object from scratch using your own data and then serialize it.
    # For example, here are the commands to reproduce the example above. Note that in this format
    # opponents' ratings are FIDE.
    #
    #   t = ICU::Tournament.new("Isle of Man Masters, 2007", '2007-09-22', :rounds => 9)
    #   t.site = 'http://www.bcmchess.co.uk/monarch2007/'
    #   t.add_player(ICU::Player.new('Anthony',  'Fox',      1, :fide_rating => 2100, :fed => 'IRL', :id => 456))
    #   t.add_player(ICU::Player.new('Peter P.', 'Taylor',   2, :fide_rating => 2209, :fed => 'ENG'))
    #   t.add_player(ICU::Player.new('Egozi',    'Nadav',    3, :fide_rating => 2205, :fed => 'ISR'))
    #   t.add_player(ICU::Player.new('Peter',    'Cafolla',  4, :fide_rating => 2048, :fed => 'IRL'))
    #   t.add_player(ICU::Player.new('Tim R.',   'Spanton',  5, :fide_rating => 1982, :fed => 'ENG'))
    #   t.add_player(ICU::Player.new('Alan',     'Grant',    6, :fide_rating => 2223, :fed => 'SCO'))
    #   t.add_player(ICU::Player.new('Alan J.',  'Walton',   7, :fide_rating => 2223, :fed => 'ENG'))
    #   t.add_player(ICU::Player.new('Bernard',  'Bannink',  8, :fide_rating => 2271, :fed => 'NED', :title => 'FM'))
    #   t.add_player(ICU::Player.new('Roy',      'Phillips', 9, :fide_rating => 2271, :fed => 'MAU'))
    #   t.add_result(ICU::Result.new(1, 1, 'L', :opponent => 2, :colour => 'B'))
    #   t.add_result(ICU::Result.new(2, 1, 'D', :opponent => 3, :colour => 'W'))
    #   t.add_result(ICU::Result.new(3, 1, 'D', :opponent => 4, :colour => 'B'))
    #   t.add_result(ICU::Result.new(4, 1, 'W', :opponent => 5, :colour => 'W'))
    #   t.add_result(ICU::Result.new(5, 1, 'W', :opponent => 6, :colour => 'B'))
    #   t.add_result(ICU::Result.new(6, 1, 'L'))
    #   t.add_result(ICU::Result.new(7, 1, 'D', :opponent => 7, :colour => 'W'))
    #   t.add_result(ICU::Result.new(8, 1, 'L', :opponent => 8, :colour => 'B'))
    #   t.add_result(ICU::Result.new(9, 1, 'D', :opponent => 9, :colour => 'W'))
    #   puts t.serialize('ForeignCSV')
    #
    class ForeignCSV
      attr_reader :error

      # Parse CSV data returning a Tournament on success or raising an exception on error.
      def parse!(csv, arg={})
        @state, @line, @round, @sum, @error = 0, 0, nil, nil, nil
        @tournament = Tournament.new('Dummy', '2000-01-01')
        csv = ICU::Util.to_utf8(csv) unless arg[:is_utf8]

        CSV.parse(csv, :row_sep => :auto) do |r|
          @line += 1                            # increment line number
          next if r.size == 0                   # skip empty lines
          r = r.map{|c| c.nil? ? '' : c.strip}  # trim all spaces, turn nils to blanks
          next if r[0] == ''                    # skip blanks in column 1
          @r = r                                # remember this record for later

          begin
            case @state
              when 0 then event
              when 1 then start
              when 2 then rounds
              when 3 then website
              when 4 then player
              when 5 then result
              when 6 then total
              else raise "internal error - state #{@state} does not exist"
            end
          rescue => err
            raise err.class, "line #{@line}: #{err.message}", err.backtrace unless err.message.match(/^line [1-9]/)
            raise
          end
        end

        unless @state == 4
          exp = case @state
                when 0 then "the event name"
                when 1 then "the start date"
                when 2 then "the number of rounds"
                when 3 then "the website address"
                when 5 then "a result for round #{@round+1}"
                when 6 then "a total score"
                end
          raise "line #{@line}: premature termination - expected #{exp}"
        end
        raise "line #{@line}: no players found in file" if @tournament.players.size == 0

        @tournament.validate!

        @tournament
      end

      # Parse CSV data returning a Tournament on success or a nil on failure.
      # In the case of failure, an error message can be retrived via the <em>error</em> method.
      def parse(csv)
        begin
          parse!(csv)
        rescue => ex
          @error = ex.message
          nil
        end
      end

      # Same as <em>parse!</em> except the input is a file name rather than file contents.
      def parse_file!(file)
        csv = ICU::Util.read_utf8(file)
        parse!(csv, :is_utf8 => true)
      end

      # Same as <em>parse</em> except the input is a file name rather than file contents.
      def parse_file(file)
        begin
          parse_file!(file)
        rescue => ex
          @error = ex.message
          nil
        end
      end

      # Serialise a tournament back into CSV format.
      def serialize(t, arg={})
        t.validate!(:type => self)
        CSV.generate do |csv|
          csv << ["Event", t.name]
          csv << ["Start", t.start]
          csv << ["Rounds", t.rounds]
          csv << ["Website", t.site]
          t.players.each do |p|
            next unless p.id
            csv << []
            csv << ["Player", p.id, p.last_name, p.first_name]
            (1..t.rounds).each do |n|
              data = []
              data << n
              r = p.find_result(n)
              data << case r.score; when 'W' then '1'; when 'L' then '0'; else '='; end
              if r.opponent
                data << r.colour
                o = t.player(r.opponent)
                data << o.last_name
                data << o.first_name
                data << o.fide_rating
                data << o.title
                data << o.fed
              else
                data << '-'
              end
              csv << data
            end
            csv << ["Total", p.points]
          end
        end
      end

      # Additional tournament validation rules for this specific type.
      def validate!(t)
        raise "missing site" unless t.site.to_s.length > 0
        icu = t.players.find_all { |p| p.id }
        raise "there must be at least one ICU player (with an ID number)" if icu.size == 0
        foreign = t.players.find_all { |p| !p.id }
        raise "all foreign players must have a federation" if foreign.detect { |f| !f.fed }
        icu.each do |p|
          rated = 0
          (1..t.rounds).each do |r|
            result = p.find_result(r)
            raise "ICU players must have a result in every round" unless result
            raise "all opponents of ICU players must have a federation" if result.opponent && !t.player(result.opponent).fed
            rated += 1 if result.opponent && t.player(result.opponent).fide_rating
          end
          raise "player #{p.num} (#{p.name}) has no rated opponents" if rated == 0
        end
      end

      # :enddoc:
      private

      def event
        abort "the 'Event' keyword", 0 unless @r[0].match(/^(Event|Tournament)$/i)
        abort "the event name",      1 unless @r.size > 1 && @r[1] != ''
        @tournament.name = @r[1]
        @state = 1
      end

      def start
        abort "the 'Start' keyword", 0 unless @r[0].match(/^(Start(\s+Date)?|Date)$/i)
        abort "the start date",      1 unless @r.size > 1 && @r[1] != ''
        @tournament.start = @r[1]
        @state = 2
      end

      def rounds
        abort "the 'Rounds' keyword", 0 unless @r[0].match(/(Number of )?Rounds$/)
        abort "the number of rounds", 1 unless @r.size > 1 && @r[1].match(/^[1-9]\d*/)
        @tournament.rounds = @r[1]
        @state = 3
      end

      def website
        abort "the 'Website' keyword", 0 unless @r[0].match(/^(Web(\s?site)?|Site)$/i)
        abort "the event website",     1 unless @r.size > 1 && @r[1] != ''
        @tournament.site = @r[1]
        @state = 4
      end

      def player
        abort "the 'Player' keyword",  0 unless @r[0].match(/^Player$/i)
        abort "a player's ICU number", 1 unless @r.size > 1 && @r[1].match(/^[1-9]/i)
        abort "a player's last name",  2 unless @r.size > 2 && @r[2].match(/[a-z]/i)
        abort "a player's first name", 3 unless @r.size > 3 && @r[3].match(/[a-z]/i)
        @player = Player.new(@r[3], @r[2], @tournament.players.size + 1, :id => @r[1])
        old_player = @tournament.find_player(@player)
        if old_player
          raise "two players with the same name (#{@player.name}) have conflicting details" unless old_player.eql?(@player)
          raise "same player (#{@player.name}) has more than one set of results" if old_player.id
          old_player.merge(@player)
          @player = old_player
        else
          @tournament.add_player(@player)
        end
        @round = 0
        @state = 5
      end

      def result
        @round+= 1
        abort "round number #{round}",              0 unless @r[0].to_i == @round
        abort "a colour (W/B) or dash (for a bye)", 2 unless @r.size > 2 && @r[2].match(/^(W|B|-)/i)
        result = Result.new(@round, @player.num, @r[1])
        if @r[2] == '-'
          @tournament.add_result(result)
        else
          result.colour = @r[2]
          opponent = Player.new(@r[4], @r[3], @tournament.players.size + 1, :fide_rating => @r[5], :title => @r[6], :fed => @r[7])
          raise "opponent must have a federation" unless opponent.fed
          old_player = @tournament.find_player(opponent)
          if old_player
            raise "two players with the same name (#{opponent.name}) have conflicting details" unless old_player.eql?(opponent)
            result.opponent = old_player.num
            if old_player.id
              old_player.merge(opponent)
              old_result = @player.find_result(@round)
              raise "missing result for player (#{@player.name}) in round #{@round}" unless old_result
              raise "mismatched results for player (#{old_player.name}): #{result.inspect} #{old_result.inspect}" unless result.eql?(old_result)
            else
              old_result = old_player.find_result(@round)
              raise "a player (#{old_player.name}) has more than one game in the same round (#{@round})" if old_result
              @tournament.add_result(result)
            end
          else
            @tournament.add_player(opponent)
            result.opponent = opponent.num
            @tournament.add_result(result)
          end
        end
        @state = 6 if @round == @tournament.rounds
      end

      def total
        points = @player.points
        abort "the 'Total' keyword", 0 unless @r[0].match(/^Total$/i)
        abort "the player's (#{@player.object_id}, #{@player.results.size}) total points to be #{points}", 1 unless @r[1].to_f == points
        @state = 4
      end

      def abort(expected, cell)
        got = @r[cell]
        error = "line #{@line}"
        error << ", cell #{cell+1}"
        error << ": expected #{expected}"
        error << " but got #{got == '' ? 'a blank cell' : "'#{got}'"}"
        raise error
      end
    end
  end
end
