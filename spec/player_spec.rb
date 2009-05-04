require File.dirname(__FILE__) + '/spec_helper'

module ICU
  describe Player do
    context "a typical player" do
      it "should have a name, number and some results" do
        lambda do
          player = Player.new('Mark', 'Orr', 1)
          player.add_result(Result.new(1, 1, 'W', :opponent => 37, :score => 'W', :colour => 'W'))
          player.add_result(Result.new(2, 1, 'W', :opponent => 13, :score => 'W', :colour => 'B'))
          player.add_result(Result.new(3, 1, 'W', :opponent => 7,  :score => 'D', :colour => 'W'))
        end.should_not raise_error
      end
    end
    
    context "names" do
      it "should be specified in constructor" do
        p = Player.new('Mark', 'Orr', 1)
        p.first_name.should == 'Mark'
        p.last_name.should == 'Orr'
      end
      
      it "should be resettable via accessors" do
        p = Player.new('Mark', 'Orr', 1)
        p.first_name= 'Gary'
        p.last_name= 'Kasparov'
        p.first_name.should == 'Gary'
        p.last_name.should == 'Kasparov'
      end
      
      it "should not contain invalid characters" do
        lambda { Player.new('12', 'Orr', 1) }.should raise_error(/invalid first name/)
        lambda { Player.new('Mark', '*!', 1) }.should raise_error(/invalid last name/)
      end
      
      it "should not have empty last name" do
        lambda { Player.new('Mark', '', 1) }.should raise_error(/invalid last name/)
        lambda { Player.new('', 'Orr', 1) }.should raise_error(/invalid first name/)
      end
      
      it "both names can be returned together" do
        p = Player.new('Mark', 'Orr', 1)
        p.name.should == 'Orr, Mark'
      end
      
      it "names should be automatically canonicalised" do
        p = Player.new(' maRk J   l ', '  ORR', 1)
        p.name.should == 'Orr, Mark J. L.'
        p.first_name = 'z'
        p.name.should == 'Orr, Z.'
        p.last_name = "  o   meFiSto  "
        p.name.should == "O'Mefisto, Z."
      end
    end
    
    context "number" do
      it "should just be an integer" do
        Player.new('Mark', 'Orr', 3).num.should == 3
        Player.new('Mark', 'Orr', -7).num.should == -7
        Player.new('Mark', 'Orr', '  -4  ').num.should == -4
        Player.new('Mark', 'Orr', '0').num.should == 0
        lambda { Player.new('Mark', 'Orr', '  ') }.should raise_error(/invalid player number/)
      end
    end
    
    context "ID" do
      it "defaults to nil" do
        Player.new('Mark', 'Orr', 3).id.should be_nil
      end

      it "should be a positive integer" do
        Player.new('Mark', 'Orr', 3, :id => 1350).id.should == 1350
        Player.new('Gary', 'Kasparov', 4, :id => '4100018').id.should == 4100018
        lambda { Player.new('Mark', 'Orr', 3, :id => ' 0 ') }.should raise_error(/invalid ID/)
      end
    end
    
    context "federation" do
      it "defaults to nil" do
        Player.new('Mark', 'Orr', 3).fed.should be_nil
        Player.new('Mark', 'Orr', 3, :fed => '   ').fed.should be_nil
      end

      it "should consist of at least three letters" do
        Player.new('Gary', 'Kasparov', 1, :fed => 'RUS').fed.should == 'RUS'
        Player.new('Mark', 'Orr', 3, :fed => ' Ireland ').fed.should == 'Ireland'
        lambda { Player.new('Danny', 'Kopec', 3, :fed => 'US') }.should raise_error(/invalid federation/)
      end
    end
    
    context "title" do
      it "defaults to nil" do
        Player.new('Mark', 'Orr', 3).title.should be_nil
        Player.new('Mark', 'Orr', 3, :title => '   ').title.should be_nil
      end

      it "should be one of national, candidate, FIDE, international or grand master" do
        Player.new('Gary', 'Kasparov', 1, :title => 'GM').title.should == 'GM'
        Player.new('Mark', 'Orr', 2, :title => ' im ').title.should == 'IM'
        Player.new('Mark', 'Quinn', 2, :title => 'm').title.should == 'IM'
        Player.new('Pia', 'Cramling', 3, :title => ' wg ').title.should == 'WGM'
        Player.new('Philip', 'Short', 4, :title => 'F ').title.should == 'FM'
        Player.new('Gearoidin', 'Ui Laighleis', 5, :title => 'wc').title.should == 'WCM'
        Player.new('Gearoidin', 'Ui Laighleis', 7, :title => 'wm').title.should == 'WIM'
        Player.new('Eamon', 'Keogh', 6, :title => 'nm').title.should == 'NM'
        lambda { Player.new('Mark', 'Orr', 3, :title => 'Dr') }.should raise_error(/invalid chess title/)
      end
    end
    
    context "rating" do
      it "defaults to nil" do
        Player.new('Mark', 'Orr', 3).rating.should be_nil
        Player.new('Mark', 'Orr', 3, :rating => '   ').rating.should be_nil
      end

      it "should be a positive integer" do
        Player.new('Gary', 'Kasparov', 1, :rating => 2800).rating.should == 2800
        Player.new('Mark', 'Orr', 2, :rating => ' 2100 ').rating.should == 2100
        lambda { Player.new('Mark', 'Orr', 3, :rating => -2100) }.should raise_error(/invalid rating/)
        lambda { Player.new('Mark', 'Orr', 3, :rating => 'IM') }.should raise_error(/invalid rating/)
      end
    end
    
    context "rank" do
      it "defaults to nil" do
        Player.new('Mark', 'Orr', 3).rank.should be_nil
      end

      it "should be a positive integer" do
        Player.new('Mark', 'Orr', 3, :rank => 1).rank.should == 1
        Player.new('Gary', 'Kasparov', 4, :rank => ' 29 ').rank.should == 29
        lambda { Player.new('Mark', 'Orr', 3, :rank => 0) }.should raise_error(/invalid rank/)
        lambda { Player.new('Mark', 'Orr', 3, :rank => ' -1 ') }.should raise_error(/invalid rank/)
      end
    end
    
    context "date of birth" do
      it "defaults to nil" do
        Player.new('Mark', 'Orr', 3).dob.should be_nil
        Player.new('Mark', 'Orr', 3, :dob => '   ').dob.should be_nil
      end

      it "should be a yyyy-mm-dd date" do
        Player.new('Mark', 'Orr', 3, :dob => '1955-11-09').dob.should == '1955-11-09'
        lambda { Player.new('Mark', 'Orr', 3, :dob => 'X') }.should raise_error(/invalid DOB/)
      end
    end
    
    context "gender" do
      it "defaults to nil" do
        Player.new('Mark', 'Orr', 3).gender.should be_nil
        Player.new('Mark', 'Orr', 3, :gender => '   ').gender.should be_nil
      end

      it "should be either M or F" do
        Player.new('Mark', 'Orr', 3, :gender => 'male').gender.should == 'M'
        Player.new('April', 'Cronin', 3, :gender => 'woman').gender.should == 'F'
      end
      
      it "should raise an exception if the gender is not specified properly" do
        lambda { Player.new('Mark', 'Orr', 3, :gender => 'X') }.should raise_error(/invalid gender/)
      end
    end
    
    context "results and points" do
      it "should initialise to an empty array" do
        results = Player.new('Mark', 'Orr', 3).results
        results.should be_instance_of Array
        results.size.should == 0
      end
      
      it "can be added to" do
        player = Player.new('Mark', 'Orr', 3)
        player.add_result(Result.new(1, 3, 'W', :opponent => 1))
        player.add_result(Result.new(2, 3, 'D', :opponent => 2))
        player.add_result(Result.new(3, 3, 'L', :opponent => 4))
        results = player.results
        results.should be_instance_of Array
        results.size.should == 3
        player.points.should == 1.5
      end
      
      it "should not allow mismatched player numbers" do
        player = Player.new('Mark', 'Orr', 3)
        lambda { player.add_result(Result.new(1, 4, 'W', :opponent => 1)) }.should raise_error(/player number .* matched/)
      end
      
      it "should enforce unique round numbers" do
        player = Player.new('Mark', 'Orr', 3)
        player.add_result(Result.new(1, 3, 'W', :opponent => 1))
        player.add_result(Result.new(2, 3, 'D', :opponent => 2))
        lambda { player.add_result(Result.new(2, 3, 'L', :opponent => 4)) }.should raise_error(/round number .* unique/)
      end
    end
    
    context "looking up results" do
      before(:all) do
        @p = Player.new('Mark', 'Orr', 1)
        @p.add_result(Result.new(1, 1, 'W', :opponent => 37, :score => 'W', :colour => 'W'))
        @p.add_result(Result.new(2, 1, 'W', :opponent => 13, :score => 'W', :colour => 'B'))
        @p.add_result(Result.new(3, 1, 'W', :opponent => 7,  :score => 'D', :colour => 'W'))
      end
      
      it "should find results by round number" do
        @p.find_result(1).opponent.should == 37
        @p.find_result(2).opponent.should == 13
        @p.find_result(3).opponent.should == 7
        @p.find_result(4).should be_nil
      end
    end
    
    context "merge" do
      before(:each) do
        @p1 = Player.new('Mark', 'Orr', 1, :id => 1350)
        @p2 = Player.new('Mark', 'Orr', 2, :rating => 2100, :title => 'IM', :fed => 'IRL')
        @p3 = Player.new('Gearoidin', 'Ui Laighleis', 3, :rating => 1600, :title => 'WIM', :fed => 'IRL')
      end
      
      it "takes on the ID, rating, title and fed of the other player but not the player number" do
        @p1.merge(@p2)
        @p1.num.should == 1
        @p1.id.should == 1350
        @p1.rating.should == 2100
        @p1.title.should == 'IM'
        @p1.fed.should == 'IRL'
      end
      
      it "should have a kind of symmetry" do
        p1 = @p1.dup
        p2 = @p2.dup
        p1.merge(p2).eql?(@p2.merge(@p1))
      end
      
      it "cannot be done with unequal objects" do
        lambda { @p1.merge(@p3) }.should raise_error(/cannot merge.*not equal/)
      end
    end
    
    context "loose equality" do
      before(:all) do
        @mark1 = Player.new('Mark', 'Orr', 1)
        @mark2 = Player.new('Mark', 'Orr', 2, :fed => 'IRL')
        @mark3 = Player.new('Mark', 'Orr', 3, :fed => 'USA')
        @mark4 = Player.new('Mark', 'Sax', 4, :def => 'HUN')
        @john1 = Player.new('John', 'Orr', 5, :fed => 'IRL')
      end
      
      it "any player is equal to itself" do
        (@mark1 == @mark1).should be_true
      end
      
      it "two players are equal if their names are the same and their federations do not conflict" do
        (@mark1 == @mark2).should be_true
      end
      
      it "two players cannot be equal if they have different names" do
        (@mark1 == @mark4).should be_false
        (@mark1 == @john1).should be_false
      end
      
      it "two players cannot be equal if they have different federations" do
        (@mark2 == @mark3).should be_false
        (@mark1 == @mark3).should be_true
      end
    end
  
    context "strict equality" do
      before(:all) do
        @mark1 = Player.new('Mark', 'Orr', 1)
        @mark2 = Player.new('Mark', 'Orr', 2, :id => 1350, :rating => 2100, :title => 'IM')
        @mark3 = Player.new('Mark', 'Orr', 3, :id => 1530)
        @mark4 = Player.new('Mark', 'Orr', 4, :rating => 2200)
        @mark5 = Player.new('Mark', 'Orr', 5, :title => 'GM')
      end
    
      it "any player is equal to itself" do
        @mark1.eql?(@mark1).should be_true
        @mark1.eql?(@mark1).should be_true
      end
      
      it "two players are equal as long as their ID, rating and title do not conflict" do
        @mark1.eql?(@mark2).should be_true
        @mark3.eql?(@mark4).should be_true
        @mark4.eql?(@mark5).should be_true
      end
      
      it "two players are not equal if their ID, rating or title conflict" do
        @mark2.eql?(@mark3).should be_false
        @mark2.eql?(@mark4).should be_false
        @mark2.eql?(@mark5).should be_false
      end
    end
  end
end