require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

module ICU
  describe Player do
    context "a typical player" do
      it "should have a name, number and some results" do
        expect do
          player = Player.new('Mark', 'Orr', 1)
          player.add_result(Result.new(1, 1, 'W', :opponent => 37, :score => 'W', :colour => 'W'))
          player.add_result(Result.new(2, 1, 'W', :opponent => 13, :score => 'W', :colour => 'B'))
          player.add_result(Result.new(3, 1, 'W', :opponent => 7,  :score => 'D', :colour => 'W'))
        end.not_to raise_error
      end
    end

    context "names" do
      it "should be specified in constructor" do
        p = Player.new('Mark', 'Orr', 1)
        expect(p.first_name).to eq('Mark')
        expect(p.last_name).to eq('Orr')
        expect(p.original_name).to eq('Orr, Mark')
      end

      it "should be resettable via accessors" do
        p = Player.new('Mark', 'Orr', 1)
        p.first_name= 'Gary'
        p.last_name= 'Kasparov'
        expect(p.first_name).to eq('Gary')
        expect(p.last_name).to eq('Kasparov')
        expect(p.original_name).to eq('Orr, Mark')
      end

      it "should not contain invalid characters" do
        expect { Player.new('12', 'Orr', 1) }.to raise_error(/invalid first name/)
        expect { Player.new('Mark', '*!', 1) }.to raise_error(/invalid last name/)
      end

      it "should not have empty last name or first name" do
        expect { Player.new('Mark', '', 1) }.to raise_error(/invalid last name/)
        expect { Player.new('', 'Orr', 1) }.to raise_error(/invalid first name/)
      end

      it "both names can be returned together" do
        p = Player.new('Mark', 'Orr', 1)
        expect(p.name).to eq('Orr, Mark')
      end

      it "names should be automatically canonicalised" do
        p = Player.new(' maRk J   l ', '  ORR', 1)
        expect(p.name).to eq('Orr, Mark J. L.')
        p.first_name = 'z'
        expect(p.name).to eq('Orr, Z.')
        p.last_name = "  o   meFiSto  "
        expect(p.name).to eq("O'Mefisto, Z.")
        expect(p.original_name).to eq('ORR, maRk J l')
      end

      it "the original name is resetable" do
        p = Player.new('Mark', 'Orr', 1)
        expect(p.name).to eq('Orr, Mark')
        expect(p.original_name).to eq('Orr, Mark')
        p.original_name = 'Cronin, April'
        expect(p.name).to eq('Orr, Mark')
        expect(p.original_name).to eq('Cronin, April')
      end
    end

    context "number" do
      it "should just be an integer" do
        expect(Player.new('Mark', 'Orr', 3).num).to eq(3)
        expect(Player.new('Mark', 'Orr', -7).num).to eq(-7)
        expect(Player.new('Mark', 'Orr', '  -4  ').num).to eq(-4)
        expect(Player.new('Mark', 'Orr', '0').num).to eq(0)
        expect { Player.new('Mark', 'Orr', '  ') }.to raise_error(/invalid integer/)
      end
    end

    context "local ID" do
      it "defaults to nil" do
        expect(Player.new('Mark', 'Orr', 3).id).to be_nil
      end

      it "should be a positive integer" do
        expect(Player.new('Mark', 'Orr', 3, :id => 1350).id).to eq(1350)
        expect(Player.new('Stephen', 'Brady', 4, :id => ' 90 ').id).to eq(90)
        expect { Player.new('Mark', 'Orr', 3, :id => ' 0 ') }.to raise_error(/invalid positive integer/)
      end
    end

    context "FIDE ID" do
      it "defaults to nil" do
        expect(Player.new('Stephen', 'Brady', 1).fide_id).to be_nil
      end

      it "should be a positive integer" do
        expect(Player.new('Stephen', 'Brady', 1, :fide_id => 2500124).fide_id).to eq(2500124)
        expect(Player.new('Gary', 'Kasparov', 2, :fide_id => '4100018').fide_id).to eq(4100018)
        expect { Player.new('Mark', 'Orr', 3, :fide_id => ' 0 ') }.to raise_error(/invalid positive integer/)
      end
    end

    context "federation" do
      it "defaults to nil" do
        expect(Player.new('Mark', 'Orr', 3).fed).to be_nil
        expect(Player.new('Mark', 'Orr', 3, :fed => '   ').fed).to be_nil
      end

      it "should consist of at least three letters" do
        expect(Player.new('Gary', 'Kasparov', 1, :fed => 'RUS').fed).to eq('RUS')
        expect(Player.new('Mark', 'Orr', 3, :fed => ' Ireland ').fed).to eq('IRL')
        expect { Player.new('Danny', 'Kopec', 3, :fed => 'US') }.to raise_error(/invalid federation/)
      end

      it "should correct common code errors" do
        expect(Player.new('Ricardo', 'Calvo', 1, :fed => 'SPA').fed).to eq('ESP')
        expect(Player.new('Mark', 'Orr', 2, :fed => 'Icu').fed).to eq('IRL')
        expect(Player.new('Florin', 'Gheorghiu', 3, :fed => 'ROM').fed).to eq('ROU')
      end
    end

    context "title" do
      it "defaults to nil" do
        expect(Player.new('Mark', 'Orr', 3).title).to be_nil
        expect(Player.new('Mark', 'Orr', 3, :title => '   ').title).to be_nil
      end

      it "should be one of national, candidate, FIDE, international or grand master" do
        expect(Player.new('Gary', 'Kasparov', 1, :title => 'GM').title).to eq('GM')
        expect(Player.new('Mark', 'Orr', 2, :title => ' im ').title).to eq('IM')
        expect(Player.new('Mark', 'Quinn', 2, :title => 'm').title).to eq('IM')
        expect(Player.new('Pia', 'Cramling', 3, :title => ' wg ').title).to eq('WGM')
        expect(Player.new('Philip', 'Short', 4, :title => 'F ').title).to eq('FM')
        expect(Player.new('Gearoidin', 'Ui Laighleis', 5, :title => 'wc').title).to eq('WCM')
        expect(Player.new('Gearoidin', 'Ui Laighleis', 7, :title => 'wm').title).to eq('WIM')
        expect(Player.new('Eamon', 'Keogh', 6, :title => 'nm').title).to eq('NM')
        expect { Player.new('Mark', 'Orr', 3, :title => 'Dr') }.to raise_error(/invalid chess title/)
      end
    end

    context "rating" do
      it "defaults to nil" do
        expect(Player.new('Mark', 'Orr', 3).rating).to be_nil
        expect(Player.new('Mark', 'Orr', 3, :rating => '   ').rating).to be_nil
      end

      it "should be a positive integer" do
        expect(Player.new('Gary', 'Kasparov', 1, :rating => 2800).rating).to eq(2800)
        expect(Player.new('Mark', 'Orr', 2, :rating => ' 2100 ').rating).to eq(2100)
        expect { Player.new('Mark', 'Orr', 3, :rating => -2100) }.to raise_error(/invalid positive integer/)
        expect { Player.new('Mark', 'Orr', 3, :rating => 'IM') }.to raise_error(/invalid positive integer/)
      end
    end

    context "FIDE rating" do
      it "defaults to nil" do
        expect(Player.new('Mark', 'Orr', 3).fide_rating).to be_nil
        expect(Player.new('Mark', 'Orr', 3, :fide_rating => '   ').fide_rating).to be_nil
      end

      it "should be a positive integer" do
        expect(Player.new('Gary', 'Kasparov', 1, :fide_rating => 2800).fide_rating).to eq(2800)
        expect(Player.new('Mark', 'Orr', 2, :fide_rating => ' 2200 ').fide_rating).to eq(2200)
        expect { Player.new('Mark', 'Orr', 3, :fide_rating => -2100) }.to raise_error(/invalid positive integer/)
        expect { Player.new('Mark', 'Orr', 3, :fide_rating => 'IM') }.to raise_error(/invalid positive integer/)
      end
    end

    context "rank" do
      it "defaults to nil" do
        expect(Player.new('Mark', 'Orr', 3).rank).to be_nil
      end

      it "should be a positive integer" do
        expect(Player.new('Mark', 'Orr', 3, :rank => 1).rank).to eq(1)
        expect(Player.new('Gary', 'Kasparov', 4, :rank => ' 29 ').rank).to eq(29)
        expect { Player.new('Mark', 'Orr', 3, :rank => 0) }.to raise_error(/invalid positive integer/)
        expect { Player.new('Mark', 'Orr', 3, :rank => ' -1 ') }.to raise_error(/invalid positive integer/)
      end
    end

    context "date of birth" do
      it "defaults to nil" do
        expect(Player.new('Mark', 'Orr', 3).dob).to be_nil
        expect(Player.new('Mark', 'Orr', 3, :dob => '   ').dob).to be_nil
      end

      it "should be a yyyy-mm-dd date" do
        expect(Player.new('Mark', 'Orr', 3, :dob => '1955-11-09').dob).to eq('1955-11-09')
        expect { Player.new('Mark', 'Orr', 3, :dob => 'X') }.to raise_error(/invalid.*dob/)
      end
    end

    context "gender" do
      it "defaults to nil" do
        expect(Player.new('Mark', 'Orr', 3).gender).to be_nil
        expect(Player.new('Mark', 'Orr', 3, :gender => '   ').gender).to be_nil
      end

      it "should be either M or F" do
        expect(Player.new('Mark', 'Orr', 3, :gender => 'male').gender).to eq('M')
        expect(Player.new('April', 'Cronin', 3, :gender => 'woman').gender).to eq('F')
      end

      it "should raise an exception if the gender is not specified properly" do
        expect { Player.new('Mark', 'Orr', 3, :gender => 'X') }.to raise_error(/invalid gender/)
      end
    end

    context "results and points" do
      it "should initialise to an empty array" do
        results = Player.new('Mark', 'Orr', 3).results
        expect(results).to be_instance_of Array
        expect(results.size).to eq(0)
      end

      it "can be added to" do
        player = Player.new('Mark', 'Orr', 3)
        player.add_result(Result.new(1, 3, 'W', :opponent => 1))
        player.add_result(Result.new(2, 3, 'D', :opponent => 2))
        player.add_result(Result.new(3, 3, 'L', :opponent => 4))
        results = player.results
        expect(results).to be_instance_of Array
        expect(results.size).to eq(3)
        expect(player.points).to eq(1.5)
      end

      it "should not allow mismatched player numbers" do
        player = Player.new('Mark', 'Orr', 3)
        expect { player.add_result(Result.new(1, 4, 'W', :opponent => 1)) }.to raise_error(/player number .* matched/)
      end

      it "should enforce unique round numbers" do
        player = Player.new('Mark', 'Orr', 3)
        player.add_result(Result.new(1, 3, 'W', :opponent => 1))
        player.add_result(Result.new(2, 3, 'D', :opponent => 2))
        expect { player.add_result(Result.new(2, 3, 'L', :opponent => 4)) }.to raise_error(/does not match/)
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
        expect(@p.find_result(1).opponent).to eq(37)
        expect(@p.find_result(2).opponent).to eq(13)
        expect(@p.find_result(3).opponent).to eq(7)
        expect(@p.find_result(4)).to be_nil
      end
    end

    context "removing a result" do
      before(:all) do
        @p = Player.new('Mark', 'Orr', 1)
        @p.add_result(Result.new(1, 1, 'W', :opponent => 37, :score => 'W', :colour => 'W'))
        @p.add_result(Result.new(2, 1, 'W', :opponent => 13, :score => 'W', :colour => 'B'))
        @p.add_result(Result.new(3, 1, 'W', :opponent => 7,  :score => 'D', :colour => 'W'))
      end

      it "should find and remove a result by round number" do
        result = @p.remove_result(1)
        expect(result.inspect).to eq("R1P1O37WWR")
        expect(@p.results.size).to eq(2)
        expect(@p.results.map(&:round).join("|")).to eq("2|3")
      end
    end

    context "merge" do
      before(:each) do
        @p1 = Player.new('Mark', 'Orr', 1, :id => 1350)
        @p2 = Player.new('Mark', 'Orr', 2, :rating => 2100, :title => 'IM', :fed => 'IRL', :fide_id => 2500035)
        @p3 = Player.new('Gearoidin', 'Ui Laighleis', 3, :rating => 1600, :title => 'WIM', :fed => 'IRL', :fide_id =>  2501171)
      end

      it "takes on the ID, rating, title and fed of the other player but not the player number" do
        @p1.merge(@p2)
        expect(@p1.num).to eq(1)
        expect(@p1.id).to eq(1350)
        expect(@p1.rating).to eq(2100)
        expect(@p1.title).to eq('IM')
        expect(@p1.fed).to eq('IRL')
        expect(@p1.fide_id).to eq(2500035)
      end

      it "should have a kind of symmetry" do
        p1 = @p1.dup
        p2 = @p2.dup
        p1.merge(p2).eql?(@p2.merge(@p1))
      end

      it "cannot be done with unequal objects" do
        expect { @p1.merge(@p3) }.to raise_error(/cannot merge.*not equal/)
      end
    end

    context "renumber the player numbers" do
      before(:each) do
        @p = Player.new('Mark', 'Orr', 10)
        @p.add_result(Result.new(1, 10, 'W', :opponent => 20))
        @p.add_result(Result.new(2, 10, 'W', :opponent => 30))
      end

      it "should renumber successfully if the map has the relevant player numbers" do
        map = { 10 => 1, 20 => 2, 30 => 3 }
        expect(@p.renumber(map).num).to eq(1)
        expect(@p.results.map{ |r| r.opponent }.sort.join('')).to eq('23')
      end

      it "should raise exception if a player number is not in the map" do
        expect { @p.renumber({ 100 => 1, 20 => 2, 30 => 3 }) }.to raise_error(/player.*10.*not found/)
        expect { @p.renumber({ 10 => 1, 200 => 2, 30 => 3 }) }.to raise_error(/opponent.*20.*not found/)
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
        expect(@mark1 == @mark1).to be_truthy
      end

      it "two players are equal if their names are the same and their federations do not conflict" do
        expect(@mark1 == @mark2).to be_truthy
      end

      it "two players cannot be equal if they have different names" do
        expect(@mark1 == @mark4).to be_falsey
        expect(@mark1 == @john1).to be_falsey
      end

      it "two players cannot be equal if they have different federations" do
        expect(@mark2 == @mark3).to be_falsey
        expect(@mark1 == @mark3).to be_truthy
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
        expect(@mark1.eql?(@mark1)).to be_truthy
        expect(@mark1.eql?(@mark1)).to be_truthy
      end

      it "two players are equal as long as their ID, rating and title do not conflict" do
        expect(@mark1.eql?(@mark2)).to be_truthy
        expect(@mark3.eql?(@mark4)).to be_truthy
        expect(@mark4.eql?(@mark5)).to be_truthy
      end

      it "two players are not equal if their ID, rating or title conflict" do
        expect(@mark2.eql?(@mark3)).to be_falsey
        expect(@mark2.eql?(@mark4)).to be_falsey
        expect(@mark2.eql?(@mark5)).to be_falsey
      end
    end
  end
end