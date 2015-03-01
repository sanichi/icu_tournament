# encoding: UTF-8
require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

module ICU
  module Util
    describe Date do
      context "#parse" do
        it "should parse standard dates" do
          expect(Date.parse('2001-01-01')).to eq('2001-01-01')
          expect(Date.parse('1955-11-09')).to eq('1955-11-09')
        end
    
        it "should handle US format" do
          expect(Date.parse('03/30/2009')).to eq('2009-03-30')
        end
    
        it "should handle European format" do
          expect(Date.parse('30/03/2009')).to eq('2009-03-30')
        end
    
        it "should prefer European format" do
          expect(Date.parse('02/03/2009')).to eq('2009-03-02')
        end
    
        it "should handle US style when there's no alternative" do
          expect(Date.parse('02/23/2009')).to eq('2009-02-23')
        end
    
        it "should handle single digits" do
          expect(Date.parse('9/8/2006')).to eq('2006-08-09')
        end
    
        it "should handle names of monthsx" do
          expect(Date.parse('9th Nov 1955')).to eq('1955-11-09')
          expect(Date.parse('16th June 1986')).to eq('1986-06-16')
        end
      end
    end
    
    describe File do
      context "#read_utf8" do
        before(:all) do
          @s = ::File.dirname(__FILE__) + '/samples/file'
        end

        it "should read ASCII" do
          expect(File.read_utf8("#{@s}/ascii.txt")).to eq("Resume\nResume\n")
        end

        it "should read Latin-1" do
          expect(File.read_utf8("#{@s}/latin1.txt")).to eq("Résumé\nRésumé\n")
        end

        it "should read Windows CP1252" do
          expect(File.read_utf8("#{@s}/cp1252.txt")).to eq("€3\n£7\n¥1\n")
        end

        it "should read UTF-8" do
          expect(File.read_utf8("#{@s}/utf8.txt")).to eq("ヒラガナ\nヒラガナ\n")
        end

        it "should thow an exception for a non-existant file" do
          expect { File.read_utf8("#{@s}/no_such_file.txt") }.to raise_error
        end
      end

      context "#load_ini" do
        before(:all) do
          @s = ::File.dirname(__FILE__) + '/samples/ini'
        end

        it "should read ASCII" do
          data = File.load_ini("#{@s}/ascii.ini")
          expect(data).to be_an_instance_of(Hash)
          expect(data["Pairing"]["UseRating"]).to eq("0")
          data["NoKeys"] == nil
          expect(data["Tournament Info"]["Arbiter"]).to eq("Herbert Scarry")
          expect(data["Tournament Info"]["DrawSymbol"]).to eq("D")
        end

        it "should read Latin1" do
          data = File.load_ini("#{@s}/latin1.ini")
          expect(data).to be_an_instance_of(Hash)
          expect(data["Tournament Info"]["Arbiter"]).to eq("Gearóidín")
          expect(data["Tournament Info"]["DrawSymbol"]).to eq("½")
        end

        it "should read Windows-1252" do
          data = File.load_ini("#{@s}/cp1252.ini")
          expect(data).to be_an_instance_of(Hash)
          expect(data["Tournament Info"]["Entry Fee"]).to eq("€50")
        end

        it "should read UTF8" do
          data = File.load_ini("#{@s}/utf8.ini")
          expect(data).to be_an_instance_of(Hash)
          expect(data["Tournament Info"]["Entry Fee"]).to eq("€50")
          expect(data["Tournament Info"]["Arbiter"]).to eq("ヒラガナ")
          expect(data["Tournament Info"]["DrawSymbol"]).to eq("½")
        end

        it "should handle untidily formatted files" do
          data = File.load_ini("#{@s}/untidy.ini")
          expect(data).to be_an_instance_of(Hash)
          expect(data["Tournament Info"]["Entry Fee"]).to eq("€50")
          expect(data["Tournament Info"]["DrawSymbol"]).to eq("½")
          expect(data["Pairing"]["Use  Rating"]).to eq("0")
        end

        it "should thow an exception for a non-existant file" do
          expect { File.read_utf8("#{@s}/no_such_file.ini") }.to raise_error
        end
      end
    end

    describe Accessor do
      context "#attr_accessor" do
        before(:each) do
          @class = Class.new
          @class.extend ICU::Util::Accessor
          @obj = @class.new
        end

        it "should not have an accessor unless declared" do
          expect(@obj.respond_to?(:myatr)).to be_falsey
          expect(@obj.respond_to?(:myatr=)).to be_falsey
        end

        it "should have a getter but no setter with the default declaration" do
          @class.attr_accessor('myatr')
          expect(@obj.respond_to?(:myatr)).to be_truthy
          expect(@obj.respond_to?(:myatr=)).to be_falsey
          @obj.instance_eval { @myatr = 42 }
          expect(@obj.myatr).to eq(42)
        end

        it "should be able to create do-it-yourself setters such as for a positive integer" do
          @class.attr_accessor('myatr') do |val|
            tmp = val.to_i
            raise "invalid positive integer (#{val})" unless tmp > 0
            tmp
          end
          expect(@obj.respond_to?(:myatr)).to be_truthy
          expect(@obj.respond_to?(:myatr=)).to be_truthy
          expect { @obj.myatr = "no number here" }.to raise_error(/invalid positive integer \(no number here\)/)
          expect { @obj.myatr = -1 }.to raise_error
          expect { @obj.myatr = 0 }.to raise_error
          expect { @obj.myatr = 1 }.not_to raise_error
          expect(@obj.myatr).to eq(1)
          expect { @obj.myatr = '42' }.not_to raise_error
          expect(@obj.myatr).to eq(42)
          expect { @obj.myatr = '  0371  ' }.not_to raise_error
          expect(@obj.myatr).to eq(371)
        end
      end

      context "#attr_integer" do
        before(:each) do
          @class = Class.new
          @class.extend ICU::Util::Accessor
          @class.attr_integer :myint
          @obj = @class.new
        end

        it "should have a getter and setter" do
          expect(@obj.respond_to?(:myint)).to be_truthy
          expect(@obj.respond_to?(:myint=)).to be_truthy
        end

        it "should work with ints" do
          @obj.myint = -43
          expect(@obj.myint).to eq(-43)
        end

        it "should work with strings" do
          @obj.myint = "  -99 "
          expect(@obj.myint).to eq(-99)
        end

        it "should handle zero" do
          expect { @obj.myint = 0 }.not_to raise_error
          expect { @obj.myint = '0' }.not_to raise_error
        end

        it "should reject nil and other non-numbers" do
          expect { @obj.myint = nil }.to raise_error(/invalid/)
          expect { @obj.myint = "N" }.to raise_error(/invalid/)
          expect { @obj.myint = " " }.to raise_error(/invalid/)
          expect { @obj.myint = ''  }.to raise_error(/invalid/)
        end

        it "should handle multiple names" do
          @class.attr_integer :yourint, :hisint
          expect(@obj.respond_to?(:yourint)).to be_truthy
          expect(@obj.respond_to?(:hisint=)).to be_truthy
        end
      end

      context "#attr_integer_or_nil" do
        before(:each) do
          @class = Class.new
          @class.extend ICU::Util::Accessor
          @class.attr_integer_or_nil :myint
          @obj = @class.new
        end

        it "should have a getter and setter" do
          expect(@obj.respond_to?(:myint)).to be_truthy
          expect(@obj.respond_to?(:myint=)).to be_truthy
        end

        it "should work with ints and nil and spaces" do
          @obj.myint = 43
          expect(@obj.myint).to eq(43)
          @obj.myint = nil
          expect(@obj.myint).to eq(nil)
          @obj.myint = '  '
          expect(@obj.myint).to eq(nil)
        end

        it "should reject non-numbers" do
          expect { @obj.myint = "N" }.to raise_error(/invalid/)
        end

        it "should handle multiple names" do
          @class.attr_integer :yourint, :hisint
          expect(@obj.respond_to?(:yourint)).to be_truthy
          expect(@obj.respond_to?(:hisint=)).to be_truthy
        end
      end

      context "#attr_positive" do
        before(:each) do
          @class = Class.new
          @class.extend ICU::Util::Accessor
          @class.attr_positive :mypos
          @obj = @class.new
        end

        it "should have a getter and setter" do
          expect(@obj.respond_to?(:mypos)).to be_truthy
          expect(@obj.respond_to?(:mypos=)).to be_truthy
        end

        it "should work as expected" do
          @obj.mypos = "34"
          expect(@obj.mypos).to eq(34)
        end

        it "should reject nil and other non-positive integers" do
          expect { @obj.mypos = nil }.to raise_error(/invalid/)
          expect { @obj.mypos = 'X' }.to raise_error(/invalid/)
          expect { @obj.mypos = '0' }.to raise_error(/invalid/)
          expect { @obj.mypos = -13 }.to raise_error(/invalid/)
        end

        it "should handle multiple names" do
          @class.attr_integer :ourpos, :theirpos
          expect(@obj.respond_to?(:ourpos)).to be_truthy
          expect(@obj.respond_to?(:theirpos=)).to be_truthy
        end
      end

      context "#attr_positive_or_nil" do
        before(:each) do
          @class = Class.new
          @class.extend ICU::Util::Accessor
          @class.attr_positive_or_nil :mypon
          @obj = @class.new
        end

        it "should have a getter and setter" do
          expect(@obj.respond_to?(:mypon)).to be_truthy
          expect(@obj.respond_to?(:mypon=)).to be_truthy
        end

        it "should work with numbers, nil, empty strings and spaces" do
          @obj.mypon = " 54 "
          expect(@obj.mypon).to eq(54)
          @obj.mypon = nil
          expect(@obj.mypon).to be_nil
          @obj.mypon = ''
          expect(@obj.mypon).to be_nil
          @obj.mypon = '  '
          expect(@obj.mypon).to be_nil
        end

        it "should reject non-integers and non-positive integers" do
          expect { @obj.mypon = 'X' }.to raise_error(/invalid/)
          expect { @obj.mypon = '0' }.to raise_error(/invalid/)
          expect { @obj.mypon = -13 }.to raise_error(/invalid/)
        end

        it "should handle multiple names" do
          @class.attr_integer :ourpon, :theirpon
          expect(@obj.respond_to?(:ourpon)).to be_truthy
          expect(@obj.respond_to?(:theirpon=)).to be_truthy
        end
      end

      context "#attr_date" do
        before(:each) do
          @class = Class.new
          @class.extend ICU::Util::Accessor
          @class.attr_date :mydate
          @obj = @class.new
        end

        it "should have a getter and setter" do
          expect(@obj.respond_to?(:mydate)).to be_truthy
          expect(@obj.respond_to?(:mydate=)).to be_truthy
        end

        it "should work as expected" do
          @obj.mydate = "2009/11/09"
          expect(@obj.mydate).to eq('2009-11-09')
        end

        it "should reject nil and other non-dates" do
          expect { @obj.mydate = nil }.to raise_error(/invalid/)
          expect { @obj.mydate = 'blah de blah' }.to raise_error(/invalid/)
          expect { @obj.mydate = ' ' }.to raise_error(/invalid/)
          expect { @obj.mydate = 0 }.to raise_error(/invalid/)
        end

        it "should handle multiple names" do
          @class.attr_date :ourdate, :theirdate
          expect(@obj.respond_to?(:ourdate)).to be_truthy
          expect(@obj.respond_to?(:theirdate=)).to be_truthy
        end
      end

      context "#attr_date_or_nil" do
        before(:each) do
          @class = Class.new
          @class.extend ICU::Util::Accessor
          @class.attr_date_or_nil :mydate
          @obj = @class.new
        end

        it "should have a getter and setter" do
          expect(@obj.respond_to?(:mydate)).to be_truthy
          expect(@obj.respond_to?(:mydate=)).to be_truthy
        end

        it "should work as expected, including with nil" do
          @obj.mydate = "2009/11/09"
          expect(@obj.mydate).to eq('2009-11-09')
          @obj.mydate = nil
          expect(@obj.mydate).to be_nil
        end

        it "should reject non-dates" do
          expect { @obj.mydate = 'blah de blah' }.to raise_error(/invalid/)
          expect { @obj.mydate = 0 }.to raise_error(/invalid/)
        end

        it "should handle multiple names" do
          @class.attr_date :ourdate, :theirdate
          expect(@obj.respond_to?(:ourdate)).to be_truthy
          expect(@obj.respond_to?(:theirdate=)).to be_truthy
        end
      end

      context "#attr_string" do
        before(:each) do
          @class = Class.new
          @class.extend ICU::Util::Accessor
          @class.attr_string %r%[a-z]+%i, :mystring
          @obj = @class.new
        end

        it "should have a getter and setter" do
          expect(@obj.respond_to?(:mystring)).to be_truthy
          expect(@obj.respond_to?(:mystring=)).to be_truthy
        end

        it "should work as expected" do
          @obj.mystring = "  mark   "
          expect(@obj.mystring).to eq('mark')
        end

        it "should reject values that don't match" do
          expect { @obj.mystring = nil }.to raise_error(/invalid/)
          expect { @obj.mystring = ' 123 ' }.to raise_error(/invalid/)
          expect { @obj.mystring = ' ' }.to raise_error(/invalid/)
          expect { @obj.mystring = 0 }.to raise_error(/invalid/)
          expect { @obj.mystring = ' a ' }.not_to raise_error
          expect { @obj.mystring = 'ZYX' }.not_to raise_error
        end

        it "should handle multiple names" do
          @class.attr_string %r%^[A-Z]{3}$%, :ourstring, :theirstring
          expect(@obj.respond_to?(:ourstring=)).to be_truthy
          expect(@obj.respond_to?(:theirstring)).to be_truthy
        end
      end

      context "#attr_string_or_nil" do
        before(:each) do
          @class = Class.new
          @class.extend ICU::Util::Accessor
          @class.attr_string_or_nil %r%^[1-9]\d*$%i, :mystring
          @obj = @class.new
        end

        it "should have a getter and setter" do
          expect(@obj.respond_to?(:mystring)).to be_truthy
          expect(@obj.respond_to?(:mystring=)).to be_truthy
        end

        it "should work as expected" do
          @obj.mystring = " 12345  "
          expect(@obj.mystring).to eq('12345')
          @obj.mystring = nil
          expect(@obj.mystring).to be_nil
          @obj.mystring = '   '
          expect(@obj.mystring).to be_nil
        end

        it "should reject values that don't match" do
          expect { @obj.mystring = ' 0 ' }.to raise_error(/invalid/)
          expect { @obj.mystring = 0 }.to raise_error(/invalid/)
          expect { @obj.mystring = -1 }.to raise_error(/invalid/)
          expect { @obj.mystring = 98 }.not_to raise_error
        end

        it "should handle multiple names" do
          @class.attr_string %r%^[A-Z][a-z]+%, :ourstring, :theirstring
          expect(@obj.respond_to?(:ourstring=)).to be_truthy
          expect(@obj.respond_to?(:theirstring)).to be_truthy
        end
      end
    end
  end
end