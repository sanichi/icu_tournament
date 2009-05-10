require File.dirname(__FILE__) + '/spec_helper'

module ICU
  describe Tournament do
    context "a basic tournament" do
      it "has a name, start date, some players and some results" do
        lambda do
          t = Tournament.new('Bangor Bash', '2009-11-09')
          t.add_player(Player.new('Bobby', 'Fischer', 1))
          t.add_player(Player.new('Garry', 'Kasparov', 2))
          t.add_player(Player.new('Mark', 'Orr', 3))
          t.add_result(Result.new(1, 1, '=', :opponent => 2, :colour => 'W'))
          t.add_result(Result.new(2, 2, 'L', :opponent => 3, :colour => 'W'))
          t.add_result(Result.new(3, 3, 'W', :opponent => 1, :colour => 'W'))
          t.validate!
        end.should_not raise_error
      end
    end

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

    context "city" do
      before(:each) do
        @t = Tournament.new('Edinburgh Masters', '2009-11-09', :city => 'Edinburgh')
      end

      it "may be specified in constructor" do
        @t.city.should == 'Edinburgh'
      end

      it "can be replaced by accessor" do
        @t.city = 'Glasgow'
        @t.city.should == 'Glasgow'
      end

      it "can be set to nil" do
        @t.city = ''
        @t.city.should be_nil
      end

      it "should not be without letters if set" do
        lambda { @t.city = '123' }.should raise_error(/invalid.*city/)
      end
    end

    context "federation" do
      before(:each) do
        @t = Tournament.new('Edinburgh Masters', '2009-11-09', :fed => 'SCO')
      end

      it "may be specified in constructor" do
        @t.fed.should == 'SCO'
      end

      it "can be replaced by accessor" do
        @t.fed = 'IRL'
        @t.fed.should == 'IRL'
      end

      it "can be set to nil" do
        @t.fed = ''
        @t.fed.should be_nil
      end

      it "three letters will automatically be upcased" do
        @t.fed = 'rus'
        @t.fed.should == 'RUS'
      end

      it "should not be without letters if set" do
        lambda { @t.fed = '123' }.should raise_error(/invalid.*federation/)
      end
    end

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

    context "finish date" do
      before(:each) do
        @t = Tournament.new('Edinburgh Masters', '2009-11-09', :finish => '12th November 2009')
      end

      it "may be specified in constructor" do
        @t.finish.should == '2009-11-12'
      end

      it "can be replaced by accessor" do
        @t.finish = '16th December 2009'
        @t.finish.should == '2009-12-16'
      end

      it "can be set to nil" do
        @t.finish = ''
        @t.finish.should be_nil
      end

      it "should be a valid date" do
        lambda { Tournament.new('Edinburgh Masters', '2009-11-09', :finish => 'next week') }.should raise_error(/invalid.*date/)
        lambda { @t.finish = 'X' }.should raise_error(/invalid.*date/)
      end
    end

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

    context "round date" do
      before(:each) do
        @t = Tournament.new('Edinburgh Masters', '2009-11-09')
      end

      it "should default to none" do
        @t.round_dates.size.should == 0
      end

      it "can be added one by one in any order" do
        @t.add_round_date('2009-11-11')
        @t.add_round_date('09/11/2009')
        @t.add_round_date('10th November 2009')
        @t.round_dates.join('|').should == '2009-11-09|2009-11-10|2009-11-11'
      end
    end

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

    context "type, arbiter, deputy and time control" do
      before(:each) do
        @t = Tournament.new('Edinburgh Masters', '2009-11-09', :type => 'Swiss', :arbiter => 'Gerry Graham', :deputy => 'Herbert Scarry', :time_control => '120 minutes')
      end

      it "may be specified in constructor" do
        @t.type.should == 'Swiss'
        @t.arbiter.should == 'Gerry Graham'
        @t.deputy.should == 'Herbert Scarry'
        @t.time_control.should == '120 minutes'
      end

      it "can be replaced by accessor" do
        @t.type = 'all-play-all'
        @t.type.should == 'all-play-all'
        @t.arbiter = 'Michael Crowe'
        @t.arbiter.should == 'Michael Crowe'
        @t.deputy = 'Mark Orr'
        @t.deputy.should == 'Mark Orr'
        @t.time_control = '90 minutes'
        @t.time_control.should == '90 minutes'
      end

      it "can be set to nil" do
        @t.type = ''
        @t.type.should be_nil
        @t.arbiter = ''
        @t.arbiter.should be_nil
        @t.deputy = ''
        @t.deputy.should be_nil
        @t.time_control = ''
        @t.time_control.should be_nil
      end

      it "should be valid" do
        lambda { @t.type         = '123' }.should raise_error(/invalid.*type/)
        lambda { @t.arbiter      = '123' }.should raise_error(/invalid.*arbiter/)
        lambda { @t.deputy       = '123' }.should raise_error(/invalid.*deputy/)
        lambda { @t.time_control = 'abc' }.should raise_error(/invalid.*time control/)
      end
    end

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
    
    context "teams" do
      before(:each) do
        @t = Tournament.new('Bangor Bash', '2009-11-09')
      end

      it "should be able to create a new team, add it and retrieve it" do
        team = Team.new('Wandering Dragons')
        @t.add_team(team).should be_an_instance_of Team
        @t.get_team('  wandering  dragons  ').should be_an_instance_of Team
        @t.get_team('Blundering Bishops').should be_nil
      end
      
      it "should be able to create and add a new team and retrieve it" do
        @t.add_team('Blundering Bishops').should be_an_instance_of Team
        @t.get_team('  blundering  bishops  ').should be_an_instance_of Team
        @t.get_team('Wandering Dragons').should be_nil
      end
      
      it "should throw and exception if there is an attempt to add a team with a name that matches an existing team" do
        lambda { @t.add_team('Blundering Bishops') }.should_not raise_error
        lambda { @t.add_team('Wandering Dragons') }.should_not raise_error
        lambda { @t.add_team('  wandering   dragons  ') }.should raise_error(/similar.*exists/)
      end
    end
    
    context "validation" do
      before(:each) do
        @t = Tournament.new('Edinburgh Masters', '2009-11-09')
        @t.add_player(@mark = Player.new('Mark', 'Orr', 1))
        @t.add_player(@gary = Player.new('Gary', 'Kasparov', 2))
        @t.add_player(@boby = Player.new('Bobby', 'Fischer', 3))
        @t.add_result(Result.new(1, 1, 'W', :opponent => 2))
        @t.add_result(Result.new(2, 2, 'W', :opponent => 3))
        @t.add_result(Result.new(3, 3, 'L', :opponent => 1))
        @t.add_round_date('2009-11-09')
        @t.add_round_date('2009-11-10')
        @t.add_round_date('2009-11-11')
      end

      it "should be valid" do
        @t.invalid.should be_false
      end

      it "should have side effect of setting number of rounds" do
        @t.rounds.should be_nil
        @t.invalid
        @t.rounds.should == 3
      end

      it "should detect an inconsistent start date" do
        @t.start = '2009-11-10'
        lambda { @t.validate! }.should raise_error(/first round.*before.*start/)
      end

      it "should detect an inconsistent finish date" do
        @t.finish = '2009-11-10'
        lambda { @t.validate! }.should raise_error(/last round.*after.*end/)
      end

      it "should have side effect of setting missing finish date" do
        @t.finish.should be_nil
        @t.invalid
        @t.finish.should == '2009-11-11'
      end

      it "should detect inconsistent round dates" do
        @t.add_round_date('2009-11-12')
        lambda { @t.validate! }.should raise_error(/round dates.*match.*rounds/)
      end

      it "should have the side effect of providing missing ranks if the rerank option is set" do
        @t.players.select{ |p| p.rank }.size.should == 0
        @t.invalid(:rerank => true)
        @t.player(1).rank.should == 1
        @t.player(2).rank.should == 2
        @t.player(3).rank.should == 3
      end

      it "should have the side effect of correcting bad ranks if the rerank option is set" do
        @t.player(1).rank = 2
        @t.player(2).rank = 1
        @t.player(3).rank = 3
        @t.invalid(:rerank => true)
        @t.player(1).rank.should == 1
        @t.player(2).rank.should == 2
        @t.player(3).rank.should == 3
      end

      it "should detect missranked players" do
        @t.player(1).rank = 2
        @t.player(2).rank = 1
        @t.player(3).rank = 3
        lambda { @t.validate! }.should raise_error(/player 2.*above.*player 1/)
      end
      
      it "should be valid if there are teams, every player is in one of them, and no team has an invalid member" do
        team1 = Team.new('International Masters')
        team2 = Team.new('World Champions')
        @t.add_team(team1)
        @t.add_team(team2)
        @t.invalid.should match(/not.*member/)
        team1.add_member(1)
        team2.add_member(2)
        team2.add_member(3)
        @t.invalid.should be_false
        team1.add_member(4)
        @t.invalid.should match(/not.*valid/)
      end
      
      it "should not be valid if one player is in more than one team" do
        team1 = Team.new('XInternational Masters')
        team1.add_member(1)
        team2 = Team.new('XWorld Champions')
        team2.add_member(2)
        team2.add_member(3)
        @t.add_team(team1)
        @t.add_team(team2)
        @t.invalid.should be_false
        team1.add_member(2)
        @t.invalid.should match(/already.*member/)
      end
    end
  end
end
