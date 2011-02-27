require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

module ICU
  describe TieBreak do
    context "#identify which rule" do
      it "should recognize Buchholz" do
        TieBreak.identify(:buchholz).id.should == :buchholz
        TieBreak.identify(" BucholtS ").id.should == :buchholz
        TieBreak.identify(" bh ").id.should == :buchholz
        TieBreak.identify(" buccholts ").code.should == "BH"
      end

      it "should recognize Harkness (Median)" do
        TieBreak.identify(:harkness).id.should == :harkness
        TieBreak.identify("median").id.should == :harkness
        TieBreak.identify(" hARKNES ").id.should == :harkness
        TieBreak.identify("HK").id.should == :harkness
        TieBreak.identify("MEDIAN").code.should == "HK"
      end

      it "should recognize Modified Median" do
        TieBreak.identify(:modified).id.should == :modified_median
        TieBreak.identify(" modified  MEDIAN ").id.should == :modified_median
        TieBreak.identify("MM").code.should == "MM"
      end

      it "should recognize Number of Blacks" do
        TieBreak.identify(:blacks).id.should == :blacks
        TieBreak.identify("number\tof\tblacks\n").id.should == :blacks
        TieBreak.identify("\tnb\t").id.should == :blacks
        TieBreak.identify("number_blacks").code.should == "NB"
      end

      it "should recognize Number of Wins" do
        TieBreak.identify(:wins).id.should == :wins
        TieBreak.identify(" number-of-wins ").id.should == :wins
        TieBreak.identify("NUMBER WINS\r\n").id.should == :wins
        TieBreak.identify("nw").code.should == "NW"
      end

      it "should recognize Player's of Name" do
        TieBreak.identify(:name).id.should == :name
        TieBreak.identify("Player's Name").id.should == :name
        TieBreak.identify("players_name").id.should == :name
        TieBreak.identify("PN").id.should == :name
        TieBreak.identify("PLAYER-NAME").code.should == "PN"
      end

      it "should recognize Sonneborn-Berger" do
        TieBreak.identify(:sonneborn_berger).id.should == :neustadtl
        TieBreak.identify(:neustadtl).id.should == :neustadtl
        TieBreak.identify("  SONNEBORN\nberger").id.should == :neustadtl
        TieBreak.identify("\t  soneborn_berger  \t").id.should == :neustadtl
        TieBreak.identify("sb").id.should == :neustadtl
        TieBreak.identify("NESTADL").code.should == "SB"
      end

      it "should recognize Sum of Progressive Scores" do
        TieBreak.identify(:progressive).id.should == :progressive
        TieBreak.identify("CUMULATIVE").id.should == :progressive
        TieBreak.identify("sum of progressive scores").id.should == :progressive
        TieBreak.identify("SUM-cumulative_SCORE").id.should == :progressive
        TieBreak.identify(:cumulative_score).id.should == :progressive
        TieBreak.identify("SumOfCumulative").id.should == :progressive
        TieBreak.identify("SP").code.should == "SP"
      end

      it "should recognize Sum of Opponents' Ratings" do
        TieBreak.identify(:ratings).id.should == :ratings
        TieBreak.identify("sum of opponents ratings").id.should == :ratings
        TieBreak.identify("Opponents' Ratings").id.should == :ratings
        TieBreak.identify("SR").id.should == :ratings
        TieBreak.identify("SUMOPPONENTSRATINGS").code.should == "SR"
      end

      it "should recognize player's name" do
        TieBreak.identify(:name).id.should == :name
        TieBreak.identify(" player's  NAME ").id.should == :name
        TieBreak.identify("pn").code.should == "PN"
      end

      it "should return nil for unrecognized tie breaks" do
        TieBreak.identify("XYZ").should be_nil
        TieBreak.identify(nil).should be_nil
      end
    end
    
    context "return an array of tie break rules" do
      before(:each) do
        @rules = TieBreak.rules
      end

      it "should be an array in a specific order" do
        @rules.size.should == 9
        @rules.first.name.should == "Buchholz"
        @rules.map(&:code).join("|").should == "BH|HK|MM|NB|NW|PN|SB|SR|SP"
      end
    end
  end
end
