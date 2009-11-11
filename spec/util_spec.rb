require File.dirname(__FILE__) + '/spec_helper'

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
      
      it "should handle names of months" do
        Util.parsedate('9th Nov 1955').should == '1955-11-09'
        Util.parsedate('16th June 1986').should == '1986-06-16'
      end
    end
  end
  
  describe Accessor do
    context "#attr_accessor" do
      before(:each) do
        @test = 'string'
        @class = Class.new do
          extend ICU::Accessor
          def initialize(myval)
            @myatr = myval
          end
        end
        @object = @class.new(@test)
      end
      
      it "should not have an accessor unless declared" do
        @object.respond_to?(:myatr).should be_false
        @object.respond_to?(:myatr=).should be_false
      end
      
      it "should have a getter but no setter with the default declaration" do
        @class.attr_accessor('myatr')
        @object.respond_to?(:myatr).should be_true
        @object.respond_to?(:myatr=).should be_false
        @object.myatr.should == @test
      end
      
      it "should be able to create do-it-yourself setters such as for a positive integer" do
        @class.attr_accessor('myatr') do |val|
          tmp = val.to_i
          raise "invalid positive integer (#{val})" unless tmp > 0
          tmp
        end
        @object.respond_to?(:myatr).should be_true
        @object.respond_to?(:myatr=).should be_true
        lambda { @object.myatr = "no number here" }.should raise_error(/invalid positive integer \(no number here\)/)
        lambda { @object.myatr = -1 }.should raise_error
        lambda { @object.myatr = 0 }.should raise_error
        lambda { @object.myatr = 1 }.should_not raise_error
        @object.myatr.should == 1
        lambda { @object.myatr = '42' }.should_not raise_error
        @object.myatr.should == 42
        lambda { @object.myatr = '  0371  ' }.should_not raise_error
        @object.myatr.should == 371
      end
    end
  end
end