require File.dirname(__FILE__) + '/spec_helper'

module ICU
  describe Name do
    context "public methods" do
      before(:each) do
        @simple = Name.new('mark j l', 'orr')
      end
      
      it "#first returns the first name(s)" do
        @simple.first.should == 'Mark J. L.'
      end
      
      it "#last returns the last name(s)" do
        @simple.last.should == 'Orr'
      end
      
      it "#name returns the full name with first name(s) first" do
        @simple.name.should == 'Mark J. L. Orr'
      end
      
      it "#rname returns the full name with last name(s) first" do
        @simple.rname.should == 'Orr, Mark J. L.'
      end
      
      it "#to_s is the same as rname" do
        @simple.to_s.should == 'Orr, Mark J. L.'
      end
      
      it "#match returns true if and only if two names match" do
        @simple.match('mark j l orr').should be_true
        @simple.match('malcolm g l orr').should be_false
      end
    end
    
    context "rdoc expample" do
      before(:each) do
        @robert = Name.new(' robert  j ', ' FISCHER ')
        @bobby = Name.new(' bobby fischer ')
      end
      
      it "should get Robert" do
        @robert.name.should == 'Robert J. Fischer'
      end
      
      it "should get Bobby" do
        @bobby.last.should == 'Fischer'
        @bobby.first.should == 'Bobby'
      end
      
      it "should match Robert and Bobby" do
        @robert.match(@bobby).should be_true
        @robert.match('R. J.', 'Fischer').should be_true
        @bobby.match('R. J.', 'Fischer').should be_false
      end
      
      it "should canconicalise last names" do
        Name.new('John', 'O Reilly').last.should == "O'Reilly"
        Name.new('dave', 'mcmanus').last.should == "McManus"
        Name.new('pete', 'MACMANUS').last.should == "MacManus"
      end
    end
    
    context "names that are already canonical" do
      it "should not be altered" do
        Name.new('Mark J. L.', 'Orr').name.should == 'Mark J. L. Orr'
        Name.new('Anna-Marie J.-K.', 'Liviu-Dieter').name.should == 'Anna-Marie J.-K. Liviu-Dieter'
      end
    end
    
    context "last names beginning with a single letter followed by a quote" do
      it "should be handled correctly" do
        Name.new('una', "O'boyle").name.should == "Una O'Boyle"
        Name.new('jonathan', 'd`arcy').name.should == "Jonathan D'Arcy"
        Name.new('erwin e', "L'AMI").name.should == "Erwin E. L'Ami"
        Name.new('cormac', "o brien").name.should == "Cormac O'Brien"
      end
    end
    
    context "last beginning with Mc" do
      it "should be handled correctly" do
        Name.new('shane', "mccabe").name.should == "Shane McCabe"
        Name.new('shawn', "macDonagh").name.should == "Shawn MacDonagh"
        Name.new('shawn', "macdonagh").name.should == "Shawn Macdonagh"
        Name.new('bartlomiej', "macieja").name.should == "Bartlomiej Macieja"
      end
    end
    
    context "doubled barrelled names or initials" do
      it "should be handled correctly" do
        Name.new('anna-marie', 'den-otter').name.should == 'Anna-Marie Den-Otter'
        Name.new('j-k', 'rowling').name.should == 'J.-K. Rowling'
        Name.new("mark j. - l", 'ORR').name.should == 'Mark J.-L. Orr'
        Name.new('JOHANNA', "lowry-o'REILLY").name.should == "Johanna Lowry-O'Reilly"
        Name.new('hannah', "lowry - o reilly").name.should == "Hannah Lowry-O'Reilly"
      end
    end
    
    context "extraneous white space" do
      it "should be handled correctly" do
        Name.new(' mark j   l  ', "  \t\r\n   orr   \n").name.should == 'Mark J. L. Orr'
      end
    end
    
    context "extraneous full stops" do
      it "should be handled correctly" do
        Name.new('. mark j..l', 'orr.').name.should == 'Mark J. L. Orr'
      end
    end
    
    context "construction from a single string" do
      before(:each) do
        @mark1 = Name.new('ORR, mark j l')
        @mark2 = Name.new('MARK J L ORR')
        @oreil = Name.new("O'Reilly, j-k")
      end
      
      it "should be possible in simple cases" do
        @mark1.first.should == 'Mark J. L.'
        @mark1.last.should == 'Orr'
        @mark2.first.should == 'Mark J. L.'
        @mark2.last.should == 'Orr'
        @oreil.name.should == "J.-K. O'Reilly"
      end
    end
    
    context "construction from an instance" do
      it "should be possible" do
        Name.new(Name.new('ORR, mark j l')).name.should == 'Mark J. L. Orr'
      end
    end
        
    context "constuction corner cases" do
      it "should be handled correctly" do
        Name.new('Orr').name.should == 'Orr'
        Name.new('Orr').rname.should == 'Orr'
        Name.new('').name.should == ''
        Name.new('').rname.should == ''
        Name.new.name.should == ''
        Name.new.rname.should == ''
      end
    end
    
    context "inputs to matching" do
      before(:all) do
        @mark = Name.new('Mark', 'Orr')
        @kram = Name.new('Mark', 'Orr')
      end
      
      it "should be flexible" do
        @mark.match('Mark', 'Orr').should be_true
        @mark.match('Mark Orr').should be_true
        @mark.match('Orr, Mark').should be_true
        @mark.match(@kram).should be_true
      end
    end

    context "first name matches" do
      it "should match when first names are the same" do
        Name.new('Mark', 'Orr').match('Mark', 'Orr').should be_true
      end
      
      it "should be flexible with regards to hyphens in double barrelled names" do
        Name.new('J.-K.', 'Rowling').match('J. K.', 'Rowling').should be_true
        Name.new('Joanne-K.', 'Rowling').match('Joanne K.', 'Rowling').should be_true
      end
      
      it "should match initials" do
        Name.new('M. J. L.', 'Orr').match('Mark John Legard', 'Orr').should be_true
        Name.new('M.', 'Orr').match('Mark', 'Orr').should be_true
        Name.new('M. J. L.', 'Orr').match('Mark', 'Orr').should be_true
        Name.new('M.', 'Orr').match('M. J.', 'Orr').should be_true
        Name.new('M. J. L.', 'Orr').match('M. G.', 'Orr').should be_false
      end
      
      it "should not match on full names not in first position or without an exact match" do
        Name.new('J. M.', 'Orr').match('John', 'Orr').should be_true
        Name.new('M. J.', 'Orr').match('John', 'Orr').should be_false
        Name.new('M. John', 'Orr').match('John', 'Orr').should be_true
      end
      
      it "should handle common nicknames" do
        Name.new('William', 'Orr').match('Bill', 'Orr').should be_true
        Name.new('David', 'Orr').match('Dave', 'Orr').should be_true
        Name.new('Mick', 'Orr').match('Mike', 'Orr').should be_true
      end
      
      it "should not mix up nick names" do
        Name.new('David', 'Orr').match('Bill', 'Orr').should be_false
      end
    end
    
    context "last name matches" do
      it "should be flexible with regards to hyphens in double barrelled names" do
        Name.new('Johanna', "Lowry-O'Reilly").match('Johanna', "Lowry O'Reilly").should be_true
      end
      
      it "should be case insensitive in matches involving Macsomething and MacSomething" do
        Name.new('Alan', 'MacDonagh').match('Alan', 'Macdonagh').should be_true
      end
      
      it "should cater for the common mispelling of names beginning with Mc or Mac" do
        Name.new('Alan', 'McDonagh').match('Alan', 'MacDonagh').should be_true
        Name.new('Darko', 'Polimac').match('Darko', 'Polimc').should be_false
      end
    end
  end
end
