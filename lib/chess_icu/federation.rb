module ICU

=begin rdoc

== Federations

This class can be used to map a string into an object representing a chess federation.
In FIDE, chess federations are generally either referred to by their full names such as
_Ireland_ or _Russia_ or by three letter codes such as _IRL_ or _RUS_. The three letter
codes are mostly the same as those found in the international standard known as
{ISO 3166-1 alpha-3}[http://en.wikipedia.org/wiki/ISO_3166-1_alpha-3], but with
some differences (e.g. for England, Scotland and Wales).

You cannot directly create instances of this class using _new_. Instead, you supply
a string to the class method _find_ and, if the string supplied uniguely identifies a
federation, an instance is returned which responds to _name_ and _code_.

  fed = ICU::Federation.find('IRL')
  fed.name                                           # => "Ireland"
  fed.code                                           # => "IRL"

If the string is not sufficient to identify a federation, the _find_ method returns _nil_.

  fed = ICU::Federation.find('ZYX')                  # => nil

If the string is three letters long and matches (case insenstively) one of the unique
federation codes, then the instance corresponding to that federation is returned.

  ICU::Federation.find('rUs').code                   # => "RUS"

If the string is more than three letters long and if it is a substring (case insensitive)
of exactly one federation name, then that federation is returned.

  ICU::Federation.find('ongoli').name                # => "Mongolia"

In all other cases, nil is returned. In the following example, the string matches more than one federation.

  ICU::Federation.find('land')                       # => nil

The method is not fooled by irrelevant white space.

  ICU::Federation.find('  united   states   ').code  # => 'USA'

The class method _menu_ will return an array of two-element arrays each of which contain a name
and a code.

  ICU::Federation.menu                               # => [['Afghanistan', 'AFG'], ['Albania', 'ALB], ...]

Such an array could be used, for example, as the basis of a selection menu in a web application.
Various options are available to alter the array returned. Use the _:order_ option to order by code
instead of the default (by country name).

  ICU::Federation.menu(:order => 'code')             # => [..., ['Ireland', 'IRL'], ['Iraq', 'IRQ], ...]

To put one country at the top (followed by the rest, in order) supply the country's code with the _:top_ option:
  
  ICU::Federation.menu(:top => 'IRL')                # => [['Ireland', 'IRL'], ['Afghanistan', 'AFG], ...]

To supply an extra "None" item at the top, specify its label with the _:none_ option:
  
  ICU::Federation.menu(:none => 'None')              # => [['None', ''], ['Afghanistan', 'AFG], ...]

The "None" option's code is the empty string and it come above the "top" option if both are specified.

=end

  class Federation
    attr_reader :code, :name
    private_class_method :new
    
    # Given a code, name or part of a name, return the corresponding federation instance.
    # If there is no match or more than one match, _nil_ is returned.
    def self.find(str=nil)
      return nil unless str
      str = str.to_s
      return nil if str.length < 3
      compile unless @@objects
      str = str.strip.squeeze(' ').downcase
      return @@codes[str] if str.length == 3
      return @@names[str] if @@names[str]
      matches = Array.new
      @@names.each_key do |name|
        matches << @@names[name] if name.index(str)
      end
      matches.uniq!
      return nil unless matches.length == 1
      matches[0]
    end
    
    def self.menu(opts = {})
      compile unless @@objects;
      top, menu = nil, []
      @@objects.each {|o| opts[:top] == o.code ? top = [o.name, o.code] : menu.push([o.name, o.code]) }
      opts[:order] == 'code' ? menu.sort!{|a,b| a.last <=> b.last} : menu.sort!{|a,b| a.first <=> b.first}
      menu.unshift(top) if top
      menu.unshift([opts[:none], '']) if opts[:none]
      menu
    end
    
    def initialize(code, name) # :nodoc: because new is private
      @code = code
      @name = name
    end
    
    private
    
    def self.compile
      return if @@objects
      @@names = Hash.new
      @@codes = Hash.new
      @@objects = Array.new
      @@data.each do |d|
        object = new(d[0], d[1])
        @@objects << object
        @@codes[d[0].downcase] = object
        (1..d.length-1).each do |i|
          @@names[d[i].downcase] = object
        end
      end
    end
    
    # The data structures compiled.
    @@objects, @@codes, @@names = nil, nil, nil
    
    # An array of data that gets compiled into other data structures.
    @@data =
    [
      ['AFG', 'Afghanistan'],
      ['ALB', 'Albania'],
      ['ALG', 'Algeria'],
      ['AND', 'Andorra'],
      ['ANG', 'Angola'],
      ['ANT', 'Antigua'],
      ['ARG', 'Argentina'],
      ['ARM', 'Armenia'],
      ['ARU', 'Aruba'],
      ['AUS', 'Australia'],
      ['AUT', 'Austria'],
      ['AZE', 'Azerbaijan'],
      ['BAH', 'Bahamas'],
      ['BRN', 'Bahrain'],
      ['BAN', 'Bangladesh'],
      ['BAR', 'Barbados'],
      ['BLR', 'Belarus'],
      ['BEL', 'Belgium'],
      ['BIZ', 'Belize'],
      ['BEN', 'Benin Republic'],
      ['BER', 'Bermuda'],
      ['BHU', 'Bhutan'],
      ['BOL', 'Bolivia'],
      ['BIH', 'Bosnia and Herzegovina'],
      ['BOT', 'Botswana'],
      ['BRA', 'Brazil'],
      ['IVB', 'British Virgin Islands'],
      ['BRU', 'Brunei Darussalam'],
      ['BUL', 'Bulgaria'],
      ['BUR', 'Burkina Faso'],
      ['BDI', 'Burundi'],
      ['CAM', 'Cambodia'],
      ['CMR', 'Cameroon'],
      ['CAN', 'Canada'],
      ['CHA', 'Chad'],
      ['CHI', 'Chile'],
      ['CHN', 'China'],
      ['TPE', 'Chinese Taipei'],
      ['COL', 'Colombia'],
      ['CRC', 'Costa Rica'],
      ['CRO', 'Croatia'],
      ['CUB', 'Cuba'],
      ['CYP', 'Cyprus'],
      ['CZE', 'Czech Republic'],
      ['DEN', 'Denmark'],
      ['DJI', 'Djibouti'],
      ['DOM', 'Dominican Republic'],
      ['ECU', 'Ecuador'],
      ['EGY', 'Egypt'],
      ['ESA', 'El Salvador'],
      ['ENG', 'England'],
      ['EST', 'Estonia'],
      ['ETH', 'Ethiopia'],
      ['FAI', 'Faroe Islands'],
      ['FIJ', 'Fiji'],
      ['FIN', 'Finland'],
      ['FRA', 'France'],
      ['GAB', 'Gabon'],
      ['GAM', 'Gambia'],
      ['GEO', 'Georgia'],
      ['GER', 'Germany'],
      ['GHA', 'Ghana'],
      ['GRE', 'Greece'],
      ['GUA', 'Guatemala'],
      ['GCI', 'Guernsey'],
      ['GUY', 'Guyana'],
      ['HAI', 'Haiti'],
      ['HON', 'Honduras'],
      ['HKG', 'Hong Kong'],
      ['HUN', 'Hungary'],
      ['ISL', 'Iceland'],
      ['IND', 'India'],
      ['INA', 'Indonesia'],
      ['IRI', 'Iran'],
      ['IRQ', 'Iraq'],
      ['IRL', 'Ireland'],
      ['ISR', 'Israel'],
      ['ITA', 'Italy'],
      ['CIV', 'Ivory Coast'],
      ['JAM', 'Jamaica'],
      ['JPN', 'Japan'],
      ['JCI', 'Jersey'],
      ['JOR', 'Jordan'],
      ['KAZ', 'Kazakhstan'],
      ['KEN', 'Kenya'],
      ['KUW', 'Kuwait'],
      ['KGZ', 'Kyrgyzstan'],
      ['LAT', 'Latvia'],
      ['LIB', 'Lebanon'],
      ['LBA', 'Libya'],
      ['LIE', 'Liechtenstein'],
      ['LTU', 'Lithuania'],
      ['LUX', 'Luxembourg'],
      ['MAC', 'Macau'],
      ['MKD', 'Macedonia', 'Former YUG Rep of Macedonia', 'Former Yugoslav Republic of Macedonia', 'FYROM'],
      ['MAD', 'Madagascar'],
      ['MAW', 'Malawi'],
      ['MAS', 'Malaysia'],
      ['MDV', 'Maldives'],
      ['MLI', 'Mali'],
      ['MLT', 'Malta'],
      ['MAU', 'Mauritania'],
      ['MRI', 'Mauritius'],
      ['MEX', 'Mexico'],
      ['MDA', 'Moldova'],
      ['MNC', 'Monaco'],
      ['MGL', 'Mongolia'],
      ['MNE', 'Montenegro'],
      ['MAR', 'Morocco'],
      ['MOZ', 'Mozambique'],
      ['MYA', 'Myanmar'],
      ['NAM', 'Namibia'],
      ['NEP', 'Nepal'],
      ['NED', 'Netherlands'],
      ['AHO', 'Netherlands Antilles'],
      ['NZL', 'New Zealand'],
      ['NCA', 'Nicaragua'],
      ['NGR', 'Nigeria'],
      ['NOR', 'Norway'],
      ['PAK', 'Pakistan'],
      ['PLW', 'Palau'],
      ['PLE', 'Palestine'],
      ['PAN', 'Panama'],
      ['PNG', 'Papua New Guinea'],
      ['PAR', 'Paraguay'],
      ['PER', 'Peru'],
      ['PHI', 'Philippines'],
      ['POL', 'Poland'],
      ['POR', 'Portugal'],
      ['PUR', 'Puerto Rico'],
      ['QAT', 'Qatar'],
      ['ROU', 'Romania'],
      ['RUS', 'Russia'],
      ['RWA', 'Rwanda'],
      ['SMR', 'San Marino'],
      ['STP', 'Sao Tome and Principe'],
      ['SCO', 'Scotland'],
      ['SEN', 'Senegal'],
      ['SRB', 'Serbia'],
      ['SEY', 'Seychelles'],
      ['SIN', 'Singapore'],
      ['SVK', 'Slovakia'],
      ['SLO', 'Slovenia'],
      ['SOM', 'Somalia'],
      ['RSA', 'South Africa'],
      ['KOR', 'South Korea'],
      ['ESP', 'Spain'],
      ['SRI', 'Sri Lanka'],
      ['SUD', 'Sudan'],
      ['SUR', 'Surinam'],
      ['SWE', 'Sweden'],
      ['SUI', 'Switzerland'],
      ['SYR', 'Syria'],
      ['TJK', 'Tajikistan'],
      ['TAN', 'Tanzania'],
      ['THA', 'Thailand'],
      ['TRI', 'Trinidad and Tobago'],
      ['TUN', 'Tunisia'],
      ['TUR', 'Turkey'],
      ['TKM', 'Turkmenistan'],
      ['UGA', 'Uganda'],
      ['UKR', 'Ukraine'],
      ['UAE', 'United Arab Emirates'],
      ['USA', 'United States of America'],
      ['URU', 'Uruguay'],
      ['ISV', 'US Virgin Islands'],
      ['UZB', 'Uzbekistan'],
      ['VEN', 'Venezuela'],
      ['VIE', 'Vietnam'],
      ['WLS', 'Wales'],
      ['YEM', 'Yemen'],
      ['ZAM', 'Zambia'],
      ['ZIM', 'Zimbabwe'],
    ]
  end
end
