require 'spec_helper'

describe Knuckle do
  describe '#digit' do
    it "returns a digit" do
      knuckle = Knuckle.new('r', 3)
      expect(knuckle.digit).to eq 3
    end

    describe '#letter' do
      it "returns a letter" do
        knuckle = Knuckle.new('r')
        expect(knuckle.letter).to eq 'r'
      end
    end
  end
end

describe Hydra do
  let(:hydra)  { Hydra.new }

  describe '#[]' do
    it "works" do
      hydra['a']
    end

    it "indexes" do
      hydra.ingest 'ab'
      expect(hydra['a']).to be_a Hydra
    end
  end

  describe '#[]=' do
    it "works too" do
      hydra['a'] = Hydra.new
    end

    it "assigns an index" do
      hydra['a'] = []
      hydra['a'][0] = [1, 2, 3]
      expect(hydra['a'][0]).to eq [1, 2, 3]
    end
  end

  describe '#ensure_limb' do
    it "ensures there is a limb" do
      hydra.ensure_limb('a')
      expect(hydra['a']).to be_a Hydra
    end
  end

  describe '#inject' do
    it "works" do
      hydra.inject(0) { |t, x| }
    end

    it "injects" do
      hydra.ingest ['a', 'b', 'c']
      retvalue = hydra.inject(1) do |sum, limb|
        sum + 2
      end
      expect(retvalue).to eq 7
    end
  end

  describe '#sethead' do
    it "sets the head" do
      hydra.sethead [1, 2, 3]
    end
  end

  describe '#gethead' do
    it "gets the head" do
      hydra.sethead [1, 2, 3]
      expect(hydra.gethead).to eq [1, 2, 3]
    end
  end

  describe '#chophead' do
    it "chops off the head" do
      hydra.ingest ['a', 'b', 'c']
      hydra['a'].chophead
      expect(hydra.count).to eq 2
    end
  end

  describe '#keys' do
    it "returns the keys of the root" do
      hydra.ingest ['a', 'b', 'c', 'cd', 'cde']
      expect(hydra.keys).to eq ['a', 'b', 'c']
    end
  end

  describe '#count' do
    it "counts" do
      hydra.ingest(['a', 'b', 'c'])
      expect(hydra.count).to eq 3
    end
  end

  describe '.isdigit', isdigit: true do
    it "says 3 is a digit" do
      expect(Hydra.isdigit('3')).to be_truthy
    end

    it "says a isn’t a digit" do
      expect(Hydra.isdigit('a')).to be_falsey
    end
  end

  describe '#ingest' do
    it "works with a single word" do
      hydra.ingest('bac')
      expect(hydra.count).to eq 1
    end

    it "works with an array of words" do
      hydra.ingest(['democrat', 'democracy', 'democratic'])
      expect(hydra.count).to eq 3
    end

    it "works with an actual pattern" do
      hydra.ingest('1a2b3c4')
      expect(hydra.count).to eq 1
    end

    # TODO Test with conflicting patterns
  end

  describe '#digest' do
    it "returns the list of words" do
      hydra.ingest(['orange', 'yellow', 'red'])
      expect(hydra.digest).to eq ['orange', 'red', 'yellow']
    end

    it "returns a pattern" do
      hydra.ingest('1ab2c3')
      expect(hydra.digest).to eq ['1ab2c3']
    end

    it "works on a more complex example" do
      hydra.ingest(['1abc', 'a2b', 'a3bc4d'])
      expect(hydra.digest).to eq ['a2b', '1abc', 'a3bc4d']
    end
  end

  # Plan: #search → #delete (more complex search)
  # → #regest (search with option to delete)
  describe '#search' do
    it "searches one digitless pattern", focus: true do
      hydra.ingest ['b2a1c']
      expect(hydra.search('bac')).to eq "b2a1c"
    end

    it "doesn’t do anything if no pattern is found" do
      hydra.ingest ['a', 'b', 'c']
      expect(hydra.search('def')).to be_nil
    end

    it "raises an exception if the digits didn’t match", focus: true do
      hydra.strict_mode
      hydra.ingest 'b2a1c'
      expect { hydra.search 'ba4c3' }.to raise_exception Hydra::ConflictingPattern
    end
  end

  describe '#delete' do
    it "deletes one digitless pattern" do
      hydra.ingest ['b2a1c']
      hydra.delete('bac')
      expect(hydra.count).to eq 0
    end

    it "deletes one full-fledged pattern" do
      hydra.ingest ['b2a1c']
      hydra.delete('b2a1c')
      expect(hydra.count).to eq 0
    end

    it "raises" do
      hydra.strict_mode
      hydra.ingest 'b2a1c'
      expect { hydra.delete 'ba4c3' }.to raise_exception Hydra::ConflictingPattern
    end
  end

  describe '#regest' do
    it "works as #search" do
      hydra.ingest ['b2a1c']
      expect(hydra.regest('bac', false)).to eq "b2a1c"
    end

    it "works as #delete" do
      hydra.ingest ['b2a1c']
      hydra.regest 'bac'
      expect(hydra.count).to eq 0
    end
  end

  describe '#dump' do
    let(:device) { double(:output).as_null_object }

    it "dumps a string" do
      hydra.ingest(['apple', 'orange', 'lemon'])
      expect(PP).to receive :pp # TODO specify arguments
      hydra.dump(device)
    end

    it "returns the count" do
      hydra.ingest(['a', 'b', 'c', 'd', 'e'])
      expect(hydra.dump(device)).to eq 5
    end
  end
  # TODO ingest with dots, etc.
  # TODO Apply hydra!

  describe '.make_pattern' do
    it "makes a pattern from a word and an array of digits" do
      expect(Hydra.make_pattern('bac', [0, 2, 1])).to eq "b2a1c"
    end
  end

  describe '.get_digits' do
    it "extracts the digits from a pattern" do
      expect(Hydra.get_digits('b2a1c')).to eq [0, 2, 1]
    end
  end

  describe '.get_word' do # For completeness!
    it "extracts the word from a pattern" do
      expect(Hydra.get_word('b2a1c')).to eq "bac"
    end
  end

  describe '#ingest_file' do # TODO Allow TeX-style comments?
    it "ingests a whole file of patterns" do
      hydra.ingest_file(File.expand_path('../../files/hyph-bg.pat.txt', __FILE__))
      expect(hydra.count).to eq 1660
    end
  end
end
