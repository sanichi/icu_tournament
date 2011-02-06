module ICU
  class Tournament
    #
    # The SWissPerfect export format was important in Irish chess as it was used to submit
    # results to the ICU's first computerised ratings system based on <em>MicroSoft Access</em>.
    # As a text based format, it was easier to manipulate than the binary formats of SwissPerfect.
    # Here's an example:
    #
    #   No Name           Feder Intl Id Loc Id Rtg  Loc  Title Total  1   2   3
    #
    #   1  Duck, Daffy    IRL           12345       2200 im    2     0:= 3:W 2:D
    #   2  Mouse, Minerva       1234568        1900            1.5   3:D 0:= 1:D
    #   3  Mouse, Mickey  USA   1234567                  gm    1     2:D 1:L 0:=
    #
    # The format does not record either the name nor the start date of the tournament (and also
    # player colours are missing). When parsing data in this format it is therefore necessary
    # to specify name and start date explicitly:
    #
    #   parser = ICU::Tournament::SPExport.new
    #   tournament = parser.parse_file('tournament.txt', :name => 'Mickey Mouse Masters', :start => '2011-02-06')
    #
    #   tournament.name                   # => "Mickey Mouse Masters"
    #   tournament.start                  # => "2011-02-06"
    #   tournament.rounds                 # => 3
    #   tournament.player(1).name         # => "Duck, Daffy"
    #   tournament.player(2).points       # => 1.5
    #   tournament.player(3).fed          # => "USA"
    #
    # And so on. See ICU::Tournament for further details.
    #
    # The SwissPerfect application offers a number of choices when exporting a tournament cross table,
    # one of which is the column separator. The ICU::Tournament::SPExport parser can only handle data
    # with tab separators but is able to cope with any other configuration choices. For example, if
    # some of the optional columns are missing or if the data is not formatted with space padding.
    #
    # To serialize a tournament to the format, use the format name with the _serialize_ method of
    # the appropriate parser:
    #
    #   parser = ICU::Tournament::Krause.new
    #   spexport = parser.serialize(tournament)
    #
    # or use the _serialize_ method of the ICU::Tournament instance with the appropraie format name:
    #
    #   spexport = tournament.serialize('SPExport')
    #
    # In either case the method returns a string representation of the tourament in SwissPerfect export
    # format with tab separators, space padding and (currently) only the local player ID and total score
    # optional columns:
    #
    #   No  Name                 Loc Id  Total   1     2     3
    #
    #   1   Griffiths, Ryan-Rhys 6897    3       4:W   2:W   3:W
    #   2   Flynn, Jamie         5226    2       3:W   1:L   4:W
    #   3   Hulleman, Leon       6409    1       2:L   4:W   1:L
    #   4   Dunne, Thomas        10914   0       1:L   3:L   2:L
    #
    # The order of players in the serialized output is always by player number and as a side effect of serialization,
    # the player numbers will be adjusted to ensure they range from 1 to the total number of players maintaining the
    # original order. If you would prefer rank-order instead, then you must first renumber the players by rank (the
    # default renumbering method) before serializing. For example:
    #
    #   spexport = tournament.renumber(:rank).serialize('SPExport')
    #
    # Or equivalently, since renumbering by rank is the default, just:
    #
    #   spexport = tournament.renumber.serialize('SPExport')
    #
    # You may wish set the tie-break rules before ranking:
    #
    #   tournament.tie_breaks = [:buchholz, ::neustadtl]
    #   spexport = tournament.rerank.renumber.serialize('SwissPerfect')
    #
    # See ICU::Tournament for more about tie-breaks.
    #
    class SPExport
      attr_reader :error

      # Parse SwissPerfect export data returning a Tournament on success or raising an exception on error.
      def parse!(spx, arg={})
        @tournament = init_tournament(arg)
        @lineno = 0
        @header = nil
        @results = Array.new
        spx = ICU::Util.to_utf8(spx) unless arg[:is_utf8]

        # Process each line.
        spx.each_line do |line|
          @lineno += 1
          line.strip!          # remove leading and trailing white space
          next if line == ''   # skip blank lines

          if @header
            process_player(line)
          else
            process_header(line)
          end
        end

        # Now that all players are present, add the results to the tournament.
        @results.each do |r|
          lineno, player, data, result = r
          begin
            @tournament.add_result(result)
          rescue => err
            raise "line #{lineno}, player #{player}, result '#{data}': #{err.message}"
          end
        end

        # Finally, exercise the tournament object's internal validation, reranking if neccessary.
        @tournament.validate!(:rerank => true)

        @tournament
      end

      # Parse SwissPerfect export text returning a Tournament on success or a nil on failure.
      # In the case of failure, an error message can be retrived via the <em>error</em> method.
      def parse(spx, arg={})
        begin
          parse!(spx, arg)
        rescue => ex
          @error = ex.message
          nil
        end
      end

      # Same as <em>parse!</em> except the input is a file name rather than file contents.
      def parse_file!(file, arg={})
        spx = ICU::Util.read_utf8(file)
        arg[:is_utf8] = true
        parse!(spx, arg)
      end

      # Same as <em>parse</em> except the input is a file name rather than file contents.
      def parse_file(file, arg={})
        begin
          parse_file!(file, arg)
        rescue => ex
          @error = ex.message
          nil
        end
      end

      # Serialise a tournament to SwissPerfect text export format.
      def serialize(t, arg={})
        t.validate!(:type => self)

        # Ensure a nice set of numbers.
        t.renumber(:order)

        # Widths for the rank, name and ID and the number of rounds.
        m1 = t.players.inject(2) { |l, p| p.num.to_s.length  > l ? p.num.to_s.length  : l }
        m2 = t.players.inject(4) { |l, p| p.name.length      > l ? p.name.length      : l }
        m3 = t.players.inject(6) { |l, p| p.id.to_s.length   > l ? p.id.to_s.length   : l }
        rounds = t.last_round

        # The header, followed by a blank line.
        formats = ["%-#{m1}s", "%-#{m2}s", "%-#{m3}s", "%-5s"]
        (1..rounds).each { |r| formats << "%#{m1}d  " % r }
        sp = formats.join("\t") % ['No', 'Name', 'Loc Id', 'Total']
        sp << "\r\n\r\n"

        # Adjust the rounds part of the formats for players results.
        (1..rounds).each { |r| formats[r+3] = "%#{m1+2}s" }

        # Now add a line for each player.
        t.players.each { |p| sp << p.to_sp_text(rounds, "#{formats.join(%Q{\t})}\r\n") }

        # And return the whole lot.
        sp
      end

      # Additional tournament validation rules for this specific type.
      def validate!(t)
        # None.
      end

      # :enddoc:
      private

      def init_tournament(arg)
        raise "tournament name missing"       unless arg[:name]
        raise "tournament start date missing" unless arg[:start]
        Tournament.new(arg[:name], arg[:start])
      end

      def process_header(line)
        raise "header should always start with 'No'" unless line.match(/^No\s/)
        items = line.split(/\t/).map(&:strip)
        raise "header requires tab separators" unless items.size > 2
        @header = Hash.new
        @rounds = 1
        items.each_with_index do |item, i|
          key = case item
          when 'No'      then :num
          when 'Name'    then :name
          when 'Total'   then :total
          when 'Loc Id'  then :id
          when 'Intl Id' then :fide
          when 'Title'   then :title
          when 'Feder'   then :fed
          when 'Loc'     then :rating
          when 'Rtg'     then :fide_rating
          when /^[1-9]\d*$/
            round   = item.to_i
            @rounds = round if round > @rounds
            round
          else nil
          end
          @header[key] = i if key
        end
        raise "header is missing 'No'"    unless @header[:num]
        raise "header is missing 'Name'"  unless @header[:name]
        (1..@rounds).each { |r| raise "header is missing round #{r}" unless @header[r] }
      end

      def process_player(line)
        items = line.split(/\t/).map(&:strip)
        raise "line #{@lineno} has too few items" unless items.size > 2

        # Player details.
        num  = items[@header[:num]]
        name = Name.new(items[@header[:name]])
        opt  = Hash.new
        [:fed, :title, :id, :fide, :rating, :fide_rating].each do |key|
          if @header[key]
            val = items[@header[key]]
            opt[key] = val unless val.nil? || val == ''
          end
        end

        # Create the player and add it to the tournament.
        player = Player.new(name.first, name.last, num, opt)
        @tournament.add_player(player)

        # Save the results for later processing.
        points = items[@header[:total]] if @header[:total]
        points = nil if points == ''
        points = points.to_f if points
        total = 0.0;
        (1..@rounds).each do |r|
          total+= process_result(r, player.num, items[@header[r]])
        end
        total = points if points && fix_invisible_bonuses(player.num, points - total)
        raise "declared points total (#{points}) does not agree with total from summed results (#{total})" if points && points != total
      end

      def process_result(round, player_num, data)
        raise "illegal result (#{data})" unless data.match(/^(0|[1-9]\d*)?:([-+=LWD])?$/i)
        opponent = $1.to_i
        score = $2 || 'L'
        options = Hash.new
        options[:opponent] = opponent unless opponent == 0
        options[:rateable] = false    unless score && score.match(/^(W|L|D)$/i)
        result = Result.new(round, player_num, score, options)
        @results << [@lineno, player_num, data, result]
        result.points
      end

      def fix_invisible_bonuses(player_num, difference)
        # We don't need to fix it if it's not broken.
        return false if difference == 0.0
        # We can't fix a summed total that is greater than the declared total.
        return false if difference < 0.0
        # Get the player's results objects from the temporary store.
        results = @results.select{ |r| r[1] == player_num }.map{ |r| r.last }
        # Get all losses and draws that don't have opponents (because their scores can be harmlessly altered).
        losses = results.reject{ |r| r.opponent || r.score != 'L' }.sort{ |a,b| a.round <=> b.round }
        draws  = results.reject{ |r| r.opponent || r.score != 'D' }.sort{ |a,b| a.round <=> b.round }
        # Give up unless these results have enough capacity to accomodate the points difference.
        return false unless difference <= 1.0 * losses.size + 0.5 * draws.size
        # Start promoting losses to draws.
        losses.each do |loss|
          loss.score = 'D'
          difference -= 0.5
          break if difference == 0.0
        end
        # If that's not enough, start promoting draws to wins.
        if difference > 0.0
          draws.each do |draw|
            draw.score = 'W'
            difference -= 0.5
            break if difference == 0.0
          end
        end
        # And if that's not enough, start promoting losses to wins.
        if difference > 0.0
          losses.each do |loss|
            loss.score = 'W'
            difference -= 0.5
            break if difference == 0.0
          end
        end
        # Signal success.
        return true
      end
    end
  end

  class Player
    # Format a player's record as it would appear in an SP export file.
    def to_sp_text(rounds, format)
      attrs = [num.to_s, name, id.to_s, ('%.1f' % points).sub(/\.0/, '')]
      (1..rounds).each do |r|
        result = find_result(r)
        attrs << (result ? result.to_sp_text : " : ")
      end
      format % attrs
    end
  end

  class Result
    # Format a player's result as it would appear in an SP export file.
    def to_sp_text
      sp = opponent ? opponent.to_s : '0'
      sp << ':'
      if rateable
        sp << score
      else
        sp << case score
        when 'W' then '+'
        when 'L' then '-'
        else '='
        end
      end
    end
  end
end
