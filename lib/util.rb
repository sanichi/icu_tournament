module ICU
  class Util

=begin rdoc

Parse dates into yyyy-mm-dd format, preferring European over US convention. Return nil on error.

  Util.parsedate('1955-11-09')       # => '1955-11-09'
  Util.parsedate('02/03/2009')       # => '2009-03-02'
  Util.parsedate('02/23/2009')       # => '2009-02-23'
  Util.parsedate('16th June 1986')   # => '1986-06-16'

=end

    def self.parsedate(date)
      date = date.to_s
      return nil unless date.match(/[1-9]/)
      date.sub!(/^([1-9]|0[1-9]|[12][0-9]|3[01])([^\d])([1-9]|0[1-9]|1[0-2])([^\d])/, '\3\2\1\4')
      begin
        Date.parse(date, true).to_s
      rescue
        return nil
      end
    end
  end
end