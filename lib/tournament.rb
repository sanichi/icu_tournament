module ICU
  class Tournament
    attr_reader :name, :start, :rounds, :site
    
    # Constructor.
    def initialize(name, start, opt={})
      self.name  = name
      self.start = start
      [:rounds, :site].each { |a| self.send("#{a}=", opt[a]) unless opt[a].nil? }
      @player = {}
    end
    
    # Tournament name.
    def name=(name)
      raise "invalid tournament name (#{name})" unless name.to_s.match(/[a-z]/i)
      @name = name.to_s.strip
    end
    
    # Start data in yyyy-mm-dd format.
    def start=(start)
      start = start.to_s.strip
      @start = Util.parsedate(start)
      raise "invalid start date (#{start})" unless @start
    end
    
    # Number of rounds. Is either unknown (nil) or a positive integer.
    def rounds=(rounds)
      @rounds = case rounds
        when nil     then nil
        when Fixnum  then rounds
        when /^\s*$/ then nil
        else rounds.to_i
      end
      raise "invalid number of rounds (#{rounds})" unless @rounds.nil? || @rounds > 0
    end
    
    # Web site. Either unknown or a reasonably valid looking URL.
    def site=(site)
      @site = site.to_s.strip
      @site = nil if @site == ''
      @site = "http://#{@site}" if @site && !@site.match(/^https?:\/\//)
      raise "invalid site (#{site})" unless @site.nil? || @site.match(/^https?:\/\/[-\w]+(\.[-\w]+)+(\/[^\s]*)?$/i)
    end
    
    # Add players.
    def add_player(player)
      raise "invalid player" unless player.class == ICU::Player
      raise "player number (#{player.num}) should be unique" if @player[player.num]
      @player[player.num] = player
    end
    
    # Get a player by their number.
    def player(num)
      @player[num]
    end
    
    # Return an array of all the players.
    def players
      @player.values
    end
    
    # Lookup a player in the tournament.
    def find_player(player)
      players.find { |p| p == player }
    end
    
    # Add results.
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
