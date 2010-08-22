require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

module ICU
  describe Util do
    context "#parsedate" do
      it "should parse standard dates" do
        Util.parsedate('2001-01-01').should == '2001-01-01'
        Util.parsedate('1955-11-09').should == '1955-11-09'
      end

      it "should handle US format" do
        Util.parsedate('03/30/2009').should == '2009-03-30'
      end

      it "should handle European format" do
        Util.parsedate('30/03/2009').should == '2009-03-30'
      end

      it "should prefer European format" do
        Util.parsedate('02/03/2009').should == '2009-03-02'
      end

      it "should handle US style when there's no alternative" do
        Util.parsedate('02/23/2009').should == '2009-02-23'
      end

      it "should handle single digits" do
        Util.parsedate('9/8/2006').should == '2006-08-09'
      end

      it "should handle names of monthsx" do
        Util.parsedate('9th Nov 1955').should == '1955-11-09'
        Util.parsedate('16th June 1986').should == '1986-06-16'
      end
    end
  end

  describe Accessor do
    context "#attr_accessor" do
      before(:each) do
        @class = Class.new
        @class.extend ICU::Accessor
        @obj = @class.new
      end

      it "should not have an accessor unless declared" do
        @obj.respond_to?(:myatr).should be_false
        @obj.respond_to?(:myatr=).should be_false
      end

      it "should have a getter but no setter with the default declaration" do
        @class.attr_accessor('myatr')
        @obj.respond_to?(:myatr).should be_true
        @obj.respond_to?(:myatr=).should be_false
        @obj.instance_eval { @myatr = 42 }
        @obj.myatr.should == 42
      end

      it "should be able to create do-it-yourself setters such as for a positive integer" do
        @class.attr_accessor('myatr') do |val|
          tmp = val.to_i
          raise "invalid positive integer (#{val})" unless tmp > 0
          tmp
        end
        @obj.respond_to?(:myatr).should be_true
        @obj.respond_to?(:myatr=).should be_true
        lambda { @obj.myatr = "no number here" }.should raise_error(/invalid positive integer \(no number here\)/)
        lambda { @obj.myatr = -1 }.should raise_error
        lambda { @obj.myatr = 0 }.should raise_error
        lambda { @obj.myatr = 1 }.should_not raise_error
        @obj.myatr.should == 1
        lambda { @obj.myatr = '42' }.should_not raise_error
        @obj.myatr.should == 42
        lambda { @obj.myatr = '  0371  ' }.should_not raise_error
        @obj.myatr.should == 371
      end
    end

    context "#attr_integer" do
      before(:each) do
        @class = Class.new
        @class.extend ICU::Accessor
        @class.attr_integer :myint
        @obj = @class.new
      end

      it "should have a getter and setter" do
        @obj.respond_to?(:myint).should be_true
        @obj.respond_to?(:myint=).should be_true
      end

      it "should work with ints" do
        @obj.myint = -43
        @obj.myint.should == -43
      end

      it "should work with strings" do
        @obj.myint = "  -99 "
        @obj.myint.should == -99
      end

      it "should handle zero" do
        lambda { @obj.myint = 0 }.should_not raise_error
        lambda { @obj.myint = '0' }.should_not raise_error
      end

      it "should reject nil and other non-numbers" do
        lambda { @obj.myint = nil }.should raise_error(/invalid/)
        lambda { @obj.myint = "N" }.should raise_error(/invalid/)
        lambda { @obj.myint = " " }.should raise_error(/invalid/)
        lambda { @obj.myint = ''  }.should raise_error(/invalid/)
      end

      it "should handle multiple names" do
        @class.attr_integer :yourint, :hisint
        @obj.respond_to?(:yourint).should be_true
        @obj.respond_to?(:hisint=).should be_true
      end
    end
    
    context "#attr_integer_or_nil" do
      before(:each) do
        @class = Class.new
        @class.extend ICU::Accessor
        @class.attr_integer_or_nil :myint
        @obj = @class.new
      end

      it "should have a getter and setter" do
        @obj.respond_to?(:myint).should be_true
        @obj.respond_to?(:myint=).should be_true
      end

      it "should work with ints and nil and spaces" do
        @obj.myint = 43
        @obj.myint.should == 43
        @obj.myint = nil
        @obj.myint.should == nil
        @obj.myint = '  '
        @obj.myint.should == nil
      end

      it "should reject non-numbers" do
        lambda { @obj.myint = "N" }.should raise_error(/invalid/)
      end

      it "should handle multiple names" do
        @class.attr_integer :yourint, :hisint
        @obj.respond_to?(:yourint).should be_true
        @obj.respond_to?(:hisint=).should be_true
      end
    end

    context "#attr_positive" do
      before(:each) do
        @class = Class.new
        @class.extend ICU::Accessor
        @class.attr_positive :mypos
        @obj = @class.new
      end

      it "should have a getter and setter" do
        @obj.respond_to?(:mypos).should be_true
        @obj.respond_to?(:mypos=).should be_true
      end

      it "should work as expected" do
        @obj.mypos = "34"
        @obj.mypos.should == 34
      end

      it "should reject nil and other non-positive integers" do
        lambda { @obj.mypos = nil }.should raise_error(/invalid/)
        lambda { @obj.mypos = 'X' }.should raise_error(/invalid/)
        lambda { @obj.mypos = '0' }.should raise_error(/invalid/)
        lambda { @obj.mypos = -13 }.should raise_error(/invalid/)
      end

      it "should handle multiple names" do
        @class.attr_integer :ourpos, :theirpos
        @obj.respond_to?(:ourpos).should be_true
        @obj.respond_to?(:theirpos=).should be_true
      end
    end
    
    context "#attr_positive_or_nil" do
      before(:each) do
        @class = Class.new
        @class.extend ICU::Accessor
        @class.attr_positive_or_nil :mypon
        @obj = @class.new
      end

      it "should have a getter and setter" do
        @obj.respond_to?(:mypon).should be_true
        @obj.respond_to?(:mypon=).should be_true
      end

      it "should work with numbers, nil, empty strings and spaces" do
        @obj.mypon = " 54 "
        @obj.mypon.should == 54
        @obj.mypon = nil
        @obj.mypon.should be_nil
        @obj.mypon = ''
        @obj.mypon.should be_nil
        @obj.mypon = '  '
        @obj.mypon.should be_nil
      end

      it "should reject non-integers and non-positive integers" do
        lambda { @obj.mypon = 'X' }.should raise_error(/invalid/)
        lambda { @obj.mypon = '0' }.should raise_error(/invalid/)
        lambda { @obj.mypon = -13 }.should raise_error(/invalid/)
      end

      it "should handle multiple names" do
        @class.attr_integer :ourpon, :theirpon
        @obj.respond_to?(:ourpon).should be_true
        @obj.respond_to?(:theirpon=).should be_true
      end
    end
    
    context "#attr_date" do
      before(:each) do
        @class = Class.new
        @class.extend ICU::Accessor
        @class.attr_date :mydate
        @obj = @class.new
      end

      it "should have a getter and setter" do
        @obj.respond_to?(:mydate).should be_true
        @obj.respond_to?(:mydate=).should be_true
      end

      it "should work as expected" do
        @obj.mydate = "2009/11/09"
        @obj.mydate.should == '2009-11-09'
      end

      it "should reject nil and other non-dates" do
        lambda { @obj.mydate = nil }.should raise_error(/invalid/)
        lambda { @obj.mydate = 'blah de blah' }.should raise_error(/invalid/)
        lambda { @obj.mydate = ' ' }.should raise_error(/invalid/)
        lambda { @obj.mydate = 0 }.should raise_error(/invalid/)
      end

      it "should handle multiple names" do
        @class.attr_date :ourdate, :theirdate
        @obj.respond_to?(:ourdate).should be_true
        @obj.respond_to?(:theirdate=).should be_true
      end
    end
    
    context "#attr_date_or_nil" do
      before(:each) do
        @class = Class.new
        @class.extend ICU::Accessor
        @class.attr_date_or_nil :mydate
        @obj = @class.new
      end

      it "should have a getter and setter" do
        @obj.respond_to?(:mydate).should be_true
        @obj.respond_to?(:mydate=).should be_true
      end

      it "should work as expected, including with nil" do
        @obj.mydate = "2009/11/09"
        @obj.mydate.should == '2009-11-09'
        @obj.mydate = nil
        @obj.mydate.should be_nil
      end

      it "should reject non-dates" do
        lambda { @obj.mydate = 'blah de blah' }.should raise_error(/invalid/)
        lambda { @obj.mydate = 0 }.should raise_error(/invalid/)
      end

      it "should handle multiple names" do
        @class.attr_date :ourdate, :theirdate
        @obj.respond_to?(:ourdate).should be_true
        @obj.respond_to?(:theirdate=).should be_true
      end
    end
    
    context "#attr_string" do
      before(:each) do
        @class = Class.new
        @class.extend ICU::Accessor
        @class.attr_string %r%[a-z]+%i, :mystring
        @obj = @class.new
      end

      it "should have a getter and setter" do
        @obj.respond_to?(:mystring).should be_true
        @obj.respond_to?(:mystring=).should be_true
      end

      it "should work as expected" do
        @obj.mystring = "  mark   "
        @obj.mystring.should == 'mark'
      end

      it "should reject values that don't match" do
        lambda { @obj.mystring = nil }.should raise_error(/invalid/)
        lambda { @obj.mystring = ' 123 ' }.should raise_error(/invalid/)
        lambda { @obj.mystring = ' ' }.should raise_error(/invalid/)
        lambda { @obj.mystring = 0 }.should raise_error(/invalid/)
        lambda { @obj.mystring = ' a ' }.should_not raise_error
        lambda { @obj.mystring = 'ZYX' }.should_not raise_error
      end

      it "should handle multiple names" do
        @class.attr_string %r%^[A-Z]{3}$%, :ourstring, :theirstring
        @obj.respond_to?(:ourstring=).should be_true
        @obj.respond_to?(:theirstring).should be_true
      end
    end
    
    context "#attr_string_or_nil" do
      before(:each) do
        @class = Class.new
        @class.extend ICU::Accessor
        @class.attr_string_or_nil %r%^[1-9]\d*$%i, :mystring
        @obj = @class.new
      end

      it "should have a getter and setter" do
        @obj.respond_to?(:mystring).should be_true
        @obj.respond_to?(:mystring=).should be_true
      end

      it "should work as expected" do
        @obj.mystring = " 12345  "
        @obj.mystring.should == '12345'
        @obj.mystring = nil
        @obj.mystring.should be_nil
        @obj.mystring = '   '
        @obj.mystring.should be_nil
      end

      it "should reject values that don't match" do
        lambda { @obj.mystring = ' 0 ' }.should raise_error(/invalid/)
        lambda { @obj.mystring = 0 }.should raise_error(/invalid/)
        lambda { @obj.mystring = -1 }.should raise_error(/invalid/)
        lambda { @obj.mystring = 98 }.should_not raise_error
      end

      it "should handle multiple names" do
        @class.attr_string %r%^[A-Z][a-z]+%, :ourstring, :theirstring
        @obj.respond_to?(:ourstring=).should be_true
        @obj.respond_to?(:theirstring).should be_true
      end
    end
  end
end