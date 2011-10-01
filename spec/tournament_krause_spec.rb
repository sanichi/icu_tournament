# encoding: UTF-8
require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

module ICU
  class Tournament
    describe Krause do
      def check_player(num, first, last, other={})
        p = @t.player(num)
        p.first_name.should == first
        p.last_name.should  == last
        [:gender, :title, :rating, :fide_rating, :fed, :id, :fide_id, :dob, :rank].each do |key|
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
          @t = @p.parse!(krause, :fide => true)
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
          check_player(1, 'Gearoidin', 'Ui Laighleis', :gender => 'F', :fide_rating => 1985, :fed => 'IRL', :fide_id =>  2501171, :dob => '1964-06-10', :rank => 2)
          check_player(2, 'Mark', 'Orr',               :gender => 'M', :fide_rating => 2258, :fed => 'IRL', :fide_id =>  2500035, :dob => '1955-11-09', :rank => 1, :title => 'IM')
          check_player(3, 'Viktor', 'Bologan',         :gender => 'M', :fide_rating => 2663, :fed => 'MDA', :fide_id => 13900048, :dob => '1971-01-01', :rank => 3, :title => 'GM')
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
          check_player(1, 'Minerva', 'Mouse', :gender => 'F', :rating => 1900, :fed => 'USA', :fide_id => 1234567, :dob => '1928-05-15', :rank => 2)
          check_player(2, 'Daffy',   'Duck',  :gender => 'M', :rating => 2200, :fed => 'IRL', :fide_id => 7654321, :dob => '1937-04-17', :rank => 1, :title => 'IM')
          check_player(3, 'Mickey',  'Mouse', :gender => 'M', :rating => 2600, :fed => 'USA', :fide_id => 1726354, :dob => '1928-05-15', :rank => 3, :title => 'GM')
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
          t = @p.parse!(@krause, :fide => true)
          ICU::Tournament::Krause.new.serialize(t, :fide => true).should == @krause
        end

        it "should serialize using the convenience method of the tournament object" do
          t = @p.parse!(@krause, :fide => true)
          t.serialize('Krause', :fide => true).should == @krause
        end

        it "should serialize only if :fide option is used correctly" do
          t = @p.parse!(@krause, :fide => true)
          t.serialize('Krause', :fide => true).should == @krause
          t.serialize('Krause').should_not == @krause
        end

        it "should not serialize correctly if mixed rating types are used" do
          t = @p.parse!(@krause, :fide => true)
          t.serialize('Krause').should_not == @krause
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

      context "local or FIDE ratings and IDs" do
        before(:each) do
          @krause = <<KRAUSE
012 Las Vegas National Open
042 2008-06-07
001    1 w    Ui Laighleis,Gearoidin            1985 IRL     2501171 1964-06-10  1.0          2 b 0     3 w 1
001    2 m  m Orr,Mark                          2258 IRL        1350 1955-11-09  2.0          1 w 1               3 b 1
001    3 m  g Bologan,Viktor                    2663 MDA             1971-01-01  0.0                    1 b 0     2 w 0
KRAUSE
          @p = ICU::Tournament::Krause.new
        end

        it "should have local ratings by default" do
          @t = @p.parse(@krause)
          check_player(1, 'Gearoidin', 'Ui Laighleis', :rating => 1985, :fide_rating => nil)
          check_player(2, 'Mark',      'Orr',          :rating => 2258, :fide_rating => nil)
          check_player(3, 'Viktor',    'Bologan',      :rating => 2663, :fide_rating => nil)
        end

        it "should have FIDE ratings if option is specified" do
          @t = @p.parse(@krause, :fide => true)
          check_player(1, 'Gearoidin', 'Ui Laighleis', :rating => nil, :fide_rating => 1985)
          check_player(2, 'Mark',      'Orr',          :rating => nil, :fide_rating => 2258)
          check_player(3, 'Viktor',    'Bologan',      :rating => nil, :fide_rating => 2663)
        end

        it "should auto-detect FIDE or ICU IDs based on size, the option has no effect" do
          @t = @p.parse(@krause)
          check_player(1, 'Gearoidin', 'Ui Laighleis', :id => nil,  :fide_id => 2501171)
          check_player(2, 'Mark',      'Orr',          :id => 1350, :fide_id => nil)
          @t = @p.parse(@krause, :fide => true)
          check_player(1, 'Gearoidin', 'Ui Laighleis', :id => nil,  :fide_id => 2501171)
          check_player(2, 'Mark',      'Orr',          :id => 1350, :fide_id => nil)
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
001    2 w    Ui Laighleis,Gearoidin            1985 IRL                         1.0    2     1 b 0     3 w 1          #
001    3 m  g Bologan,Viktor                    2663 MDA                         0.0    3               2 b 0     1 w 0
REORDERED
          @reordered.sub!('#', '')
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
001    1 w    Ui Laighleis,Gearoidin            1985 IRL     2501171 1964-06-10  1.0          2 b 0     3 w 1          #
001    2    m Orr,Mark                          2258 IRL     2500035 1955-11-09  2.0          1 w 1               3 b 1
001    3    g Bologan,Viktor                    2663 MDA    13900048 1971-01-01  0.0                    1 b 0     2 w 0
KRAUSE
          @krause.sub!('#', '')
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

        it "should serialise" do
          @output.should == @krause
        end
      end

      context "customised serialisation with ICU IDs" do
        before(:all) do
          @k = <<KRAUSE
012 Las Vegas National Open
042 2008-06-07
0123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890
001    1 w    Ui Laighleis,Gearoidin            1985 IRL        3364 1964-06-10  1.0    2     2 b 0     3 w 1          #
001    2    m Orr,Mark                          2258 IRL        1350 1955-11-09  2.0    1     1 w 1               3 b 1
001    3    g Svidler,Peter                     2663 RUS       16790 1971-01-01  0.0    3               1 b 0     2 w 0
KRAUSE
          @k.sub!('#', '')
          @p = ICU::Tournament::Krause.new
          @t = @p.parse(@k)
        end

        it "should include all data without any explict cusromisation" do
          text = @t.serialize('Krause')
          text.should match(/001    1 w    Ui Laighleis,Gearoidin            1985 IRL        3364 1964-06-10  1.0    2/)
          text.should match(/001    2    m Orr,Mark                          2258 IRL        1350 1955-11-09  2.0    1/)
          text.should match(/001    3    g Svidler,Peter                     2663 RUS       16790 1971-01-01  0.0    3/)
        end

        it "should omitt ratings and IDs if FIDE option is chosen" do
          text = @t.serialize('Krause', :fide => true)
          text.should match(/001    1 w    Ui Laighleis,Gearoidin                 IRL             1964-06-10  1.0    2/)
          text.should match(/001    2    m Orr,Mark                               IRL             1955-11-09  2.0    1/)
          text.should match(/001    3    g Svidler,Peter                          RUS             1971-01-01  0.0    3/)
        end

        it "should omitt all optional data if the :only option is an empty hash" do
          text = @t.serialize('Krause', :only => [])
          text.should match(/001    1      Ui Laighleis,Gearoidin                                             1.0     /)
          text.should match(/001    2      Orr,Mark                                                           2.0     /)
          text.should match(/001    3      Svidler,Peter                                                      0.0     /)
        end

        it "should should be able to include a subset of attributes, test 1" do
          text = @t.serialize('Krause', :only => [:gender, "dob", :id, "rubbish"])
          text.should match(/001    1 w    Ui Laighleis,Gearoidin                            3364 1964-06-10  1.0     /)
          text.should match(/001    2      Orr,Mark                                          1350 1955-11-09  2.0     /)
          text.should match(/001    3      Svidler,Peter                                    16790 1971-01-01  0.0     /)
        end

        it "should should be able to include a subset of attributes, test 2" do
          text = @t.serialize('Krause', :only => [:rank, "title", :fed, "rating"])
          text.should match(/001    1      Ui Laighleis,Gearoidin            1985 IRL                         1.0    2/)
          text.should match(/001    2    m Orr,Mark                          2258 IRL                         2.0    1/)
          text.should match(/001    3    g Svidler,Peter                     2663 RUS                         0.0    3/)
        end

        it "should should be able to include all attributes" do
          text = @t.serialize('Krause', :only => [:gender, :title, :rating, :fed, :id, :dob, :rank])
          text.should match(/001    1 w    Ui Laighleis,Gearoidin            1985 IRL        3364 1964-06-10  1.0    2/)
          text.should match(/001    2    m Orr,Mark                          2258 IRL        1350 1955-11-09  2.0    1/)
          text.should match(/001    3    g Svidler,Peter                     2663 RUS       16790 1971-01-01  0.0    3/)
        end

        it "the :only and :except options are logical opposites" do
          @t.serialize('Krause', :only => [:gender, :title, :rating]).should == @t.serialize('Krause', :except => [:fed, :id, "dob", :rank])
          @t.serialize('Krause', :only => [:gender]).should == @t.serialize('Krause', :except => [:fed, :id, :dob, :rank, :title, :rating])
          @t.serialize('Krause', :only => [:gender, :title, "rating", :fed, :id, :dob]).should == @t.serialize('Krause', :except => [:rank])
          @t.serialize('Krause', :only => [:gender, :title, :rating, :fed, "id", :dob, :rank]).should == @t.serialize('Krause', :except => [])
          @t.serialize('Krause', :only => []).should == @t.serialize('Krause', :except => [:gender, :title, :rating, :fed, :id, :dob, :rank])
        end
      end

      context "customised serialisation with FIDE IDs" do
        before(:all) do
          @k = <<KRAUSE
012 Las Vegas National Open
042 2008-06-07
0123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890
001    1 w    Ui Laighleis,Gearoidin            1985 IRL     2501171 1964-06-10  1.0    2     2 b 0     3 w 1          #
001    2    m Orr,Mark                          2258 IRL     2500035 1955-11-09  2.0    1     1 w 1               3 b 1
001    3    g Svidler,Peter                     2663 RUS     4102142 1971-01-01  0.0    3               1 b 0     2 w 0
KRAUSE
          @k.gsub!('#', '')
          @p = ICU::Tournament::Krause.new
          @t = @p.parse(@k, :fide => true)
        end

        it "should include all data without any explict cusromisation" do
          text = @t.serialize('Krause', :fide => true)
          text.should match(/001    1 w    Ui Laighleis,Gearoidin            1985 IRL     2501171 1964-06-10  1.0    2/)
          text.should match(/001    2    m Orr,Mark                          2258 IRL     2500035 1955-11-09  2.0    1/)
          text.should match(/001    3    g Svidler,Peter                     2663 RUS     4102142 1971-01-01  0.0    3/)
        end

        it "should omitt ratings and IDs if FIDE option is not chosen" do
          text = @t.serialize('Krause')
          text.should match(/001    1 w    Ui Laighleis,Gearoidin                 IRL             1964-06-10  1.0    2/)
          text.should match(/001    2    m Orr,Mark                               IRL             1955-11-09  2.0    1/)
          text.should match(/001    3    g Svidler,Peter                          RUS             1971-01-01  0.0    3/)
        end

        it "should omitt all optional data if the :only option is an empty hash" do
          text = @t.serialize('Krause', :only => [])
          text.should match(/001    1      Ui Laighleis,Gearoidin                                             1.0     /)
          text.should match(/001    2      Orr,Mark                                                           2.0     /)
          text.should match(/001    3      Svidler,Peter                                                      0.0     /)
        end

        it "should should be able to include a subset of attributes, test 1" do
          text = @t.serialize('Krause', :only => [:gender, "dob", :id], :fide => true)
          text.should match(/001    1 w    Ui Laighleis,Gearoidin                         2501171 1964-06-10  1.0     /)
          text.should match(/001    2      Orr,Mark                                       2500035 1955-11-09  2.0     /)
          text.should match(/001    3      Svidler,Peter                                  4102142 1971-01-01  0.0     /)
        end

        it "should should be able to include a subset of attributes, test 2" do
          text = @t.serialize('Krause', :only => [:rank, "title", :fed, "rating", :rubbish], :fide => true)
          text.should match(/001    1      Ui Laighleis,Gearoidin            1985 IRL                         1.0    2/)
          text.should match(/001    2    m Orr,Mark                          2258 IRL                         2.0    1/)
          text.should match(/001    3    g Svidler,Peter                     2663 RUS                         0.0    3/)
        end

        it "should should be able to include all attributes" do
          text = @t.serialize('Krause', :only => [:gender, :title, :rating, :fed, :id, :dob, :rank], :fide => true)
          text.should match(/001    1 w    Ui Laighleis,Gearoidin            1985 IRL     2501171 1964-06-10  1.0    2/)
          text.should match(/001    2    m Orr,Mark                          2258 IRL     2500035 1955-11-09  2.0    1/)
          text.should match(/001    3    g Svidler,Peter                     2663 RUS     4102142 1971-01-01  0.0    3/)
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
001    1      Griffiths,Ryan Rhys                    IRL     2502054 1993-12-20  4.0    1  0000 - =     3 b 1     8 w 1     5 b =     7 w 1
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
          lambda { @p.parse!(@k) }.should_not raise_error
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
           @k.sub!('3.5', '4.0')
           lambda { @p.parse!(@k) }.should raise_error(/total/)
        end

        it "invalid federations should cause an error unless an option is used" do
           @k.sub!('SCO', 'XYZ')
           lambda { @p.parse!(@k) }.should raise_error(/federation/)
           lambda { @t = @p.parse!(@k, :fed => "skip") }.should_not raise_error
           @t.player(5).fed.should be_nil
           @t.player(1).fed.should == "IRL"
           lambda { @t = @p.parse!(@k, :fed => "ignore") }.should_not raise_error
           @t.player(5).fed.should be_nil
           @t.player(1).fed.should be_nil
        end

        it "an invalid DOB is silently ignored" do
           @k.sub!(/1993-12-20/, '1993      ')
           lambda { @t = @p.parse!(@k) }.should_not raise_error
           @t.player(1).dob.should be_nil
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

      context "preserving original names" do
        before(:all) do
          @k = <<KRAUSE
012 Las Vegas National Open
042 2008-06-07
001    1 w    ui   laighleis,GEAROIDIN                                           1.0          2 b 0     3 w 1
001    2 m  m ORR, mark                                                          2.0          1 w 1               3 b 1
001    3 m  g BOLOGAN,VIKTOR                                                     0.0                    1 b 0     2 w 0
KRAUSE
          @p = ICU::Tournament::Krause.new
        end

        it "should canonicalise names but also preserve originals" do
          @t = @p.parse!(@k)
          check_player(1, 'Gearoidin', 'Ui Laighleis')
          check_player(2, 'Mark', 'Orr')
          check_player(3, 'Viktor', 'Bologan')
          @t.player(1).original_name.should == "ui laighleis, GEAROIDIN"
          @t.player(2).original_name.should == "ORR, mark"
          @t.player(3).original_name.should == "BOLOGAN, VIKTOR"
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

        it "should parse a large file with total scores as much as 10.0" do
          file = "#{@s}/armstrong_2011.tab"
          lambda { @t = @p.parse_file!(file) }.should_not raise_error
        end
      end

      context "automatic repairing of totals" do
        before(:each) do
          @p = ICU::Tournament::Krause.new
        end

        it "cannot repair mismatched totals if there are no byes" do
          @k = <<KRAUSE
012 Las Vegas National Open
042 2008-06-07
001    1      Ui Laighleis,Gearoidin                                             0.5          2 b 0     2 w 0
001    2      Or,Mark                                                            2.0          1 w 1     1 b 1
KRAUSE
          lambda { @p.parse!(@k) }.should raise_error(/total/)
        end

        it "cannot repair mismatched totals if totals are underestimated" do
          @k = <<KRAUSE
012 Las Vegas National Open
042 2008-06-07
001    1      Ui Laighleis,Gearoidin                                             0.0          2 b 0  0000 - -
001    2      Orr,Mark                                                           1.5          1 w 1  0000 - +
KRAUSE
          lambda { @p.parse!(@k) }.should raise_error(/total/)
        end

        it "cannot repair overestimated totals if there are not enough byes" do
          @k = <<KRAUSE
012 Las Vegas National Open
042 2008-06-07
001    1      Ui Laighleis,Gearoidin                                             1.5          2 b 0  0000 - -
001    2      Orr,Mark                                                           2.0          1 w 1  0000 - +
KRAUSE
          lambda { @p.parse!(@k) }.should raise_error(/total/)
        end

        it "can repair overestimated totals if there are enough byes" do
          @k = <<KRAUSE
012 Las Vegas National Open
042 2008-06-07
001    1      Ui Laighleis,Gearoidin                                             1.0          2 b 0  0000 - -
001    2      ORR,Mark                                                           2.0          1 w 1  0000 - +
KRAUSE
          @t = @p.parse!(@k)
          @t.should_not be_nil
          check_results(1, 2, 1.0)
          @t.player(1).find_result(2).score.should == 'W'
        end

        it "extreme example" do
          @k = <<KRAUSE
012 Las Vegas National Open
042 2008-06-07
001    1      Ui Laighleis,Gearoidin                                             2.0          2 b 0  0000 - -  0000 - =
001    2      Orr,Mark                                                           2.5          1 w 1  0000 - +
001    3      Brady,Stephen                                                      1.0       0000 - -     4 b 0  0000 - =
001    4      Knox,Angela                                                        2.5       0000 - -     3 w 1  0000 - -
KRAUSE
          @t = @p.parse!(@k)
          @t.should_not be_nil
          @t.player(1).results.map(&:score).join('').should == 'LWW'
          @t.player(2).results.map(&:score).join('').should == 'WWD'
          @t.player(3).results.map(&:score).join('').should == 'DLD'
          @t.player(4).results.map(&:score).join('').should == 'WWD'
        end

        it "should work on the documentation example" do
          @k = <<KRAUSE
012 Mismatched Totals
042 2011-03-04
001    1      Mouse,Minerva                                                      1.0    2     2 b 0  0000 - =
001    2      Mouse,Mickey                                                       1.5    1     1 w 1
KRAUSE
          @t = @p.parse!(@k)
          output = <<KRAUSE
012 Mismatched Totals
042 2011-03-04
001    1      Mouse,Minerva                                                      1.0    2     2 b 0  0000 - +
001    2      Mouse,Mickey                                                       1.5    1     1 w 1  0000 - =
KRAUSE
          @t.serialize('Krause').should == output
        end
      end

      context "parsing variations on strict Krause" do
        before(:each) do
          @p = ICU::Tournament::Krause.new
          @s = File.dirname(__FILE__) + '/samples/krause'
        end

        it "should handle Bunratty Masters 2011" do
          file = "#{@s}/bunratty_masters_2011.tab"
          @t = @p.parse_file(file, :fed => :skip, :fide => true)
          @t.should_not be_nil
          @t.start.should == "2011-02-25"
          @t.finish.should == "2011-02-27"
          check_player(1, 'Nigel', 'Short', :gender => 'M', :fide_rating => 2658, :fed => 'ENG', :rating => nil, :rank => 5, :title => 'GM')
          check_results(1, 6, 4.0)
          check_player(16, 'Jonathan', "O'Connor", :gender => 'M', :fide_rating => 2111, :fed => nil, :rating => nil, :rank => 25, :title => nil)
          check_results(16, 6, 2.5)
          @t.player(16).results.map(&:score).join('').should == 'DWLDDL'
          check_player(24, 'David', 'Murray', :gender => 'M', :fide_rating => 2023, :fed => nil, :rating => nil, :rank => 34, :title => nil)
          check_results(24, 2, 0.5)
          @t.player(24).results.map(&:score).join('').should == 'LD'
          check_player(26, 'Alexandra', 'Wilson', :gender => 'F', :fide_rating => 2020, :fed => 'ENG', :rating => nil, :rank => 29, :title => 'WFM')
          check_results(26, 6, 2.0)
        end

        it "should handle Bunratty Major 2011" do
          file = "#{@s}/bunratty_major_2011.tab"
          @t = @p.parse_file(file, :fed => :ignore)
          @t.should_not be_nil
          @t.start.should == "2011-02-25"
          @t.finish.should == "2011-02-27"
          check_player(1, 'Dan', 'Clancy', :gender => 'M', :fide_rating => nil, :fed => nil, :id => 204, :rating => nil, :rank => 12)
          check_results(1, 6, 4)
          check_player(10, 'Phillip', 'Foenander', :gender => 'M', :fide_rating => nil, :fed => nil, :id => 7168, :rating => nil, :rank => 18)
          check_results(10, 6, 3.5)
          check_player(40, 'Ron', 'Cummins', :gender => 'M', :fide_rating => nil, :fed => nil, :id => 4610, :rating => nil, :rank => 56)
          check_results(40, 1, 0.0)
        end

        it "should handle bunratty_minor_2011.tab" do
          file = "#{@s}/bunratty_minor_2011.tab"
          lambda { @p.parse_file!(file, :fed => :ignore) }.should_not raise_error
        end

        it "should handle Bunratty Challengers 2011" do
          file = "#{@s}/bunratty_challengers_2011.tab"
          lambda { @p.parse_file!(file, :fed => :ignore) }.should_not raise_error
        end

        it "should handle Irish Intermediate Championships 2011" do
          file = "#{@s}/irish_intermediate_champs_2011.tab"
          lambda { @p.parse_file!(file) }.should_not raise_error
        end

        it "should handle Irish Junior Championships 2011" do
          file = "#{@s}/irish_junior_champs_2011.tab"
          lambda { @p.parse_file!(file) }.should_not raise_error
        end
      end
    end
  end
end
