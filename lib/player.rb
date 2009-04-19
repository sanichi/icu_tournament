module ICU

=begin rdoc

== Player

A player in a tournament must have a first name, a last name and a number
which is unique in the tournament but otherwise arbitary.

  bobby = ICU::Player.new('robert j', 'fischer', 17)

Names are automatically cannonicalised (tidied up).

  bobby.first_name                 # => 'Robert J.'
  bobby.last_name                  # => 'Fischer'

In addition, players have a number of optional attributes which can be specified
via setters or in constructor hash options: _id_ (either FIDE or national),
_fed_ (federation), _title_, _rating_, _rank_ and _dob_ (date of birth).

  peter = ICU::Player.new('Peter', 'Svidler', 21, :fed => 'rus', :title => 'g', :rating = 2700)
  peter.dob = '17th June, 1976'
  peter.rank = 1

Some of these values will also be canonicalised to some extent. For example,
the date of birth conforms to a _yyyy-mm-dd_ format, the chess title will be two
to three capital letters always ending in _M_ and the federation, if it's three
letters long, will be upcased.

  peter.dob                        # => 1976-07-17
  peter.title                      # => 'GM'
  peter.fed                        # => 'RUS'

Results (ICU::Result) should be added to players via the tournament (ICU::Tournament) object
to which the player instance have been added. Their total score is available via the _points_ method.

  peter.points                     # => 5.5

Players can be compared to see if they're roughly or exactly the same, which may be useful in detecting duplicates.
If the names match and the federations don't disagree then two players are equal according to the _==_ operator.
The player number is irrelevant.

  john1 = ICU::Player.new('John', 'Smith', 12)
  john2 = ICU::Player.new('John', 'Smith', 22, :fed = 'IRL')
  john2 = ICU::Player.new('John', 'Smith', 32, :fed = 'ENG')

  john1 == john2                   # => true (federations don't disagree because one is unset)
  john2 == john3                   # => false (federations disagree)

If, in addition, _rating_, _dob_, _gender_ and _id_ do not disagree then two players are equal
according to the stricter criteria of _eql?_.

  mark1 = ICU::Player.new('Mark', 'Orr', 31, :fed = 'IRL', :rating => 2100)
  mark2 = ICU::Player.new('Mark', 'Orr', 33, :fed = 'IRL', :rating => 2100, :title => 'IM')
  mark3 = ICU::Player.new('Mark', 'Orr', 37, :fed = 'IRL', :rating => 2200, :title => 'IM')

  mark1.eql?(mark2)                # => true (ratings agree and titles don't disagree)
  mark2.eql?(mark3)                # => false (the ratings are not the same)

The presence of two players in the same tournament that are equal according to _==_ but unequal
according to _eql?__ is likely to indicate a data entry error.

If two instances represent the same player and are equal according to _==_ then the _id_, _rating_,
_title_ and _fed_ attributes of the two can be merged. For example:

  fox1 = ICU::Player.new('Tony', 'Fox', 12, :id => 456)
  fox2 = ICU::Player.new('Tony', 'Fox', 21, :rating => 2100, :fed => 'IRL', :gender => 'M')
  fox1.merge(fox2)

Any attributes present in the second player but not in the first are copied to the first.
All other attributes are unaffected.

  fox1.rating                      # => 2100
  fox1.fed                         # => 'IRL'
  fox1.gender                      # => 'M'

=end

  class Player
    attr_accessor :first_name, :last_name, :num, :id, :fed, :title, :rating, :rank, :dob, :gender
    attr_reader :results
    
    # Constructor. Must supply both names and a unique number for the tournament.
    def initialize(first_name, last_name, num, opt={})
      self.first_name = first_name
      self.last_name  = last_name
      self.num        = num
      [:id, :fed, :title, :rating, :rank, :dob, :gender].each do |atr|
        self.send("#{atr}=", opt[atr]) unless opt[atr].nil?
      end
      @results = []
    end
    
    # Canonicalise and set the first name(s).
    def first_name=(first_name)
      name = Name.new(first_name, 'Last')
      raise "invalid first name" unless name.first.length > 0
      @first_name = name.first
    end
    
    # Canonicalise and set the last name(s).
    def last_name=(last_name)
      name = Name.new('First', last_name)
      raise "invalid last name" unless name.last.length > 0 && name.first.length > 0
      @last_name = name.last
    end
    
    # Return the full name, last name first.
    def name
      "#{last_name}, #{first_name}"
    end
    
    # Player number. Any integer is valid including zero and negative numbers, as long as it's unique in the tournament.
    def num=(num)
      @num = case num
        when Fixnum then num
        else num.to_i
      end
      raise "invalid player number (#{num})" if @num == 0 && !num.to_s.match(/\d/)
    end
    
    # National or FIDE ID. Is either unknown (nil) or a positive integer.
    def id=(id)
      @id = case id
        when nil     then nil
        when Fixnum  then id
        when /^\s*$/ then nil
        else id.to_i
      end
      raise "invalid ID (#{id})" unless @id.nil? || @id > 0
    end
    
    # Federation. Is either unknown (nil) or a string containing at least three letters.
    def fed=(fed)
      @fed = fed.to_s.strip
      @fed.upcase! if @fed.length == 3
      @fed = nil if @fed == ''
      raise "invalid federation (#{fed})" unless @fed.nil? || @fed.match(/[a-z]{3}/i)
    end
    
    # Chess title. Is either unknown (nil) or one of: _GM_, _IM_, _FM_, _CM_, _NM_,
    # or any of these preceeded by the letter _W_.
    def title=(title)
      @title = title.to_s.strip.upcase
      @title << 'M' if @title.match(/[A-LN-Z]$/)
      @title = nil if @title == ''
      raise "invalid chess title (#{title})" unless @title.nil? || @title.match(/^W?[GIFCN]M$/)
    end
    
    # Rating. Is either unknown (nil) or a positive integer.
    def rating=(rating)
      @rating = case rating
        when nil     then nil
        when Fixnum  then rating
        when /^\s*$/ then nil
        else rating.to_i
      end
      raise "invalid rating (#{rating})" unless @rating.nil? || @rating > 0
    end
    
    # Rank in the tournament. Is either unknown (nil) or a positive integer. Must be unique in the tournament.
    def rank=(rank)
      @rank = case rank
        when nil     then nil
        when Fixnum  then rank
        when /^\s*$/ then nil
        else rank.to_i
      end
      raise "invalid rank (#{rank})" unless @rank.nil? || @rank > 0
    end
    
    # Date of birth. Is either unknown (nil) or a yyyy-mm-dd format date.
    def dob=(dob)
      dob = dob.to_s.strip
      @dob = dob == '' ? nil : Util.parsedate(dob)
      raise "invalid DOB (#{dob})" if @dob.nil? && dob.length > 0
    end
    
    # Gender. Is either unknown (nil) or one of _M_ or _F_.
    def gender=(gender)
      @gender = gender.to_s.strip[0,1].upcase
      @gender = nil if @gender == ''
      @gender = 'F' if @gender == 'W'
      raise "invalid gender (#{gender})" unless @gender.nil? || @gender.match(/^[MF]$/)
    end
    
    # Add a result. Use the same name method in ICU::Tournament instead.
    def add_result(result)
      raise "invalid result" unless result.class == ICU::Result
      raise "player number (#{@num}) is not matched to result player number (#{result.player})" unless @num == result.player
      raise "round number (#{result.round}) of new result should be unique" unless @results.map { |r| r.round }.grep(result.round).size == 0
      @results << result
    end
    
    # Lookup a result by round number.
    def find_result(round)
      @results.find { |r| r.round == round }
    end
    
    # Return the player's total points.
    def points
      @results.inject(0.0) { |t, r| t += r.points }
    end
    
    # Loose equality test. Passes if the names match and the federations are not different.
    def ==(other)
      return true if equal?(other)
      return false unless other.is_a? Player
      return false unless @first_name == other.first_name
      return false unless @last_name  == other.last_name
      return false if @fed && other.fed && @fed != other.fed
      true
    end
    
    # Strict equality test. Passes if the playes are loosly equal and also if their ID, rating, gender and title are not different.
    def eql?(other)
      return true if equal?(other)
      return false unless self == other
      [:id, :rating, :title, :gender].each do |m|
        return false if self.send(m) && other.send(m) && self.send(m) != other.send(m)
      end
      true
    end
    
    # Merge in some of the details of another player.
    def merge(other)
      raise "cannot merge two players that are not equal" unless self == other
      [:id, :rating, :title, :fed, :gender].each do |m|
        self.send("#{m}=", other.send(m)) unless self.send(m)
      end
    end
  end
end