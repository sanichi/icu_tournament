module ICU

=begin rdoc

== Generic Tournament

Normally a tournament object is created by parsing a data file (e.g. with ICU::Tournament::ForeignCSV).
However, it is also possible to build a tournament by first creating a bare tournament instance and then
firstly adding all the players and then adding all the results.

  require 'rubygems'
  require 'chess_icu'

  t = ICU::Tournament.new('Bangor Masters', '2009-11-09')

  t.add_player(ICU::Player.new('Bobby', 'Fischer', 10))
  t.add_player(ICU::Player.new('Garry', 'Kasparov', 20))
  t.add_player(ICU::Player.new('Mark', 'Orr', 30))

  t.add_result(ICU::Result.new(1, 10, 'D', :opponent => 30, :colour => 'W'))
  t.add_result(ICU::Result.new(2, 20, 'W', :opponent => 30, :colour => 'B'))
  t.add_result(ICU::Result.new(3, 20, 'L', :opponent => 10, :colour => 'W'))

  [10, 20, 30].each { |n| p = t.player(n); puts "#{p.points} #{p.name}" }

Would result in the following output.

  1.5 Bobby Fischer
  1.0 Gary Kasparov
  0.5 Mark Orr

Note that the players should be added first because the _add_result_ method will
raise an exception if the players it references through their tournament numbers
(10, 20 and 30 in this example) have not already been added to the tournament.

A tournament can be validated with either the _validate!_ or _invalid_ methods.
On success, the first returns true while the second returns false.
On error, the first throws an exception while the second returns a description of the error.

Validations checks that:

* there are at least two players
* every player has a least one result
* the round numbers of the players results are consistent
* the tournament dates (start, finish, round dates) are consistent
* the player ranks are consistent with their scores

Side effects of calling _validate!_ or _invalid_ include:

* the number of rounds will be set if not set already
* the finish date will be set if not set already and if there are round dates

If the _rerank_ option is set, as in this example:

  t.validate!(:rerank => true)

then there are additional side effects of validating a tournament:

* the players will be ranked if no players have any rank
* the players will be reranked if the existing ranking is inconsistent

Ranking is consistent if either no players have any rank or if all players have a rank and no player is ranked higher than another player with more points.

The players in a tournament can be renumbered by rank or name. After any renumbering the player numbers,
which initially can be any collection of unique integers, will start at 1 and go up to the number of players.

  t.renumber!(:name)       # renumber by name
  t.renumber!(:rank)       # renumber by rank
  t.renumber!              # same - rank is the default

A side effect of renumbering by rank is that if the tournament started without any player ranking or
with inconsitent ranking, it will be reranked (i.e. the method _rerank_ will be called on it).

=end

  class Tournament
    attr_reader :name, :rounds, :start, :finish, :round_dates, :site, :city, :fed, :type, :arbiter, :deputy, :time_control, :teams
    
    # Constructor. Name and start date must be supplied. Other attributes are optional.
    def initialize(name, start, opt={})
      self.name  = name
      self.start = start
      [:finish, :rounds, :site, :city, :fed, :type, :arbiter, :deputy, :time_control].each { |a| self.send("#{a}=", opt[a]) unless opt[a].nil? }
      @player = {}
      @teams = []
      @round_dates = []
    end
    
    # Set the tournament name.
    def name=(name)
      raise "invalid tournament name (#{name})" unless name.to_s.match(/[a-z]/i)
      @name = name.to_s.strip
    end
    
    # Set the tournament city. Can be _nil.
    def city=(city)
      city = city.to_s.strip
      if city == ''
        @city = nil
      else
        raise "invalid tournament city (#{city})" unless city.match(/[a-z]/i)
        @city = city
      end
    end
    
    # Set the tournament federation. Can be _nil_.
    def fed=(fed)
      obj = Federation.find(fed)
      @fed = obj ? obj.code : nil
      raise "invalid tournament federation (#{fed})" if @fed.nil? && fed.to_s.strip.length > 0
    end
    
    # Set a start date in yyyy-mm-dd format.
    def start=(start)
      start = start.to_s.strip
      @start = Util.parsedate(start)
      raise "invalid start date (#{start})" unless @start
    end
    
    # Set an end date in yyyy-mm-dd format.
    def finish=(finish)
      finish = finish.to_s.strip
      if finish == ''
        @finish = nil
      else
        @finish = Util.parsedate(finish)
        raise "invalid finish date (#{finish})" unless @finish
      end
    end
    
    # Set the number of rounds. Is either unknown (_nil_) or a positive integer.
    def rounds=(rounds)
      @rounds = case rounds
        when nil     then nil
        when Fixnum  then rounds
        when /^\s*$/ then nil
        else rounds.to_i
      end
      raise "invalid number of rounds (#{rounds})" unless @rounds.nil? || @rounds > 0
    end
    
    # Add a round date.
    def add_round_date(round_date)
      round_date = round_date.to_s.strip
      parsed_date = Util.parsedate(round_date)
      raise "invalid round date (#{round_date})" unless parsed_date
      @round_dates << parsed_date
      @round_dates.sort!
    end
    
    # Return the date of a given round, or nil if unavailable.
    def round_date(round)
      @round_dates[round-1]
    end
    
    # Set the tournament web site. Should be either unknown (_nil_) or a reasonably valid looking URL.
    def site=(site)
      @site = site.to_s.strip
      @site = nil if @site == ''
      @site = "http://#{@site}" if @site && !@site.match(/^https?:\/\//)
      raise "invalid site (#{site})" unless @site.nil? || @site.match(/^https?:\/\/[-\w]+(\.[-\w]+)+(\/[^\s]*)?$/i)
    end
    
    # Set the tournament type. Should be either unknown (_nil_) or contain some letters.
    def type=(type)
      @type = type.to_s.strip
      @type = nil if @type == ''
      raise "invalid tournament type (#{type})" unless @type.nil? || @type.match(/[a-z]/i)
    end
    
    # Set the tournament arbiter. Should be either unknown (_nil_) or contain some letters.
    def arbiter=(arbiter)
      @arbiter = arbiter.to_s.strip
      @arbiter = nil if @arbiter == ''
      raise "invalid tournament arbiter (#{arbiter})" unless @arbiter.nil? || @arbiter.match(/[a-z]/i)
    end
    
    # Set the tournament deputy. Should be either unknown (_nil_) or contain some letters.
    def deputy=(deputy)
      @deputy = deputy.to_s.strip
      @deputy = nil if @deputy == ''
      raise "invalid tournament deputy (#{deputy})" unless @deputy.nil? || @deputy.match(/[a-z]/i)
    end
    
    # Set the time control. Should be either unknown (_nil_) or contain some numbers.
    def time_control=(time_control)
      @time_control = time_control.to_s.strip
      @time_control = nil if @time_control == ''
      raise "invalid tournament time control (#{time_control})" unless @time_control.nil? || @time_control.match(/[1-9]\d/)
    end
    
    # Add a new team. The argument is either a team (possibly already with members) or the name of a new team.
    # The team's name must be unique in the tournament. Returns the the team instance.
    def add_team(team)
      team = Team.new(team.to_s) unless team.is_a? Team
      raise "a team with a name similar to '#{team.name}' already exists" if self.get_team(team.name)
      @teams << team
      team
    end
    
    # Return the team object that matches a given name, or nil if not found.
    def get_team(name)
      @teams.find{ |t| t.matches(name) }
    end
    
    # Add a new player to the tournament. Must have a unique player number.
    def add_player(player)
      raise "invalid player" unless player.class == ICU::Player
      raise "player number (#{player.num}) should be unique" if @player[player.num]
      @player[player.num] = player
    end
    
    # Get a player by their number.
    def player(num)
      @player[num]
    end
    
    # Return an array of all players in order of their player number.
    def players
      @player.values.sort_by{ |p| p.num }
    end
    
    # Lookup a player in the tournament by player number, returning _nil_ if the player number does not exist.
    def find_player(player)
      players.find { |p| p == player }
    end
    
    # Add a result to a tournament. An exception is raised if the players referenced in the result (by number)
    # do not exist in the tournament. The result, which remember is from the perspective of one of the players,
    # is added to that player's results. Additionally, the reverse of the result is automatically added to the player's
    # opponent, unless the opponent does not exist (e.g. byes, walkovers). By default, if the result is rateable
    # then the opponent's result will also be rateable. To make the opponent's result unrateable, set the optional
    # second parameter to false.
    def add_result(result, reverse_rateable=true)
      raise "invalid result" unless result.class == ICU::Result
      raise "result round number (#{result.round}) inconsistent with number of tournament rounds" if @rounds && result.round > @rounds
      raise "player number (#{result.player}) does not exist" unless @player[result.player]
      @player[result.player].add_result(result)
      if result.opponent
        raise "opponent number (#{result.opponent}) does not exist" unless @player[result.opponent]
        reverse = result.reverse
        reverse.rateable = false unless reverse_rateable
        @player[result.opponent].add_result(reverse)
      end
    end
        
    # Rerank the tournament by score, resolving ties using name.
    def rerank
      @player.values.map{ |p| [p, p.points] }.sort do |a,b|
        d = b[1] <=> a[1]
        d = a[0].last_name <=> b[0].last_name if d == 0
        d = a[0].first_name <=> b[0].first_name if d == 0
        d
      end.each_with_index do |v,i|
        v[0].rank = i + 1
      end
    end
    
    # Renumber the players according to a given criterion. Return self.
    def renumber!(criterion = :rank)
      map = Hash.new
      
      # Decide how to rank.
      if criterion == :name
        @player.values.sort_by{ |p| p.name }.each_with_index{ |p, i| map[p.num] = i + 1 }
      else
        begin check_ranks rescue rerank end
        @player.values.each{ |p| map[p.num] = p.rank}
      end
      
      # Apply ranking.
      @teams.each{ |t| t.renumber!(map) }
      @player = @player.values.inject({}) do |hash, player|
        player.renumber!(map)
        hash[player.num] = player
        hash
      end
      
      self
    end

    # Is a tournament invalid? Either returns false (if it's valid) or an error message.
    def invalid(options={})
      begin
        validate!(options)
      rescue => err
        return err.message
      end
      false
    end

    # Raise an exception if a tournament is not valid.
    # Covers all the ways a tournament can be invalid not already enforced by the setters.
    def validate!(options={})
      begin check_ranks rescue rerank end if options[:rerank]
      check_players
      check_rounds
      check_dates
      check_teams
      check_ranks(:allow_none => true)
      true
    end

    private
    
    # Check players.
    def check_players
      raise "the number of players (#{@player.size}) must be at least 2" if @player.size < 2
      @player.each do |num, p|
        raise "player #{num} has no results" if p.results.size == 0
        p.results.each do |r|
          next unless r.opponent
          raise "opponent #{r.opponent} of player #{num} is not in the tournament" unless @player[r.opponent]
        end
      end
    end
    
    # Round should go from 1 to a maximum, there should be at least one result in every round and,
    # if the number of rounds has been set, it should agree with the largest round from the results.
    def check_rounds
      round = Hash.new
      round_last = 0
      @player.values.each do |p|
        p.results.each do |r|
          round[r.round] = true
          round_last = r.round if r.round > round_last
        end
      end
      (1..round_last).each { |r| raise "there are no results for round #{r}" unless round[r] }
      if rounds
        raise "declared number of rounds is #{rounds} but there are results in later rounds, such as #{round_last}" if rounds < round_last
        raise "declared number of rounds is #{rounds} but there are no results with rounds greater than #{round_last}" if rounds > round_last
      else
        self.rounds = round_last
      end
    end

    # Check dates are consistent.
    def check_dates
      raise "start date (#{start}) is after end date (#{finish})" if @start && @finish && @start > @finish
      if @round_dates.size > 0
        raise "the number of round dates (#{@round_dates.size}) does not match the number of rounds (#{@rounds})" unless @round_dates.size == @rounds
        raise "the date of the first round (#{@round_dates[0]}) comes before the start (#{@start}) of the tournament" if @start && @start > @round_dates[0]
        raise "the date of the last round (#{@round_dates[-1]}) comes after the end (#{@finish}) of the tournament" if @finish && @finish < @round_dates[-1]
        @finish = @round_dates[-1] unless @finish
      end
    end
    
    # Check teams. Either there are none or:
    # * every team member is a valid player, and
    # * every player is a member of exactly one team.
    def check_teams
      return if @teams.size == 0
      member = Hash.new
      @teams.each do |t|
        t.members.each do |m|
          raise "member #{m} of team '#{t.name}' is not a valid player number for this tournament" unless @player[m]
          raise "member #{m} of team '#{t.name}' is already a member of team #{member[m]}" if member[m]
          member[m] = t.name
        end
      end
      @player.keys.each do |p|
        raise "player #{p} is not a member of any team" unless member[p]
      end
    end

    # Check if the players ranking is consistent, which will be true if:
    # * every player has a rank
    # * no two players have the same rank
    # * the highest rank is 1
    # * the lowest rank is equal to the total of players
    def check_ranks(options={})
      ranks = Hash.new
      @player.values.each do |p|
        if p.rank
          raise "two players have the same rank #{p.rank}" if ranks[p.rank]
          ranks[p.rank] = p
        end
      end
      return if ranks.size == 0 && options[:allow_none]
      raise "every player has to have a rank" unless ranks.size == @player.size
      by_rank = @player.values.sort{ |a,b| a.rank <=> b.rank}
      raise "the highest rank must be 1" unless by_rank[0].rank == 1
      raise "the lowest rank must be #{ranks.size}" unless by_rank[-1].rank == ranks.size
      if by_rank.size > 1
        (1..by_rank.size-1).each do |i|
          p1 = by_rank[i-1]
          p2 = by_rank[i]
          raise "player #{p1.num} with #{p1.points} points is ranked above player #{p2.num} with #{p2.points} points" if p1.points < p2.points
        end
      end
    end
  end
end
