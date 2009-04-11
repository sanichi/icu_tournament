module ICU
  class Util
    # Parse dates into yyyy-mm-dd format, preferring European format. Return nil on error.
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