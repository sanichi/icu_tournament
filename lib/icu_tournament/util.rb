module ICU
  module Util
    module Date
      # Parse dates into yyyy-mm-dd format, preferring European over US convention. Returns nil on error.
      #
      #   Date.parse('1955-11-09')       # => '1955-11-09'
      #   Date.parse('02/03/2009')       # => '2009-03-02'
      #   Date.parse('02/23/2009')       # => '2009-02-23'
      #   Date.parse('16th June 1986')   # => '1986-06-16'
      #
      # Note that the parse method of the Date class behaves differently in Ruby 1.8 and 1.9.
      # In 1.8 it assumes American dates and will raise ArgumentError on "30/03/2003".
      # In 1.9 it assumes European dates and will raise ArgumentError on "03/30/2003".
      def self.parse(date)
        date = date.to_s.strip
        return nil unless date.match(/[1-9]/)
        date = [$3].concat($2.to_i > 12 ? [$1, $2] : [$2, $1]).join('-') if date.match(/^(\d{1,2}).(\d{1,2}).(\d{4})$/)
        begin
          ::Date.parse(date, true).to_s
        rescue
          nil
        end
      end
    end

    module File
      # Read UTF data from a file.
      def self.read_utf8(name)
        ::File.open(name, "r:ASCII-8BIT") do |f|
          data = f.read
          bom = "\xEF\xBB\xBF".force_encoding("ASCII-8BIT")
          data.sub!(/^#{bom}/, "")         # get rid of a UTF-8 BOM
          ICU::Util::String.to_utf8(data)  # defined in icu_name
        end
      end

      # Load an INI file and convert to a hash.
      def self.load_ini(name)
        text = self.read_utf8(name)
        data = Hash.new
        header = nil
        text.split(/\n/).each do |line|
          if line.match(/^\s*\[([^\]]+)\]\s*$/)
            header = $1.strip
            header = nil if header == ""
          elsif header && line.match(/^([^=]+)=(.*)$/)
            key = $1.strip
            val = $2.strip
            unless key == ""
              data[header] ||= Hash.new
              data[header][key] = val
            end
          end
        end
        data
      end
    end

    # Miscellaneous accessor helpers.
    module Accessor
      def attr_accessor(name, &block)
        attr_reader name
        if block
          define_method("#{name}=") do |val|
            val = block.call(val)
            instance_variable_set("@#{name}", val)
          end
        end
      end

      def attr_integer(*names)
        names.each do |name|
          attr_accessor(name) do |val|
            tmp = val.to_i
            raise "invalid integer (#{val}) for #{name}" unless val.is_a?(Fixnum) || (val.is_a?(::String) && val.include?(tmp.to_s))
            tmp
          end
        end
      end

      def attr_integer_or_nil(*names)
        names.each do |name|
          attr_accessor(name) do |val|
            tmp = case val
              when nil      then nil
              when Fixnum   then val
              when /^\s*$/  then nil
              else val.to_i
            end
            raise "invalid integer (#{val}) for #{name}" if tmp == 0 && val.is_a?(::String) && !val.include?('0')
            tmp
          end
        end
      end

      def attr_positive(*names)
        names.each do |name|
          attr_accessor(name) do |val|
            tmp = val.to_i
            raise "invalid positive integer (#{val}) for #{name}" unless tmp > 0
            tmp
          end
        end
      end

      def attr_positive_or_nil(*names)
        names.each do |name|
          attr_accessor(name) do |val|
            tmp = case val
              when nil      then nil
              when Fixnum   then val
              when /^\s*$/  then nil
              else val.to_i
            end
            raise "invalid positive integer or nil (#{val}) for #{name}" unless tmp.nil? || tmp > 0
            tmp
          end
        end
      end

      def attr_date(*names)
        names.each do |name|
          attr_accessor(name) do |val|
            tmp = val.to_s.strip
            tmp = ICU::Util::Date::parse(tmp)
            raise "invalid date (#{val}) for #{name}" unless tmp
            tmp
          end
        end
      end

      def attr_date_or_nil(*names)
        names.each do |name|
          attr_accessor(name) do |val|
            tmp = val.to_s.strip
            if tmp == ''
              tmp = nil
            else
              tmp = ICU::Util::Date::parse(tmp)
              raise "invalid date or nil (#{val}) for #{name}" unless tmp
            end
            tmp
          end
        end
      end

      def attr_string(regex, *names)
        names.each do |name|
          attr_accessor(name) do |val|
            tmp = val.to_s.strip
            raise "invalid #{name} (#{val})" unless tmp.match(regex)
            tmp
          end
        end
      end

      def attr_string_or_nil(regex, *names)
        names.each do |name|
          attr_accessor(name) do |val|
            tmp = val.to_s.strip
            tmp = nil if tmp == ''
            raise "invalid #{name} (#{val})" unless tmp.nil? || tmp.match(regex)
            tmp
          end
        end
      end
    end
  end
end