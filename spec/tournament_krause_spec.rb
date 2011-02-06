# encoding: UTF-8
require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

module ICU
  class Tournament
    describe Krause do
      def check_player(num, first, last, other={})
        p = @t.player(num)
        p.first_name.should == first
        p.last_name.should  == last
        [:gender, :title, :rating, :fed, :id, :fide, :dob, :rank].each do |key|
          p.send(key).should == other[key] if other.has_key?(key)
        end
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
052 2008.06.09
062 3
072 3
082 1
092 All-Play-All
102 Hans Scmidt
112 Gerry Graham, Herbert Scarry
122 60 in 2hr, 30 in 1hr, rest in 1hr
013 Coaching Team                      1    2    3
0         1         2         3         4         5         6         7         8         9         0         1         2
0123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890
132                                                                                        08.06.07  08.06.08  08.06.09
001    1 w    Ui Laighleis,Gearoidin            1985 IRL     2501171 1964.06.10  1.0    2     2 b 0     3 w 1
001    2 m  m Orr,Mark                          2258 IRL     2500035 1955.11.09  2.0    1     1 w 1               3 b 1
001    3 m  g Bologan,Viktor                    2663 MDA    13900048 1971.01.01  0.0    3               1 b 0     2 w 0
KRAUSE
          @p = ICU::Tournament::Krause.new
          @t = @p.parse!(krause)
        end

        it "should have a name, city and federation" do
          @t.name.should == 'Las Vegas National Open'
          @t.city.should == 'Las Vegas'
          @t.fed.should  == 'USA'
        end

        it "should have start and end dates" do
          @t.start.should  == '2008-06-07'
          @t.finish.should == '2008-06-09'
        end

        it "should have a number of rounds, a type and a time control" do
          @t.rounds.should       == 3
          @t.last_round.should   == 3
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

        it "should have correct round dates" do
          @t.round_dates.join('|').should == '2008-06-07|2008-06-08|2008-06-09'
        end

        it "the parser should retain comment lines" do
          comments = <<COMMENTS
062 3
072 3
082 1
0         1         2         3         4         5         6         7         8         9         0         1         2
0123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890
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
132                                                                                        09.09.09  09.09.10  09.09.11
001    1 w    Mouse,Minerva                     1900 USA     1234567 1928.05.15  1.0    2     2 b 0     3 w 1
001    2 m  m Duck,Daffy                        2200 IRL     7654321 1937.04.17  2.0    1     1 w 1               3 b 1
001    3 m  g Mouse,Mickey                      2600 USA     1726354 1928.05.15  0.0    3               1 b 0     2 w 0
KRAUSE
          @p = ICU::Tournament::Krause.new
          @t = @p.parse!(krause)
        end

        it "should have a name and federation" do
          @t.name.should == 'Fantasy Tournament'
          @t.fed.should  == 'IRL'
        end

        it "should have a various dates" do
          @t.start.should  == '2009-09-09'
          @t.finish.should  == '2009-09-11'
          @t.round_dates.join('|').should == '2009-09-09|2009-09-10|2009-09-11'
        end

        it "should have a number of rounds" do
          @t.rounds.should == 3
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

      context "the README serialisation example" do
        before(:all) do
          @t = ICU::Tournament.new('World Championship', '1972-07-11')
          @t.add_player(ICU::Player.new('Robert J.', 'Fischer', 1))
          @t.add_player(ICU::Player.new('Boris V.', 'Spassky', 2))
          @t.add_result(ICU::Result.new(1, 1, 'L', :opponent => 2, :colour => 'B'))
          @t.add_result(ICU::Result.new(2, 1, 'L', :opponent => 2, :colour => 'W', :rateable => false))
          @t.add_result(ICU::Result.new(3, 1, 'W', :opponent => 2, :colour => 'B'))
          @t.add_result(ICU::Result.new(4, 1, 'D', :opponent => 2, :colour => 'W'))
          serializer = ICU::Tournament::Krause.new
          @k = serializer.serialize(@t)
        end

        it "should produce a valid tournament" do
          @t.invalid.should be_false
        end

        it "should produce output that looks reasonable" do
          @k.should match(/Fischer,Robert J\./)
        end
      end

      context "serialisation" do
        before(:each) do
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
013 Boys                               2    3
013 Girls                              1    4
132                                                                                        08-06-07  08-06-08  08-06-09
001    1 w    Ui Laighleis,Gearoidin            1985 IRL     2501171 1964-06-10  2.0    2     2 b 0     3 w +     4 b 1
001    2 m  m Orr,Mark                          2258 IRL     2500035 1955-11-09  2.5    1     1 w 1  0000 - =     3 b 1
001    3 m  g Bologan,Viktor                    2663 MDA    13900048 1971-01-01  0.0    4               1 b -     2 w 0
001    4   wg Cramling,Pia                      2500 SWE     1700030 1963-04-23  0.5    3            0000 - =     1 w 0
KRAUSE
          @p = ICU::Tournament::Krause.new
        end

        it "should serialize back to the original if the input is fully canonicalised" do
          t = @p.parse!(@krause)
          ICU::Tournament::Krause.new.serialize(t).should == @krause
        end

        it "should serialize using the convenience method of the tournament object" do
          t = @p.parse!(@krause)
          t.serialize('Krause').should == @krause
        end

        it "should not serialize coorectly if mixed ID types are used" do
          t = @p.parse!(@krause, :fide => true)
          t.serialize('Krause').should_not == @krause
        end

        it "should serialize coorectly if FIDE IDs are used consistently" do
          t = @p.parse!(@krause, :fide => true)
          t.serialize('Krause', :fide => true).should == @krause
        end

      end

      context "auto-ranking" do
        before(:all) do
          @krause = <<KRAUSE
012 Las Vegas National Open
042 2008-06-07
001    1 w    Ui Laighleis,Gearoidin            1985 IRL     2501171 1964-06-10  1.0          2 b 0     3 w 1
001    2 m  m Orr,Mark                          2258 IRL     2500035 1955-11-09  2.0          1 w 1               3 b 1
001    3 m  g Bologan,Viktor                    2663 MDA    13900048 1971-01-01  0.0                    1 b 0     2 w 0
KRAUSE
          @p = ICU::Tournament::Krause.new
          @t = @p.parse!(@krause)
        end

        it "should have rankings automatically set" do
          @t.player(1).rank.should == 2
          @t.player(2).rank.should == 1
          @t.player(3).rank.should == 3
        end
      end
      
      context "local or FIDE IDs" do
        before(:each) do
          @krause = <<KRAUSE
012 Las Vegas National Open
042 2008-06-07
001    1 w    Ui Laighleis,Gearoidin            1985 IRL     2501171 1964-06-10  1.0          2 b 0     3 w 1
001    2 m  m Orr,Mark                          2258 IRL     2500035 1955-11-09  2.0          1 w 1               3 b 1
001    3 m  g Bologan,Viktor                    2663 MDA             1971-01-01  0.0                    1 b 0     2 w 0
KRAUSE
          @p = ICU::Tournament::Krause.new
        end

        it "should have local IDs by default" do
          @t = @p.parse(@krause)
          check_player(1, 'Gearoidin', 'Ui Laighleis', :id => 2501171, :fide => nil)
          check_player(2, 'Mark',      'Orr',          :id => 2500035, :fide => nil)
          check_player(3, 'Viktor',    'Bologan',      :id => nil,     :fide => nil)
        end

        it "should have FIDE IDs if option is used" do
          @t = @p.parse(@krause, :fide => true)
          check_player(1, 'Gearoidin', 'Ui Laighleis', :fide => 2501171, :id => nil)
          check_player(2, 'Mark',      'Orr',          :fide => 2500035, :id => nil)
          check_player(3, 'Viktor',    'Bologan',      :fide => nil,     :id => nil)
        end
      end

      context "renumbering" do
        before(:all) do
          @krause = <<KRAUSE
012 Las Vegas National Open
042 2008-06-07
001   10 w    Ui Laighleis,Gearoidin            1985 IRL                         1.0         20 b 0    30 w 1          
001   20 m  m Orr,Mark                          2258 IRL                         2.0         10 w 1              30 b 1
001   30 m  g Bologan,Viktor                    2663 MDA                         0.0                   10 b 0    20 w 0
KRAUSE
          @p = ICU::Tournament::Krause.new
          @t = @p.parse!(@krause)
          @reordered = <<REORDERED
012 Las Vegas National Open
042 2008-06-07
001    1 m  m Orr,Mark                          2258 IRL                         2.0    1     2 w 1               3 b 1
001    2 w    Ui Laighleis,Gearoidin            1985 IRL                         1.0    2     1 b 0     3 w 1          
001    3 m  g Bologan,Viktor                    2663 MDA                         0.0    3               2 b 0     1 w 0
REORDERED
        end

        it "should serialise correctly after renumbering by rank" do
          @t.renumber
          @p.serialize(@t).should == @reordered
        end
      end

      context "serialisation of a manually build tournament" do
        before(:all) do
          @krause = <<KRAUSE
012 Las Vegas National Open
042 2008-06-07
001    1 w    Ui Laighleis,Gearoidin            1985 IRL     2501171 1964-06-10  1.0          2 b 0     3 w 1          
001    2    m Orr,Mark                          2258 IRL     2500035 1955-11-09  2.0          1 w 1               3 b 1
001    3    g Bologan,Viktor                    2663 MDA    13900048 1971-01-01  0.0                    1 b 0     2 w 0
KRAUSE
          @p = ICU::Tournament::Krause.new
          @t = ICU::Tournament.new('Las Vegas National Open', '2008-06-07')
          @t.add_player(ICU::Player.new('Gearoidin', 'Ui Laighleis', 1, :rating => 1985, :id => 2501171,  :dob => '1964-06-10', :fed => 'IRL', :gender => 'f'))
          @t.add_player(ICU::Player.new('Mark',      'Orr',          2, :rating => 2258, :id => 2500035,  :dob => '1955-11-09', :fed => 'IRL', :title => 'm'))
          @t.add_player(ICU::Player.new('Viktor',    'Bologan',      3, :rating => 2663, :id => 13900048, :dob => '1971-01-01', :fed => 'MDA', :title => 'g'))
          @t.add_result(ICU::Result.new(1, 1, 'L', :opponent => 2, :colour => 'B'))
          @t.add_result(ICU::Result.new(2, 1, 'W', :opponent => 3, :colour => 'W'))
          @t.add_result(ICU::Result.new(3, 2, 'W', :opponent => 3, :colour => 'B'))
          @output = @p.serialize(@t)
        end

        it "should serialise manually build tournaments" do
          @output.should == @krause
        end
      end

      context "errors" do
        before(:each) do
          @k = <<KRAUSE
012 Gonzaga Classic
022 Dublin
032 IRL
042 2008-02-01
052 2008-02-03
062 12
092 Swiss
102 Michael Germaine, mlgermaine@eircom.net
122 120 minutes per player per game
001    1      Griffiths,Ryan Rhys                    IRL     2502054             4.0    1  0000 - =     3 b 1     8 w 1     5 b =     7 w 1
001    2      Hotak,Marian                           SVK    14909677             3.5    2     3 w 0     6 b =    11 w 1     8 b 1     5 w 1
001    3      Duffy,Seamus                           IRL                         3.0    3     2 b 1     1 w 0     4 w 1     6 b =     8 w =
001    4      Cafolla,Peter                          IRL     2500884             3.0    4     7 b 1     5 w =     3 b 0    11 b +     6 w =
001    5      Ferry,Edward                           SCO     2461587             3.0    5    10 b 1     4 b =     9 w 1     1 w =     2 b 0
001    6      Boyle,Bernard                          IRL     2501830             3.0    6    12 b =     2 w =    10 b 1     3 w =     4 b =
001    7      McCarthy,Tim                           IRL     2500710             2.5    7     4 w 0    10 w =    12 b +     9 b 1     1 b 0
001    8      Benson,Oisin P.                        IRL     2501821             2.0    8  0000 - =    11 w 1     1 b 0     2 w 0     3 b =
001    9      Murray,David B.                        IRL     2501511             2.0    9    11 b =    12 w +     5 b 0     7 w 0    10 w =
001   10      Moser,Philippe                         SUI     1308041             1.5   10     5 w 0     7 b =     6 w 0  0000 - =     9 b =
001   11      Barbosa,Paulo                          POR     1904612             1.5   11     9 w =     8 b 0     2 b 0     4 w -  0000 - +
001   12      McCabe,Darren                          IRL     2500760             0.5   12     6 w =     9 b -     7 w -
KRAUSE
          @p = ICU::Tournament::Krause.new
        end

        it "the unaltered example is valid Krause" do
          t = @p.parse(@k).should be_instance_of(ICU::Tournament)
        end

        it "removing the line on which the tournament name is specified should cause an error" do
          @k.sub!('012 Gonzaga Classic', '')
          lambda { @p.parse!(@k) }.should raise_error(/name missing/)
        end

        it "blanking the tournament name should cause an error" do
          @k.sub!('Gonzaga Classic', '')
          lambda { @p.parse!(@k) }.should raise_error(/name missing/)
        end

        it "blanking the start date should cause an error" do
          @k.sub!('2008-02-01', '2008-02-04')
          lambda { @p.parse!(@k) }.should raise_error(/start.*after.*end/)
        end

        it "the start cannot be later than the end date" do
          @k.sub!('2008-02-01', '')
          lambda { @p.parse!(@k) }.should raise_error(/start date missing/)
        end

        it "creating a duplicate player number should cause an error" do
          @k.sub!('  2  ', '  1  ')
          lambda { @p.parse!(@k) }.should raise_error(/player number/)
        end

        it "creating a duplicate rank number should not cause an error becuse the tournament will be reranked" do
          @k.sub!('4.0    1', '4.0    2')
          t = @p.parse!(@k)
          t.player(1).rank.should == 1
        end

        it "referring to a non-existant player number should cause an error" do
           @k.sub!(' 3 b 1', '33 b 1')
           lambda { @p.parse!(@k) }.should raise_error(/opponent number/)
        end

        it "inconsistent colours should cause an error" do
           @k.sub!('3 b 1', '3 w 1')
           lambda { @p.parse!(@k) }.should raise_error(/result/)
        end

        it "inconsistent scores should cause an error" do
           @k.sub!('3 b 1', '3 b =')
           lambda { @p.parse!(@k) }.should raise_error(/result/)
        end

        it "inconsistent totals should cause an error" do
           @k.sub!('4.0', '4.5')
           lambda { @p.parse!(@k) }.should raise_error(/total/)
        end

        it "invalid federations should cause an error" do
           @k.sub!('SCO', 'XYZ')
           lambda { @p.parse!(@k) }.should raise_error(/federation/)
        end

        it "removing any player that somebody else has played should cause an error" do
           @k.sub!(/^001   12.*$/, '')
           lambda { @p.parse!(@k) }.should raise_error(/opponent/)
        end
      end
      
      context "encoding" do
        before(:all) do
          @utf8 = <<KRAUSE
012 Läs Végas National Opeñ
042 2008-06-07
001    1 w    Uì Laighlèis,Gearoìdin                                             1.0          2 b 0     3 w 1
001    2 m  m Örr,Mârk                                                           2.0          1 w 1               3 b 1
001    3 m  g Bologan,Viktor                                                     0.0                    1 b 0     2 w 0
KRAUSE
          @p = ICU::Tournament::Krause.new
        end

        it "should handle UTF-8" do
          @t = @p.parse!(@utf8)
          check_player(1, 'Gearoìdin', 'Uì Laighlèis')
          check_player(2, 'Mârk', 'Örr')
          check_player(3, 'Viktor', 'Bologan')
          @t.name.should == "Läs Végas National Opeñ"
        end

        it "should handle Latin-1" do
          latin1 = @utf8.encode("ISO-8859-1")
          @t = @p.parse!(latin1)
          check_player(1, 'Gearoìdin', 'Uì Laighlèis')
          check_player(2, 'Mârk', 'Örr')
          check_player(3, 'Viktor', 'Bologan')
          @t.name.should == "Läs Végas National Opeñ"
        end
      end

      context "parsing files" do
        before(:each) do
          @p = ICU::Tournament::Krause.new
          @s = File.dirname(__FILE__) + '/samples/krause'
        end

        it "should error on a non-existant valid file" do
          file = "#{@s}/not_there.tab"
          lambda { @p.parse_file!(file) }.should raise_error
          t = @p.parse_file(file)
          t.should be_nil
          @p.error.should match(/no such file/i)
        end

        it "should error on an invalid file" do
          file = "#{@s}/invalid.tab"
          lambda { @p.parse_file!(file) }.should raise_error
          t = @p.parse_file(file)
          t.should be_nil
          @p.error.should match(/tournament name missing/i)
        end

        it "should parse a valid file" do
          file = "#{@s}/valid.tab"
          lambda { @p.parse_file!(file) }.should_not raise_error
          t = @p.parse_file(file)
          t.should be_an_instance_of(ICU::Tournament)
          t.players.size.should == 12
        end

        it "should parse a file with UTF-8 encoding" do
          file = "#{@s}/utf-8.tab"
          lambda { @t = @p.parse_file!(file) }.should_not raise_error
          check_player(1, 'Gearoìdin', 'Uì Laighlèis')
          check_player(2, 'Mârk', 'Örr')
          check_player(3, 'Viktor', 'Bologan')
          @t.name.should == "Läs Végas National Opeñ"
        end

        it "should parse a file with Latin-1 encoding" do
          file = "#{@s}/latin-1.tab"
          lambda { @t = @p.parse_file!(file) }.should_not raise_error
          check_player(1, 'Gearoìdin', 'Uì Laighlèis')
          check_player(2, 'Mârk', 'Örr')
          check_player(3, 'Viktor', 'Bologan')
          @t.name.should == "Läs Végas National Opeñ"
        end
      end
    end
  end
end
