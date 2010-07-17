require File.dirname(__FILE__) + '/spec_helper'
SAMPLES = File.dirname(__FILE__) + '/samples/sp/'

module ICU
  class Tournament
    def signature
      [name, arbiter, rounds, start, players.size].join("|")
    end
  end
  class Player
    def signature
      [
        name, id, rating, points, rank,
        results.map{ |r| r.round }.join(''),
        results.map{ |r| r.score }.join(''),
        results.map{ |r| r.colour || "-" }.join(''),
        results.map{ |r| r.rateable ? 'T' : 'F' }.join(''),
      ].join("|")
    end
  end
end

module ICU
  class Tournament
    describe SwissPerfect do

      context "Gonzaga Challengers 2010" do

        before(:all) do
          @p = ICU::Tournament::SwissPerfect.new
          @t = @p.parse_file(SAMPLES + 'gonzaga_challengers_2010.trn', "2010-01-29")
          @s = open(SAMPLES + 'gonzaga_challengers_2010.txt') { |f| f.read }
        end

        it "should parse and have the right basic details" do
          @p.error.should be_nil
          @t.signature.should == "Gonzaga Chess Classic 2010 Challengers Section|Herbert Scarry|6|2010-01-29|56"
        end

        it "should have correct details for selected players" do
          @t.player(2).signature.should  == "Mullooly, Neil M.|6438|1083|6.0|1|123456|WWWWWW|WBWBWB|TTTTTT" # winner
          @t.player(4).signature.should  == "Gallagher, Mark|12138|1036|4.0|9|123456|WLWWWL|WBWBWB|FTTTTT"  # had one bye
          @t.player(45).signature.should == "Catre, Loredan||507|3.5|18|123456|WDLWLW|BWBWBW|FTTTFT"         # had two byes
          @t.player(56).signature.should == "McDonnell, Cathal||498|0.0|54|1|L|-|F"                          # last
        end

        it "should have consistent ranks" do
          @t.players.map{ |p| p.rank }.sort.join('').should == (1..@t.players.size).to_a.join('')
        end

        it "should have the correct tie breaks" do
          @t.tie_breaks.join('|').should == "buchholz|harkness|progressive"
        end

        it "should serialize to the text export format" do
          @t.serialize('SwissPerfect').should == @s
        end
      end

      context "U19 Junior Championships 2010" do

        before(:all) do
          @p = ICU::Tournament::SwissPerfect.new
          @t = @p.parse_file(SAMPLES + 'junior_championships_u19_2010.sco', "2010-04-11")
          @s = open(SAMPLES + 'junior_championships_u19_2010.txt') { |f| f.read }
        end

        it "should parse and have the right basic details" do
          @p.error.should be_nil
          @t.signature.should == "U - 19 All Ireland||3|2010-04-11|4"
        end

        it "should have correct details for selected players" do
          @t.player(1).signature.should == "Griffiths, Ryan-Rhys|6897|2225|3.0|1|123|WWW|WWB|TTT"
          @t.player(2).signature.should == "Flynn, Jamie|5226|1633|2.0|2|123|WLW|WBW|TTT"
          @t.player(3).signature.should == "Hulleman, Leon|6409|1466|1.0|3|123|LWL|BBW|TTT"
          @t.player(4).signature.should == "Dunne, Thomas|10914||0.0|4|123|LLL|BWB|TTT"
        end

        it "should have consistent ranks" do
          @t.players.map{ |p| p.rank }.sort.join('').should == (1..@t.players.size).to_a.join('')
        end

        it "should have the no tie breaks" do
          @t.tie_breaks.join('|').should == ""
        end

        it "should serialize to the text export format" do
          @t.rerank.renumber.serialize('SwissPerfect').should == @s
        end
      end

      context "Limerick Club Championship 2009-10" do

        before(:all) do
          @p = ICU::Tournament::SwissPerfect.new
          @t = @p.parse_file(SAMPLES + 'LimerickClubChampionship09.ini', "2009-09-15")
        end

        it "should parse and have the right basic details" do
          @p.error.should be_nil
          @t.signature.should == "Limerick Club Championship 2009||7|2009-09-15|19"
        end

        it "should have correct details for selected players" do
          @t.player(15).signature.should == "Talazec, Laurent|10692|1570|5.5|1|1234567|WWWDDDW|WWBWBWB|FTTTTTT"  # winner
          @t.player(6).signature.should  == "Foenander, Phillip|7168|1434|4.0|7|1234567|WLWLLWW|BWBWBWB|TTFFTTT" # had some byes
          @t.player(19).signature.should == "Wall, Robert|||3.0|14|34567|WWLWL|WWBBW|FTTTT"                       # didn't play 1st 2 rounds
          @t.player(17).signature.should == "Freeman, Conor|||2.0|16|1234567|DDLWLLL|--BWBWB|FFTTTTT"             # had byes and bonus (in BONUS)
          @t.player(18).signature.should == "Freeman, Ruiri|||2.0|17|1234567|DDLLLLW|--WBBWB|FFTTTTF"             # had byes and bonus (in BONUS)
          @t.player(16).signature.should == "O'Connor, David|||1.0|19|123|WLL|WBW|FTF"                            # last
        end

        it "should have consistent ranks" do
          @t.players.map{ |p| p.rank }.sort.join('').should == (1..@t.players.size).to_a.join('')
        end

        it "should have the correct tie breaks" do
          @t.tie_breaks.join('|').should == "harkness|buchholz|progressive"
        end
      end

      context "Junior Inter Provincials U16 2010" do

        before(:all) do
          @p = ICU::Tournament::SwissPerfect.new
          @t = @p.parse_file(SAMPLES + 'junior_provincials_u16_2010', "2010-02-02")
        end

        it "should parse and have the right basic details" do
          @p.error.should be_nil
          @t.signature.should == "U16 Inter Provincials 2010|David B Murray|3|2010-02-02|18"
        end

        it "should have correct details for selected players" do
          @t.player(15).signature.should == "Gupta, Radhika||1247|3.0|1|123|WWW|BBW|TTT"            # won all his games
          @t.player(18).signature.should == "Hurley, Thomas|6292|820|1.0|14|1|W|B|F"                 # scored just 1 from a bye in R1
          @t.player(8).signature.should  == "Berney, Mark|10328|1948|2.0|3|23|WW|BW|TT"             # didn't play in round 1
          @t.player(10).signature.should == "O'Donnell, Conor E.|10792|1073|2.0|10|123|LWW|WBW|TFT"  # got just 1 point for a bye
        end

        it "should have consistent ranks" do
          @t.players.map{ |p| p.rank }.sort.join('').should == (1..@t.players.size).to_a.join('')
        end

        it "should have the correct tie breaks" do
          @t.tie_breaks.join('|').should == "neustadtl"
        end
      end

      context "Mulcahy Cup 2010" do

        before(:all) do
          @p = ICU::Tournament::SwissPerfect.new
          @t = @p.parse_file(SAMPLES + 'mulcahy_2010', "2010-01-15")
        end

        it "should parse and have the right basic details" do
          @p.error.should be_nil
          @t.signature.should == "Mulcahy Cup 2010|Stephen Short|6|2010-01-15|50"
        end

        it "should have correct details for selection of players who got bonuses (in MEMO)" do
          @t.player(23).signature.should == "Long, Killian|10293|1506|2.5|33|123456|WDLLWL|WWBWBB|TFTTTT"
          @t.player(26).signature.should == "Bradley, Michael|6756|1413|3.0|26|123456|DDLWWL|BWWBWW|TFTTTT"
          @t.player(15).signature.should == "Twomey, Pat|1637|1656|4.5|7|123456|WDLWWW|WWWBWB|FFTTTT"
          @t.player(46).signature.should == "O'Riordan, Pat|10696|900|2.0|42|123456|LDDLDD|BWBWWB|TTTTFT"
          @t.player(38).signature.should == "Gill, Craig I.|10637|1081|2.0|43|123456|LLWDDL|BWBWWB|TTTTFT"
        end

        it "should have consistent ranks" do
          @t.players.map{ |p| p.rank }.sort.join('').should == (1..@t.players.size).to_a.join('')
        end
      end

      context "National Club Champiomships 2010" do

        before(:all) do
          @p = ICU::Tournament::SwissPerfect.new
          @t = @p.parse_file(SAMPLES + 'ncc', "2010-05-08")
        end

        it "should parse and have the right basic details" do
          @p.error.should be_nil
          @t.signature.should == "National Club Championship 2010|Gerry Graham|4|2010-05-08|77"
        end

        it "should have correct details for selection of players, including ICU IDs" do
          @t.player(2).signature.should  == "Szabo, Gergely|12379|2530|4.0|4|1234|WWWW|WBWB|TTTT"
          @t.player(5).signature.should  == "Daly, Colm|295|2314|3.5|7|1234|WWWD|WBWB|TTTT"
          @t.player(8).signature.should  == "Vega, Marcos Llaneza||2475|3.0|16|1234|DDWW|BWBW|TTTT"
          @t.player(67).signature.should == "Lee, Shane|780|1633|1.0|52|134|DLD|WWW|TTT"
        end

        it "should have correct details for selection of players, including international IDs and ratings when so configured" do
          @t = @p.parse_file(SAMPLES + 'ncc', "2010-05-08", :id => :intl, :rating => :intl)
          @t.player(2).signature.should  == "Szabo, Gergely|1205064||4.0|4|1234|WWWW|WBWB|TTTT"
          @t.player(5).signature.should  == "Daly, Colm|2500434||3.5|7|1234|WWWD|WBWB|TTTT"
          @t.player(8).signature.should  == "Vega, Marcos Llaneza|2253585||3.0|16|1234|DDWW|BWBW|TTTT"
          @t.player(67).signature.should == "Lee, Shane|||1.0|52|134|DLD|WWW|TTT"
        end
      end

      context "Non-existant ZIP file" do

        before(:all) do
          @p = ICU::Tournament::SwissPerfect.new
          @t = @p.parse_file(SAMPLES + 'nosuchzipfile.zip', "2010-05-08")
        end

        it "should not parse and should have a relevant error" do
          @t.should be_nil
          @p.error.should match(/invalid ZIP file/i)
        end
      end

      context "Invalid ZIP file" do

        before(:all) do
          @p = ICU::Tournament::SwissPerfect.new
          @t = @p.parse_file(SAMPLES + 'notazipfile.zip', "2010-05-08")
        end

        it "should not parse and have a should have relevant error" do
          @t.should be_nil
          @p.error.should match(/invalid ZIP file/i)
        end
      end

      context "ZIP file containing the wrong number of files" do

        before(:all) do
          @p = ICU::Tournament::SwissPerfect.new
          @t = @p.parse_file(SAMPLES + 'notenoughfiles.zip', "2010-05-08")
        end

        it "should not parse and should have a relevant error" do
          @t.should be_nil
          @p.error.should match(/3 files/i)
        end
      end

      context "ZIP file containing the files with mixed stems" do

        before(:all) do
          @p = ICU::Tournament::SwissPerfect.new
          @t = @p.parse_file(SAMPLES + 'mixedstems.zip', "2010-05-08")
        end

        it "should not parse and should have a relevant error" do
          @t.should be_nil
          @p.error.should match(/different stem/i)
        end
      end

      context "National Club Champiomships 2010 ZIP file" do

        before(:all) do
          @p = ICU::Tournament::SwissPerfect.new
          @t = @p.parse_file(SAMPLES + 'nccz.zip', "2010-05-08")
        end

        it "should parse and have the right basic details" do
          @p.error.should be_nil
          @t.signature.should == "National Club Championship 2010|Gerry Graham|4|2010-05-08|77"
        end

        it "should have correct details for selection of players, including ICU IDs" do
          @t.player(2).signature.should  == "Szabo, Gergely|12379|2530|4.0|4|1234|WWWW|WBWB|TTTT"
          @t.player(5).signature.should  == "Daly, Colm|295|2314|3.5|7|1234|WWWD|WBWB|TTTT"
          @t.player(8).signature.should  == "Vega, Marcos Llaneza||2475|3.0|16|1234|DDWW|BWBW|TTTT"
          @t.player(67).signature.should == "Lee, Shane|780|1633|1.0|52|134|DLD|WWW|TTT"
        end
      end
    end
  end
end