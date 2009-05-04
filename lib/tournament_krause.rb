module ICU
  class Tournament
    
=begin rdoc

== Krause

This is the {format}[http://www.fide.com/component/content/article/5-whats-news/2245-736-general-data-exchange-format-for-tournament-results]
used to submit tournament results to FIDE[http://www.fide.com] for rating.

Suppose, for example, that the following data is the file <em>tournament.tab</em>:

  012 Fantasy Tournament
  032 IRL
  042 2009.09.09
  0123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890
  001    1 w    Mouse,Minerva                     1900 USA     1234567 1928.05.15  1.0    2     2 b 0     3 w 1          
  001    2 m  m Duck,Daffy                        2200 IRL     7654321 1937.04.17  2.0    1     1 w 1               3 b 1
  001    3 m  g Mouse,Mickey                      2600 USA     1726354 1928.05.15  0.0    3               1 b 0     2 w 0

This file can be parsed as follows.

  data = open('tournament.tab') { |f| f.read }
  parser = ICU::Tournament::Krause.new
  tournament = parser.parse(data)

If the file is correctly specified, the return value from the <em>parse</em> method is an instance of
ICU::Tournament (rather than <em>nil</em>, which indicates an error). In this example the file is valid, so:
  
  tournament.name                   # => "Fantasy Tournament"
  tournament.start                  # => "2009-09-09"
  tournament.rounds                 # => 3
  tournament.fed                    # => "IRL"
  tournament.players.size           # => 9
  
A player can be retrieved from the tournament via the _players_ array or by sending a valid player number to the _player_ method.

  minnie = tournament.player(1)
  minnie.name                       # => "Mouse, Minerva"
  minnie.points                     # => 1.0
  minnie.results.size               # => 2
  
  daffy = tournament.player(2)
  daffy.title                       # => "IM"
  daffy.rating                      # => 2200
  daffy.fed                         # => "IRL"
  daffy.id                          # => 7654321
  daffy.dob                         # => "1937-04-17"

Comments in the input file (lines that do not start with a valid data identification number) are available from the parser
instance via its _comments_ method. Note that these comments are reset evry time the instance is used to parse another file.

  parser.comments                   # => "0123456789..."

A tournament can be serialized back to Krause format (the reverse of parsing) with the _serialize_ method.

  krause = parser.serialize(tournament)

The following lists Krause data identification numbers, their description and, where available, their corresponding attributes in an ICU::Tournament instance.

[001 Player record]           Use _players_ to get all players or _player_ with a player number to get a single instance.
[012 Name]                    Get or set with _name_. Free text. A tounament name is mandatory.
[013 Teams]                   Not implemented yet.
[022 City]                    Get or set with _city_. Free text.
[032 Federation]              Get or set with _fed_. Getter returns either _nil_ or a three letter code. Setter can take various formats (see ICU::Federation).
[042 Start date]              Get or set with _start_. Getter returns _yyyy-mm-dd_ format, but setter can use any reasonable date format. Start date is mandadory.
[052 End date]                Get or set with _finish_. Returns either _yyyy-mm-dd_ format or _nil_ if not set. Like _start_, can be set with various date formats.
[062 Number of players]       Not used. Treated as comment in parsed files. Can be determined from the size of the _players_ array.
[072 Number of rated players] Not used. Treated as comment in parsed files. Can be determined by analysing the array returned by _players_.
[082 Number of teams]         Not used. Treated as comment in parsed files.
[092 Type of tournament]      Get or set with _type_. Free text.
[102 Arbiter(s)]              Get or set with -arbiter_. Free text.
[112 Deputy(ies)]             Get or set with _deputy_. Free text.
[122 Time control]            Get or set with _time_control_. Free text.
[132 Round dates]             Not implemented yet.

=end

    class Krause
      attr_reader :error, :comments
      
      # Parse Krause data returning a Tournament on success or a nil on failure.
      # In the case of failure, an error message can be retrived via the <em>error</em> method.
      def parse(krs)
        begin
          parse!(krs)
        rescue => ex
          @error = ex.message
          nil
        end
      end
      
      # Parse Krause data returning a Tournament on success or raising an exception on error.
      def parse!(krs)
        @lineno = 0
        @tournament = Tournament.new('Dummy', '2000-01-01')
        @name_set, @start_set = false, false
        @comments = ''
        @results = Array.new
        
        # Process all lines.
        krs.each_line do |line|
          @lineno += 1         # increment line number
          line.strip!          # remove leading and trailing white space
          next if line == ''   # skip blank lines
          @line = line         # remember this line for later
          
          # Does it havea DIN or is it just a comment?
          if @line.match(/^(\d{3}) (.*)$/)
            din = $1           # data identification number (DIN)
            @data = $2         # the data after the DIN
          else
            add_comment
            next
          end
          
          # Process the line given the DIN.
          begin
            case din
              when '001' then add_player                        # player and results record
              when '012' then set_name                          # name (mandatory)
              when '013' then add_comment                       # team name and members (not implemented yet)
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
              when '132' then add_comment                       # round dates (not implemented yet)
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
        
        # Validate the data now that we have everything.
        validate
        
        @tournament
      end
      
      # Serialise a tournament back into Krause format.
      def serialize(t)
        return nil unless t.class == ICU::Tournament;
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
        t.players.each{ |p| krause << p.to_krause(@tournament.rounds) }
        krause
      end

      private
      
      def set_name
        @tournament.name = @data
        @name_set = true
      end
      
      def set_start
        @tournament.start = @data
        @start_set = true
      end
      
      def add_player
        raise "player record less than minimum length" if @line.length < 99
        
        # Player details.
        num = @data[0, 4]
        nam = Name.new(@data[10, 32])
        opt =
        {
          :gender => @data[5, 1],
          :title  => @data[6, 3],
          :rating => @data[44, 4],
          :fed    => @data[49, 3],
          :id     => @data[53, 11],
          :dob    => @data[65, 10],
          :rank   => @data[81, 4],
        }
        player = Player.new(nam.first, nam.last, num, opt)
        @tournament.add_player(player)
        
        # Results.
        points = @data[77, 4].strip
        points = points == '' ? nil : points.to_f
        index  = 87
        round  = 1
        total  = 0.0
        while @data.length >= index + 8
          total+= add_result(round, player.num, @data[index, 8])
          index+= 10
          round+= 1
        end
        raise "declared points total (#{points}) does not agree with total from summed results (#{total})" if points && points != total
      end
      
      def add_result(round, player, data)
        return 0.0 if data.strip! == ''  # no result for this round
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
        result.points
      end

      def add_comment
        @comments << @line
        @comments << "\n"
      end
      
      def validate
        # Certain attributes are mandatory.
        raise "tournament name missing"       unless @name_set
        raise "tournament start date missing" unless @start_set
        
        # There must be at least two players.
        raise "minimum number of players is 2" if @tournament.players.length < 2
        
        # Every player must have at least one result.
        @tournament.players.each { |p| raise "player #{p.num} has no results" if p.results.size == 0 }
        
        # Rerank the tournament if there are no ranking values or if there are but they're not consistent.
        @tournament.rerank unless @tournament.ranking_consistent?

        # Set the number of rounds.
        @tournament.rounds = @tournament.players.inject(0) do |pa, p|
          pm = p.results.inject(0){ |ra, r| ra < r.round ? r.round : ra }
          pa < pm ? pm : pa
        end
      end
    end
  end
  
  class Player
    # Format a player's 001 record as it would appear in a Krause formatted file (including the final newline).
    def to_krause(rounds)
      krause = '001'
      krause << sprintf(' %4d', @num)
      krause << sprintf(' %1s', case @gender; when 'M': 'm'; when 'F': 'w'; else ''; end)
      krause << sprintf(' %2s', case @title; when nil: ''; when 'IM': 'm'; when 'WIM': 'wm'; else @title[0, @title.length-1].downcase; end)
      krause << sprintf(' %-33s', "#{@last_name},#{@first_name}")
      krause << sprintf(' %4s', @rating)
      krause << sprintf(' %3s', @fed)
      krause << sprintf(' %11s', @id)
      krause << sprintf(' %10s', @dob)
      krause << sprintf(' %4.1f', points)
      krause << sprintf(' %4s', @rank)
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
      krause << case @score; when 'W': '1'; when 'L': '0'; else '='; end if  @rateable
      krause << case @score; when 'W': '+'; when 'L': '-'; else '='; end if !@rateable
      krause
    end
  end
end
