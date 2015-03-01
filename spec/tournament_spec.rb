require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

module ICU
  describe Tournament do
    context "a basic tournament" do
      it "has a name, start date, some players and some results" do
        expect do
          t = Tournament.new('Bangor Bash', '2009-11-09')
          t.add_player(Player.new('Bobby', 'Fischer', 1))
          t.add_player(Player.new('Garry', 'Kasparov', 2))
          t.add_player(Player.new('Mark', 'Orr', 3))
          t.add_result(Result.new(1, 1, '=', :opponent => 2, :colour => 'W'))
          t.add_result(Result.new(2, 2, 'L', :opponent => 3, :colour => 'W'))
          t.add_result(Result.new(3, 3, 'W', :opponent => 1, :colour => 'W'))
          t.validate!
        end.not_to raise_error
      end
    end

    context "documentation example" do
      before(:each) do
        @t = t = ICU::Tournament.new('Bangor Masters', '2009-11-09')
        t.add_player(ICU::Player.new('Bobby', 'Fischer', 10))
        t.add_player(ICU::Player.new('Garry', 'Kasparov', 20))
        t.add_player(ICU::Player.new('Mark', 'Orr', 30))
        t.add_result(ICU::Result.new(1, 10, 'D', :opponent => 30, :colour => 'W'))
        t.add_result(ICU::Result.new(2, 20, 'W', :opponent => 30, :colour => 'B'))
        t.add_result(ICU::Result.new(3, 20, 'L', :opponent => 10, :colour => 'W'))
        t.validate!(:rerank => true)
        @s = <<EOS
012 Bangor Masters
042 2009-11-09
001   10      Fischer,Bobby                                                      1.5    1    30 w =              20 b 1
001   20      Kasparov,Garry                                                     1.0    2              30 b 1    10 w 0
001   30      Orr,Mark                                                           0.5    3    10 b =    20 w 0          #
EOS
        @s.sub!(/#/, '')
      end

      it "should serialize to Krause" do
        parser = ICU::Tournament::Krause.new
        expect(parser.serialize(@t)).to eq(@s)
      end
    end

    context "name" do
      before(:each) do
        @t = Tournament.new('Edinburgh Masters', '2009-11-09')
      end

      it "must be specified in constructor" do
        expect(@t.name).to eq('Edinburgh Masters')
      end

      it "can be replaced by accessor" do
        @t.name = 'Bangor Bashers'
        expect(@t.name).to eq('Bangor Bashers')
      end

      it "should not be blank or without letters" do
        expect { Tournament.new('   ', '2009-11-09') }.to raise_error(/invalid.*name/)
        expect { @t.name = '333' }.to raise_error(/invalid.*name/)
      end
    end

    context "city" do
      before(:each) do
        @t = Tournament.new('Edinburgh Masters', '2009-11-09', :city => 'Edinburgh')
      end

      it "may be specified in constructor" do
        expect(@t.city).to eq('Edinburgh')
      end

      it "can be replaced by accessor" do
        @t.city = 'Glasgow'
        expect(@t.city).to eq('Glasgow')
      end

      it "can be set to nil" do
        @t.city = ''
        expect(@t.city).to be_nil
      end

      it "should not be without letters if set" do
        expect { @t.city = '123' }.to raise_error(/invalid.*city/)
      end
    end

    context "federation" do
      before(:each) do
        @t = Tournament.new('Edinburgh Masters', '2009-11-09', :fed => 'SCO')
      end

      it "may be specified in constructor" do
        expect(@t.fed).to eq('SCO')
      end

      it "can be replaced by accessor" do
        @t.fed = 'IRL'
        expect(@t.fed).to eq('IRL')
      end

      it "can be set to nil" do
        @t.fed = ''
        expect(@t.fed).to be_nil
      end

      it "three letters will automatically be upcased" do
        @t.fed = 'rus'
        expect(@t.fed).to eq('RUS')
      end

      it "should not be without letters if set" do
        expect { @t.fed = '123' }.to raise_error(/invalid.*federation/)
      end
    end

    context "start date" do
      before(:each) do
        @t = Tournament.new('Edinburgh Masters', '2009-11-09')
      end

      it "must be specified in constructor" do
        expect(@t.start).to eq('2009-11-09')
      end

      it "can be replaced by accessor" do
        @t.start = '16th June 2010'
        expect(@t.start).to eq('2010-06-16')
      end

      it "should be a valid date" do
        expect { Tournament.new('Edinburgh Masters', '  ') }.to raise_error(/invalid.*date/)
        expect { @t.start = 'X' }.to raise_error(/invalid.*date/)
      end
    end

    context "finish date" do
      before(:each) do
        @t = Tournament.new('Edinburgh Masters', '2009-11-09', :finish => '12th November 2009')
      end

      it "may be specified in constructor" do
        expect(@t.finish).to eq('2009-11-12')
      end

      it "can be replaced by accessor" do
        @t.finish = '16th December 2009'
        expect(@t.finish).to eq('2009-12-16')
      end

      it "can be set to nil" do
        @t.finish = ''
        expect(@t.finish).to be_nil
      end

      it "should be a valid date" do
        expect { Tournament.new('Edinburgh Masters', '2009-11-09', :finish => 'next week') }.to raise_error(/invalid.*date/)
        expect { @t.finish = 'X' }.to raise_error(/invalid.*date/)
      end
    end

    context "rounds" do
      it "defaults to nil" do
        expect(Tournament.new('Edinburgh Masters', '2009-11-09').rounds).to be_nil
      end

      it "should be a positive integer or nil" do
        expect(Tournament.new('Edinburgh Masters', '2009-11-09', :rounds => 3).rounds).to eq(3)
        expect(Tournament.new('Edinburgh Masters', '2009-11-09', :rounds => ' 10 ').rounds).to eq(10)
        expect(Tournament.new('Edinburgh Masters', '2009-11-09', :rounds => nil).rounds).to be_nil
        expect { Tournament.new('Edinburgh Masters', '2009-11-09', :rounds => ' 0 ') }.to raise_error(/invalid.*rounds/)
      end
    end

    context "last_round" do
      before(:each) do
        @t = Tournament.new('Edinburgh Masters', '2009-11-09')
        @t.add_player(@mark = Player.new('Mark', 'Orr', 1))
        @t.add_player(@gary = Player.new('Gary', 'Kasparov', 2))
        @t.add_player(@boby = Player.new('Bobby', 'Fischer', 3))
      end

      it "depends on the players results" do
        expect(@t.last_round).to eq(0)
        @t.add_result(Result.new(1, 1, 'W', :opponent => 2))
        expect(@t.last_round).to eq(1)
        @t.add_result(Result.new(2, 2, 'D', :opponent => 3))
        expect(@t.last_round).to eq(2)
        @t.add_result(Result.new(5, 3, 'L', :opponent => 1))
        expect(@t.last_round).to eq(5)
      end
    end

    context "round date" do
      before(:each) do
        @t = Tournament.new('Edinburgh Masters', '2009-11-09')
      end

      it "should default to none" do
        expect(@t.round_dates.size).to eq(0)
      end

      it "should be added one by one in the correct order" do
        @t.add_round_date('09/11/2009')
        @t.add_round_date('10th November 2009')
        @t.add_round_date('2009-11-11')
        expect(@t.round_dates.join('|')).to eq('2009-11-09|2009-11-10|2009-11-11')
      end
    end

    context "site" do
      it "defaults to nil" do
        expect(Tournament.new('Edinburgh Masters', '2009-11-09').site).to be_nil
      end

      it "should be a reasonably valid looking URL" do
        expect(Tournament.new('Edinburgh Masters', '2009-11-09', :site => 'https://www.bbc.co.uk').site).to eq('https://www.bbc.co.uk')
        expect(Tournament.new('Edinburgh Masters', '2009-11-09', :site => 'www.icu.ie/event.php?id=1').site).to eq('http://www.icu.ie/event.php?id=1')
        expect { Tournament.new('Edinburgh Masters', '2009-11-09', :site => 'X') }.to raise_error(/invalid.*site/)
      end
    end

    context "type, arbiter, deputy and time control" do
      before(:each) do
        @t = Tournament.new('Edinburgh Masters', '2009-11-09', :type => 'Swiss', :arbiter => 'Gerry Graham', :deputy => 'Herbert Scarry', :time_control => '120 minutes')
      end

      it "may be specified in constructor" do
        expect(@t.type).to eq('Swiss')
        expect(@t.arbiter).to eq('Gerry Graham')
        expect(@t.deputy).to eq('Herbert Scarry')
        expect(@t.time_control).to eq('120 minutes')
      end

      it "can be replaced by accessor" do
        @t.type = 'all-play-all'
        expect(@t.type).to eq('all-play-all')
        @t.arbiter = 'Michael Crowe'
        expect(@t.arbiter).to eq('Michael Crowe')
        @t.deputy = 'Mark Orr'
        expect(@t.deputy).to eq('Mark Orr')
        @t.time_control = '90 minutes'
        expect(@t.time_control).to eq('90 minutes')
      end

      it "can be set to nil" do
        @t.type = ''
        expect(@t.type).to be_nil
        @t.arbiter = ''
        expect(@t.arbiter).to be_nil
        @t.deputy = ''
        expect(@t.deputy).to be_nil
        @t.time_control = ''
        expect(@t.time_control).to be_nil
      end

      it "should be valid" do
        expect { @t.type         = '123' }.to raise_error(/invalid.*type/)
        expect { @t.arbiter      = '123' }.to raise_error(/invalid.*arbiter/)
        expect { @t.deputy       = '123' }.to raise_error(/invalid.*deputy/)
        expect { @t.time_control = 'abc' }.to raise_error(/invalid.*time.*control/)
      end
    end

    context "tie breaks" do
      before(:each) do
        @t = Tournament.new('Edinburgh Masters', '2009-11-09')
      end

      it "should an empty tie breaks list by default" do
        expect(@t.tie_breaks).to be_an_instance_of(Array)
        expect(@t.tie_breaks).to be_empty
      end

      it "should be settable to one or more valid tie break methods" do
        @t.tie_breaks = [:neustadtl]
        expect(@t.tie_breaks.join('|')).to eq("neustadtl")
        @t.tie_breaks = [:neustadtl, :blacks]
        expect(@t.tie_breaks.join('|')).to eq("neustadtl|blacks")
        @t.tie_breaks = ['Wins', 'Sonneborn-Berger', :harkness]
        expect(@t.tie_breaks.join('|')).to eq("wins|neustadtl|harkness")
        @t.tie_breaks = []
        expect(@t.tie_breaks.join('|')).to eq("")
      end

      it "should rasie an error is not given an array" do
        expect { @t.tie_breaks = :neustadtl }.to raise_error(/array/i)
      end

      it "should rasie an error is given any invalid tie-break methods" do
        expect { @t.tie_breaks = ["My Bum"] }.to raise_error(/invalid/i)
        expect { @t.tie_breaks = [:neustadtl, "Your arse"] }.to raise_error(/invalid/i)
      end
    end

    context "players" do
      before(:each) do
        @t = Tournament.new('Edinburgh Masters', '2009-11-09')
      end

      it "should have unique numbers" do
        @t.add_player(Player.new('Mark', 'Orr', 1))
        expect { @t.add_player(Player.new('Bobby', 'Fischer', 1)) }.to raise_error(/player.*unique/)
      end

      it "can be added one at a time" do
        @t.add_player(Player.new('Mark', 'Orr', -1))
        @t.add_player(Player.new('Gary', 'Kasparov', -2))
        @t.add_player(Player.new('Bobby', 'Fischer', -3))
        expect(@t.players.size).to eq(3)
        expect(@t.player(-1).first_name).to eq('Mark')
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
        @t.add_result(Result.new(3, 3, 'L', :opponent => 1, :rateable => false))
        expect(@mark.results.size).to eq(2)
        expect(@mark.points).to eq(2.0)
        expect(@gary.results.size).to eq(2)
        expect(@gary.points).to eq(0.5)
        expect(@boby.results.size).to eq(2)
        expect(@boby.points).to eq(0.5)
      end

      it "results with asymmetric scores cannot be added unless both results are unrateable" do
        @t.add_result(Result.new(1, 1, 'W', :opponent => 2))
        expect { @t.add_result(Result.new(1, 2, 'D', :opponent => 1)) }.to raise_error(/result.*match/)
        expect { @t.add_result(Result.new(1, 2, 'L', :opponent => 1, :rateable => false)) }.to raise_error(/result.*match/)
        expect { @t.add_result(Result.new(3, 3, 'L', :opponent => 1, :rateable => false)) }.not_to raise_error
      end

      it "should have a defined player" do
        expect { @t.add_result(Result.new(1, 4, 'L', :opponent => 1)) }.to raise_error(/player.*exist/)
      end

      it "should have a defined opponent" do
        expect { @t.add_result(Result.new(1, 1, 'W', :opponent => 4)) }.to raise_error(/opponent.*exist/)
      end

      it "should be consistent with the tournament's number of rounds" do
        expect { @t.add_result(Result.new(4, 1, 'W', :opponent => 2)) }.to raise_error(/round/)
      end

      it "documentation example should ne correct" do
        @t.add_result(ICU::Result.new(3, 2, 'L', :opponent => 1, :rateable => false))
        @t.add_result(ICU::Result.new(3, 1, 'L', :opponent => 2, :rateable => false))
        expect(@t.player(1).results.first.points).to eq(0.0)
        expect(@t.player(2).results.first.points).to eq(0.0)
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
        expect(@t.find_player(Player.new('Mark', 'Orr', 4, :fed => 'IRL')).num).to eq(3)
        expect(@t.find_player(Player.new('Mark', 'Orr', 4, :fed => 'USA'))).to be_nil
        expect(@t.find_player(Player.new('Mark', 'Sax', 4, :fed => 'IRL'))).to be_nil
        expect(@t.find_player(Player.new('John', 'Orr', 4, :fed => 'IRL'))).to be_nil
      end
    end

    context "teams" do
      before(:each) do
        @t = Tournament.new('Bangor Bash', '2009-11-09')
      end

      it "should be able to create a new team, add it and retrieve it" do
        team = Team.new('Wandering Dragons')
        expect(@t.add_team(team)).to be_an_instance_of Team
        expect(@t.get_team('  wandering  dragons  ')).to be_an_instance_of Team
        expect(@t.get_team('Blundering Bishops')).to be_nil
      end

      it "should be able to create and add a new team and retrieve it" do
        expect(@t.add_team('Blundering Bishops')).to be_an_instance_of Team
        expect(@t.get_team('  blundering  bishops  ')).to be_an_instance_of Team
        expect(@t.get_team('Wandering Dragons')).to be_nil
      end

      it "should throw and exception if there is an attempt to add a team with a name that matches an existing team" do
        expect { @t.add_team('Blundering Bishops') }.not_to raise_error
        expect { @t.add_team('Wandering Dragons') }.not_to raise_error
        expect { @t.add_team('  wandering   dragons  ') }.to raise_error(/similar.*exists/)
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
        expect(@t.invalid).to be_falsey
      end

      it "should have side effect of setting number of rounds" do
        expect(@t.rounds).to be_nil
        @t.invalid
        expect(@t.rounds).to eq(3)
      end

      it "should detect an inconsistent start date" do
        @t.start = '2009-11-10'
        expect { @t.validate! }.to raise_error(/first round.*not match.*start/)
      end

      it "should detect an inconsistent finish date" do
        @t.finish = '2009-11-10'
        expect { @t.validate! }.to raise_error(/last round.*not match.*end/)
      end

      it "should have side effect of setting missing finish date" do
        expect(@t.finish).to be_nil
        @t.invalid
        expect(@t.finish).to eq('2009-11-11')
      end

      it "should detect inconsistent round dates" do
        @t.add_round_date('2009-11-12')
        expect { @t.validate! }.to raise_error(/round dates.*match.*rounds/)
      end

      it "should have the side effect of providing missing ranks if the rerank option is set" do
        expect(@t.players.select{ |p| p.rank }.size).to eq(0)
        @t.invalid(:rerank => true)
        expect(@t.player(1).rank).to eq(1)
        expect(@t.player(2).rank).to eq(2)
        expect(@t.player(3).rank).to eq(3)
      end

      it "should have the side effect of correcting bad ranks if the rerank option is set" do
        @t.player(1).rank = 2
        @t.player(2).rank = 1
        @t.player(3).rank = 3
        @t.invalid(:rerank => true)
        expect(@t.player(1).rank).to eq(1)
        expect(@t.player(2).rank).to eq(2)
        expect(@t.player(3).rank).to eq(3)
      end

      it "should detect missranked players" do
        @t.player(1).rank = 2
        @t.player(2).rank = 1
        @t.player(3).rank = 3
        expect { @t.validate! }.to raise_error(/player 2.*above.*player 1/)
      end

      it "should be valid if there are teams, every player is in one of them, and no team has an invalid member" do
        team1 = Team.new('International Masters')
        team2 = Team.new('World Champions')
        @t.add_team(team1)
        @t.add_team(team2)
        expect(@t.invalid).to match(/not.*member/)
        team1.add_member(1)
        team2.add_member(2)
        team2.add_member(3)
        expect(@t.invalid).to be_falsey
        team1.add_member(4)
        expect(@t.invalid).to match(/not.*valid/)
      end

      it "should not be valid if one player is in more than one team" do
        team1 = Team.new('XInternational Masters')
        team1.add_member(1)
        team2 = Team.new('XWorld Champions')
        team2.add_member(2)
        team2.add_member(3)
        @t.add_team(team1)
        @t.add_team(team2)
        expect(@t.invalid).to be_falsey
        team1.add_member(2)
        expect(@t.invalid).to match(/already.*member/)
      end

      it "should not be valid if two players share the same ICU or FIDE ID" do
        @t.player(1).id = 1350
        @t.player(2).id = 1350
        expect(@t.invalid).to match(/duplicate.*ICU/)
      end

      it "should allow players to have no results" do
        (1..3).each { |r| @t.player(1).remove_result(r) }
        expect(@t.invalid).to be_falsey
      end

      it "should not allow asymmetric scores for rateable results" do
        @t.player(1).find_result(1).score = 'L'
        expect(@t.invalid).to match(/result.*reverse/)
      end

      it "should allow asymmetric scores for unrateable results" do
        @t.player(1).find_result(1).score = 'L'
        (1..2).each do |p|
          r = @t.player(p).find_result(1)
          r.rateable = false
          r.score = 'L'
        end
        expect(@t.invalid).to be_falsey
      end
    end

    context "renumbering" do
      before(:each) do
        @t = Tournament.new('Edinburgh Masters', '2009-11-09')
        @t.add_player(@mark = Player.new('Mark', 'Orr', 20))
        @t.add_player(@boby = Player.new('Bobby', 'Fischer', 10))
        @t.add_player(@gary = Player.new('Gary', 'Kasparov', 30))
        @t.add_result(Result.new(1, 20, 'W', :opponent => 10))
        @t.add_result(Result.new(2, 30, 'W', :opponent => 10))
        @t.add_result(Result.new(3, 20, 'W', :opponent => 30))
      end

      it "sample tournament is valid but unranked" do
        expect(@t.invalid).to be_falsey
        expect(@t.player(10).rank).to be_nil
        expect(@t.players.map{ |p| p.num }.join('|')).to eq('10|20|30')
        expect(@t.players.map{ |p| p.last_name }.join('|')).to eq('Fischer|Orr|Kasparov')
      end

      it "should be renumberable by name in the absence of ranking" do
        @t.renumber
        expect(@t.invalid).to be_falsey
        expect(@t.players.map{ |p| p.num }.join('|')).to eq('1|2|3')
        expect(@t.players.map{ |p| p.last_name }.join('|')).to eq('Fischer|Kasparov|Orr')
      end

      it "should be renumberable by rank if the tournament is ranked" do
        @t.rerank.renumber
        expect(@t.invalid).to be_falsey
        expect(@t.players.map{ |p| p.num }.join('|')).to eq('1|2|3')
        expect(@t.players.map{ |p| p.rank }.join('|')).to eq('1|2|3')
        expect(@t.players.map{ |p| p.last_name }.join('|')).to eq('Orr|Kasparov|Fischer')
      end

      it "should be renumberable by name even if the tourament is ranked" do
        @t.rerank.renumber(:name)
        expect(@t.invalid).to be_falsey
        expect(@t.players.map{ |p| p.num }.join('|')).to eq('1|2|3')
        expect(@t.players.map{ |p| p.last_name }.join('|')).to eq('Fischer|Kasparov|Orr')
      end

      it "should be renumberable by order" do
        @t.rerank.renumber(:order)
        expect(@t.invalid).to be_falsey
        expect(@t.players.map{ |p| p.num }.join('|')).to eq('1|2|3')
        expect(@t.players.map{ |p| p.last_name }.join('|')).to eq('Fischer|Orr|Kasparov')
      end
    end

    context "reranking" do
      before(:each) do
        @t = Tournament.new('Edinburgh Masters', '2009-11-09')
        @t.add_player(@boby = Player.new('Bobby', 'Fischer', 1, :rating => 2600))
        @t.add_player(@gary = Player.new('Gary', 'Kasparov', 2, :rating => 2700))
        @t.add_player(@boby = Player.new('Micky', 'Mouse', 3))
        @t.add_player(@boby = Player.new('Minnie', 'Mouse', 4, :rating => 1500))
        @t.add_player(@boby = Player.new('Gearoidin', 'Ui Laighleis', 5, :rating => 1700))
        @t.add_player(@mark = Player.new('Mark', 'Orr', 6, :rating => 2300))
        @t.add_result(Result.new(1, 1, 'W', :opponent => 6, :colour => 'W'))
        @t.add_result(Result.new(2, 1, 'W', :opponent => 3, :colour => 'B'))
        @t.add_result(Result.new(3, 1, 'W', :opponent => 5, :colour => 'W'))
        @t.add_result(Result.new(1, 2, 'W', :opponent => 5, :colour => 'B'))
        @t.add_result(Result.new(2, 2, 'W', :opponent => 4, :colour => 'W'))
        @t.add_result(Result.new(3, 2, 'W', :opponent => 3, :colour => 'B'))
        @t.add_result(Result.new(1, 3, 'W', :opponent => 4, :colour => 'W'))
        @t.add_result(Result.new(3, 4, 'W', :opponent => 6, :colour => 'W'))
        @t.add_result(Result.new(2, 5, 'D', :opponent => 6, :colour => 'W'))
      end

      it "should initially be valid but unranked" do
        expect(@t.invalid).to be_falsey
        expect(@t.player(1).rank).to be_nil
      end

      it "should have correct default tie break scores" do
        scores = @t.tie_break_scores
        expect(scores[1]).to eq('Fischer, Bobby')
        expect(scores[5]).to eq('Ui Laighleis, Gearoidin')
      end

      it "should have correct actual scores" do
        expect(@t.player(1).points).to eq(3.0)
        expect(@t.player(2).points).to eq(3.0)
        expect(@t.player(3).points).to eq(1.0)
        expect(@t.player(4).points).to eq(1.0)
        expect(@t.player(5).points).to eq(0.5)
        expect(@t.player(6).points).to eq(0.5)
      end

      it "should have correct Buchholz tie break scores" do
        @t.tie_breaks = ["Buchholz"]
        scores = @t.tie_break_scores
        expect(scores[1]).to eq(2.0)
        expect(scores[2]).to eq(2.5)
        expect(scores[3]).to eq(7.0)
        expect(scores[4]).to eq(4.5)
        expect(scores[5]).to eq(6.5)
        expect(scores[6]).to eq(4.5)
      end

      it "Buchholz should be sensitive to unplayed games" do
        @t.player(1).find_result(1).opponent = nil
        @t.player(6).find_result(1).opponent = nil
        @t.tie_breaks = ["Buchholz"]
        scores = @t.tie_break_scores
        expect(scores[1]).to eq(1.5)  # 0.5 from Orr changed to 0
        expect(scores[2]).to eq(2.5)  # didn't play Fischer or Orr so unaffected
        expect(scores[3]).to eq(6.5)  # 3 from Fischer's changed to 2.5
        expect(scores[4]).to eq(5.0)  # 0.5 from Orr changed to 1 (because Orr's unrated loss to Fischer now counts as a draw)
        expect(scores[5]).to eq(6.5)  # 3 from Fischer changed to 2.5, 0.5 from Orr changed to 1 (cancels out)
        expect(scores[6]).to eq(1.5)  # 3 from Fischer changed to 0
      end

      it "should have correct progressive tie break scores" do
        @t.tie_breaks = [:progressive]
        scores = @t.tie_break_scores
        expect(scores[1]).to eq(6.0)
        expect(scores[2]).to eq(6.0)
        expect(scores[3]).to eq(3.0)
        expect(scores[4]).to eq(1.0)
        expect(scores[5]).to eq(1.0)
        expect(scores[6]).to eq(1.0)
      end

      it "should have correct ratings tie break scores" do
        @t.tie_breaks = ['ratings']
        scores = @t.tie_break_scores
        expect(scores[1]).to eq(4000)
        expect(scores[2]).to eq(3200)
        expect(scores[3]).to eq(6800)
        expect(scores[4]).to eq(5000)
        expect(scores[5]).to eq(7600)
        expect(scores[6]).to eq(5800)
      end

      it "should have correct Neustadtl tie break scores" do
        @t.tie_breaks = [:neustadtl]
        scores = @t.tie_break_scores
        expect(scores[1]).to eq(2.0)
        expect(scores[2]).to eq(2.5)
        expect(scores[3]).to eq(1.0)
        expect(scores[4]).to eq(0.5)
        expect(scores[5]).to eq(0.25)
        expect(scores[6]).to eq(0.25)
      end

      it "Neustadtl should be sensitive to unplayed games" do
        @t.player(1).find_result(1).opponent = nil
        @t.player(6).find_result(1).opponent = nil
        @t.tie_breaks = ["Neustadtl"]
        scores = @t.tie_break_scores
        expect(scores[1]).to eq(1.5)  # 0.5 from Orr changed to 0
        expect(scores[2]).to eq(2.5)  # didn't play Fischer or Orr so unaffected
        expect(scores[3]).to eq(1.0)  # win against Minnie unaffected
        expect(scores[4]).to eq(1.0)  # 0.5 from Orr changed to 1 (because Orr's unrated loss to Fischer now counts as a draw)
        expect(scores[5]).to eq(0.5)  # 0.25 from Orr changed to 0.5
        expect(scores[6]).to eq(0.25) # loss against Fisher and unplayed against Fisher equivalent
      end

      it "should have correct Harkness tie break scores" do
        @t.tie_breaks = ['harkness']
        scores = @t.tie_break_scores
        expect(scores[1]).to eq(0.5)
        expect(scores[2]).to eq(1.0)
        expect(scores[3]).to eq(3.0)
        expect(scores[4]).to eq(1.0)
        expect(scores[5]).to eq(3.0)
        expect(scores[6]).to eq(1.0)
      end

      it "should have correct Modified Median tie break scores" do
        @t.tie_breaks = ['Modified Median']
        scores = @t.tie_break_scores
        expect(scores[1]).to eq(1.5)
        expect(scores[2]).to eq(2.0)
        expect(scores[3]).to eq(4.0)
        expect(scores[4]).to eq(1.5)
        expect(scores[5]).to eq(3.5)
        expect(scores[6]).to eq(1.5)
      end

      it "should have correct tie break scores for number of blacks" do
        @t.tie_breaks = ['Blacks']
        scores = @t.tie_break_scores
        expect(scores[3]).to eq(0)
        expect(scores[4]).to eq(2)
      end

      it "number of blacks should should be sensitive to unplayed games" do
        @t.player(2).find_result(1).opponent = nil
        @t.player(4).find_result(1).opponent = nil
        @t.tie_breaks = [:blacks]
        scores = @t.tie_break_scores
        expect(scores[3]).to eq(0)
        expect(scores[4]).to eq(1)
      end

      it "should have correct tie break scores for number of wins" do
        @t.tie_breaks = [:wins]
        scores = @t.tie_break_scores
        expect(scores[1]).to eq(3)
        expect(scores[6]).to eq(0)
      end

      it "number of wins should should be sensitive to unplayed games" do
        @t.player(1).find_result(1).opponent = nil
        @t.player(6).find_result(1).opponent = nil
        @t.tie_breaks = ['WINS']
        scores = @t.tie_break_scores
        expect(scores[1]).to eq(2)
        expect(scores[6]).to eq(0)
      end

      it "should use names for tie breaking by default" do
        @t.rerank
        expect(@t.player(1).rank).to eq(1)  # 3.0/"Fischer"
        expect(@t.player(2).rank).to eq(2)  # 3.0/"Kasparov"
        expect(@t.player(3).rank).to eq(3)  # 1.0/"Mouse,Mickey"
        expect(@t.player(4).rank).to eq(4)  # 1.0/"Mouse,Minnie"
        expect(@t.player(6).rank).to eq(5)  # 0.5/"Ui"
        expect(@t.player(5).rank).to eq(6)  # 0.5/"Orr"
      end

      it "should be configurable to use Buchholz" do
        @t.tie_breaks = ['Buchholz']
        @t.rerank
        expect(@t.player(2).rank).to eq(1)  # 3.0/2.5
        expect(@t.player(1).rank).to eq(2)  # 3.0/2.0
        expect(@t.player(3).rank).to eq(3)  # 1.0/7.0
        expect(@t.player(4).rank).to eq(4)  # 1.0/4.5
        expect(@t.player(5).rank).to eq(5)  # 0.5/6.5
        expect(@t.player(6).rank).to eq(6)  # 0.5/4.5
      end

      it "should be configurable to use Neustadtl" do
        @t.tie_breaks = [:neustadtl]
        @t.rerank
        expect(@t.player(2).rank).to eq(1)  # 3.0/2.5
        expect(@t.player(1).rank).to eq(2)  # 3.0/2.0
        expect(@t.player(3).rank).to eq(3)  # 1.0/1.0
        expect(@t.player(4).rank).to eq(4)  # 1.0/0.5
        expect(@t.player(6).rank).to eq(5)  # 0.5/0.25/"Orr"
        expect(@t.player(5).rank).to eq(6)  # 0.5/0.25/"Ui"
      end

      it "should be configurable to use number of blacks" do
        @t.tie_breaks = [:blacks]
        @t.rerank
        expect(@t.player(2).rank).to eq(1)  # 3.0/2
        expect(@t.player(1).rank).to eq(2)  # 3.0/1
        expect(@t.player(4).rank).to eq(3)  # 1.0/2
        expect(@t.player(3).rank).to eq(4)  # 1.0/1
        expect(@t.player(6).rank).to eq(5)  # 0.5/2
        expect(@t.player(5).rank).to eq(6)  # 0.5/1
      end

      it "should be configurable to use number of wins" do
        @t.tie_breaks = [:wins]
        @t.rerank
        expect(@t.player(1).rank).to eq(1)  # 3.0/3/"Fi"
        expect(@t.player(2).rank).to eq(2)  # 3.0/3/"Ka"
        expect(@t.player(3).rank).to eq(3)  # 1.0/1/"Mic"
        expect(@t.player(4).rank).to eq(4)  # 1.0/1/"Min"
        expect(@t.player(6).rank).to eq(5)  # 0.5/0/"Orr"
        expect(@t.player(5).rank).to eq(6)  # 0.5/0/"Ui"
      end

      it "should exhibit equivalence between Neustadtl and Sonneborn-Berger" do
        @t.tie_breaks = ['Sonneborn-Berger']
        @t.rerank
        expect((1..6).inject(''){ |t,r| t << @t.player(r).rank.to_s }).to eq('213465')
      end

      it "should be able to use more than one method" do
        @t.tie_breaks = [:neustadtl, :buchholz]
        @t.rerank
        expect(@t.player(2).rank).to eq(1)  # 3.0/2.5
        expect(@t.player(1).rank).to eq(2)  # 3.0/2.0
        expect(@t.player(3).rank).to eq(3)  # 1.0/1.0
        expect(@t.player(4).rank).to eq(4)  # 1.0/0.5
        expect(@t.player(5).rank).to eq(5)  # 0.5/0.25/6.5
        expect(@t.player(6).rank).to eq(6)  # 0.5/0.25/4.5
      end

      it "should be possible as a side effect of validation" do
        @t.tie_breaks = [:buchholz]
        expect(@t.invalid(:rerank => true)).to be_falsey
        expect(@t.player(2).rank).to eq(1)  # 3/3
        expect(@t.player(1).rank).to eq(2)  # 3/2
        expect(@t.player(3).rank).to eq(3)  # 1/7
        expect(@t.player(4).rank).to eq(4)  # 1/4
        expect(@t.player(5).rank).to eq(5)  # 1/6
        expect(@t.player(6).rank).to eq(6)  # 0/5
      end

      it "should be possible as a side effect of validation with multiple tie break methods" do
        @t.tie_breaks = [:neustadtl, :buchholz]
        expect(@t.invalid(:rerank => true)).to be_falsey
        expect(@t.player(2).rank).to eq(1)  # 3/3
        expect(@t.player(1).rank).to eq(2)  # 3/2
        expect(@t.player(3).rank).to eq(3)  # 1/7
        expect(@t.player(4).rank).to eq(4)  # 1/4
        expect(@t.player(5).rank).to eq(5)  # 1/6
        expect(@t.player(6).rank).to eq(6)  # 0/5
      end
    end

    context "convenience file parser" do
      before(:all) do
        @s = File.dirname(__FILE__) + '/samples'
        @c = ICU::Tournament
      end

      it "should parse a valid SwissPerfect file" do
        t = nil
        expect { t = @c.parse_file!("#{@s}/sp/nccz.zip", 'SwissPerfect', :start => '2010-05-08') }.not_to raise_error
        expect(t.players.size).to eq(77)
        expect(t.start).to eq('2010-05-08')
      end

      it "should parse a valid CSV file" do
        t = nil
        expect { t = @c.parse_file!("#{@s}/fcsv/valid.csv", 'ForeignCSV') }.not_to raise_error
        expect(t.players.size).to eq(16)
      end

      it "should parse a valid Krause file" do
        t = nil
        expect { t = @c.parse_file!("#{@s}/krause/valid.tab", 'Krause') }.not_to raise_error
        expect(t.players.size).to eq(12)
      end

      it "should ignore options where appropriate" do
        t = nil
        expect { t = @c.parse_file!("#{@s}/krause/valid.tab", 'Krause', :start => '2010-05-08') }.not_to raise_error
        expect(t.start).to eq('2008-02-01')
      end

      it "should raise exceptions for invalid files" do
        expect { @c.parse_file!("#{@s}/sp/notenoughfiles.zip", 'SwissPerfect', :start => '2010-05-08') }.to raise_error(/files/)
        expect { @c.parse_file!("#{@s}/krause/invalid.tab", 'Krause') }.to raise_error(/name/)
        expect { @c.parse_file!("#{@s}/fcsv/invalid.csv", 'ForeignCSV') }.to raise_error(/termination/)
      end

      it "should raise exceptions if the wrong type is used" do
        expect { @c.parse_file!("#{@s}/krause/valid.tab", 'ForeignCSV') }.to raise_error(/expected/)
        expect { @c.parse_file!("#{@s}/fcsv/valid.csv", 'SwissPerfect') }.to raise_error(/cannot/)
        expect { @c.parse_file!("#{@s}/sp/nccz.zip", 'Krause') }.to raise_error(/(invalid|conversion)/i)
      end

      it "should raise an exception if file does not exist" do
        expect { @c.parse_file!("#{@s}/nosuchfile.cvs", 'ForeignCSV') }.to raise_error(/no such file/i)
        expect { @c.parse_file!("#{@s}/nosuchfile.zip", 'SwissPerfect') }.to raise_error(/invalid/i)
        expect { @c.parse_file!("#{@s}/nosuchfile.tab", 'Krause') }.to raise_error(/no such file/i)
      end

      it "should raise an exception if an invalid type is used" do
        expect { @c.parse_file!("#{@s}/krause/valid.tab", 'NoSuchType') }.to raise_error(/invalid format/i)
      end
    end

    context "type specific validation" do
      before(:all) do
        @t = Tournament.new('Bangor Bash', '2009-11-09')
        @t.add_player(Player.new('Bobby', 'Fischer', 1))
        @t.add_player(Player.new('Garry', 'Kasparov', 2))
        @t.add_player(Player.new('Mark', 'Orr', 3))
        @t.add_result(Result.new(1, 1, '=', :opponent => 2, :colour => 'W'))
        @t.add_result(Result.new(2, 2, 'L', :opponent => 3, :colour => 'W'))
        @t.add_result(Result.new(3, 3, 'W', :opponent => 1, :colour => 'W'))
      end

      it "should pass generic validation" do
        expect(@t.invalid).to be_falsey
      end

      it "should fail type-specific validation when the type supplied is inappropriate" do
        expect(@t.invalid(:type => String)).to match(/invalid type/)
        expect(@t.invalid(:type => "AbCd")).to match(/invalid type/)
      end
    end
  end
end
