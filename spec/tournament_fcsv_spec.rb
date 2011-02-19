# encoding: UTF-8
require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

module ICU
  class Tournament
    describe ForeignCSV do
      def check_player(num, first, last, results, rateable, points, other={})
        p = @t.player(num)
        p.first_name.should == first
        p.last_name.should == last
        p.id.should == other[:id]
        p.fide_rating.should == other[:fide_rating]
        p.fed.should == other[:fed]
        p.title.should == other[:title]
        p.results.size.should == results
        p.results.select{|r| r.rateable}.size.should == rateable
        p.points.should == points
      end

      context "a typical tournament" do
        before(:all) do
          @csv = <<CSV
Event,"Bangor Open, 2003"
Start,1st July 2003
Rounds,4
Website,http://www.icu.ie/tournaments/display.php?id=371

Player,3364,Ui Laighleis,Gearoidin
1,0,B,Cronin,April,2005,,IRL
2,=,W,Connolly,Suzanne,1950,,IRL
3,=,-
4,1,B,Powell,Linda,1850,,WLS
Total,2
CSV
          @f = ICU::Tournament::ForeignCSV.new
          @t = @f.parse!(@csv)
        end

        it "should have a name" do
          @t.name.should == 'Bangor Open, 2003'
        end

        it "should have a start date" do
          @t.start.should == '2003-07-01'
        end

        it "should have a number of rounds" do
          @t.rounds.should == 4
        end

        it "should have a website" do
          @t.site.should == 'http://www.icu.ie/tournaments/display.php?id=371'
        end

        it "should have some players" do
          @t.should have(4).players
        end

        it "should have correct player details" do
          check_player(1, 'Gearoidin', 'Ui Laighleis', 4, 3, 2.0, :id => 3364)
          check_player(2, 'April',     'Cronin',       1, 0, 1.0, :fide_rating => 2005, :fed => 'IRL')
          check_player(3, 'Suzanne',   'Connolly',     1, 0, 0.5, :fide_rating => 1950, :fed => 'IRL')
          check_player(4, 'Linda',     'Powell',       1, 0, 0.0, :fide_rating => 1850, :fed => 'WLS')
        end
      end

      context "the rdoc example tournament" do
        before(:all) do
          @csv = <<CSV
Event,"Isle of Man Masters, 2007"
Start,2007-09-22
Rounds,9
Website,http://www.bcmchess.co.uk/monarch2007/

Player,456,Fox,Anthony
1,0,B,Taylor,Peter P.,2209,,ENG
2,=,W,Nadav,Egozi,2205,,ISR
3,=,B,Cafolla,Peter,2048,,IRL
4,1,W,Spanton,Tim R.,1982,,ENG
5,1,B,Grant,Alan,2223,,SCO
6,0,-
7,=,W,Walton,Alan J.,2223,,ENG
8,0,B,Bannink,Bernard,2271,FM,NED
9,=,W,Phillips,Roy,2271,,MAU
Total,4
CSV
          @f = ICU::Tournament::ForeignCSV.new
          @t = @f.parse!(@csv)
          @p = @t.player(1)
          @o = @t.players.reject { |o| o.num == 1 }
          @r = @t.player(2)
        end

        it "should have correct basic details" do
          @t.name.should == 'Isle of Man Masters, 2007'
          @t.start.should == '2007-09-22'
          @t.rounds.should == 9
          @t.site.should == 'http://www.bcmchess.co.uk/monarch2007/'
        end

        it "should have the right number of players in the right order" do
          @t.players.size.should == 9
          @t.players.inject(''){ |a,o| a << o.num.to_s }.should == '123456789'
        end

        it "should have the right details for the main player" do
          @p.name.should == "Fox, Anthony"
          @p.results.size == 9
          @p.results.find_all{ |r| r.rateable }.size.should == 8
          @p.points.should == 4.0
        end

        it "should have the right details for the opponents" do
          @o.size.should == 8
          @o.find_all{ |o| o.results.size == 1}.size.should == 8
          @r.name.should == "Taylor, Peter P."
          @r.results[0].rateable.should be_false
        end
      end

      context "a tournament with more than one player" do
        before(:all) do
          @csv = <<CSV
Event,"Edinburgh Masters, 2007"
Start,3rd January 2007
Rounds,2
Website,http://www.chesscenter.com/twic/twic.html

Player,3364,Ui Laighleis,Gearoidin
1,=,W,Kasparov,Gary,2800,GM,RUS
2,=,B,Cronin,April,2005,,IRL
Total,1.0

Player,1350,Orr,Mark
1,=,W,Cronin,April,2005,,IRL
2,1,B,Fischer,Bobby,2700,GM,USA
Total,1.5
CSV
          @f = ICU::Tournament::ForeignCSV.new
          @t = @f.parse!(@csv)
        end

        it "should have the usual basic details" do
          @t.name.should == 'Edinburgh Masters, 2007'
          @t.start.should == '2007-01-03'
          @t.rounds.should == 2
          @t.site.should == 'http://www.chesscenter.com/twic/twic.html'
        end

        it "should have the correct number of players" do
          @t.should have(5).players
        end

        it "should have correct player details" do
          check_player(1, 'Gearoidin', 'Ui Laighleis', 2, 2, 1.0, :id => 3364)
          check_player(4, 'Mark',      'Orr',          2, 2, 1.5, :id => 1350)
          check_player(2, 'Gary',      'Kasparov',     1, 0, 0.5, :fide_rating => 2800, :fed => 'RUS', :title => 'GM')
          check_player(3, 'April',     'Cronin',       2, 0, 1.0, :fide_rating => 2005, :fed => 'IRL')
          check_player(5, 'Bobby',     'Fischer',      1, 0, 0.0, :fide_rating => 2700, :fed => 'USA', :title => 'GM')
        end
      end

      context "a tournament where someone is both a player and an opponent" do
        before(:all) do
          @csv = <<CSV
Event,"Bratto Open, 2001"
Start,7th March 2001
Rounds,2
Website,http://www.federscacchi.it/

Player,3364,Ui Laighleis,Gearoidin
1,=,W,Kasparov,Gary,2800,,RUS
2,=,B,Orr,Mark,2100,IM,IRL
Total,1.0

Player,1350,Orr,Mark
1,=,W,Cronin,April,2005,,IRL
2,=,W,Ui Laighleis,Gearoidin,1800,,IRL
Total,1.0
CSV
          @f = ICU::Tournament::ForeignCSV.new
          @t = @f.parse!(@csv)
        end

        it "should have the usual basic details" do
          @t.name.should == 'Bratto Open, 2001'
          @t.start.should == '2001-03-07'
          @t.rounds.should == 2
          @t.site.should == 'http://www.federscacchi.it/'
        end

        it "should have the correct number of players" do
          @t.should have(4).players
        end

        it "should have correct player details" do
          check_player(1, 'Gearoidin', 'Ui Laighleis', 2, 2, 1.0, :fide_rating => 1800, :fed => 'IRL', :id => 3364)
          check_player(3, 'Mark',      'Orr',          2, 2, 1.0, :fide_rating => 2100, :fed => 'IRL', :id => 1350, :title => 'IM')
          check_player(2, 'Gary',      'Kasparov',     1, 0, 0.5, :fide_rating => 2800, :fed => 'RUS')
          check_player(4, 'April',     'Cronin',       1, 0, 0.5, :fide_rating => 2005, :fed => 'IRL')
        end
      end

      context "a file that contains spurious white space and other untidiness" do
        before(:all) do
          @csv = <<CSV

 Event," Bratto Open, 2001 "
Start, 7th  March  2001
 Rounds, 2
  Website, http://www.federscacchi.it/
Player ,3364 , ui Laighleis, gearoidin

1, = ,W, kasparov,  gary, 2800 , g , Rus

 2 ,=, b, Orr , Mark,2100, iM , irl
Total,1.0

CSV
          @f = ICU::Tournament::ForeignCSV.new
          @t = @f.parse!(@csv)
        end

        it "should have the correct basic details" do
          @t.name.should == 'Bratto Open, 2001'
          @t.start.should == '2001-03-07'
          @t.rounds.should == 2
          @t.site.should == 'http://www.federscacchi.it/'
        end

        it "should have the correct number of players" do
          @t.should have(3).players
        end

        it "should have correct player details" do
          check_player(1, 'Gearoidin', 'Ui Laighleis', 2, 2, 1.0, :id => 3364)
          check_player(2, 'Gary',      'Kasparov',     1, 0, 0.5, :fide_rating => 2800, :fed => 'RUS', :title => 'GM')
          check_player(3, 'Mark',      'Orr',          1, 0, 0.5, :fide_rating => 2100, :fed => 'IRL', :title => 'IM')
        end
        
        it "should still have original names" do
          @t.player(1).original_name.should == "ui Laighleis, gearoidin"
          @t.player(2).original_name.should == "kasparov, gary"
          @t.player(3).original_name.should == "Orr, Mark"
        end
      end

      context "#parse" do
        before(:each) do
          @f = ICU::Tournament::ForeignCSV.new
        end

        it "should behave just like #parse! on success" do
          csv = <<CSV
Event,"Bratto Open, 2001"
Start,7th March 2001
Rounds,2
Website,http://www.federscacchi.it/

Player,3364,Ui Laighleis,Gearoidin
1,=,W,Kasparov,Gary,2800,GM,RUS
2,=,B,Orr,Mark,2100,IM,IRL
Total,1.0
CSV
          @f.parse(csv).should be_an_instance_of(ICU::Tournament)
          @f.error.should be_nil
        end

        it "should not throw an exception but return nil on error" do
          @f.parse(' ').should be_nil
          @f.error.should match(/event/)
        end
      end

      context "invalid files" do
        before(:each) do
          @f = ICU::Tournament::ForeignCSV.new
        end

        it "a blank file is invalid" do
          lambda { @f.parse!(' ') }.should raise_error(/event/i)
        end

        it "the event should come first" do
          csv = <<CSV
Start,7th March 2001
Event,"Bratto Open, 2001"
Rounds,2
Website,http://www.federscacchi.it/
CSV
          lambda { @f.parse!(csv) }.should raise_error(/line 1.*event/i)
        end

        it "the start should come second" do
          csv = <<CSV
Event,"Bratto Open, 2001"
Rounds,2
Start,7th March 2001
Website,http://www.federscacchi.it/
CSV
          lambda { @f.parse!(csv) }.should raise_error(/line 2.*start/i)
        end

        it "the number of rounds should come third" do
          csv = <<CSV
Event,"Bratto Open, 2001"
Start,7th March 2001
Website,http://www.federscacchi.it/
Rounds,2
CSV
          lambda { @f.parse!(csv) }.should raise_error(/line 3.*rounds/i)
        end

        it "there should be a web site" do
          csv = <<CSV
Event,"Bratto Open, 2001"
Start,7th March 2001
Rounds,2

CSV
          lambda { @f.parse!(csv) }.should raise_error(/line 4.*site/i)
        end

        it "should have at least one player" do
          csv = <<CSV
Event,"Bratto Open, 2001"
Start,7th March 2001
Rounds,2
Website,http://www.federscacchi.it/
CSV
          lambda { @f.parse!(csv) }.should raise_error(/line 4.*no players/i)
        end

        it "the player needs to have a valid ID number" do
          csv = <<CSV
Event,"Bratto Open, 2001"
Start,7th March 2001
Rounds,2
Website,http://www.federscacchi.it/

Player,0,Ui Laighleis,Gearoidin
CSV
          lambda { @f.parse!(csv) }.should raise_error(/line 6.*number/i)
        end

        it "should have the right number of results for each player" do
          csv = <<CSV
Event,"Bratto Open, 2001"
Start,7th March 2001
Rounds,2
Website,http://www.federscacchi.it/

Player,3364,Ui Laighleis,Gearoidin
1,=,W,Kasparov,Gary,2800,GM,RUS
Total,0.5
CSV
          lambda { @f.parse!(csv) }.should raise_error(/line 8.*round/i)
        end

        it "should have correct totals" do
          csv = <<CSV
Event,"Bratto Open, 2001"
Start,7th March 2001
Rounds,2
Website,http://www.federscacchi.it/

Player,3364,Ui Laighleis,Gearoidin
1,=,W,Kasparov,Gary,2800,GM,RUS
2,=,B,Orr,Mark,2100,IM,IRL
Total,1.5
CSV
          lambda { @f.parse!(csv) }.should raise_error(/line 9.*total/i)
        end


        it "players who match by name and federation should match in all other details" do
          csv = <<CSV
Event,"Bratto Open, 2001"
Start,7th March 2001
Rounds,2
Website,http://www.federscacchi.it/

Player,3364,Ui Laighleis,Gearoidin
1,=,W,Kasparov,Gary,2800,GM,RUS
2,=,B,Orr,Mark,2100,IM,IRL
Total,1.0

Player,1350,Orr,Mark
1,=,W,Fischer,Bobby,2700,,USA
2,=,B,Kasparov,Gary,2850,GM,RUS
Total,1.0
CSV
          lambda { @f.parse!(csv) }.should raise_error(/line 13.*same name.*conflicting/i)
        end
      end

      context "serialisation of simple tournament" do
        before(:each) do
          @csv = <<CSV
Event,"Edinburgh Masters, 2007"
Start,2007-08-09
Rounds,2
Website,http://www.chesscenter.com/twic/twic.html

Player,3364,Ui Laighleis,Gearoidin
1,0,W,Kasparov,Gary,2800,GM,RUS
2,1,B,Cronin,April,2005,,IRL
Total,1.0

Player,1350,Orr,Mark
1,=,W,Cronin,April,2005,,IRL
2,=,-
Total,1.0
CSV
          @f = ICU::Tournament::ForeignCSV.new
          @t = @f.parse!(@csv)
        end

        it "should serialize back to the original" do
          @f.serialize(@t).should == @csv
        end
      end

      context "serialisation of ForeignCSV documentation example" do
        before(:each) do
          @csv = <<CSV
Event,"Isle of Man Masters, 2007"
Start,2007-09-22
Rounds,9
Website,http://www.bcmchess.co.uk/monarch2007/

Player,456,Fox,Anthony
1,0,B,Taylor,Peter P.,2209,,ENG
2,=,W,Nadav,Egozi,2205,,ISR
3,=,B,Cafolla,Peter,2048,,IRL
4,1,W,Spanton,Tim R.,1982,,ENG
5,1,B,Grant,Alan,2223,,SCO
6,0,-
7,=,W,Walton,Alan J.,2223,,ENG
8,0,B,Bannink,Bernard,2271,FM,NED
9,=,W,Phillips,Roy,2271,,MAU
Total,4.0

Player,159,Cafolla,Peter
1,0,W,Jackson,Oliver A.,2198,,ENG
2,0,B,Jeroen,Van Den Berssalaar,,,NED
3,=,W,Fox,Anthony,2100,,IRL
4,=,B,Collins,Sam E.,2394,IM,IRL
5,1,W,Troyke,Doreen,2151,WFM,GER
6,=,B,Nelson,Jonathan P.,2282,,ENG
7,0,W,Egozi,Nadav,2205,,ISR
8,=,B,Weeks,Manuel,2200,FM,AUS
9,0,W,Grant,Alan,2223,,SCO
Total,3.0
CSV
          @t = ICU::Tournament.new("Isle of Man Masters, 2007", '2007-09-22')
          @t.site = 'http://www.bcmchess.co.uk/monarch2007/'
          @t.rounds = 9
          @t.add_player(ICU::Player.new('Anthony', 'Fox', 1, :id => 456, :fide_rating => 2100, :fed => 'IRL'))
          @t.add_player(ICU::Player.new('Peter', 'Cafolla', 2, :id => 159, :fide_rating => 2048, :fed => 'IRL'))
          @t.add_player(ICU::Player.new('Peter P.', 'Taylor', 3, :fide_rating => 2209, :fed => 'ENG'))
          @t.add_player(ICU::Player.new('Egozi', 'Nadav', 4, :fide_rating => 2205, :fed => 'ISR'))
          @t.add_player(ICU::Player.new('Tim R.', 'Spanton', 5, :fide_rating => 1982, :fed => 'ENG'))
          @t.add_player(ICU::Player.new('Alan', 'Grant', 6, :fide_rating => 2223, :fed => 'SCO'))
          @t.add_player(ICU::Player.new('Alan J.', 'Walton', 7, :fide_rating => 2223, :fed => 'ENG'))
          @t.add_player(ICU::Player.new('Bernard', 'Bannink', 8, :fide_rating => 2271, :fed => 'NED', :title => 'FM'))
          @t.add_player(ICU::Player.new('Roy', 'Phillips', 9, :fide_rating => 2271, :fed => 'MAU'))
          @t.add_player(ICU::Player.new('Oliver A.', 'Jackson', 10, :fide_rating => 2198, :fed => 'ENG'))
          @t.add_player(ICU::Player.new('Van Den Berssalaar', 'Jeroen', 11, :fed => 'NED'))
          @t.add_player(ICU::Player.new('Sam E.', 'Collins', 12, :fide_rating => 2394, :fed => 'IRL', :title => 'IM'))
          @t.add_player(ICU::Player.new('Doreen', 'Troyke', 13, :fide_rating => 2151, :fed => 'GER', :title => 'WFM'))
          @t.add_player(ICU::Player.new('Jonathan P.', 'Nelson', 14, :fide_rating => 2282, :fed => 'ENG'))
          @t.add_player(ICU::Player.new('Nadav', 'Egozi', 15, :fide_rating => 2205, :fed => 'ISR'))
          @t.add_player(ICU::Player.new('Manuel', 'Weeks', 16, :fide_rating => 2200, :fed => 'AUS', :title => 'FM'))
          @t.add_player(ICU::Player.new('Alan', 'Grant', 17, :fide_rating => 2223, :fed => 'SCO'))
          @t.add_result(ICU::Result.new(1, 1, 'L', :opponent => 3,  :colour => 'B'))
          @t.add_result(ICU::Result.new(2, 1, 'D', :opponent => 4,  :colour => 'W'))
          @t.add_result(ICU::Result.new(3, 1, 'D', :opponent => 2,  :colour => 'B'))
          @t.add_result(ICU::Result.new(4, 1, 'W', :opponent => 5,  :colour => 'W'))
          @t.add_result(ICU::Result.new(5, 1, 'W', :opponent => 6,  :colour => 'B'))
          @t.add_result(ICU::Result.new(6, 1, 'L'))
          @t.add_result(ICU::Result.new(7, 1, 'D', :opponent => 7,  :colour => 'W'))
          @t.add_result(ICU::Result.new(8, 1, 'L', :opponent => 8,  :colour => 'B'))
          @t.add_result(ICU::Result.new(9, 1, 'D', :opponent => 9,  :colour => 'W'))
          @t.add_result(ICU::Result.new(1, 2, 'L', :opponent => 10, :colour => 'W'))
          @t.add_result(ICU::Result.new(2, 2, 'L', :opponent => 11, :colour => 'B'))
          @t.add_result(ICU::Result.new(3, 2, 'D', :opponent => 1,  :colour => 'W'))
          @t.add_result(ICU::Result.new(4, 2, 'D', :opponent => 12, :colour => 'B'))
          @t.add_result(ICU::Result.new(5, 2, 'W', :opponent => 13, :colour => 'W'))
          @t.add_result(ICU::Result.new(6, 2, 'D', :opponent => 14, :colour => 'B'))
          @t.add_result(ICU::Result.new(7, 2, 'L', :opponent => 15, :colour => 'W'))
          @t.add_result(ICU::Result.new(8, 2, 'D', :opponent => 16, :colour => 'B'))
          @t.add_result(ICU::Result.new(9, 2, 'L', :opponent => 17, :colour => 'W'))
        end

        it "should serialize to the expected string" do
          @t.serialize('ForeignCSV').should == @csv
        end
      end

      context "serialisation of shortened ForeignCSV documentation example" do
        before(:each) do
          @csv = <<CSV
Event,"Isle of Man Masters, 2007"
Start,2007-09-22
Rounds,9
Website,http://www.bcmchess.co.uk/monarch2007/

Player,456,Fox,Anthony
1,0,B,Taylor,Peter P.,2209,,ENG
2,=,W,Nadav,Egozi,2205,,ISR
3,=,B,Cafolla,Peter,2048,,IRL
4,1,W,Spanton,Tim R.,1982,,ENG
5,1,B,Grant,Alan,2223,,SCO
6,0,-
7,=,W,Walton,Alan J.,2223,,ENG
8,0,B,Bannink,Bernard,2271,FM,NED
9,=,W,Phillips,Roy,2271,,MAU
Total,4.0
CSV
          @t = ICU::Tournament.new("Isle of Man Masters, 2007", '2007-09-22')
          @t.site = 'http://www.bcmchess.co.uk/monarch2007/'
          @t.add_player(ICU::Player.new('Anthony', 'Fox', 1, :id => 456, :fide_rating => 2100, :fed => 'IRL'))
          @t.add_player(ICU::Player.new('Peter P.', 'Taylor', 2, :fide_rating => 2209, :fed => 'ENG'))
          @t.add_player(ICU::Player.new('Egozi', 'Nadav', 3, :fide_rating => 2205, :fed => 'ISR'))
          @t.add_player(ICU::Player.new('Peter', 'Cafolla', 4, :fide_rating => 2048, :fed => 'IRL'))
          @t.add_player(ICU::Player.new('Tim R.', 'Spanton', 5, :fide_rating => 1982, :fed => 'ENG'))
          @t.add_player(ICU::Player.new('Alan', 'Grant', 6, :fide_rating => 2223, :fed => 'SCO'))
          @t.add_player(ICU::Player.new('Alan J.', 'Walton', 7, :fide_rating => 2223, :fed => 'ENG'))
          @t.add_player(ICU::Player.new('Bernard', 'Bannink', 8, :fide_rating => 2271, :fed => 'NED', :title => 'FM'))
          @t.add_player(ICU::Player.new('Roy', 'Phillips', 9, :fide_rating => 2271, :fed => 'MAU'))
          @t.add_result(ICU::Result.new(1, 1, 'L', :opponent => 2,  :colour => 'B'))
          @t.add_result(ICU::Result.new(2, 1, 'D', :opponent => 3,  :colour => 'W'))
          @t.add_result(ICU::Result.new(3, 1, 'D', :opponent => 4,  :colour => 'B'))
          @t.add_result(ICU::Result.new(4, 1, 'W', :opponent => 5,  :colour => 'W'))
          @t.add_result(ICU::Result.new(5, 1, 'W', :opponent => 6,  :colour => 'B'))
          @t.add_result(ICU::Result.new(6, 1, 'L'))
          @t.add_result(ICU::Result.new(7, 1, 'D', :opponent => 7,  :colour => 'W'))
          @t.add_result(ICU::Result.new(8, 1, 'L', :opponent => 8,  :colour => 'B'))
          @t.add_result(ICU::Result.new(9, 1, 'D', :opponent => 9,  :colour => 'W'))
          @t.validate!
        end

        it "should serialize to the expected string" do
          @t.serialize('ForeignCSV').should == @csv
        end
      end

      context "encoding" do
        before(:each) do
          @csv = <<CSV
Event,"Brätto Open, 2001"
Start,7th March 2001
Rounds,2
Website,http://www.federscacchi.it/

Player,3364,Uì Laighlèis,Gearoìdin
1,=,W,Kasparov,Gary,2800,GM,RUS
2,=,B,Örr,Mârk,2100,IM,IRL
Total,1.0
CSV
          @f = ICU::Tournament::ForeignCSV.new
        end

        it "should parse UTF-8" do
          lambda { @t = @f.parse!(@csv) }.should_not raise_error
          check_player(1, 'Gearoìdin', 'Uì Laighlèis', 2, 2, 1.0, :id => 3364)
          check_player(2, 'Gary', 'Kasparov', 1, 0, 0.5, :fide_rating => 2800, :fed => 'RUS', :title => 'GM')
          check_player(3, 'Mârk', 'Örr', 1, 0, 0.5, :fide_rating => 2100, :fed => 'IRL', :title => 'IM')
          @t.name.should == "Brätto Open, 2001"
        end

        it "should parse Latin-1" do
          @csv = @csv.encode("ISO-8859-1")
          lambda { @t = @f.parse!(@csv) }.should_not raise_error
          check_player(1, 'Gearoìdin', 'Uì Laighlèis', 2, 2, 1.0, :id => 3364)
          check_player(2, 'Gary', 'Kasparov', 1, 0, 0.5, :fide_rating => 2800, :fed => 'RUS', :title => 'GM')
          check_player(3, 'Mârk', 'Örr', 1, 0, 0.5, :fide_rating => 2100, :fed => 'IRL', :title => 'IM')
          @t.name.should == "Brätto Open, 2001"
        end
      end

      context "parsing files" do
        before(:each) do
          @p = ICU::Tournament::ForeignCSV.new
          @s = File.dirname(__FILE__) + '/samples/fcsv'
        end

        it "should error on a non-existant valid file" do
          file = "#{@s}/not_there.csv"
          lambda { @p.parse_file!(file) }.should raise_error
          t = @p.parse_file(file)
          t.should be_nil
          @p.error.should match(/no such file/i)
        end

        it "should error on an invalid file" do
          file = "#{@s}/invalid.csv"
          lambda { @p.parse_file!(file) }.should raise_error
          t = @p.parse_file(file)
          t.should be_nil
          @p.error.should match(/expected.*event.*name/i)
        end

        it "should parse a valid file" do
          file = "#{@s}/valid.csv"
          lambda { @p.parse_file!(file) }.should_not raise_error
          t = @p.parse_file(file)
          t.should be_an_instance_of(ICU::Tournament)
          t.players.size.should == 16
        end

        it "should parse a file encoded in UTF-8" do
          file = "#{@s}/utf-8.csv"
          lambda { @t = @p.parse_file!(file) }.should_not raise_error
          check_player(1, 'Gearoìdin', 'Uì Laighlèis', 2, 2, 1.0, :id => 3364)
          check_player(2, 'Gary', 'Kasparov', 1, 0, 0.5, :fide_rating => 2800, :fed => 'RUS', :title => 'GM')
          check_player(3, 'Mârk', 'Örr', 1, 0, 0.5, :fide_rating => 2100, :fed => 'IRL', :title => 'IM')
          @t.name.should == "Brätto Open, 2001"
        end

        it "should parse a file encoded in Latin-1" do
          file = "#{@s}/latin-1.csv"
          lambda { @t = @p.parse_file!(file) }.should_not raise_error
          check_player(1, 'Gearoìdin', 'Uì Laighlèis', 2, 2, 1.0, :id => 3364)
          check_player(2, 'Gary', 'Kasparov', 1, 0, 0.5, :fide_rating => 2800, :fed => 'RUS', :title => 'GM')
          check_player(3, 'Mârk', 'Örr', 1, 0, 0.5, :fide_rating => 2100, :fed => 'IRL', :title => 'IM')
          @t.name.should == "Brätto Open, 2001"
        end
      end

      context "type validation" do
        before(:each) do
          @p = ICU::Tournament::ForeignCSV.new
          @t = ICU::Tournament.new("Isle of Man Masters, 2007", '2007-09-22')
          @t.site = 'http://www.bcmchess.co.uk/monarch2007/'
          @t.add_player(ICU::Player.new('Anthony', 'Fox', 1, :id => 456))
          @t.add_player(ICU::Player.new('Peter', 'Cafolla', 2, :id => 159))
          @t.add_player(ICU::Player.new('Peter P.', 'Taylor', 10, :fide_rating => 2209, :fed => 'ENG'))
          @t.add_player(ICU::Player.new('Egozi', 'Nadav', 20, :fide_rating => 2205, :fed => 'ISR'))
          @t.add_player(ICU::Player.new('Tim R.', 'Spanton', 30, :fide_rating => 1982, :fed => 'ENG'))
          @t.add_player(ICU::Player.new('Alan', 'Grant', 40, :fide_rating => 2223, :fed => 'SCO'))
          @t.add_result(ICU::Result.new(1, 1, 'W', :opponent => 10, :colour => 'W'))
          @t.add_result(ICU::Result.new(1, 2, 'L', :opponent => 20, :colour => 'B'))
          @t.add_result(ICU::Result.new(2, 1, 'D', :opponent => 30, :colour => 'B'))
          @t.add_result(ICU::Result.new(2, 2, 'L', :opponent => 40, :colour => 'W'))
        end

        it "should pass" do
          @t.invalid.should be_false
          @t.invalid(:type => @p).should be_false
        end

        it "should fail if there's no site" do
          @t.site = nil;
          @t.invalid(:type => @p).to_s.should match(/site/)
        end

        it "should fail if there are no ICU players" do
          [1, 2].each { |n| @t.player(n).id = nil }
          @t.player(2).id = nil;
          @t.invalid(:type => @p).to_s.should match(/ID/)
        end

        it "should fail unless all foreign players have a federation" do
          @t.player(10).fed = nil;
          @t.invalid(:type => @p).to_s.should match(/federation/)
        end

        it "should fail unless every ICU player has a result in every round" do
          @t.add_player(ICU::Player.new('Mark', 'Orr', 3, :id => 1350))
          @t.add_result(ICU::Result.new(1, 3, 'W', :opponent => 30, :colour => 'B'))
          @t.invalid(:type => @p).to_s.should match(/result/)
          @t.add_result(ICU::Result.new(2, 3, 'W', :opponent => 10, :colour => 'W'))
          @t.invalid(:type => @p).should be_false
        end

        it "should fail unless every ICU player's opponents have a federation" do
          @t.add_player(ICU::Player.new('Mark', 'Orr', 3, :id => 1350))
          @t.add_result(ICU::Result.new(1, 3, 'W', :opponent => 30, :colour => 'B'))
          @t.add_result(ICU::Result.new(2, 3, 'W', :opponent => 10, :colour => 'W'))
          @t.add_result(ICU::Result.new(3, 1, 'D', :opponent => 40, :colour => 'W'))
          @t.add_result(ICU::Result.new(3, 2, 'L', :opponent => 3,  :colour => 'B'))
          @t.invalid(:type => @p).to_s.should match(/opponents.*federation/)
          @t.player(2).fed = 'IRL'
          @t.invalid(:type => @p).to_s.should match(/opponents.*federation/)
          @t.player(3).fed = 'IRL'
          @t.invalid(:type => @p).should be_false
        end

        it "should be serializable unless invalid" do
          lambda { @p.serialize(@t) }.should_not raise_error
          @t.site = nil;
          lambda { @p.serialize(@t) }.should raise_error
        end
      end
    end
  end
end
