# encoding: UTF-8
require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

module ICU
  class Tournament
    def spx_signature
      [name, rounds, start, players.size].join("|")
    end
  end
  class Player
    def spx_signature
      [
        name, id, points,
        results.map{ |r| r.round }.join(''),
        results.map{ |r| r.score }.join(''),
        results.map{ |r| r.colour || "-" }.join(''),
        results.map{ |r| r.rateable ? 'T' : 'F' }.join(''),
      ].join("|")
    end
    def spx_signature2
      [
        results.map{ |r| r.round }.join(''),
        results.map{ |r| r.score }.join(''),
        results.map{ |r| r.rateable ? 'T' : 'F' }.join(''),
      ].join("|")
    end
  end
end

module ICU
  class Tournament
    describe SPExport do
      def samples
        File.dirname(__FILE__) + '/samples/spx/'
      end

      context "documentation example" do
        before(:each) do
          @x = <<EXPORT
No	Name          	Feder	Intl Id	Loc Id	Rtg 	Loc 	Title	Total	1  	2  	3

1 	Duck, Daffy   	IRL  	       	12345 	    	2200	im   	2    	0:D	3:W	2:D
2 	Mouse, Minerva	     	1234568	      	1900	    	     	1.5  	3:D	0:D	1:D
3 	Mouse, Mickey 	USA  	1234567	      	    	    	gm   	1    	2:D	1:L	0:D
EXPORT
          @p = ICU::Tournament::SPExport.new
          @opt = { :name => "Mickey Mouse Masters", :start => "2012-01-01" }
          @t = ICU::Tournament::SPExport.new.parse(@x, @opt)
        end

        it "should parse without exception" do
          lambda { @p.parse!(@x, @opt) }.should_not raise_error
        end

        it "should parse without error" do
          @p.parse(@x, @opt)
          @p.error.should be_nil
        end

        it "players should have all the right names and numbers" do
          @t.player(1).name.should == "Duck, Daffy"
          @t.player(2).name.should == "Mouse, Minerva"
          @t.player(3).name.should == "Mouse, Mickey"
        end

        it "players should have correct ICU IDs" do
          @t.player(1).id.should == 12345
          @t.player(2).id.should be_nil
          @t.player(3).id.should be_nil
        end

        it "players should have correct FIDE IDs" do
          @t.player(1).fide.should be_nil
          @t.player(2).fide.should == 1234568
          @t.player(3).fide.should == 1234567
        end

        it "players should have correct ratings" do
          @t.player(1).rating.should == 2200
          @t.player(2).rating.should == 1900
          @t.player(3).rating.should be_nil
        end

        it "players should have correct titles" do
          @t.player(1).title.should == "IM"
          @t.player(2).title.should be_nil
          @t.player(3).title.should == "GM"
        end

        it "players should have correct federations" do
          @t.player(1).fed.should == "IRL"
          @t.player(2).fed.should be_nil
          @t.player(3).fed.should == "USA"
        end

        it "players should have correct scores" do
          @t.player(1).points.should == 2.0
          @t.player(2).points.should == 1.5
          @t.player(3).points.should == 1.0
        end

        it "players should have correct ranks" do
          @t.player(1).rank.should == 1
          @t.player(2).rank.should == 2
          @t.player(3).rank.should == 3
        end

        it "players should have correct results" do
          @t.player(1).spx_signature2.should == '123|DWD|FTT'
          @t.player(2).spx_signature2.should == '123|DDD|TFT'
          @t.player(3).spx_signature2.should == '123|DLD|TTF'
        end
      end

      context "serialisation" do
        before(:each) do
          name = "Bangor Masters"
          start = "2009-11-09"
          t = ICU::Tournament.new(name, start)
          t.add_player(ICU::Player.new('Bobby', 'Fischer', 10))
          t.add_player(ICU::Player.new('Garry', 'Kasparov', 20))
          t.add_player(ICU::Player.new('Mark', 'Orr', 30))
          t.add_result(ICU::Result.new(1, 10, 'D', :opponent => 30))
          t.add_result(ICU::Result.new(2, 20, 'W', :opponent => 30))
          t.add_result(ICU::Result.new(3, 20, 'L', :opponent => 10))
          @p = ICU::Tournament::SPExport.new
          @t = @p.parse(t.serialize('SPExport'), :name => name, :start => start)
        end

        it "round trip" do
          @p.error.should be_nil
          @t.spx_signature.should == "Bangor Masters|3|2009-11-09|3"
          @t.player(1).spx_signature.should == "Fischer, Bobby||1.5|123|DLW|---|TFT"
          @t.player(2).spx_signature.should == "Kasparov, Garry||1.0|123|LWL|---|FTT"
          @t.player(3).spx_signature.should == "Orr, Mark||0.5|123|DLL|---|TTF"
        end
      end

      context "invisible bonuses" do
        before(:each) do
          @x = <<EXPORT
No	Name          	Total	1  	2  	3

1 	Daffy Duck    	2.0  	0: 	3:W	2:D
2 	Mouse, Minerva	1.5  	3:D	0: 	1:D
3 	Mouse, Mickey 	1.0  	2:D	1:L	0:D
EXPORT
          @p = ICU::Tournament::SPExport.new
          @t = @p.parse!(@x, :name => "Mickey Mouse Masters", :start => "2012-01-01")
        end

        it "players should have correct results" do
          @t.player(1).spx_signature2.should == '123|DWD|FTT'
          @t.player(2).spx_signature2.should == '123|DDD|TFT'
          @t.player(3).spx_signature2.should == '123|DLD|TTF'
        end
      end

      context "invisible bonuses extreme example" do
        before(:each) do
          @x = <<EXPORT
No	Name          	Total	1  	2  	3

1 	Daffy Duck    	2.5  	 : 	 : 	 :
2 	Mouse, Minerva	2.0  	 : 	 : 	 :
3 	Mouse, Mickey 	1.0  	 : 	 : 	 :
EXPORT
          @p = ICU::Tournament::SPExport.new
          @t = @p.parse!(@x, :name => "Mickey Mouse Masters", :start => "2012-01-01")
        end

        it "players should have correct results" do
          @t.player(1).spx_signature2.should == '123|WWD|FFF'
          @t.player(2).spx_signature2.should == '123|WDD|FFF'
          @t.player(3).spx_signature2.should == '123|DDL|FFF'
        end
      end

      context "odds and ends" do
        before(:each) do
          @x = <<EXPORT
No	Name          	Total	1  	2  	3

1 	Daffy Duck    	2.0  	0:=	3:+	2:d
2 	Mouse, Minerva	1.0  	3:=	 : 	1:D
3 	Mouse, Mickey 	1.0  	2:=	1:-	0:D
EXPORT
          @p = ICU::Tournament::SPExport.new
          @t = @p.parse!(@x, :name => "Mickey Mouse Masters", :start => "2012-01-01")
        end

        it "players should have all the right names and numbers" do
          @t.player(1).name.should == "Duck, Daffy"
          @t.player(2).name.should == "Mouse, Minerva"
          @t.player(3).name.should == "Mouse, Mickey"
        end

        it "players should have correct results" do
          @t.player(1).spx_signature2.should == '123|DWD|FFT'
          @t.player(2).spx_signature2.should == '123|DLD|FFT'
          @t.player(3).spx_signature2.should == '123|DLD|FFF'
        end

        it "players should have correct ranks given default name tie-break" do
          @t.player(1).rank.should == 1
          @t.player(2).rank.should == 3
          @t.player(3).rank.should == 2
        end
      end

      context "strings and encoding" do
        before(:each) do
          @p = ICU::Tournament::SPExport.new
          @x = <<EXPORT
No	Name          	Total	1  	2

1 	Dück, Dâffy   	1.5  	2:W	2:D
2 	Möuse, Mickéy 	0.5  	1:L	1:D
EXPORT
          @opt = { :name => "Test", :start => "2011-02-05" }
        end

        it "UTF-8" do
          t = @p.parse(@x, @opt)
          @p.error.should be_nil
          t.player(1).name.should == "Dück, Dâffy"
          t.player(2).name.should == "Möuse, Mickéy"
        end

        it "Latin-1" do
          t = @p.parse(@x.encode("ISO-8859-1"), @opt)
          @p.error.should be_nil
          t.player(1).name.should == "Dück, Dâffy"
          t.player(2).name.should == "Möuse, Mickéy"
        end
      end

      context "errors" do
        before(:each) do
          @p = ICU::Tournament::SPExport.new
          @opt = { :name => "Test", :start => "2011-02-05" }
        end

        it "correct example" do
          data = <<EXPORT
No	Name          	Total	1  	2

1 	Duck, Daffy   	1.5  	2:W	2:D
2 	Mouse, Mickey 	0.5  	1:L	1:D
EXPORT
          lambda { @p.parse!(data, @opt) }.should_not raise_error
        end

        it "no header" do
          data = <<EXPORT
1 	Duck, Daffy   	1.5  	2:W	2:D
2 	Mouse, Mickey 	0.5  	1:L	1:L
EXPORT
          lambda { @p.parse!(data, @opt) }.should raise_error(/header/)
        end

        it "invalid header" do
          data = <<EXPORT
Xx	Name          	Total	1  	2

1 	Duck, Daffy   	1.5  	2:W	2:D
2 	Mouse, Mickey 	0.5  	1:L	1:D
EXPORT
          lambda { @p.parse!(data, @opt) }.should raise_error(/header/)
        end

        it "missing round 1" do
          data = <<EXPORT
No	Name          	Total	2  	3

1 	Duck, Daffy   	1.5  	2:W	2:D
2 	Mouse, Mickey 	0.0  	1:L	1:L
EXPORT
          lambda { @p.parse!(data, @opt) }.should raise_error(/round 1/)
        end

        it "missing round 2" do
          data = <<EXPORT
No	Name          	Total	1  	3

1 	Duck, Daffy   	1.5  	2:W	2:D
2 	Mouse, Mickey 	0.0  	1:L	1:L
EXPORT
          lambda { @p.parse!(data, @opt) }.should raise_error(/round 2/)
        end

        it "incorrect total" do
          data = <<EXPORT
No	Name          	Total	1  	2

1 	Duck, Daffy   	1.5  	2:W	2:D
2 	Mouse, Mickey 	1.0  	1:L	1:D
EXPORT
          lambda { @p.parse!(data, @opt) }.should raise_error(/total/)
        end


        it "mismatched results" do
          data = <<EXPORT
No	Name          	Total	1  	2

1 	Duck, Daffy   	1.5  	2:W	2:D
2 	Mouse, Mickey 	0.0  	1:L	1:L
EXPORT
          lambda { @p.parse!(data, @opt) }.should raise_error(/result/)
        end

        it "invalid attribute, title for example)" do
          data = <<EXPORT
No	Name          	Title	Total	1  	2

1 	Duck, Daffy   	mg   	1.5  	2:W	2:D
2 	Mouse, Mickey 	     	0.5  	1:L	1:D
EXPORT
          lambda { @p.parse!(data, @opt) }.should raise_error(/title/)
        end
      end

      context "Gonzaga Challengers 2010 file" do
        before(:each) do
          @p = ICU::Tournament::SPExport.new
          @t = @p.parse_file(samples + 'gonzaga_challengers_2010.txt', :name => "Gonzaga Chess Classic 2010 Challengers Section", :start => "2010-01-29")
          @s = open(samples + 'gonzaga_challengers_2010.txt') { |f| f.read }
        end

        it "should parse and have the right basic details" do
          @p.error.should be_nil
          @t.spx_signature.should == "Gonzaga Chess Classic 2010 Challengers Section|6|2010-01-29|56"
        end

        it "should have correct details for selected players" do
          @t.player(2).spx_signature.should  == "Mullooly, Neil M.|6438|6.0|123456|WWWWWW|------|TTTTTT" # winner
          @t.player(4).spx_signature.should  == "Gallagher, Mark|12138|4.0|123456|WLWWWL|------|FTTTTT"  # had one bye
          @t.player(45).spx_signature.should == "Catre, Loredan||3.5|123456|WDLWLW|------|FTTTFT"        # had two byes
          @t.player(56).spx_signature.should == "McDonnell, Cathal||0.0|123456|LLLLLL|------|FFFFFF"     # last, all defaults
        end

        it "should have consistent ranks" do
          @t.players.map{ |p| p.rank }.sort.join('').should == (1..@t.players.size).to_a.join('')
        end
      end
    end
  end
end