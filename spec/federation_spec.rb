require File.dirname(__FILE__) + '/spec_helper'

module ICU
  describe Federation do
    context "#find using codes" do
      it "should find a federation given a valid code" do
        fed = Federation.find('IRL')
        fed.code.should == 'IRL'
        fed.name.should == 'Ireland'
      end
      
      it "should find a federation from code case insensitively" do
        fed = Federation.find('rUs')
        fed.code.should == 'RUS'
        fed.name.should == 'Russia'
      end
      
      it "should find a federation despite irrelevant whitespace" do
        fed = Federation.find('  mex    ')
        fed.code.should == 'MEX'
        fed.name.should == 'Mexico'
      end
      
      it "should return nil for an invalid code" do
        Federation.find('XYZ').should be_nil
      end
    end
    
    context "#find using names" do
      it "should find a federation given a valid name" do
        fed = Federation.find('England')
        fed.code.should == 'ENG'
        fed.name.should == 'England'
      end
      
      it "should find a federation from name case insensitively" do
        fed = Federation.find('franCE')
        fed.code.should == 'FRA'
        fed.name.should == 'France'
      end
      
      it "should not be fooled by irrelevant whitespace" do
        fed = Federation.find(' united  states  of  america ')
        fed.code.should == 'USA'
        fed.name.should == 'United States of America'
      end
      
      it "should return nil for an invalid name" do
        Federation.find('Mordor').should be_nil
      end
    end
    
    context "#find using parts of names" do
      it "should find a federation given a substring which is unique and at least 4 characters" do
        fed = Federation.find('bosni')
        fed.code.should == 'BIH'
        fed.name.should == 'Bosnia and Herzegovina'
      end
      
      it "should not be fooled by irrelevant whitespace" do
        fed = Federation.find('  arab    EMIRATES   ')
        fed.code.should == 'UAE'
        fed.name.should == 'United Arab Emirates'
      end
      
      it "should not find a federation if the substring matches more than one" do
        Federation.find('land').should be_nil
      end
      
      it "should return nil for any string smaller in length than 3" do
        Federation.find('ze').should be_nil
      end
    end
    
    context "#find federations with alternative names" do
      it "should find Macedonia multiple ways" do
        Federation.find('MKD').name.should == 'Macedonia'
        Federation.find('FYROM').name.should == 'Macedonia'
        Federation.find('macedoni').name.should == 'Macedonia'
        Federation.find('Macedonia').name.should == 'Macedonia'
        Federation.find('former YUG Rep').name.should == 'Macedonia'
        Federation.find('Republic of Macedonia').name.should == 'Macedonia'
        Federation.find('former yugoslav republic').name.should == 'Macedonia'
      end
      
      context "#find and alternative inputs" do
        it "should behave robustly with silly inputs" do
          Federation.find().should be_nil
          Federation.find(nil).should be_nil
          Federation.find('').should be_nil
          Federation.find(1).should be_nil
        end
      end
    end
  end
end
