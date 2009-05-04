require File.dirname(__FILE__) + '/spec_helper'

module ICU
  class Tournament
    describe Krause do
      def check_player(num, first, last, other={})
        p = @t.player(num)
        p.first_name.should == first
        p.last_name.should  == last
        p.gender.should     == other[:gender]
        p.title.should      == other[:title]
        p.rating.should     == other[:rating]
        p.fed.should        == other[:fed]
        p.id.should         == other[:id]
        p.dob.should        == other[:dob]
        p.rank.should       == other[:rank]
      end
      
      def check_results(num, results, points)
        p = @t.player(num)
        p.results.size.should == results
        p.points.should == points
      end
      
      context "a typical tournament" do
        before(:all) do
          krause = <<KRAUSE
012 Las Vegas National Open
022 Las Vegas
032 USA
042 2008.06.07
052 2008.06.10
062 3
072 3
082 1
092 All-Play-All
102 Hans Scmidt
112 Gerry Graham, Herbert Scarry
122 60 in 2hr, 30 in 1hr, rest in 1hr
013 Coaching Team                      1    2
0         1         2         3         4         5         6         7         8         9         0         1         2
0123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890
132                                                                                        08.02.01  08.02.02  08.02.03
001    1 w    Ui Laighleis,Gearoidin            1985 IRL     2501171 1964.06.10  1.0    2     2 b 0     3 w 1          
001    2 m  m Orr,Mark                          2258 IRL     2500035 1955.11.09  2.0    1     1 w 1               3 b 1
001    3 m  g Bologan,Viktor                    2663 MDA    13900048 1971.01.01  0.0    3               1 b 0     2 w 0
KRAUSE
          @p = Krause.new
          @t = @p.parse!(krause)
        end
        
        it "should have a name, city and federation" do
          @t.name.should == 'Las Vegas National Open'
          @t.city.should == 'Las Vegas'
          @t.fed.should  == 'USA'
        end
        
        it "should have start and end dates" do
          @t.start.should  == '2008-06-07'
          @t.finish.should == '2008-06-10'
        end
        
        it "should have a number of rounds, a type and a time control" do
          @t.rounds.should       == 3
          @t.type.should         == 'All-Play-All'
          @t.time_control.should == '60 in 2hr, 30 in 1hr, rest in 1hr'
        end
        
        it "should have an arbiter and deputies" do
          @t.arbiter.should == 'Hans Scmidt'
          @t.deputy.should  == 'Gerry Graham, Herbert Scarry'
        end
        
        it "should have players and their details" do
          @t.should have(3).players
          check_player(1, 'Gearoidin', 'Ui Laighleis', :gender => 'F', :rating => 1985, :fed => 'IRL', :id =>  2501171, :dob => '1964-06-10', :rank => 2)
          check_player(2, 'Mark', 'Orr',               :gender => 'M', :rating => 2258, :fed => 'IRL', :id =>  2500035, :dob => '1955-11-09', :rank => 1, :title => 'IM')
          check_player(3, 'Viktor', 'Bologan',         :gender => 'M', :rating => 2663, :fed => 'MDA', :id => 13900048, :dob => '1971-01-01', :rank => 3, :title => 'GM')
        end
        
        it "should have correct results for each player" do
          check_results(1, 2, 1.0)
          check_results(2, 2, 2.0)
          check_results(3, 2, 0.0)
        end
        
        it "the parser should retain comment lines" do
          comments = <<COMMENTS
062 3
072 3
082 1
013 Coaching Team                      1    2
0         1         2         3         4         5         6         7         8         9         0         1         2
0123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890
132                                                                                        08.02.01  08.02.02  08.02.03
COMMENTS
          @p.comments.should == comments
        end
      end
      
      context "the documentation example" do
        before(:all) do
          krause = <<KRAUSE
012 Fantasy Tournament
032 IRL
042 2009.09.09
0123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890
001    1 w    Mouse,Minerva                     1900 USA     1234567 1928.05.15  1.0    2     2 b 0     3 w 1          
001    2 m  m Duck,Daffy                        2200 IRL     7654321 1937.04.17  2.0    1     1 w 1               3 b 1
001    3 m  g Mouse,Mickey                      2600 USA     1726354 1928.05.15  0.0    3               1 b 0     2 w 0
KRAUSE
          @p = Krause.new
          @t = @p.parse!(krause)
        end

        it "should have a name and federation" do
          @t.name.should == 'Fantasy Tournament'
          @t.fed.should  == 'IRL'
        end

        it "should have a startdates" do
          @t.start.should  == '2009-09-09'
        end

        it "should have a number of rounds" do
          @t.rounds.should       == 3
        end

        it "should have players and their details" do
          @t.should have(3).players
          check_player(1, 'Minerva', 'Mouse', :gender => 'F', :rating => 1900, :fed => 'USA', :id => 1234567, :dob => '1928-05-15', :rank => 2)
          check_player(2, 'Daffy',   'Duck',  :gender => 'M', :rating => 2200, :fed => 'IRL', :id => 7654321, :dob => '1937-04-17', :rank => 1, :title => 'IM')
          check_player(3, 'Mickey',  'Mouse', :gender => 'M', :rating => 2600, :fed => 'USA', :id => 1726354, :dob => '1928-05-15', :rank => 3, :title => 'GM')
        end

        it "should have correct results for each player" do
          check_results(1, 2, 1.0)
          check_results(2, 2, 2.0)
          check_results(3, 2, 0.0)
        end

        it "the parser should retain comment lines" do
          @p.comments.should == "0123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890\n"
        end
      end
      
      context "serialisation" do
        before(:all) do
          @krause = <<KRAUSE
012 Las Vegas National Open
022 Las Vegas
032 USA
042 2008-06-07
052 2008-06-10
092 All-Play-All
102 Hans Scmidt
112 Gerry Graham, Herbert Scarry
122 60 in 2hr, 30 in 1hr, rest in 1hr
001    1 w    Ui Laighleis,Gearoidin            1985 IRL     2501171 1964-06-10  2.0    2     2 b 0     3 w +     4 b 1
001    2 m  m Orr,Mark                          2258 IRL     2500035 1955-11-09  2.5    1     1 w 1  0000 - =     3 b 1
001    3 m  g Bologan,Viktor                    2663 MDA    13900048 1971-01-01  0.0    4               1 b -     2 w 0
001    4   wg Cramling,Pia                      2500 SWE     1700030 1963-04-23  0.5    3            0000 - =     1 w 0
KRAUSE
          @p = Krause.new
          @t = @p.parse!(@krause)
        end

        it "should serialize back to the original if the input is fully canonicalised" do
          @p.serialize(@t).should == @krause
        end

        it "should return nil on invalid input" do
          @p.serialize('Rubbish').should be_nil
        end
      end
    end
  end
end
