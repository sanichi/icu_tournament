module ICU
  #
  # This class is used to recognise the names of tie break rules. The class method _identify_
  # takes a string as it's only argument and returns a new intstance if it recognises a
  # tie break rule from the string, or _nil_ otherwise. An instance has three read-only methods:
  # _id_ (a shoet symbolic name), _code_ (a two letter code) and _name_ (the full name).
  # For example:
  #
  #   ICU::TieBreak.identify("no such rule")           # => nil
  #   tb = ICU::TieBreak.identify("Neustadlt")
  #   tb.id                                            # => :neustadtl
  #   tb.code                                          # => "SB"
  #   tb.name                                          # => "Sonneborn-Berger"
  #
  # The method is case insensitive and can cope with extraneous white space and,
  # to a limited extent, name variations and spelling mistakes:
  #
  #   ICU::TieBreak.identify("SB").name                # => "Sonneborn-Berger"
  #   ICU::TieBreak.identify("NESTADL").name           # => "Sonneborn-Berger"
  #   ICU::TieBreak.identify(" wins ").name            # => "Number of wins"
  #   ICU::TieBreak.identify(:sum_ratings).name        # => "Sum of opponent's ratings"
  #   ICU::TieBreak.identify("median").name            # => "Harkness"
  #   ICU::TieBreak.identify("MODIFIED").name          # => "Modified median"
  #   ICU::TieBreak.identify("Modified\nMedian").name  # => "Modified median"
  #   ICU::TieBreak.identify("\tbuccholts\t").name     # => "Buchholz"
  #   ICU::TieBreak.identify("progressive\r\n").name   # => "Sum of progressive scores"
  #   ICU::TieBreak.identify("SumOfCumulative").name   # => "Sum of progressive scores"
  #
  # The full list of supported tie break rules is:
  #
  # * Buchholz (:buchholz, "BH"): sum of opponents' scores
  # * Harkness (:harkness, "HK"): like Buchholz except the highest and lowest opponents' scores are discarded (or two highest and lowest if 9 rounds or more)
  # * Modified median (:modified_median, "MM"): same as Harkness except only lowest (or highest) score(s) are discarded for players with more (or less) than 50%
  # * Number of blacks (:blacks, "NB") number of blacks
  # * Number of wins (:wins, "NW") number of wins
  # * Player's name (:name, "PN"): alphabetical by name
  # * Sonneborn-Berger (:neustadtl, "SB"): sum of scores of players defeated plus half sum of scores of players drawn against
  # * Sum of opponents' ratings (:ratings, "SR"): sum of opponents ratings (FIDE ratings are used in preference to local ratings if available)
  # * Sum of progressive scores (:progressive, "SP"): sum of running score for each round
  #
  # An array of all supported TieBreak instances (ordered by name) is returned by the class method _rules_.
  #
  #   rules = ICU::TieBreak.rules
  #   rules.size                                       # => 9
  #   rules.first.name                                 # => "Buchholz"
  #
  # Note that this class only deals with the recognition of tie break names, not the calculation of tie break scores.
  # The latter is currently implemented in the ICU::Tournament class.
  #
  class TieBreak
    attr_reader :id, :code, :name
    private_class_method :new
    
    RULES =
    {
      :blacks          => ["NB", "Number of blacks",          %r{(number[-_ ]?of[-_ ])?blacks?}],
      :buchholz        => ["BH", "Buchholz",                  %r{^buc{1,2}h{1,2}olt?[zs]}],
      :harkness        => ["HK", "Harkness",                  %r{^(harkness?|median)$}],
      :modified_median => ["MM", "Modified median",           %r{^modified([-_ ]?median)?$}],
      :name            => ["PN", "Player's name",             %r{^(player('?s)?[-_ ]?)?name$}],
      :neustadtl       => ["SB", "Sonneborn-Berger",          %r{^(sonn?eborn[-_ ]?berger|n[eu]{1,2}sta[dtl]{2,3})}],
      :progressive     => ["SP", "Sum of progressive scores", %r{^(sum[-_ ]?(of[-_ ]?)?)?(progressive|cumulative)([-_ ]?scores?)?}],
      :ratings         => ["SR", "Sum of opponent's ratings", %r{(sum[-_ ]?(of[-_ ]?)?)?(opponents'?[-_ ]?)?ratings}],
      :wins            => ["NW", "Number of wins",            %r{(number[-_ ]?of[-_ ])?wins?}],
    }

    # Given a string, return the TieBreak rule it is recognised as, or return nil.
    def self.identify(str)
      return nil unless str
      str = str.to_s.gsub(/\s+/, ' ').strip.downcase
      return nil if str.length <= 1 || str.length == 3
      RULES.each_pair { |id, rule| return new(id, rule[0], rule[1]) if str.upcase == rule[0] || str.match(rule[2]) }
      nil
    end

    # Return an array of all tie break rules, ordered by name.
    def self.rules
      RULES.keys.sort_by{ |id| RULES[id][1] }.inject([]) do |rules, id|
        rules << new(id, RULES[id][0], RULES[id][1])
      end
    end

    # :enddoc:
    private

    def initialize(id, code, name)
      @id   = id
      @code = code
      @name = name
    end
  end
end
