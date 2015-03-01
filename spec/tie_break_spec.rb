require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

module ICU
  describe TieBreak do
    context "#identify which rule" do
      it "should recognize Buchholz" do
        expect(TieBreak.identify(:buchholz).id).to eq(:buchholz)
        expect(TieBreak.identify(" BucholtS ").id).to eq(:buchholz)
        expect(TieBreak.identify(" bh ").id).to eq(:buchholz)
        expect(TieBreak.identify(" buccholts ").code).to eq("BH")
      end

      it "should recognize Harkness (Median)" do
        expect(TieBreak.identify(:harkness).id).to eq(:harkness)
        expect(TieBreak.identify("median").id).to eq(:harkness)
        expect(TieBreak.identify(" hARKNES ").id).to eq(:harkness)
        expect(TieBreak.identify("HK").id).to eq(:harkness)
        expect(TieBreak.identify("MEDIAN").code).to eq("HK")
      end

      it "should recognize Modified Median" do
        expect(TieBreak.identify(:modified).id).to eq(:modified_median)
        expect(TieBreak.identify(" modified  MEDIAN ").id).to eq(:modified_median)
        expect(TieBreak.identify("MM").code).to eq("MM")
      end

      it "should recognize Number of Blacks" do
        expect(TieBreak.identify(:blacks).id).to eq(:blacks)
        expect(TieBreak.identify("number\tof\tblacks\n").id).to eq(:blacks)
        expect(TieBreak.identify("\tnb\t").id).to eq(:blacks)
        expect(TieBreak.identify("number_blacks").code).to eq("NB")
      end

      it "should recognize Number of Wins" do
        expect(TieBreak.identify(:wins).id).to eq(:wins)
        expect(TieBreak.identify(" number-of-wins ").id).to eq(:wins)
        expect(TieBreak.identify("NUMBER WINS\r\n").id).to eq(:wins)
        expect(TieBreak.identify("nw").code).to eq("NW")
      end

      it "should recognize Player's of Name" do
        expect(TieBreak.identify(:name).id).to eq(:name)
        expect(TieBreak.identify("Player's Name").id).to eq(:name)
        expect(TieBreak.identify("players_name").id).to eq(:name)
        expect(TieBreak.identify("PN").id).to eq(:name)
        expect(TieBreak.identify("PLAYER-NAME").code).to eq("PN")
      end

      it "should recognize Sonneborn-Berger" do
        expect(TieBreak.identify(:sonneborn_berger).id).to eq(:neustadtl)
        expect(TieBreak.identify(:neustadtl).id).to eq(:neustadtl)
        expect(TieBreak.identify("  SONNEBORN\nberger").id).to eq(:neustadtl)
        expect(TieBreak.identify("\t  soneborn_berger  \t").id).to eq(:neustadtl)
        expect(TieBreak.identify("sb").id).to eq(:neustadtl)
        expect(TieBreak.identify("NESTADL").code).to eq("SB")
      end

      it "should recognize Sum of Progressive Scores" do
        expect(TieBreak.identify(:progressive).id).to eq(:progressive)
        expect(TieBreak.identify("CUMULATIVE").id).to eq(:progressive)
        expect(TieBreak.identify("sum of progressive scores").id).to eq(:progressive)
        expect(TieBreak.identify("SUM-cumulative_SCORE").id).to eq(:progressive)
        expect(TieBreak.identify(:cumulative_score).id).to eq(:progressive)
        expect(TieBreak.identify("SumOfCumulative").id).to eq(:progressive)
        expect(TieBreak.identify("SP").code).to eq("SP")
      end

      it "should recognize Sum of Opponents' Ratings" do
        expect(TieBreak.identify(:ratings).id).to eq(:ratings)
        expect(TieBreak.identify("sum of opponents ratings").id).to eq(:ratings)
        expect(TieBreak.identify("Opponents' Ratings").id).to eq(:ratings)
        expect(TieBreak.identify("SR").id).to eq(:ratings)
        expect(TieBreak.identify("SUMOPPONENTSRATINGS").code).to eq("SR")
      end

      it "should recognize player's name" do
        expect(TieBreak.identify(:name).id).to eq(:name)
        expect(TieBreak.identify(" player's  NAME ").id).to eq(:name)
        expect(TieBreak.identify("pn").code).to eq("PN")
      end

      it "should return nil for unrecognized tie breaks" do
        expect(TieBreak.identify("XYZ")).to be_nil
        expect(TieBreak.identify(nil)).to be_nil
      end
    end
    
    context "return an array of tie break rules" do
      before(:each) do
        @rules = TieBreak.rules
      end

      it "should be an array in a specific order" do
        expect(@rules.size).to eq(9)
        expect(@rules.first.name).to eq("Buchholz")
        expect(@rules.map(&:code).join("|")).to eq("BH|HK|MM|NB|NW|PN|SB|SR|SP")
      end
    end
  end
end
