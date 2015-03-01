# encoding: UTF-8
require File.expand_path(File.dirname(__FILE__) + '/spec_helper')
SAMPLES = File.dirname(__FILE__) + '/samples/sp/'

module ICU
  class Tournament
    def sp_signature
      [name, arbiter, rounds, start, players.size].join("|")
    end
  end
  class Player
    def sp_signature
      [
        name, id, fide_id, rating, fide_rating, points, rank,
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
          @t = @p.parse_file(SAMPLES + 'gonzaga_challengers_2010.trn', :start => "2010-01-29")
          @s = open(SAMPLES + 'gonzaga_challengers_2010.txt') { |f| f.read }
        end

        it "should parse and have the right basic details" do
          expect(@p.error).to be_nil
          expect(@t.sp_signature).to eq("Gonzaga Chess Classic 2010 Challengers Section|Herbert Scarry|6|2010-01-29|56")
        end

        it "should have correct details for selected players" do
          expect(@t.player(2).sp_signature).to  eq("Mullooly, Neil M.|6438||1083||6.0|1|123456|WWWWWW|WBWBWB|TTTTTT") # winner
          expect(@t.player(4).sp_signature).to  eq("Gallagher, Mark|12138||1036||4.0|9|123456|WLWWWL|WBWBWB|FTTTTT")  # had one bye
          expect(@t.player(45).sp_signature).to eq("Catre, Loredan|||507||3.5|18|123456|WDLWLW|BWBWBW|FTTTFT")        # had two byes
          expect(@t.player(56).sp_signature).to eq("McDonnell, Cathal|||498||0.0|54|1|L|-|F")                          # last
        end

        it "original names should be preserved" do
          expect(@t.player(2).original_name).to eq("MULLOOLY, neil m")
          expect(@t.player(4).original_name).to eq("Gallagher, Mark")
        end

        it "should have consistent ranks" do
          expect(@t.players.map{ |p| p.rank }.sort.join('')).to eq((1..@t.players.size).to_a.join(''))
        end

        it "should have the correct tie breaks" do
          expect(@t.tie_breaks.join('|')).to eq("buchholz|harkness|progressive")
        end

        it "should serialize to the text export format" do
          expect(@t.serialize('SPExport', :only => [:id, :points])).to eq(@s)
        end
      end

      context "U19 Junior Championships 2010" do
        before(:all) do
          @p = ICU::Tournament::SwissPerfect.new
          @t = @p.parse_file(SAMPLES + 'junior_championships_u19_2010.sco', :start => "2010-04-11")
          @s = open(SAMPLES + 'junior_championships_u19_2010.txt') { |f| f.read }
        end

        it "should parse and have the right basic details" do
          expect(@p.error).to be_nil
          expect(@t.sp_signature).to eq("U - 19 All Ireland||3|2010-04-11|4")
        end

        it "should have correct details for selected players" do
          expect(@t.player(1).sp_signature).to eq("Griffiths, Ryan-Rhys|6897||2225||3.0|1|123|WWW|WWB|TTT")
          expect(@t.player(2).sp_signature).to eq("Flynn, Jamie|5226||1633||2.0|2|123|WLW|WBW|TTT")
          expect(@t.player(3).sp_signature).to eq("Hulleman, Leon|6409||1466||1.0|3|123|LWL|BBW|TTT")
          expect(@t.player(4).sp_signature).to eq("Dunne, Thomas|10914||||0.0|4|123|LLL|BWB|TTT")
        end

        it "should have consistent ranks" do
          expect(@t.players.map{ |p| p.rank }.sort.join('')).to eq((1..@t.players.size).to_a.join(''))
        end

        it "should have the no tie breaks" do
          expect(@t.tie_breaks.join('|')).to eq("")
        end

        it "should serialize to the text export format" do
          expect(@t.rerank.renumber.serialize('SPExport', :only => [:id, :points])).to eq(@s)
        end
      end

      context "Limerick Club Championship 2009-10" do
        before(:all) do
          @p = ICU::Tournament::SwissPerfect.new
          @t = @p.parse_file(SAMPLES + 'LimerickClubChampionship09.ini', :start => "2009-09-15")
        end

        it "should parse and have the right basic details" do
          expect(@p.error).to be_nil
          expect(@t.sp_signature).to eq("Limerick Club Championship 2009||7|2009-09-15|19")
        end

        it "should have correct details for selected players" do
          expect(@t.player(15).sp_signature).to eq("Talazec, Laurent|10692||1570||5.5|1|1234567|WWWDDDW|WWBWBWB|FTTTTTT")  # winner
          expect(@t.player(6).sp_signature).to  eq("Foenander, Phillip|7168||1434||4.0|7|1234567|WLWLLWW|BWBWBWB|TTFFTTT") # had some byes
          expect(@t.player(19).sp_signature).to eq("Wall, Robert|||||3.0|14|34567|WWLWL|WWBBW|FTTTT")                      # didn't play 1st 2 rounds
          expect(@t.player(17).sp_signature).to eq("Freeman, Conor|||||2.0|16|1234567|DDLWLLL|--BWBWB|FFTTTTT")            # had byes and bonus (in BONUS)
          expect(@t.player(18).sp_signature).to eq("Freeman, Ruiri|||||2.0|17|1234567|DDLLLLW|--WBBWB|FFTTTTF")            # had byes and bonus (in BONUS)
          expect(@t.player(16).sp_signature).to eq("O'Connor, David|||||1.0|19|123|WLL|WBW|FTF")                           # last
        end

        it "should have consistent ranks" do
          expect(@t.players.map{ |p| p.rank }.sort.join('')).to eq((1..@t.players.size).to_a.join(''))
        end

        it "should have the correct tie breaks" do
          expect(@t.tie_breaks.join('|')).to eq("harkness|buchholz|progressive")
        end
      end

      context "Junior Inter Provincials U16 2010" do
        before(:all) do
          @p = ICU::Tournament::SwissPerfect.new
          @t = @p.parse_file(SAMPLES + 'junior_provincials_u16_2010', :start => "2010-02-02")
        end

        it "should parse and have the right basic details" do
          expect(@p.error).to be_nil
          expect(@t.sp_signature).to eq("U16 Inter Provincials 2010|David B Murray|3|2010-02-02|18")
        end

        it "should have correct details for selected players" do
          expect(@t.player(15).sp_signature).to eq("Gupta, Radhika|||1247||3.0|1|123|WWW|BBW|TTT")            # won all his games
          expect(@t.player(18).sp_signature).to eq("Hurley, Thomas|6292||820||1.0|14|1|W|B|F")                # scored just 1 from a bye in R1
          expect(@t.player(8).sp_signature).to  eq("Berney, Mark|10328||1948||2.0|3|23|WW|BW|TT")             # didn't play in round 1
          expect(@t.player(10).sp_signature).to eq("O'Donnell, Conor E.|10792||1073||2.0|10|123|LWW|WBW|TFT") # got just 1 point for a bye
        end

        it "should have consistent ranks" do
          expect(@t.players.map{ |p| p.rank }.sort.join('')).to eq((1..@t.players.size).to_a.join(''))
        end

        it "should have the correct tie breaks" do
          expect(@t.tie_breaks.join('|')).to eq("neustadtl")
        end
      end

      context "Mulcahy Cup 2010" do
        before(:all) do
          @p = ICU::Tournament::SwissPerfect.new
          @t = @p.parse_file(SAMPLES + 'mulcahy_2010', :start => "2010-01-15")
        end

        it "should parse and have the right basic details" do
          expect(@p.error).to be_nil
          expect(@t.sp_signature).to eq("Mulcahy Cup 2010|Stephen Short|6|2010-01-15|50")
        end

        it "should have correct details for selection of players who got bonuses (in MEMO)" do
          expect(@t.player(23).sp_signature).to eq("Long, Killian|10293||1506||2.5|33|123456|WDLLWL|WWBWBB|TFTTTT")
          expect(@t.player(26).sp_signature).to eq("Bradley, Michael|6756||1413||3.0|26|123456|DDLWWL|BWWBWW|TFTTTT")
          expect(@t.player(15).sp_signature).to eq("Twomey, Pat|1637||1656||4.5|7|123456|WDLWWW|WWWBWB|FFTTTT")
          expect(@t.player(46).sp_signature).to eq("O'Riordan, Pat|10696||900||2.0|42|123456|LDDLDD|BWBWWB|TTTTFT")
          expect(@t.player(38).sp_signature).to eq("Gill, Craig I.|10637||1081||2.0|43|123456|LLWDDL|BWBWWB|TTTTFT")
        end

        it "should have consistent ranks" do
          expect(@t.players.map{ |p| p.rank }.sort.join('')).to eq((1..@t.players.size).to_a.join(''))
        end
      end

      context "National Club Champiomships 2010" do
        before(:all) do
          @p = ICU::Tournament::SwissPerfect.new
          @t = @p.parse_file(SAMPLES + 'ncc', :start => "2010-05-08")
        end

        it "should parse and have the right basic details" do
          expect(@p.error).to be_nil
          expect(@t.sp_signature).to eq("National Club Championship 2010|Gerry Graham|4|2010-05-08|77")
        end

        it "should have correct details for selection of players, including ICU IDs" do
          expect(@t.player(2).sp_signature).to  eq("Szabo, Gergely|12379|1205064||2530|4.0|4|1234|WWWW|WBWB|TTTT")
          expect(@t.player(5).sp_signature).to  eq("Daly, Colm|295|2500434|2314||3.5|7|1234|WWWD|WBWB|TTTT")
          expect(@t.player(8).sp_signature).to  eq("Vega, Marcos Llaneza||2253585|2475||3.0|16|1234|DDWW|BWBW|TTTT")
          expect(@t.player(67).sp_signature).to eq("Lee, Shane|780||1633||1.0|52|134|DLD|WWW|TTT")
        end
      end

      context "Drogheda Section A, 2010, with an invalid federation" do
        before(:each) do
          @p = ICU::Tournament::SwissPerfect.new
        end

        it "should not parse because of the invalid federation" do
          t = @p.parse_file(SAMPLES + 'drog_a.zip', :start => "2010-06-04")
          expect(t).to be_nil
          expect(@p.error).to match(/invalid federation/i)
        end

        it "should parse if instructed to skip bad feds" do
          t = @p.parse_file(SAMPLES + 'drog_a.zip', :start => "2010-06-04", :fed => :skip)
          expect(@p.error).to be_nil
          expect(t.player(5).fed).to be_nil
          expect(t.player(6).fed).to eq("ESP")
        end

        it "should parse if instructed to skip all feds" do
          t = @p.parse_file(SAMPLES + 'drog_a.zip', :start => "2010-06-04", :fed => 'ignore')
          expect(@p.error).to be_nil
          expect(t.player(5).fed).to be_nil
          expect(t.player(6).fed).to be_nil
        end
      end

      context "Limerick CC, 2010-11, which has no 'Tournament Info' section in the INI file" do
        before(:each) do
          @p = ICU::Tournament::SwissPerfect.new
        end

        it "should parse" do
          @t = @p.parse_file(SAMPLES + 'limerick_cc_2011.zip', :start => "2010-10-15")
          expect(@p.error).to be_nil
          expect(@t.name).to eq("Unspecified")
          expect(@t.rounds).to eq(7)
          expect(@t.arbiter).to be_nil
        end
      end

      context "Phibsborough Intermediate CC, 2012, which has zero for the number of rounds in the INI file" do
        before(:each) do
          @p = ICU::Tournament::SwissPerfect.new
        end

        it "should parse" do
          @t = @p.parse_file(SAMPLES + 'phibs_cc_inter_2012.zip', :start => "2012-04-16")
          expect(@p.error).to be_nil
          expect(@t.name).to eq("Phibsboro Club Championship 2012 Inter")
          expect(@t.rounds).to eq(5)
          expect(@t.arbiter).to eq("Michael Germaine")
        end
      end

      context "Non-existant ZIP file" do
        before(:all) do
          @p = ICU::Tournament::SwissPerfect.new
          @t = @p.parse_file(SAMPLES + 'nosuchzipfile.zip', :start => "2010-05-08")
        end

        it "should not parse and should have a relevant error" do
          expect(@t).to be_nil
          expect(@p.error).to match(/invalid ZIP file/i)
        end
      end

      context "Invalid ZIP file" do
        before(:all) do
          @p = ICU::Tournament::SwissPerfect.new
          @t = @p.parse_file(SAMPLES + 'notazipfile.zip', :start => "2010-05-08")
        end

        it "should not parse and have a should have relevant error" do
          expect(@t).to be_nil
          expect(@p.error).to match(/invalid ZIP file/i)
        end
      end

      context "ZIP file containing the wrong number of files" do
        before(:all) do
          @p = ICU::Tournament::SwissPerfect.new
          @t = @p.parse_file(SAMPLES + 'notenoughfiles.zip', :start => "2010-05-08")
        end

        it "should not parse and should have a relevant error" do
          expect(@t).to be_nil
          expect(@p.error).to match(/3 files/i)
        end
      end

      context "ZIP file containing the files with mixed stems" do
        before(:all) do
          @p = ICU::Tournament::SwissPerfect.new
          @t = @p.parse_file(SAMPLES + 'mixedstems.zip', :start => "2010-05-08")
        end

        it "should not parse and should have a relevant error" do
          expect(@t).to be_nil
          expect(@p.error).to match(/different stem/i)
        end
      end

      context "ZIP file" do
        before(:all) do
          @p = ICU::Tournament::SwissPerfect.new
          @t = @p.parse_file(SAMPLES + 'nccz.zip', :start => "2010-05-08")
        end

        it "should parse and have the right basic details" do
          expect(@p.error).to be_nil
          expect(@t.sp_signature).to eq("National Club Championship 2010|Gerry Graham|4|2010-05-08|77")
        end

        it "should have correct details for selection of players, including ICU IDs" do
          expect(@t.player(2).sp_signature).to  eq("Szabo, Gergely|12379|1205064||2530|4.0|4|1234|WWWW|WBWB|TTTT")
          expect(@t.player(5).sp_signature).to  eq("Daly, Colm|295|2500434|2314||3.5|7|1234|WWWD|WBWB|TTTT")
          expect(@t.player(8).sp_signature).to  eq("Vega, Marcos Llaneza||2253585|2475||3.0|16|1234|DDWW|BWBW|TTTT")
          expect(@t.player(67).sp_signature).to eq("Lee, Shane|780||1633||1.0|52|134|DLD|WWW|TTT")
        end
      end

      context "ZIP file without a ZIP ending" do
        before(:all) do
          @p = ICU::Tournament::SwissPerfect.new
        end

        it "should not parse unless ZIP format is signalled with an option" do
          expect { @p.parse_file!(SAMPLES + 'nccz.piz', :start => "2010-05-08") }.to raise_error(/cannot find/i)
        end

        it "should parse if ZIP format is signalled with an option" do
          expect { @p.parse_file!(SAMPLES + 'nccz.piz', :zip => true, :start => "2010-05-08") }.not_to raise_error
        end
      end

      context "Names with accented characters" do
        before(:all) do
          @p = ICU::Tournament::SwissPerfect.new
        end

        it "should parse and the name should be in UTF-8" do
          expect { @t = @p.parse_file!(SAMPLES + 'munster_u10_2011.zip', :start => "2011-01-20") }.not_to raise_error
          expect(@t.player(1).sp_signature).to  eq("Kennedy, Stephen|||849||2.0|6|12345|WLWLL|BWBWB|TTTTT")
          expect(@t.player(4).sp_signature).to  eq("Sheehan, Ciarán|||||3.0|5|12345|LWWLW|WBWBW|TTTTF")
          expect(@t.player(10).sp_signature).to  eq("Sheehan, Adam|||||2.0|7|12345|WLLWL|WBWWB|TTTFT")
        end
      end

      context "Defaulting the start date" do
        before(:all) do
          @p = ICU::Tournament::SwissPerfect.new
          @t = @p.parse_file(SAMPLES + 'nccz.zip')
        end

        it "should default the start date if not supplied" do
          expect(@t.start).to eq("2000-01-01")
        end
      end
    end
  end
end