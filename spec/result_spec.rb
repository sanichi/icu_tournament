# encoding: utf-8

require File.dirname(__FILE__) + '/spec_helper'

module ICU
  describe Result do
    context "a typical result" do
      it "should have a round, player number and score plus optional opponent number, colour and rateable flag" do
        lambda { Result.new(3, 5, 'W', :opponent => 11, :colour => 'W') }.should_not raise_error
      end
    end
    
    context "round number" do
      it "should be a positive integer" do
        lambda { Result.new(-2, 2, 0) }.should raise_error(/invalid positive integer/)
        lambda { Result.new(0, 2, 0) }.should raise_error(/invalid positive integer/)
        Result.new(1, 2, 0).round.should == 1
        Result.new(' 3 ', 2, 0).round.should == 3
      end
    end
    
    context "player number" do
      it "should be an integer" do
        lambda { Result.new(1, '  ', 0) }.should raise_error(/invalid integer/)
        Result.new(1, 2, 0).player.should == 2
        Result.new(1, ' 0 ', 0).player.should == 0
        Result.new(1, -5, 0).player.should == -5
        Result.new(1, " 9 ", 0).player.should == 9
      end
    end
    
    context "score" do
      [1, 1.0, 'W', 'w', '+'].each do |score|
        it "should be 'W' for #{score}, #{score.class}" do
          Result.new(1, 2, score).score.should == 'W'
        end
      end
      [0, 0.0, 'L', 'l', '-'].each do |score|
        it "should be 'L' for #{score}, #{score.class}" do
          Result.new(1, 2, score).score.should == 'L'
        end
      end
      ['½', 0.5, 'D', 'd', '='].each do |score|
        it "should be 'L' for #{score}, #{score.class}" do
          Result.new(1, 2, score).score.should == 'D'
        end
      end
      ['', ' ', 'x', 2, -1.0, nil].each do |score|
        it "should raise error for invalid score (#{score})" do
          lambda { Result.new(1, 2, score) }.should raise_error(/invalid score/)
        end
      end
      it "should be expressable as a number" do
        Result.new(1, 2, 'W').points.should == 1.0
        Result.new(1, 2, 'L').points.should == 0.0
        Result.new(1, 2, 'D').points.should == 0.5
      end
    end
    
    context "colour" do
      it "should be 'W' or 'B' or nil (unknown)" do
        Result.new(4, 1, 0).colour.should be_nil
        Result.new(4, 1, 0, :colour => 'W').colour.should == 'W'
        Result.new(4, 1, 0, :colour => 'white').colour.should == 'W'
        Result.new(4, 1, 0, :colour => '  b ').colour.should == 'B'
        Result.new(4, 1, 0, :colour => ' BLACK ').colour.should == 'B'
        lambda { Result.new(4, 1, 0, :colour => 'red') }.should raise_error(/invalid colour/)
      end
    end
    
    context "opponent number" do
      it "should be nil (the default) or an integer" do
        Result.new(4, 1, 0).opponent.should be_nil
        Result.new(4, 1, 0, :opponent => nil).opponent.should be_nil
        Result.new(4, 1, 0, :opponent => '   ').opponent.should be_nil
        Result.new(4, 1, 0, :opponent => 0).opponent.should == 0
        Result.new(4, 1, 0, :opponent => 2).opponent.should == 2
        Result.new(4, 1, 0, :opponent => -6).opponent.should == -6
        Result.new(4, 1, 0, :opponent => ' 10 ').opponent.should == 10
        lambda { Result.new(4, 1, 0, :opponent => 'X') }.should raise_error(/invalid opponent number/)
      end
      
      it "should be different to player number" do
        lambda { Result.new(4, 1, 0, :opponent => 1) }.should raise_error(/opponent .* player .* different/)
      end
    end
    
    context "rateable flag" do
      it "should default to false if there is no opponent" do
        Result.new(4, 1, 0).rateable.should be_false
      end
      
      it "should default to true if there is an opponent" do
        Result.new(4, 1, 0, :opponent => 10).rateable.should be_true
      end
      
      it "should change if an opponent is added" do
        r = Result.new(4, 1, 0)
        r.opponent = 5;
        r.rateable.should be_true
      end
      
      it "should be settable to false from the constructor" do
        Result.new(4, 1, 0, :opponent => 10, :rateable => false).rateable.should be_false
      end

      it "should be settable to false using the accessor" do
        r = Result.new(4, 1, 0, :opponent => 10)
        r.rateable= false
        r.rateable.should be_false
      end
      
      it "should not be settable to true if there is no opponent" do
        r = Result.new(4, 1, 0)
        r.rateable= true
        r.rateable.should be_false
      end
    end
    
    context "reversed result" do
      it "should be nil if there is no opponent" do
        Result.new(4, 1, 0).reverse.should be_nil
      end
      
      it "should have player and opponent swapped" do
        r = Result.new(4, 1, 0, :opponent => 2).reverse
        r.player.should == 2
        r.opponent.should == 1
      end
      
      it "should have reversed result" do
        Result.new(4, 1, 0, :opponent => 2).reverse.score.should == 'W'
        Result.new(4, 1, 1, :opponent => 2).reverse.score.should == 'L'
        Result.new(4, 1, '=', :opponent => 2).reverse.score.should == 'D'
      end
      
      it "should preserve rateability" do
        Result.new(4, 1, 0, :opponent => 2).reverse.rateable.should be_true
        Result.new(4, 1, 0, :opponent => 2, :rateable => false).reverse.rateable.should be_false
      end
    end
    
    context "renumber the player numbers in a result" do
      before(:each) do
        @r1 = Result.new(1, 4, 0)
        @r2 = Result.new(2, 3, 1, :opponent => 4, :color => 'B')
      end
      
      it "should renumber successfully if the map has the relevant player numbers" do
        map = { 4 => 1, 3 => 2 }
        @r1.renumber(map).player.should == 1
        @r2.renumber(map).player.should == 2
        @r1.opponent.should be_nil
        @r2.opponent.should == 1
      end
      
      it "should raise exception if a player number is not in the map" do
        lambda { @r1.renumber({ 5 => 1, 3 => 2 }) }.should raise_error(/player.*4.*not found/)
      end
    end
    
    context "loose equality" do
      before(:each) do
        @r1 = Result.new(1, 1, 0, :opponent => 2, :colour => 'W')
        @r2 = Result.new(1, 1, 0, :opponent => 2, :colour => 'W')
        @r3 = Result.new(2, 1, 0, :opponent => 2, :colour => 'W')
        @r4 = Result.new(1, 3, 0, :opponent => 2, :colour => 'W')
        @r5 = Result.new(1, 1, 1, :opponent => 2, :colour => 'W')
        @r6 = Result.new(1, 1, 0, :opponent => 3, :colour => 'W')
        @r7 = Result.new(1, 1, 0, :opponent => 2, :colour => 'B')
      end
      
      it "should be equal if the round, player numbers, result and colour all match" do
        (@r1 == @r1).should be_true
        (@r1 == @r2).should be_true
      end
      
      it "should not be equal if the round, player numbers, result or colour do not match" do
        (@r1 == @r3).should be_false
        (@r1 == @r4).should be_false
        (@r1 == @r5).should be_false
        (@r1 == @r6).should be_false
        (@r1 == @r7).should be_false
      end
    end
    
    context "strict equality" do
      before(:each) do
        @r1 = Result.new(1, 1, 0, :opponent => 2, :colour => 'W')
        @r2 = Result.new(1, 1, 0, :opponent => 2, :colour => 'W')
        @r3 = Result.new(1, 1, 0, :opponent => 2, :colour => 'W', :rateable => false)
        @r4 = Result.new(2, 1, 0, :opponent => 2, :colour => 'W')
      end
      
      it "should only be equal if everything is the same" do
        @r1.eql?(@r1).should be_true
        @r1.eql?(@r2).should be_true
        @r1.eql?(@r3).should be_false
        @r1.eql?(@r4).should be_false
      end
    end
  end
end