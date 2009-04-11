require File.dirname(__FILE__) + '/spec_helper'

module ICU
  describe Tournament do
    context "a typical tournament" do
      it "has a name, start date, some players and some results" do
        lambda do
          t = Tournament.new('Bangor Bash', '2009-11-09')
          t.add_player(Player.new('Bobby', 'Fischer', 1))
          t.add_player(Player.new('Garry', 'Gary Kasparov', 2))
          t.add_player(Player.new('Mark', 'Orr', 3))
          t.add_result(Result.new(1, 1, '=', :opponent => 2, :colour => 'W'))
          t.add_result(Result.new(2, 2, 'L', :opponent => 3, :colour => 'W'))
          t.add_result(Result.new(3, 3, 'W', :opponent => 1, :colour => 'W'))
        end.should_not raise_error
      end
    end
    
    # Tournament name.
    context "name" do
      before(:each) do
        @t = Tournament.new('Edinburgh Masters', '2009-11-09')
      end
      
      it "must be specified in constructor" do
        @t.name.should == 'Edinburgh Masters'
      end
      
      it "can be replaced by accessor" do
        @t.name = 'Bangor Bashers'
        @t.name.should == 'Bangor Bashers'
      end
      
      it "should not be blank or without letters" do
        lambda { Tournament.new('   ', '2009-11-09') }.should raise_error(/invalid.*name/)       
        lambda { @t.name = '333' }.should raise_error(/invalid.*name/)   
      end
    end
    
    # Tournament start date.
    context "start date" do
      before(:each) do
        @t = Tournament.new('Edinburgh Masters', '2009-11-09')
      end
      
      it "must be specified in constructor" do
        @t.start.should == '2009-11-09'
      end
      
      it "can be replaced by accessor" do
        @t.start = '16th June 2010'
        @t.start.should == '2010-06-16'
      end
      
      it "should be a valid date" do
        lambda { Tournament.new('Edinburgh Masters', '  ') }.should raise_error(/invalid.*date/)
        lambda { @t.start = 'X' }.should raise_error(/invalid.*date/)
      end
    end
    
    # Number of rounds.
    context "rounds" do
      it "defaults to nil" do
        Tournament.new('Edinburgh Masters', '2009-11-09').rounds.should be_nil
      end

      it "should be a positive integer" do
        Tournament.new('Edinburgh Masters', '2009-11-09', :rounds => 3).rounds.should == 3
        Tournament.new('Edinburgh Masters', '2009-11-09', :rounds => ' 10 ').rounds.should == 10
        lambda { Tournament.new('Edinburgh Masters', '2009-11-09', :rounds => ' 0 ') }.should raise_error(/invalid.*rounds/)
      end
    end
    
    # Web site.
    context "site" do
      it "defaults to nil" do
        Tournament.new('Edinburgh Masters', '2009-11-09').site.should be_nil
      end

      it "should be a reasonably valid looking URL" do
        Tournament.new('Edinburgh Masters', '2009-11-09', :site => 'https://www.bbc.co.uk').site.should == 'https://www.bbc.co.uk'
        Tournament.new('Edinburgh Masters', '2009-11-09', :site => 'www.icu.ie/event.php?id=1').site.should == 'http://www.icu.ie/event.php?id=1'
        lambda { Tournament.new('Edinburgh Masters', '2009-11-09', :site => 'X') }.should raise_error(/invalid.*site/)
      end
    end
    
    # Tournament players.
    context "players" do
      before(:each) do
        @t = Tournament.new('Edinburgh Masters', '2009-11-09')
      end
      
      it "should have unique numbers" do
        @t.add_player(Player.new('Mark', 'Orr', 1))
        lambda { @t.add_player(Player.new('Bobby', 'Fischer', 1)) }.should raise_error(/player.*unique/)
      end
      
      it "can be added one at a time" do
        @t.add_player(Player.new('Mark', 'Orr', -1))
        @t.add_player(Player.new('Gary', 'Kasparov', -2))
        @t.add_player(Player.new('Bobby', 'Fischer', -3))
        @t.players.size.should == 3
        @t.player(-1).first_name.should == 'Mark'
      end
    end
    
    # Tournament results.
    context "results" do
      before(:each) do
        @t = Tournament.new('Edinburgh Masters', '2009-11-09', :rounds => 3)
        @t.add_player(@mark = Player.new('Mark', 'Orr', 1))
        @t.add_player(@gary = Player.new('Gary', 'Kasparov', 2))
        @t.add_player(@boby = Player.new('Bobby', 'Fischer', 3))
      end
      
      it "can be added one at a time" do
        @t.add_result(Result.new(1, 1, 'W', :opponent => 2))
        @t.add_result(Result.new(2, 2, 'D', :opponent => 3))
        @t.add_result(Result.new(3, 3, 'L', :opponent => 1))
        @mark.results.size.should == 2
        @mark.points.should == 2.0
        @gary.results.size.should == 2
        @gary.points.should == 0.5
        @boby.results.size.should == 2
        @boby.points.should == 0.5
      end
      
      it "can be added symmetrically or asymmetrically with respect to rateability" do
        @t.add_result(Result.new(1, 1, 'W', :opponent => 2))
        @mark.results[0].rateable.should be_true
        @gary.results[0].rateable.should be_true
        @t.add_result(Result.new(2, 1, 'W', :opponent => 3), false)
        @mark.results[1].rateable.should be_true
        @boby.results[0].rateable.should be_false
      end
      
      it "should have a defined player" do
        lambda { @t.add_result(Result.new(1, 4, 'L', :opponent => 1)) }.should raise_error(/player.*exist/)
      end
      
      it "should have a defined opponent" do
        lambda { @t.add_result(Result.new(1, 1, 'W', :opponent => 4)) }.should raise_error(/opponent.*exist/)
      end
      
      it "should be consistent with the tournament's number of rounds" do
        lambda { @t.add_result(Result.new(4, 1, 'W', :opponent => 2)) }.should raise_error(/round/)
      end
    end
    
    context "finding players" do
      before(:all) do
        @t = Tournament.new('Bangor Bash', '2009-11-09')
        @t.add_player(Player.new('Bobby', 'Fischer', 1, :fed => 'USA'))
        @t.add_player(Player.new('Garry', 'Gary Kasparov', 2, :fed => 'RUS'))
        @t.add_player(Player.new('Mark', 'Orr', 3, :fed => 'IRL'))
      end
      
      it "should find players based on loose equality" do
        @t.find_player(Player.new('Mark', 'Orr', 4, :fed => 'IRL')).num.should == 3
        @t.find_player(Player.new('Mark', 'Orr', 4, :fed => 'USA')).should be_nil
        @t.find_player(Player.new('Mark', 'Sax', 4, :fed => 'IRL')).should be_nil
        @t.find_player(Player.new('John', 'Orr', 4, :fed => 'IRL')).should be_nil
      end
    end
  end
end
