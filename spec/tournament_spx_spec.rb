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
          expect { @p.parse!(@x, @opt) }.not_to raise_error
        end

        it "should parse without error" do
          @p.parse(@x, @opt)
          expect(@p.error).to be_nil
        end

        it "players should have all the right names and numbers" do
          expect(@t.player(1).name).to eq("Duck, Daffy")
          expect(@t.player(2).name).to eq("Mouse, Minerva")
          expect(@t.player(3).name).to eq("Mouse, Mickey")
        end

        it "players should have correct ICU IDs" do
          expect(@t.player(1).id).to eq(12345)
          expect(@t.player(2).id).to be_nil
          expect(@t.player(3).id).to be_nil
        end

        it "players should have correct FIDE IDs" do
          expect(@t.player(1).fide_id).to be_nil
          expect(@t.player(2).fide_id).to eq(1234568)
          expect(@t.player(3).fide_id).to eq(1234567)
        end

        it "players should have correct ICU ratings" do
          expect(@t.player(1).rating).to eq(2200)
          expect(@t.player(2).rating).to be_nil
          expect(@t.player(3).rating).to be_nil
        end

        it "players should have correct FIDE ratings" do
          expect(@t.player(1).fide_rating).to be_nil
          expect(@t.player(2).fide_rating).to eq(1900)
          expect(@t.player(3).fide_rating).to be_nil
        end

        it "players should have correct titles" do
          expect(@t.player(1).title).to eq("IM")
          expect(@t.player(2).title).to be_nil
          expect(@t.player(3).title).to eq("GM")
        end

        it "players should have correct federations" do
          expect(@t.player(1).fed).to eq("IRL")
          expect(@t.player(2).fed).to be_nil
          expect(@t.player(3).fed).to eq("USA")
        end

        it "players should have correct scores" do
          expect(@t.player(1).points).to eq(2.0)
          expect(@t.player(2).points).to eq(1.5)
          expect(@t.player(3).points).to eq(1.0)
        end

        it "players should have correct ranks" do
          expect(@t.player(1).rank).to eq(1)
          expect(@t.player(2).rank).to eq(2)
          expect(@t.player(3).rank).to eq(3)
        end

        it "players should have correct results" do
          expect(@t.player(1).spx_signature2).to eq('123|DWD|FTT')
          expect(@t.player(2).spx_signature2).to eq('123|DDD|TFT')
          expect(@t.player(3).spx_signature2).to eq('123|DLD|TTF')
        end
      end

      context "serialisation" do
        before(:each) do
          name = "Bangor Masters"
          start = "2009-11-09"
          @t = ICU::Tournament.new(name, start)
          @t.add_player(ICU::Player.new('Bobby', 'Fischer', 10))
          @t.add_player(ICU::Player.new('Garry', 'Kasparov', 20))
          @t.add_player(ICU::Player.new('Mark', 'Orr', 30, :id => 1350, :fide_id => 2500035, :fed => 'IRL', :rating => 2200, :fide_rating => 2250))
          @t.add_result(ICU::Result.new(1, 10, 'D', :opponent => 30))
          @t.add_result(ICU::Result.new(2, 20, 'W', :opponent => 30))
          @t.add_result(ICU::Result.new(3, 20, 'L', :opponent => 10))
          @p = ICU::Tournament::SPExport.new
          @x = @t.serialize('SPExport')
          @r = @p.parse(@x, :name => name, :start => start)
        end

        it "should round trip" do
          expect(@p.error).to be_nil
          expect(@r.spx_signature).to eq("Bangor Masters|3|2009-11-09|3")
          expect(@r.player(1).spx_signature).to eq("Fischer, Bobby||1.5|123|DLW|---|TFT")
          expect(@r.player(2).spx_signature).to eq("Kasparov, Garry||1.0|123|LWL|---|FTT")
          expect(@r.player(3).spx_signature).to eq("Orr, Mark|1350|0.5|123|DLL|---|TTF")
        end

        it "should show all columns by default" do
          expect(@x).to match(/^No\s*Name\s*Feder\s*Intl Id\s*Loc Id\s*Rtg\s*Loc\s*Title\s*Total\s*1\s*2\s*3\s*/)
          expect(@x).to match(/1\s*Fischer,\s*Bobby\s*1\.5\s*3:D\s*0?:L?\s*2:W\s*/)
        end

        it "can have custom columns" do
          @x = @t.serialize('SPExport', :only => [])
          expect(@x).to match(/^No\s*Name\s*1\s*2\s*3\s*/)
          @x = @t.serialize('SPExport', :only => [:points])
          expect(@x).to match(/^No\s*Name\s*Total\s*1\s*2\s*3\s*/)
          @x = @t.serialize('SPExport', :only => [:points, :id])
          expect(@x).to match(/^No\s*Name\s*Loc Id\s*Total\s*1\s*2\s*3\s*/)
          @x = @t.serialize('SPExport', :only => [:points, :id, :fed])
          expect(@x).to match(/^No\s*Name\s*Feder\s*Loc Id\s*Total\s*1\s*2\s*3\s*/)
          @x = @t.serialize('SPExport', :only => [:points, :id, :fed, "fed", :rubbish, "fide_id"])
          expect(@x).to match(/^No\s*Name\s*Feder\s*Intl Id\s*Loc Id\s*Total\s*1\s*2\s*3\s*/)
          @x = @t.serialize('SPExport', :only => [:fed, "fide_id", :points, :id, :rating])
          expect(@x).to match(/^No\s*Name\s*Feder\s*Intl Id\s*Loc Id\s*Loc\s*Total\s*1\s*2\s*3\s*/)
          @x = @t.serialize('SPExport', :only => [:fed, :fide_id, "fide_rating", :points, :id, :rating])
          expect(@x).to match(/^No\s*Name\s*Feder\s*Intl Id\s*Loc Id\s*Rtg\s*Loc\s*Total\s*1\s*2\s*3\s*/)
          expect(@x).to match(/3\s*Orr,\s*Mark\s*IRL\s*2500035\s*1350\s*2250\s*2200\s*0.5\s*1:D\s*2:L\s*:\s*/)
        end

        it "the :only and :except options are logical opposites" do
          expect(@t.serialize('SPExport', :only => [:points, :id, "fed"])).to eq(@t.serialize('SPExport', :except => [:fide_id, :rating, "fide_rating", :title]))
          expect(@t.serialize('SPExport', :only => ["points"])).to eq(@t.serialize('SPExport', :except => ["fide_id", :rating, :fide_rating, :title, :id, :fed]))
          expect(@t.serialize('SPExport', :only => [:rating, :fide_rating, :title, :id, :fed, :points])).to eq(@t.serialize('SPExport', :except => [:fide_id]))
          expect(@t.serialize('SPExport', :only => %w{rating fide_rating fide_id title id fed points})).to eq(@t.serialize('SPExport', :except => []))
          expect(@t.serialize('SPExport', :only => [])).to eq(@t.serialize('SPExport', :except => [:rating, :fide_rating, :fide_id, :title, :id, :fed, :points]))
          expect(@t.serialize('SPExport', :except => [])).to eq(@t.serialize('SPExport'))
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
          expect(@t.player(1).spx_signature2).to eq('123|DWD|FTT')
          expect(@t.player(2).spx_signature2).to eq('123|DDD|TFT')
          expect(@t.player(3).spx_signature2).to eq('123|DLD|TTF')
        end
      end

      context "extreme invisible bonuses example" do
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
          expect(@t.player(1).spx_signature2).to eq('123|WWD|FFF')
          expect(@t.player(2).spx_signature2).to eq('123|WDD|FFF')
          expect(@t.player(3).spx_signature2).to eq('123|DDL|FFF')
        end
      end

      context "preservation of original names" do
        before(:each) do
          @x = <<EXPORT
No	Name          	Total	1  	2  	3

1 	daffy  duck    	2.0  	0: 	3:W	2:D
2 	MOUSE,  minerva	1.5  	3:D	0: 	1:D
3 	mouse,  MICKEY 	1.0  	2:D	1:L	0:D
EXPORT
          @p = ICU::Tournament::SPExport.new
          @t = @p.parse!(@x, :name => "Mickey Mouse Masters", :start => "2012-01-01")
        end

        it "players should have canonicalised names" do
          expect(@t.player(1).name).to eq('Duck, Daffy')
          expect(@t.player(2).name).to eq('Mouse, Minerva')
          expect(@t.player(3).name).to eq('Mouse, Mickey')
        end

        it "players should have original names" do
          expect(@t.player(1).original_name).to eq('daffy duck')
          expect(@t.player(2).original_name).to eq('MOUSE, minerva')
          expect(@t.player(3).original_name).to eq('mouse, MICKEY')
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
          expect(@t.player(1).name).to eq("Duck, Daffy")
          expect(@t.player(2).name).to eq("Mouse, Minerva")
          expect(@t.player(3).name).to eq("Mouse, Mickey")
        end

        it "players should have correct results" do
          expect(@t.player(1).spx_signature2).to eq('123|DWD|FFT')
          expect(@t.player(2).spx_signature2).to eq('123|DLD|FFT')
          expect(@t.player(3).spx_signature2).to eq('123|DLD|FFF')
        end

        it "players should have correct ranks given default name tie-break" do
          expect(@t.player(1).rank).to eq(1)
          expect(@t.player(2).rank).to eq(3)
          expect(@t.player(3).rank).to eq(2)
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
          expect(@p.error).to be_nil
          expect(t.player(1).name).to eq("Dück, Dâffy")
          expect(t.player(2).name).to eq("Möuse, Mickéy")
        end

        it "Latin-1" do
          t = @p.parse(@x.encode("ISO-8859-1"), @opt)
          expect(@p.error).to be_nil
          expect(t.player(1).name).to eq("Dück, Dâffy")
          expect(t.player(2).name).to eq("Möuse, Mickéy")
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
          expect { @p.parse!(data, @opt) }.not_to raise_error
        end

        it "no header" do
          data = <<EXPORT
1 	Duck, Daffy   	1.5  	2:W	2:D
2 	Mouse, Mickey 	0.5  	1:L	1:L
EXPORT
          expect { @p.parse!(data, @opt) }.to raise_error(/header/)
        end

        it "invalid header" do
          data = <<EXPORT
Xx	Name          	Total	1  	2

1 	Duck, Daffy   	1.5  	2:W	2:D
2 	Mouse, Mickey 	0.5  	1:L	1:D
EXPORT
          expect { @p.parse!(data, @opt) }.to raise_error(/header/)
        end

        it "missing round 1" do
          data = <<EXPORT
No	Name          	Total	2  	3

1 	Duck, Daffy   	1.5  	2:W	2:D
2 	Mouse, Mickey 	0.0  	1:L	1:L
EXPORT
          expect { @p.parse!(data, @opt) }.to raise_error(/round 1/)
        end

        it "missing round 2" do
          data = <<EXPORT
No	Name          	Total	1  	3

1 	Duck, Daffy   	1.5  	2:W	2:D
2 	Mouse, Mickey 	0.0  	1:L	1:L
EXPORT
          expect { @p.parse!(data, @opt) }.to raise_error(/round 2/)
        end

        it "incorrect total" do
          data = <<EXPORT
No	Name          	Total	1  	2

1 	Duck, Daffy   	1.5  	2:W	2:D
2 	Mouse, Mickey 	1.0  	1:L	1:D
EXPORT
          expect { @p.parse!(data, @opt) }.to raise_error(/total/)
        end


        it "mismatched results" do
          data = <<EXPORT
No	Name          	Total	1  	2

1 	Duck, Daffy   	1.5  	2:W	2:D
2 	Mouse, Mickey 	0.0  	1:L	1:L
EXPORT
          expect { @p.parse!(data, @opt) }.to raise_error(/result/)
        end

        it "invalid attribute, title for example)" do
          data = <<EXPORT
No	Name          	Title	Total	1  	2

1 	Duck, Daffy   	mg   	1.5  	2:W	2:D
2 	Mouse, Mickey 	     	0.5  	1:L	1:D
EXPORT
          expect { @p.parse!(data, @opt) }.to raise_error(/title/)
        end
      end

      context "Gonzaga Challengers 2010 file" do
        before(:each) do
          @p = ICU::Tournament::SPExport.new
          @t = @p.parse_file(samples + 'gonzaga_challengers_2010.txt', :name => "Gonzaga Chess Classic 2010 Challengers Section", :start => "2010-01-29")
          @s = open(samples + 'gonzaga_challengers_2010.txt') { |f| f.read }
        end

        it "should parse and have the right basic details" do
          expect(@p.error).to be_nil
          expect(@t.spx_signature).to eq("Gonzaga Chess Classic 2010 Challengers Section|6|2010-01-29|56")
        end

        it "should have correct details for selected players" do
          expect(@t.player(2).spx_signature).to  eq("Mullooly, Neil M.|6438|6.0|123456|WWWWWW|------|TTTTTT") # winner
          expect(@t.player(4).spx_signature).to  eq("Gallagher, Mark|12138|4.0|123456|WLWWWL|------|FTTTTT")  # had one bye
          expect(@t.player(45).spx_signature).to eq("Catre, Loredan||3.5|123456|WDLWLW|------|FTTTFT")        # had two byes
          expect(@t.player(56).spx_signature).to eq("McDonnell, Cathal||0.0|123456|LLLLLL|------|FFFFFF")     # last, all defaults
        end

        it "should have consistent ranks" do
          expect(@t.players.map{ |p| p.rank }.sort.join('')).to eq((1..@t.players.size).to_a.join(''))
        end
      end
    end
  end
end