module ICU
  class Tournament
    #
    # This is the {format}[http://www.fide.com/component/content/article/5-whats-news/2245-736-general-data-exchange-format-for-tournament-results]
    # used to submit tournament results to FIDE[http://www.fide.com] for rating.
    #
    # Suppose, for example, that the following data is the file <em>tournament.tab</em>:
    #
    #   012 Fantasy Tournament
    #   032 IRL
    #   042 2009.09.09
    #   0123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890
    #   132                                                                                        09.09.09  09.09.10  09.09.11
    #   001    1 w    Mouse,Minerva                     1900 USA     1234567 1928.05.15  1.0    2     2 b 0     3 w 1
    #   001    2 m  m Duck,Daffy                        2200 IRL     7654321 1937.04.17  2.0    1     1 w 1               3 b 1
    #   001    3 m  g Mouse,Mickey                      2600 USA     1726354 1928.05.15  0.0    3               1 b 0     2 w 0
    #
    # This file can be parsed as follows.
    #
    #   parser = ICU::Tournament::Krause.new
    #   tournament = parser.parse_file('tournament.tab')
    #
    # If the file is correctly specified, the return value from the <em>parse_file</em> method is an instance of
    # ICU::Tournament (rather than <em>nil</em>, which indicates an error). In this example the file is valid, so:
    #
    #   tournament.name                   # => "Fantasy Tournament"
    #   tournament.start                  # => "2009-09-09"
    #   tournament.fed                    # => "IRL"
    #   tournament.players.size           # => 9
    #
    # Some values, not explicitly set in the file, are deduced:
    #
    #   tournament.rounds                 # => 3
    #   tournament.finish                 # => "2009-09-11"
    #
    # A player can be retrieved from the tournament via the _players_ array or by sending a valid player number to the _player_ method.
    #
    #   minnie = tournament.player(1)
    #   minnie.name                       # => "Mouse, Minerva"
    #   minnie.points                     # => 1.0
    #   minnie.results.size               # => 2
    #
    #   daffy = tournament.player(2)
    #   daffy.title                       # => "IM"
    #   daffy.rating                      # => 2200
    #   daffy.fide_rating                 # => nil
    #   daffy.fed                         # => "IRL"
    #   daffy.id                          # => nil
    #   daffy.fide_id                     # => 7654321
    #   daffy.dob                         # => "1937-04-17"
    #
    # By default, ratings are interpreted as ICU. If, instead, they should be interpreted as
    # FIDE ratings, add the _fide_ option:
    #
    #   tournament = parser.parse_file('tournament.tab', :fide => true)
    #   daffy = tournament.player(2)
    #   daffy.rating                      # => nil
    #   daffy.fide_rating                 # => 2200
    #
    # ID numbers, on the other hand, are automatically classified as either FIDE or ICU on the basis of size.
    # IDs larger than 100000 are assumed to be FIDE IDs, while smaller numbers are treated as ICU IDs.
    #
    # If the ranking numbers are missing from the file or inconsistent (e.g. player A is ranked above player B
    # but has less points) they are recalculated as a side effect of the parse.
    #
    #   daffy.rank                        # => 1
    #   minnie.rank                       # => 2
    #   mickey.rank                       # => 3
    #
    # Comments in the input file (lines that do not start with a valid data identification number) are available from the parser
    # instance via its _comments_ method (returning a string). Note that these comments are reset evry time the instance is used
    # to parse another file.
    #
    #   parser.comments                   # => "0123456789..."
    #
    # If the file contains errors, then the return value from <em>parse_file</em> is <em>nil</em> and
    # an error message is returned by the <em>error</em> method of the parser object. The method
    # <em>parse_file!</em> is similar except that it raises errors, and the methods <em>parse</em>
    # and <em>parse!</em> are similar except their inputs are strings rather than file names.
    #
    # == Serialization
    #
    # A tournament can be serialized back to Krause format (the reverse of parsing) with the _serialize_ method of the parser.
    #
    #   krause = parser.serialize(tournament)
    #
    # Or alternatively, by the _serialize_ method of the tournament object if the name of the serializer is supplied.
    #
    #   krause = tournament.serialize('Krause')
    #
    # By default, local (ICU) IDs and ratings are used for the serialization, but both methods accept an option that
    # causes FIDE IDs and ratings to be used instead:
    #
    #   krause = parser.serialize(tournament, :fide => true)
    #   krause = tournament.serialize('Krause', :fide => true)
    #
    # By default all available information is output for each player, however, this is customizable. The player number,
    # name, total points and results are always output but any of the remaining data (_gender_, _title_, _rating_ or _fide_rating_,
    # _fed_, _id_ or _fide_id_, _dob_ and _rank_) can be omitted, if desired, by specifying an array of columns to include
    # or exclude. To omitt all the optional data, supply an empty array:
    #
    #   krause = tournament.serialize('Krause', :only => [])
    #
    # To omitt just federation and rating but include all others:
    #
    #   krause = tournament.serialize('Krause', :except => [:fed, :rating])
    #
    # To include only date of birth and title:
    #
    #   krause = tournament.serialize('Krause', :only => [:dob, :title])
    #
    # To output FIDE IDs and ratings use the _fide_ option in conjunctions with the _id_ and _rating_ options:
    #
    #   krause = tournament.serialize('Krause', :only => [:gender, :id, :rating], :fide => true)
    #
    # == Parser Strictness
    #
    # In practice, Krause formatted files encontered in the wild can be produced in a variety of different ways and not always according to
    # FIDE's standard, which itself is rather loose. This Ruby gem deals with that situation by not raising parsing errors when data is encountered
    # where it is clear what is meant, even if it doesn't conform to the standards, such as they are. However, on output (serialisation) a strict
    # interpretation of FIDE's standard is adhered to.
    #
    # For example in input data if a player's gender is given as "F" it's clear this means female, even though the specification calls for a lower
    # case "w" (for woman) in this case. Similarly, for titles where, for example, both "GM" and FIDE's "g" are recognised as meaning Grand Master.
    #
    # When it comes to dates, the specification recommends the YYYY/MM/DD format for birth dates and YY/MM/DD for round dates but quotes an example where
    # the start and finish dates are in the opposite order (DD.MM.YYYY) with a different separator. In practice, the author has encountered Krause files
    # with US style date formatting (MM-DD-YYYY) and other bizarre formats (YY.DD.MM) which suffer from ambiguity when the day is 12 or less.
    # It's not the separator ("/", "=", ".") that causes a problem but the year, month and day order. The solution adopted here is for all serialized
    # dates to be in YYYY-MM-DD format (or YY-MM-DD for round dates which must fit in 8 characters), which is a recognised international standard
    # (ISO 8601). However, for parsing, a much wider variation is permitted and there is some ability to detect and correct ambiguous dates. For example
    # the following dates would all be interpreted as 2011-03-30:
    #
    # * 30th March 2011
    # * 30.03.2011
    # * 03/30/2011
    #
    # Where no additional information is available to resolve an ambiguity, the month is assumed to come in the middle, so 04/03/2011 is interpreted
    # as 2011.03.04 and not 2011.04.03.
    #
    # Some Krause files that the author has encountered in the wild have 3-letter player federation codes that are not federations at all but something
    # completely different (for example the first 3 letters of the player's club). This is a clear violation of the specification and raises a parsing
    # exception. However in practice it's often necessary to deal with such files so the parser has two options to help in these cases. If the _fed_ option
    # is set to "ignore" then all player federation codes will be ignored, even if valid. While when set to "skip" then invalid codes will be ignored but
    # valid ones retained.
    #
    #   tournament = parser.parse_file('tournament.tab', :fed => "ignore")
    #   tournament = parser.parse_file('tournament.tab', :fed => "skip")
    #
    # Similar options are available for parsing SwissPerfect files (see ICU::Tournament::SwissPerfect) which can suffer from the same problem.
    #
    # == Automatic Total Correction
    #
    # Another problem encountered with Krause files in practice is a mismatch between the declared total points for a player and the sum of their points
    # from each round. Normally this just raises a parsing exception. However, there is one set of circumstances when such mismatches can be repaired:
    #
    # * the declared total score is higher than the sum of scores,
    # * the player has at least one bye which isn't a full point bye or at least one round where no result is recorded,
    # * the number of byes or missing results is enough to account for the difference in total score.
    #
    # If all these conditions are met then just enough bye scores are incremented, or new byes created, to make the sum match the total, and the
    # data will parse without raising an exception.
    #
    #   012 Mismatched Totals
    #   042 2011.03.04
    #   001    1      Mouse,Minerva                                                      1.0    2     2 b 0  0000 - =
    #   001    2      Mouse,Mickey                                                       1.5    1     1 w 1
    #
    # In this example both totals are underestimates. However, player 1 has a half-point bye which can be upgraded to a full-point and player 2
    # has no result in round 2 which leaves room for the creation of a new half-point bye. So this data parses without error and serializes to:
    #
    #   012 Mismatched Totals
    #   042 2011-03-04
    #   001    1      Mouse,Minerva                                                      1.0    2     2 b 0  0000 - +
    #   001    2      Mouse,Mickey                                                       1.5    1     1 w 1  0000 - =
    #
    # == Tournament Attributes
    #
    # The following lists Krause data identification numbers, their description and, where available, their corresponding
    # attributes in an ICU::Tournament instance.
    #
    # [001 Player record]           Use _players_ to get all players or _player_ with a player number to get a single instance.
    # [012 Name]                    Get or set with _name_. Free text. A tounament name is mandatory.
    # [013 Teams]                   Create an ICU::Team, add player numbers to it, use _add_team_ to add to tournament, _get_team_/_teams_ to retrive it/them.
    # [022 City]                    Get or set with _city_. Free text.
    # [032 Federation]              Get or set with _fed_. Getter returns either _nil_ or a three letter code. Setter can take various formats (see ICU::Federation).
    # [042 Start date]              Get or set with _start_. Getter returns <em>yyyy-mm-dd</em> format, but setter can use any reasonable date format. Start date is mandadory.
    # [052 End date]                Get or set with _finish_. Returns either <em>yyyy-mm-dd</em> format or _nil_ if not set. Like _start_, can be set with various date formats.
    # [062 Number of players]       Not used. Treated as comment in parsed files. Can be determined from the size of the _players_ array.
    # [072 Number of rated players] Not used. Treated as comment in parsed files. Can be determined by analysing the array returned by _players_.
    # [082 Number of teams]         Not used. Treated as comment in parsed files.
    # [092 Type of tournament]      Get or set with _type_. Free text.
    # [102 Arbiter(s)]              Get or set with -arbiter_. Free text.
    # [112 Deputy(ies)]             Get or set with _deputy_. Free text.
    # [122 Time control]            Get or set with _time_control_. Free text.
    # [132 Round dates]             Get an array of dates using _round_dates_ or one specific round date by calling _round_date_ with a round number.
    #
    class Krause
      attr_reader :error, :comments

      OPTIONS =
      [
        [:gender,  "Gender"],
        [:title,    "Title"],
        [:rating,  "Rating"],
        [:fed, "Federation"],
        [:id,          "ID"],
        [:dob,        "DOB"],
        [:rank,      "Rank"],
      ]

      # Parse Krause data returning a Tournament on success or raising an exception on error.
      def parse!(krs, arg={})
        @lineno = 0
        @tournament = Tournament.new('Unspecified', '2000-01-01')
        @name_set, @start_set = false, false
        @comments = ''
        @results = Array.new
        krs = ICU::Util.to_utf8(krs) unless arg[:is_utf8]
        lines = get_lines(krs)

        # Process all lines.
        lines.each do |line|
          @lineno += 1                 # increment line number
          next if line.match(/^\s*$/)  # skip blank lines
          @line = line                 # remember this line for later

          # Does it have a DIN or is it just a comment?
          if @line.match(/^(\d{3}) (.*)$/)
            din = $1             # data identification number (DIN)
            @data = $2           # the data after the DIN
          else
            add_comment
            next
          end

          # Process the line given the DIN.
          begin
            case din
              when '001' then add_player(arg)                   # player and results record
              when '012' then set_name                          # name (mandatory)
              when '013' then add_team                          # team name and members
              when '022' then @tournament.city = @data          # city
              when '032' then @tournament.fed = @data           # federation
              when '042' then set_start                         # start date (mandatory)
              when '052' then @tournament.finish = @data        # end date
              when '062' then add_comment                       # number of players (calculated from 001 records)
              when '072' then add_comment                       # number of rated players (calculated from 001 records)
              when '082' then add_comment                       # number of teams (calculated from 013 records)
              when '092' then @tournament.type = @data          # type of tournament
              when '102' then @tournament.arbiter = @data       # arbiter(s)
              when '112' then @tournament.deputy = @data        # deputy(ies)
              when '122' then @tournament.time_control = @data  # time control
              when '132' then add_round_dates(arg)              # round dates
              else raise "invalid DIN #{din}"
            end
          rescue => err
            raise err.class, "line #{@lineno}: #{err.message}", err.backtrace
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

        # Certain attributes are mandatory and should have been specifically set.
        raise "tournament name missing"       unless @name_set
        raise "tournament start date missing" unless @start_set

        # Finally, exercise the tournament object's internal validation, reranking if neccessary.
        @tournament.validate!(:rerank => true)

        @tournament
      end

      # Parse Krause data returning a Tournament on success or a nil on failure.
      # In the case of failure, an error message can be retrived via the <em>error</em> method.
      def parse(krs, arg={})
        begin
          parse!(krs, arg)
        rescue => ex
          @error = ex.message
          nil
        end
      end

      # Same as <em>parse!</em> except the input is a file name rather than file contents.
      def parse_file!(file, arg={})
        krause = ICU::Util.read_utf8(file)
        arg[:is_utf8] = true
        parse!(krause, arg)
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

      # Serialize a tournament back into Krause format.
      def serialize(t, arg={})
        t.validate!(:type => self)
        krause = ''
        krause << "012 #{t.name}\n"
        krause << "022 #{t.city}\n"         if t.city
        krause << "032 #{t.fed}\n"          if t.fed
        krause << "042 #{t.start}\n"
        krause << "052 #{t.finish}\n"       if t.finish
        krause << "092 #{t.type}\n"         if t.type
        krause << "102 #{t.arbiter}\n"      if t.arbiter
        krause << "112 #{t.deputy}\n"       if t.deputy
        krause << "122 #{t.time_control}\n" if t.time_control
        t.teams.each do |team|
          krause << sprintf('013 %-31s', team.name)
          team.members.each{ |m| krause << sprintf(' %4d', m) }
          krause << "\n"
        end
        rounds = t.last_round
        if t.round_dates.size == rounds && rounds > 0
          krause << "132 #{' ' * 85}"
          t.round_dates.each{ |d| krause << d.sub(/^../, '  ') }
          krause << "\n"
        end
        t.players.each{ |p| krause << p.to_krause(rounds, arg) }
        krause
      end

      # Additional tournament validation rules for this specific type.
      def validate!(t)
        # None.
      end

      # :enddoc:
      private

      def set_name
        @tournament.name = @data
        @name_set = true
      end

      def set_start
        @tournament.start = @data
        @start_set = true
      end

      # Split text into lines but also pad the player lines (those beginning "001 ").
      def get_lines(text)
        lines = text.split(/\s*\n/)
        max = 99  # length up to the end of round 1 result, including DIN
        lines.each do |line|
          next unless line.match(/^001 /)
          next unless line.length > max
          max+= 10 * (1 + (line.length - max - 1) / 10)  # increase by multiples of 10, the length of 1 result (including 2-space prefix)
        end
        lines.each_index do |i|
          line = lines[i]
          next unless line.match(/^001 /)
          next unless line.length < max
          line+= ' ' * (max - line.length)
          lines[i] = line
        end
        lines
      end

      def add_player(arg)
        raise "player record less than minimum length" if @line.length < 99

        # Prepare player details.
        num = @data[0, 4]
        nam = @data[10, 32]
        nams = nam.split(/,/)
        raise "missing comma in name #{nam.trim}" unless nams.size > 1
        opt =
        {
          :gender => @data[5, 1],
          :title  => @data[6, 3],
          :fed    => @data[49, 3],
          :dob    => @data[65, 10],
          :rank   => @data[81, 4],
        }

        # Ratings are assumed to be local unless otherwise specified.
        rating = @data[44, 4].to_i
        opt[arg[:fide] ? :fide_rating : :rating] = rating if rating > 0 && rating < 4000
        
        # Strings that can't possibly be DOBs should just be ignored.
        opt[:dob] = '' unless opt[:dob].match(/^(\d{4}.\d\d.\d\d|\d\d.\d\d.\d{4})$/);

        # IDs can be determined to be FIDE or ICU on the basis of their size.
        id = @data[53, 11].to_i
        opt[id >= 100000 ? :fide_id : :id] = id if id > 0

        # Options to remove other bad data.
        opt.delete(:fed) if arg[:fed].to_s == 'ignore'
        opt.delete(:fed) if arg[:fed].to_s == 'skip' && !ICU::Federation.find(opt[:fed])

        # Create the player.
        player = Player.new(nams.last, nams.first, num, opt)
        @tournament.add_player(player)

        # Results.
        total = @data[76, 4].strip
        total = total == '' ? nil : total.to_f
        index = 87
        round = 1
        sum = 0.0
        full_byes = []
        half_byes = []
        while @data.length > index
          sum+= add_result(round, player.num, @data[index, 8], full_byes, half_byes)
          index+= 10
          round+= 1
        end
        if total
          sum = total if total != sum && fix_sum(player.num, full_byes, half_byes, total, sum)
          raise "declared points total (#{total}) does not agree with summed scores (#{sum})" if total != sum
        end
      end

      def add_result(round, player, data, full_byes, half_byes)
        data.strip!
        if data.match(/^-?$/)
          full_byes << round
          return 0.0
        end
        data = "#{data} -" if data.match(/^\d+ (w|b|-)$/)
        raise "invalid result '#{data}'" unless data.match(/^(0{1,4}|[1-9]\d{0,3}) (w|b|-) (1|0|=|\+|-)$/)
        opponent = $1.to_i
        colour   = $2
        score    = $3
        options  = Hash.new
        options[:opponent] = opponent unless opponent == 0
        options[:colour]   = colour   unless colour == '-'
        options[:rateable] = false    unless score.match(/^(1|0|=)$/)
        result   = Result.new(round, player, score, options)
        @results << [@lineno, player, data, result]
        if opponent == 0
          case score
          when '-' then full_byes << result
          when '=' then half_byes << result
          end
        end
        result.points
      end

      # See if byes can be used to make the sum of scores match the declared total.
      def fix_sum(player, full_byes, half_byes, total, sum)
        return false unless total > sum
        return false unless total <= sum + full_byes.size * 1.0 + half_byes.size * 0.5
        full_byes.each_index do |i|
          bye = full_byes[i]
          if bye.class == Fixnum
            # Round number - create a half-point bye in that round.
            result = Result.new(bye, player, '=')
            @results << ['none', player, "extra bye for player #{player} in round #{bye}", result]
            full_byes[i] = result
          else
            # Zero point bye - upgrade to a half point.
            bye.score = 'D'
          end
          sum += 0.5
          return true if total == sum
        end
        (half_byes + full_byes).each do |bye|
          # Upgrade to full point.
          bye.score = 'W'
          sum += 0.5
          return true if total == sum
        end
        return false
      end

      def add_team
        raise error "team record less than minimum length" if @line.length < 40
        team = Team.new(@data[0, 31])
        index = 32
        while @data.length >= index + 4
          team.add_member(@data[index, 4])
          index+= 5
        end
        @tournament.add_team(team)
      end

      def add_round_dates(arg)
        return if arg[:round_dates].to_s == 'ignore'
        raise "round dates record less than minimum length" if @line.length < 99
        index = 87
        american = nil
        while @data.length >= index + 8
          date = @data[index, 8].strip
          # Cope with heinous date formats like yy.dd.mm.
          if date.match((/^(\d{2}).(\d{2}).(\d{2})$/))
            if american.nil?
              american = $2.to_i > 12 || (@tournament.start[5,2] == $3 && @tournament.start[8,2] != $2)
            end
            date = "#{$1}.#{$3}.#{$2}" if american
          end
          @tournament.add_round_date("20#{date}") unless date == ''
          index+= 10
        end
      end

      def add_comment
        @comments << @line
        @comments << "\n"
      end
    end
  end

  class Player
    # Format a player's 001 record as it would appear in a Krause formatted file (including the final newline).
    def to_krause(rounds, arg)
      defaults = ICU::Tournament::Krause::OPTIONS.map(&:first)

      # Optional columns.
      case
      when arg[:except].instance_of?(Array)
        optional = (Set.new(defaults) - arg[:except].map!(&:to_s).map!(&:to_sym)).to_a
      when arg[:only].instance_of?(Array)
        optional = arg[:only].map!(&:to_s).map!(&:to_sym)
      else
        optional = defaults
      end
      optional = optional.inject({}) { |m, a| m[a] = true; m }

      # Get the values to use.
      val = defaults.inject({}) do |m, a|
        if optional[a]
          if arg[:fide] && (a == :rating || a == :id)
            m[a] = send("fide_#{a}")
          else
            m[a] = send(a)
          end
        end
        m
      end

      # Output the mandatory and optional values.
      krause = '001'
      krause << sprintf(' %4d', @num)
      krause << sprintf(' %1s', case val[:gender]; when 'M' then 'm'; when 'F' then 'w'; else ''; end)
      krause << sprintf(' %2s', case val[:title]; when nil then ''; when 'IM' then 'm'; when 'WIM' then 'wm'; else val[:title][0, val[:title].length-1].downcase; end)
      krause << sprintf(' %-33s', "#{@last_name},#{@first_name}")
      krause << sprintf(' %4s', val[:rating])
      krause << sprintf(' %3s', val[:fed])
      krause << sprintf(' %11s', val[:id])
      krause << sprintf(' %10s', val[:dob])
      krause << sprintf(' %4.1f', points)
      krause << sprintf(' %4s', val[:rank])

      # And finally the round scores.
      (1..rounds).each do |r|
        result = find_result(r)
        krause << sprintf('  %8s', result ? result.to_krause : '')
      end
      krause << "\n"
    end
  end

  class Result
    # Format a player's result as it would appear in a Krause formatted file (exactly 8 characters long, including leading whitespace).
    def to_krause
      return ' ' * 8 if !@opponent && !@colour && @score == 'L'
      krause = sprintf('%4s ', @opponent || '0000')
      krause << sprintf('%1s ', @colour ? @colour.downcase : '-')
      krause << case @score; when 'W' then '1'; when 'L' then '0'; else '='; end if  @rateable
      krause << case @score; when 'W' then '+'; when 'L' then '-'; else '='; end if !@rateable
      krause
    end
  end
end
