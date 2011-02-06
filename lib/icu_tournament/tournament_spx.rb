module ICU
  class Tournament
    #
    # TODO
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

        # Adjust the round parts of the formats for players results.
        (1..t.last_round).each { |r| formats[r+3] = "%#{m1+2}s" }

        # Now add a line for each player.
        t.players.each { |p| sp << p.to_sp_text(rounds, "#{formats.join(%Q{\t})}\r\n") }

        # And return the whole lot.
        sp
      end

      # Additional tournament validation rules for this specific type.
      def validate!(t)
        # None.
      end

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
          when 'Rtg'     then :int_rating
          when 'Loc'     then :loc_rating
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
        [:fed, :title, :id, :fide].each do |key|
          if @header[key]
            val = items[@header[key]]
            opt[key] = val unless val.nil? || val == ''
          end
        end
        
        # Rating (prefer international over local).
        [:int_rating, :loc_rating].each do |key|
          if @header[key]
            val = items[@header[key]]
            opt[:rating] = val unless opt[:rating] || val.nil? || val == ''
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
