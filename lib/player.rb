module ICU
  class Player
    attr_accessor :first_name, :last_name, :num, :id, :fed, :title, :rating, :rank, :dob
    attr_reader :results
    
    def initialize(first_name, last_name, num, opt={})
      self.first_name = first_name
      self.last_name  = last_name
      self.num        = num
      [:id, :fed, :title, :rating, :rank, :dob].each do |atr|
        self.send("#{atr}=", opt[atr]) unless opt[atr].nil?
      end
      @results = []
    end
    
    def first_name=(first_name)
      name = Name.new(first_name, 'Last')
      raise "invalid first name" unless name.first.length > 0
      @first_name = name.first
    end
    
    def last_name=(last_name)
      name = Name.new('First', last_name)
      raise "invalid last name" unless name.last.length > 0 && name.first.length > 0
      @last_name = name.last
    end
    
    def name
      "#{last_name}, #{first_name}"
    end
    
    # Player number. Any integer.
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
    
    # Federation. Is either unknown (nil) or contains at least three letters.
    def fed=(fed)
      @fed = fed.to_s.strip
      @fed.upcase! if @fed.length == 3
      @fed = nil if @fed == ''
      raise "invalid federation (#{fed})" unless @fed.nil? || @fed.match(/[a-z]{3}/i)
    end
    
    # Chess title. Is either unknown (nil) or one of a set of possibilities (after a little cleaning up).
    def title=(title)
      @title = title.to_s.strip.upcase
      @title << 'M' if @title.match(/[A-LN-Z]$/)
      @title = nil if @title == ''
      raise "invalid chess title (#{title})" unless @title.nil? || @title.match(/^W?[GIFCN]M$/)
    end
    
    # Elo rating. Is either unknown (nil) or a positive integer.
    def rating=(rating)
      @rating = case rating
        when nil     then nil
        when Fixnum  then rating
        when /^\s*$/ then nil
        else rating.to_i
      end
      raise "invalid rating (#{rating})" unless @rating.nil? || @rating > 0
    end
    
    # Rank in the tournament. Is either unknown (nil) or a positive integer.
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
    
    # Add a result.
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
    
    # Loose equality test.
    def ==(other)
      return true if equal?(other)
      return false unless other.is_a? Player
      return false unless @first_name == other.first_name
      return false unless @last_name  == other.last_name
      return false if @fed && other.fed && @fed != other.fed
      true
    end
    
    # Strict equality test.
    def eql?(other)
      return true if equal?(other)
      return false unless self == other
      [:id, :rating, :title].each do |m|
        return false if self.send(m) && other.send(m) && self.send(m) != other.send(m)
      end
      true
    end
    
    # Merge in some of the details of another player.
    def subsume(other)
      raise "cannot merge two players that are not strictly equal" unless eql?(other)
      [:id, :rating, :title, :fed].each do |m|
        self.send("#{m}=", other.send(m)) if other.send(m)
      end
    end
  end
end