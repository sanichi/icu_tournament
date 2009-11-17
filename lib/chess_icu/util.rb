module ICU
  class Util

=begin rdoc

== Loading the best CSV parser

For Ruby 1.8.7 the CSV parser used here was FasterCSV (in preference to CSV from the standard library).
From Ruby 1.9.1, the standard CSV is replaced by an updated version of FasterCSV while the old
FasterCSV remains incompatible with the new Ruby. ICU::Util::CSV is therefore set to whichever
class is the right one for the version of Ruby being used.

== Parsing dates

Parse dates into yyyy-mm-dd format, preferring European over US convention. Returns nil on error.

  Util.parsedate('1955-11-09')       # => '1955-11-09'
  Util.parsedate('02/03/2009')       # => '2009-03-02'
  Util.parsedate('02/23/2009')       # => '2009-02-23'
  Util.parsedate('16th June 1986')   # => '1986-06-16'

Note that the parse method of the Date class behaves differently in Ruby 1.8.7 and 1.9.1.
In 1.8.7 it assumes American dates and will raise ArgumentError on "30/03/2003".
In 1.9.1 it assumes European dates and will raise ArgumentError on "03/30/2003".

=end

    if RUBY_VERSION > '1.9'
      require 'csv'
      CSV = ::CSV
    else
      require 'fastercsv'
      CSV = ::FasterCSV
    end

    def self.parsedate(date)
      date = date.to_s.strip
      return nil unless date.match(/[1-9]/)
      date = [$3].concat($2.to_i > 12 ? [$1, $2] : [$2, $1]).join('-') if date.match(/^(\d{1,2}).(\d{1,2}).(\d{4})$/)
      begin
        Date.parse(date, true).to_s
      rescue
        nil
      end
    end
  end
  
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
          raise "invalid integer (#{val}) for #{name}" unless val.is_a?(Fixnum) || (val.is_a?(String) && val.include?(tmp.to_s))
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
          raise "invalid integer (#{val}) for #{name}" if tmp == 0 && val.is_a?(String) && !val.include?('0')
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
          tmp = ICU::Util::parsedate(tmp)
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
            tmp = ICU::Util::parsedate(tmp)
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