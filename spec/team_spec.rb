require File.dirname(__FILE__) + '/spec_helper'

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
        @t.name.should == 'Wandering Dragons'
      end
      
      it "should have some members" do
        @t.should have(3).members
        @t.include?(0).should be_true
        @t.include?(3).should be_true
        @t.include?(-7).should be_true
        @t.include?(7).should be_false
      end
      
      it "should match names ignoring case and irrelevant whitespace" do
        @t.matches('Wandering Dragons').should be_true
        @t.matches('  wandering  dragons  ').should be_true
        @t.matches('  wanderingdragons  ').should be_false
        @t.matches('Blundering Bishops').should be_false
      end
      
      it "should have a changeable name with irrelevant whitespace being trimmed" do
        @t.name = '  blue    dragons   '
        @t.name.should == 'blue dragons'
      end
      
      it "should blowup if an attempt is made to blank the name" do
        lambda { @t.name = '  ' }.should raise_error(/blank/)
      end
      
      it "should blowup if an attempt is made to add a non-number" do
        lambda { @t.add_member('  ') }.should raise_error(/number/)
      end

      it "should blow up if an attempt is made to add a duplicate number" do
        lambda { @t.add_member(3) }.should raise_error(/duplicate/)
      end

      it "should renumber successfully if the map has the relevant player numbers" do
        map = { 0 => 1, 3 => 2, -7 => 3 }
        @t.renumber!(map).members.sort.join('').should == '123'
      end

      it "should raise exception if a player is missing from the renumber map" do
        lambda { @t.renumber!({ 5 => 1, 3 => 2 }) }.should raise_error(/player.*not found/)
      end
    end
  end
end