# encoding: utf-8
require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

module ICU
  describe Result do
    context "a typical result" do
      it "should have a round, player number and score plus optional opponent number, colour and rateable flag" do
        expect { Result.new(3, 5, 'W', :opponent => 11, :colour => 'W') }.not_to raise_error
      end
    end

    context "round number" do
      it "should be a positive integer" do
        expect { Result.new(-2, 2, 0) }.to raise_error(/invalid positive integer/)
        expect { Result.new(0, 2, 0) }.to raise_error(/invalid positive integer/)
        expect(Result.new(1, 2, 0).round).to eq(1)
        expect(Result.new(' 3 ', 2, 0).round).to eq(3)
      end
    end

    context "player number" do
      it "should be an integer" do
        expect { Result.new(1, '  ', 0) }.to raise_error(/invalid integer/)
        expect(Result.new(1, 2, 0).player).to eq(2)
        expect(Result.new(1, ' 0 ', 0).player).to eq(0)
        expect(Result.new(1, -5, 0).player).to eq(-5)
        expect(Result.new(1, " 9 ", 0).player).to eq(9)
      end
    end

    context "score" do
      [1, 1.0, 'W', 'w', '+'].each do |score|
        it "should be 'W' for #{score}, #{score.class}" do
          expect(Result.new(1, 2, score).score).to eq('W')
        end
      end
      [0, 0.0, 'L', 'l', '-'].each do |score|
        it "should be 'L' for #{score}, #{score.class}" do
          expect(Result.new(1, 2, score).score).to eq('L')
        end
      end
      ['½', 0.5, 'D', 'd', '='].each do |score|
        it "should be 'L' for #{score}, #{score.class}" do
          expect(Result.new(1, 2, score).score).to eq('D')
        end
      end
      ['', ' ', 'x', 2, -1.0, nil].each do |score|
        it "should raise error for invalid score (#{score})" do
          expect { Result.new(1, 2, score) }.to raise_error(/invalid score/)
        end
      end
      it "should be expressable as a number" do
        expect(Result.new(1, 2, 'W').points).to eq(1.0)
        expect(Result.new(1, 2, 'L').points).to eq(0.0)
        expect(Result.new(1, 2, 'D').points).to eq(0.5)
      end
    end

    context "colour" do
      it "should be 'W' or 'B' or nil (unknown)" do
        expect(Result.new(4, 1, 0).colour).to be_nil
        expect(Result.new(4, 1, 0, :colour => 'W').colour).to eq('W')
        expect(Result.new(4, 1, 0, :colour => 'white').colour).to eq('W')
        expect(Result.new(4, 1, 0, :colour => '  b ').colour).to eq('B')
        expect(Result.new(4, 1, 0, :colour => ' BLACK ').colour).to eq('B')
        expect { Result.new(4, 1, 0, :colour => 'red') }.to raise_error(/invalid colour/)
      end
    end

    context "opponent number" do
      it "should be nil (the default) or an integer" do
        expect(Result.new(4, 1, 0).opponent).to be_nil
        expect(Result.new(4, 1, 0, :opponent => nil).opponent).to be_nil
        expect(Result.new(4, 1, 0, :opponent => '   ').opponent).to be_nil
        expect(Result.new(4, 1, 0, :opponent => 0).opponent).to eq(0)
        expect(Result.new(4, 1, 0, :opponent => 2).opponent).to eq(2)
        expect(Result.new(4, 1, 0, :opponent => -6).opponent).to eq(-6)
        expect(Result.new(4, 1, 0, :opponent => ' 10 ').opponent).to eq(10)
        expect { Result.new(4, 1, 0, :opponent => 'X') }.to raise_error(/invalid opponent number/)
      end

      it "should be different to player number" do
        expect { Result.new(4, 1, 0, :opponent => 1) }.to raise_error(/opponent .* player .* different/)
      end
    end

    context "rateable flag" do
      it "should default to false if there is no opponent" do
        expect(Result.new(4, 1, 0).rateable).to be_falsey
      end

      it "should default to true if there is an opponent" do
        expect(Result.new(4, 1, 0, :opponent => 10).rateable).to be_truthy
      end

      it "should change if an opponent is added" do
        r = Result.new(4, 1, 0)
        r.opponent = 5;
        expect(r.rateable).to be_truthy
      end

      it "should be settable to false from the constructor" do
        expect(Result.new(4, 1, 0, :opponent => 10, :rateable => false).rateable).to be_falsey
      end

      it "should be settable to false using the accessor" do
        r = Result.new(4, 1, 0, :opponent => 10)
        r.rateable= false
        expect(r.rateable).to be_falsey
      end

      it "should not be settable to true if there is no opponent" do
        r = Result.new(4, 1, 0)
        r.rateable= true
        expect(r.rateable).to be_falsey
      end
    end

    context "reversed result" do
      it "should be nil if there is no opponent" do
        expect(Result.new(4, 1, 0).reverse).to be_nil
      end

      it "should have player and opponent swapped" do
        r = Result.new(4, 1, 0, :opponent => 2).reverse
        expect(r.player).to eq(2)
        expect(r.opponent).to eq(1)
      end

      it "should have reversed result" do
        expect(Result.new(4, 1, 0, :opponent => 2).reverse.score).to eq('W')
        expect(Result.new(4, 1, 1, :opponent => 2).reverse.score).to eq('L')
        expect(Result.new(4, 1, '=', :opponent => 2).reverse.score).to eq('D')
      end

      it "should preserve rateability" do
        expect(Result.new(4, 1, 0, :opponent => 2).reverse.rateable).to be_truthy
        expect(Result.new(4, 1, 0, :opponent => 2, :rateable => false).reverse.rateable).to be_falsey
      end
    end

    context "renumber the player numbers in a result" do
      before(:each) do
        @r1 = Result.new(1, 4, 0)
        @r2 = Result.new(2, 3, 1, :opponent => 4, :color => 'B')
      end

      it "should renumber successfully if the map has the relevant player numbers" do
        map = { 4 => 1, 3 => 2 }
        expect(@r1.renumber(map).player).to eq(1)
        expect(@r2.renumber(map).player).to eq(2)
        expect(@r1.opponent).to be_nil
        expect(@r2.opponent).to eq(1)
      end

      it "should raise exception if a player number is not in the map" do
        expect { @r1.renumber({ 5 => 1, 3 => 2 }) }.to raise_error(/player.*4.*not found/)
      end
    end

    context "equality" do
      before(:each) do
        @r  = Result.new(1, 1, 0, :opponent => 2, :colour => 'W')
        @r1 = Result.new(1, 1, 0, :opponent => 2, :colour => 'W')
        @r2 = Result.new(1, 1, 0, :opponent => 2, :colour => 'W', :rateable => false)
        @r3 = Result.new(2, 1, 0, :opponent => 2, :colour => 'W')
        @r4 = Result.new(1, 1, 0, :opponent => 2, :colour => 'B')
        @r5 = Result.new(2, 1, 1, :opponent => 3, :colour => 'B')
      end

      it "should only be equal if everything is the same" do
        expect(@r.eql?(@r)).to be_truthy
        expect(@r.eql?(@r1)).to be_truthy
        expect(@r.eql?(@r2)).to be_falsey
        expect(@r.eql?(@r3)).to be_falsey
        expect(@r.eql?(@r4)).to be_falsey
        expect(@r.eql?(@r5)).to be_falsey
      end

      it "exceptions are allowed" do
        expect(@r.eql?(@r2, :except => :rateable)).to be_truthy
        expect(@r.eql?(@r3, :except => "round")).to be_truthy
        expect(@r.eql?(@r4, :except => :colour)).to be_truthy
        expect(@r.eql?(@r5, :except => [:colour, :round, :score, "opponent"])).to be_truthy
      end
    end

    context "equality documentation example" do
      before(:each) do
        @r  = ICU::Result.new(1, 1, 'W', :opponent => 2)
        @r1 = ICU::Result.new(1, 1, 'W', :opponent => 2)
        @r2 = ICU::Result.new(1, 1, 'W', :opponent => 2, :rateable => false)
        @r3 = ICU::Result.new(1, 1, 'L', :opponent => 2, :rateable => false)
      end

      it "should be correct" do
        expect(@r.eql?(@r1)).to be_truthy
        expect(@r.eql?(@r2)).to be_falsey
        expect(@r.eql?(@r3)).to be_falsey
        expect(@r.eql?(@r2, :except => :rateable)).to be_truthy
        expect(@r.eql?(@r3, :except => [:rateable, :score])).to be_truthy
      end
    end
  end
end