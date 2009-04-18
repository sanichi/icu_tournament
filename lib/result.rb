module ICU
  class Result
    attr_reader :round, :player, :score, :colour, :opponent, :rateable
    
    # Constructor. Round number, player number and score must be supplied.
    # Optional hash attribute are _opponent_, _colour_ and _rateable_.
    def initialize(round, player, score, opt={})
      self.round  = round
      self.player = player
      self.score  = score
      [:colour, :opponent].each { |a| self.send("#{a}=", opt[a]) unless opt[a].nil? }
      self.rateable = opt[:rateable]  # always attempt to set this, and do it last, to get the right default
    end
    
    # Round number. Must be a positive integer.
    def round=(round)
      @round = round.to_i
      raise "invalid round number (#{round})" unless @round > 0
    end
    
    # Player number. Can be any integer.
    def player=(player)
      @player = case player
        when Fixnum then player
        else player.to_i
      end
      raise "invalid player number (#{player})" if @player == 0 && !player.to_s.match(/\d/)
    end
    
    # Score for the game, even if a default. One of 'W', 'L' or 'D'. Reasonable inputs like 1, 0, =, ½, etc will be converted.
    def score=(score)
      @score = case score.to_s.strip
        when /^(1\.0|1|\+|W|w)$/ then 'W'
        when /^(0\.5|½|\=|D|d)$/ then 'D'
        when /^(0\.0|0|\-|L|l)$/ then 'L'
        else raise "invalid score (#{score})"
      end
    end
    
    # Return the score as a floating point number.
    def points
      case @score
        when 'W' then 1.0
        when 'L' then 0.0
        else 0.5
      end
    end
    
    # Colour. Either 'W' (white) or 'B' (black).
    def colour=(colour)
      @colour = case colour.to_s
        when ''   then nil
        when /W/i then 'W'
        when /B/i then 'B'
        else raise "invalid colour (#{colour})"
      end
    end
    
    # Opponent player number. Either absent (_nil_) or any integer except the player number.
    def opponent=(opponent)
      @opponent = case opponent
        when nil     then nil
        when Fixnum  then opponent
        when /^\s*$/ then nil
        else opponent.to_i
      end
      raise "invalid opponent number (#{opponent})" if @opponent == 0 && !opponent.to_s.match(/\d/)
      raise "opponent number and player number (#{@opponent}) must be different" if @opponent == player
      self.rateable = true if @opponent
    end
    
    # Rateable flag. If false, result is not rateable. Can only be true if there is an opponent.
    def rateable=(rateable)
      if opponent.nil?
        @rateable = false
        return
      end
      @rateable = case rateable
        when nil   then true   # default (when absent) is true
        when false then false  # this is the only way to turn it off
        else true
      end
    end
    
    # Reverse a result so it is seen from the opponent's perspective.
    def reverse(rateable=nil)
      return unless @opponent
      r = Result.new(@round, @opponent, @score == 'W' ? 'L' : (@score == 'L' ? 'W' : 'D'))
      r.opponent = @player
      r.colour = 'W' if @colour == 'B'
      r.colour = 'B' if @colour == 'W'
      r.rateable = rateable || @rateable
      r
    end
    
    # Loose equality. True if the round, player and opponent numbers, colour and score all match.
    def ==(other)
      return unless other.is_a? Result
      [:round, :player, :opponent, :colour, :score].each do |m|
        return false unless self.send(m) == other.send(m)
      end
      true
    end
  end
end