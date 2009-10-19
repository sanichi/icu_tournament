require File.dirname(__FILE__) + '/spec_helper'

module ICU
  class Tournament
    describe ForeignCSV do
      def check_player(num, first, last, results, rateable, points, other={})
        p = @t.player(num)
        p.first_name.should == first
        p.last_name.should == last
        p.id.should == other[:id]
        p.rating.should == other[:rating]
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
          check_player(2, 'April',     'Cronin',       1, 0, 1.0, :rating => 2005, :fed => 'IRL')
          check_player(3, 'Suzanne',   'Connolly',     1, 0, 0.5, :rating => 1950, :fed => 'IRL')
          check_player(4, 'Linda',     'Powell',       1, 0, 0.0, :rating => 1850, :fed => 'WLS')
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
          check_player(2, 'Gary',      'Kasparov',     1, 0, 0.5, :rating => 2800, :fed => 'RUS', :title => 'GM')
          check_player(3, 'April',     'Cronin',       2, 0, 1.0, :rating => 2005, :fed => 'IRL')
          check_player(5, 'Bobby',     'Fischer',      1, 0, 0.0, :rating => 2700, :fed => 'USA', :title => 'GM')
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
          check_player(1, 'Gearoidin', 'Ui Laighleis', 2, 2, 1.0, :rating => 1800, :fed => 'IRL', :id => 3364)
          check_player(3, 'Mark',      'Orr',          2, 2, 1.0, :rating => 2100, :fed => 'IRL', :id => 1350, :title => 'IM')
          check_player(2, 'Gary',      'Kasparov',     1, 0, 0.5, :rating => 2800, :fed => 'RUS')
          check_player(4, 'April',     'Cronin',       1, 0, 0.5, :rating => 2005, :fed => 'IRL')
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
          check_player(2, 'Gary',      'Kasparov',     1, 0, 0.5, :rating => 2800, :fed => 'RUS', :title => 'GM')
          check_player(3, 'Mark',      'Orr',          1, 0, 0.5, :rating => 2100, :fed => 'IRL', :title => 'IM')
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
      
      context "serialisation" do
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

        it "should return nil on invalid input" do
          @f.serialize('Rubbish').should be_nil
        end
      end
    end
  end
end
