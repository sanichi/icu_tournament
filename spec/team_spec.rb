require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

module ICU
  describe Team do
    context "a typical team" do
      before(:each) do
        @t = Team.new('Wandering Dragons')
        @t.add_member(0)
        @t.add_member('3')
        @t.add_member('  -7  ')
      end
      
      it "should have a name" do
        expect(@t.name).to eq('Wandering Dragons')
      end
      
      it "should have some members" do
        expect(@t.members.size).to eq(3)
        expect(@t.include?(0)).to be_truthy
        expect(@t.include?(3)).to be_truthy
        expect(@t.include?(-7)).to be_truthy
        expect(@t.include?(7)).to be_falsey
      end
      
      it "should match names ignoring case and irrelevant whitespace" do
        expect(@t.matches('Wandering Dragons')).to be_truthy
        expect(@t.matches('  wandering  dragons  ')).to be_truthy
        expect(@t.matches('  wanderingdragons  ')).to be_falsey
        expect(@t.matches('Blundering Bishops')).to be_falsey
      end
      
      it "should have a changeable name with irrelevant whitespace being trimmed" do
        @t.name = '  blue    dragons   '
        expect(@t.name).to eq('blue dragons')
      end
      
      it "should blowup if an attempt is made to blank the name" do
        expect { @t.name = '  ' }.to raise_error(/blank/)
      end
      
      it "should blowup if an attempt is made to add a non-number" do
        expect { @t.add_member('  ') }.to raise_error(/number/)
      end

      it "should blow up if an attempt is made to add a duplicate number" do
        expect { @t.add_member(3) }.to raise_error(/duplicate/)
      end

      it "should renumber successfully if the map has the relevant player numbers" do
        map = { 0 => 1, 3 => 2, -7 => 3 }
        @t.renumber(map)
        expect(@t.members.sort.join('')).to eq('123')
      end

      it "should raise exception if a player is missing from the renumber map" do
        expect { @t.renumber({ 5 => 1, 3 => 2 }) }.to raise_error(/player.*not found/)
      end
    end
  end
end