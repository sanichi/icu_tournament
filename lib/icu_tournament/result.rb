# encoding: utf-8

module ICU

=begin rdoc

== Result

A result is the outcome of a game from the perspective of one of the players.
If the game was not a bye or a walkover and involved a second player, then
that second player will also have a result for the same game, and the two
results will be mirror images of each other.

A result always involves a round number, a player number and a score, so these
three attributes must be supplied in the constructor.

  result = ICU::Result.new(2, 10, 'W')

The above example represents player 10 winning in round 2. As it stands, it represends
a bye or walkover since there is no opponent. Without an opponent, it is unrateable.

  result.rateable     # => false

The player's colour and the number of their opponent can be set as follows:

  result.colour = 'B'
  result.opponent = 13

Specifying an opponent always makes a result rateable.

  result.rateable     # => true

This example now represents a win by player 10 with the black pieces over player number 13 in round 2.
Alternatively, all this can been specified in the constructor.

  result = ICU::Result.new(2, 10, 'W', :opponent => 13, :colour => 'B')

To make a game unratable, even if it involves an opponent, set the _rateable_ atribute explicity:

  result.rateable = false

or include it in the constructor:

  result = ICU::Result.new(2, 10, 'W', :opponent => 13, :colour => 'B', :rateable => false)

The result of the same game from the perspective of the opponent is:

  tluser = result.reverse

which, with the above example, would be:

  tluser.player       # => 13
  tluser.opponent     # => 10
  tluser.score        # => 'L'
  tluser.colour       # => 'B'
  tluser.round        # => 2

The reversed result copies the _rateable_ attribute of the original unless an
explicit override is supplied.

  result.rateable                 # => true
  result.reverse.rateable         # => true (copied from original)
  result.reverse(false).rateable  # => false (overriden)

A result which has no opponent is not reversible (the _reverse_ method returns _nil_).

The return value from the _score_ method is always one of _W_, _L_ or _D_. However,
when setting the score, a certain amount of variation is permitted as long as it is
clear what is meant. For eample, the following would all be converted to _D_:

  result.score = ' D '
  result.score = 'd'
  result.score = '='
  result.score = '0.5'
  result.score = '½'

The _points_ read-only accessor always returns a floating point number: either 0.0, 0.5 or 1.0.

=end

  class Result
    
    extend ICU::Accessor
    attr_positive :round
    attr_integer :player
    
    attr_reader :score, :colour, :opponent, :rateable
    
    # Constructor. Round number, player number and score must be supplied.
    # Optional hash attribute are _opponent_, _colour_ and _rateable_.
    def initialize(round, player, score, opt={})
      self.round  = round
      self.player = player
      self.score  = score
      [:colour, :opponent].each { |a| self.send("#{a}=", opt[a]) unless opt[a].nil? }
      self.rateable = opt[:rateable]  # always attempt to set this, and do it last, to get the right default
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
        when nil   then true   # default is true
        when false then false  # this is the only way to turn it off
        else true
      end
    end
    
    # Return a reversed version (from the opponent's perspective) of a result.
    def reverse(rateable=nil)
      return unless @opponent
      r = Result.new(@round, @opponent, @score == 'W' ? 'L' : (@score == 'L' ? 'W' : 'D'))
      r.opponent = @player
      r.colour = 'W' if @colour == 'B'
      r.colour = 'B' if @colour == 'W'
      r.rateable = rateable || @rateable
      r
    end
    
    # Renumber the player and opponent (if there is one) according to the supplied hash. Return self.
    def renumber(map)
      raise "result player number #{@player} not found in renumbering hash" unless map[@player]
      self.player = map[@player]
      if @opponent
        raise "result opponent number #{@opponent} not found in renumbering hash" unless map[@opponent]
        old_rateable = @rateable
        self.opponent = map[@opponent]
        self.rateable = old_rateable  # because setting the opponent has a side-effect which is undesirable in this context
      end
      self
    end
    
    # Loose equality. True if the round, player and opponent numbers, colour and score all match.
    def ==(other)
      return unless other.is_a? Result
      [:round, :player, :opponent, :colour, :score].each do |m|
        return false unless self.send(m) == other.send(m)
      end
      true
    end
    
    # Strict equality. True if the there's loose equality and also the rateablity is the same.
    def eql?(other)
      return true if equal?(other)
      return false unless self == other
      self.rateable == other.rateable
    end
  end
end