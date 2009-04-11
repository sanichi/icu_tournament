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
      
      it "should handle single digits" do
        Util.parsedate('9/8/2006').should == '2006-08-09'
      end
      
      it "should handle names of months" do
        Util.parsedate('9th Nov 1955').should == '1955-11-09'
        Util.parsedate('16th June 1986').should == '1986-06-16'
      end
    end
  end
end