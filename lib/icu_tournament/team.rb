module ICU

=begin rdoc

== Team

A team consists of a name and one or more players referenced by numbers.
Typically the team will be attached to a tournament (ICU::Tournament)
and the numbers will the unique numbers by which the players in that
tournament are referenced. To instantiate a team, you must supply a
name.

  team = ICU::Team.new('Wandering Dragons')

Then you simply add player's (numbers) to it.

  team.add_player(1)
  team.add_payeer(3)
  team.add_player(7)

To get the current members of a team

  team.members                                 # => [1, 3, 7]

You can enquire whether a team contains a given player number.

  team.contains?(3)                            # => true
  team.contains?(4)                            # => false

Or whether it matches a given name (which ignoring case and removing spurious whitespace)
  
  team.matches(' wandering  dragons  ')        # => true
  team.matches('Blundering Bishops')           # => false

Whenever you reset the name of a tournament spurious whitespace is removed but case is not altered.

  team.name = '  blundering  bishops  '
  team.name                                    # => "blundering bishops"

Attempting to add non-numbers or duplicate numbers as new team members results in an exception.

  team.add(nil)                                # exception - not a number
  team.add(3)                                  # exception - already a member

=end

  class Team

    attr_reader :name, :members
    
    # Constructor. Name must be supplied.
    def initialize(name)
      self.name = name
      @members = Array.new
    end
    
    # Set name. Must not be blank.
    def name=(name)
      @name = name.strip.squeeze(' ')
      raise "team can't be blank" if @name.length == 0
    end
    
    # Add a team member referenced by any integer.
    def add_member(number)
      pnum = number.to_i
      raise "'#{number}' is not a valid as a team member player number" if pnum == 0 && !number.to_s.match(/^[^\d]*0/)
      raise "can't add duplicate player number #{pnum} to team '#{@name}'" if @members.include?(pnum)
      @members.push(pnum)
    end
    
    # Renumber the players according to the supplied hash. Return self.
    def renumber(map)
      @members.each_with_index do |pnum, index|
        raise "player number #{pnum} not found in renumbering hash" unless map[pnum]
        @members[index] = map[pnum]
      end
      self
    end
    
    # Detect if a member exists in a team.
    def include?(number)
      @members.include?(number)
    end
    
    # Does the team name match the given string (ignoring case and spurious whitespace).
    def matches(name)
      self.name.downcase == name.strip.squeeze(' ').downcase
    end
  end
end