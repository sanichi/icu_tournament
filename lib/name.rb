module ICU

=begin rdoc

== Names

This class exists for two main reasons:

* to normalise to a common format the different ways names are typed in practice
* to be able to match two names even if they are not exactly the same

To create a name object, supply both the first and second names separately to the constructor.

  robert = ICU::Name.new(' robert  j ', ' FISHER ')

Capitalisation, white space and punctuation will all be automatically corrected:

  robert.name                                    # => 'Robert J. Fischer'
  robert.rname                                   # => 'Fischer, Robert J.'  (reversed name)

To avoid ambiguity when either the first or second names consist of multiple words, it is better to
supply the two separately, if known. However, the full name can be supplied alone to the constructor
and a guess will be made as to the first and last names.

  bobby = ICU::Name.new(' bobby fischer ')
  
  bobby.first                                    # => 'Bobby'
  bobby.last                                     # => 'Fischer'

Names will match even if one is missing middle initials or if a nickname is used for one of the first names.

  bobby.match(robert)                            # =>  true

Note that the class is aware of only common nicknames (e.g. _Bobby_ and _Robert_, _Bill_ and _William_, etc), not all possibilities.

Supplying the _match_ method with strings is equivalent to instantiating a Name instance with the same
strings and then matching it. So, for example the following are equivalent:

  robert.match('R. J.', 'Fischer')               # => true
  robert.match(ICU::Name('R. J.', 'Fischer'))    # => true

In those examples, the inital _R_ matches the first letter of _Robert_. However, nickname matches will not
always work with initials. In the next example, the initial _R_ does not match the first letter _B_ of the
nickname _Bobby_.

  bobby.match('R. J.', 'Fischer')                # => false

Some of the ways last names are canonicalised are illustrated below:

  ICU::Name.new('John', 'O Reilly').last         # => "O'Reilly"
  ICU::Name.new('dave', 'mcmanus').last          # => "McManus"
  ICU::Name.new('pete', 'MACMANUS').last         # => "MacManus"
  
=end

  class Name
    attr_reader :first, :last
    
    def initialize(name1='', name2='')
      @name1 = name1.to_s
      @name2 = name2.to_s
      canonicalize
    end
    
    def name
      name = @first
      name << ' ' if @first.length > 0 && @last.length > 0
      name << @last
      name
    end
    
    def rname
      name = @last
      name << ', ' if @first.length > 0 && @last.length > 0
      name << @first
      name
    end
    
    def to_s
      rname
    end
    
    def match(name1='', name2='')
      other = Name.new(name1, name2)
      match_first(first, other.first) && match_last(last, other.last)
    end
    
    private
    
    def canonicalize
      first, last = partition
      @first = finish_first(first)
      @last  = finish_last(last)
    end
    
    def partition
      if @name2.length == 0
        # Only one imput so we must split first and last.
        parts = @name1.split(/,/)
        if parts.size > 1
          last  = clean(parts.shift || '')
          first = clean(parts.join(' '))
        else
          parts = clean(@name1).split(/ /)
          last  = parts.pop || ''
          first = parts.join(' ')
        end
      else
        # Two inputs, so we are given first and last.
        first = clean(@name1)
        last  = clean(@name2)
      end
      [first, last]
    end
        
    def clean(name)
      name.gsub!(/`/, "'")
      name.gsub!(/[^-a-zA-Z.'\s]/, '')
      name.gsub!(/\./, ' ')
      name.gsub!(/\s*-\s*/, '-')
      name.gsub!(/'+/, "'")
      name.strip.downcase.split(/\s+/).map do |n|
        n.sub!(/^-+/, '')
        n.sub!(/-+$/, '')
        n.split(/-/).map do |p|
          p.capitalize!
        end.join('-')
      end.join(' ')
    end
    
    def finish_first(names)
      names.gsub(/([A-Z])\b/, '\1.')
    end
    
    def finish_last(names)
      names.gsub!(/\b([A-Z])'([a-z])/) { |m| $1 << "'" << $2.upcase}
      names.gsub!(/\bMc([a-z])/) { |m| 'Mc' << $1.upcase}
      names.gsub!(/\bMac([a-z])/) do |m|
        letter = $1
        'Mac'.concat(@name2.match("[mM][aA][cC]#{letter}") ? letter : letter.upcase)
      end
      names.gsub!(/\bO ([A-Z])/) { |m| "O'" << $1 }
      names
    end
    
    # Match a complete first name.
    def match_first(first1, first2)
      # Is this one a walk in the park?
      return true if first1 == first2
      
      # No easy ride. Begin by splitting into individual first names.
      first1 = split_first(first1)
      first2 = split_first(first2)
      
      # Get the long list and the short list.
      long, short = first1.size >= first2.size ? [first1, first2] : [first2, first1]
      
      # The short one must be a "subset" of the long one.
      # An extra condition must also be satisfied.
      extra = false
      (0..long.size-1).each do |i|
        lword = long.shift
        score = match_first_name(lword, short.first)
        if score >= 0
          short.shift
          extra = true if i == 0 || score == 0
        end
        break if short.empty? || long.empty?
      end
      
      # There's a match if the following is true.
      short.empty? && extra
    end
    
    # Match a complete last name.
    def match_last(last1, last2)
      return true if last1 == last2
      [last1, last2].each do |last|
        last.downcase!             # MacDonaugh and Macdonaugh
        last.gsub!(/\bmac/, 'mc')  # MacDonaugh and McDonaugh
        last.tr!('-', ' ')         # Lowry-O'Reilly and Lowry O'Reilly
      end
      last1 == last2
    end
    
    # Split a complete first name for matching.
    def split_first(first)
      first.tr!('-', ' ')              # J. K. and J.-K.
      first = first.split(/ /)         # split on spaces
      first = [''] if first.size == 0  # in case input was empty string
      first
    end
    
    # Match individual first names or initials.
    # -1 = no match
    #  0 = full match
    #  1 = match involving 1 initial
    #  2 = match involving 2 initials
    def match_first_name(first1, first2)
      initials = 0
      initials+= 1 if first1.match(/^[A-Z]\.?$/)
      initials+= 1 if first2.match(/^[A-Z]\.?$/)
      return initials if first1 == first2
      return 0 if initials == 0 && match_nick_name(first1, first2)
      return -1 unless initials > 0
      return initials if first1[0] == first2[0]
      -1
    end
    
    # Match two first names that might be equivalent nicknames.
    def match_nick_name(nick1, nick2)
      compile_nick_names unless @@nc
      code1 = @@nc[nick1]
      return false unless code1
      code1 == @@nc[nick2]
    end
    
    # Compile the nick names code hash when matching nick names is first attempted.
    def compile_nick_names
      @@nc = Hash.new
      code = 1
      @@nl.each do |nicks|
        nicks.each do |n|
          throw "duplicate name #{n}" if @@nc[n]
          @@nc[n] = code
        end
        code+= 1
      end
    end
    
    # A array of data for matching nicknames and also a few common misspellings.
    @@nc = nil
    @@nl = <<EOF.split(/\n/).reject{|x| x.length == 0 }.map{|x| x.split(' ')}
Abdul Abul
Alexander Alex
Anandagopal Ananda
Anne Ann
Anthony Tony
Benjamin Ben
Catherine Cathy Cath
Daniel Danial Danny Dan
David Dave
Deborah Debbie
Des Desmond
Eamonn Eamon
Edward Eddie Ed
Eric Erick Erik
Frederick Frederic Fred
Gerald Gerry
Gerhard Gerard Ger
James Jim
Joanna Joan Joanne
John Johnny
Jonathan Jon
Kenneth Ken Kenny
Michael Mike Mick Micky
Nicholas Nick Nicolas
Nicola Nickie Nicky
Patrick Pat Paddy
Peter Pete
Philippe Philip Phillippe Phillip
Rick Ricky
Robert Bob Bobby
Samual Sam Samuel
Stefanie Stef
Stephen Steven Steve
Terence Terry
Thomas Tom Tommy
William Will Willy Willie Bill
EOF
  end
end
