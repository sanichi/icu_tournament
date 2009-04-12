require 'fastercsv'

module ICU
  class Tournament
    class ForeignCSV
      attr_reader :error
      
      # Parse CSV data returning a Tournament on success or a nil on failure (and a message retrievable via the error method).
      def parse(csv)
        begin
          parse!(csv)
        rescue => ex
          @error = ex.message
          nil
        end
      end
      
      # Parse CSV data returning a Tournament on success or raising an exception on error.
      def parse!(csv)
        @state, @line, @round, @sum, @error = 0, 0, nil, nil, nil
        @tournament = Tournament.new('Dummy', '2000-01-01')
        
        FasterCSV.parse(csv, :row_sep => :auto) do |r|
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
        
        @tournament
      end

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
          old_player.subsume(@player)
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
          opponent = Player.new(@r[4], @r[3], @tournament.players.size + 1, :rating => @r[5], :title => @r[6], :fed => @r[7])
          raise "opponent must have a rating and federation" unless opponent.rating && opponent.fed
          old_player = @tournament.find_player(opponent)
          if old_player
            raise "two players with the same name (#{opponent.name}) have conflicting details" unless old_player.eql?(opponent)
            result.opponent = old_player.num
            if old_player.id
              old_player.subsume(opponent)
              old_result = @player.find_result(@round)
              raise "missing result for player (#{@player.name}) in round #{@round}" unless old_result
              raise "mismatched results for player (#{old_player.name}) in round #{@round}" unless result == old_result
              old_result.rateable = true
            else
              old_result = old_player.find_result(@round)
              raise "a player (#{old_player.name}) has more than one game in the same round (#{@round})" if old_result
              @tournament.add_result(result, false)
            end
          else
            @tournament.add_player(opponent)
            result.opponent = opponent.num
            @tournament.add_result(result, false)
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
