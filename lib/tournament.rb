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

=end

  class Tournament
    attr_reader :name, :start, :finish, :rounds, :site, :city, :fed, :type, :arbiter, :deputy, :time_control
    
    # Constructor. Name and start date must be supplied. Other attributes are optional.
    def initialize(name, start, opt={})
      self.name  = name
      self.start = start
      [:finish, :rounds, :site, :city, :fed, :type, :arbiter, :deputy, :time_control].each { |a| self.send("#{a}=", opt[a]) unless opt[a].nil? }
      @player = {}
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
    
    # Return an array of all players in order of their player numbers.
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
  end
end
