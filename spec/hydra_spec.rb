require 'spec_helper'

describe Hydra do
  let(:hydra)  { Hydra.new }

  describe '#ensure_neck' do
    it "ensures there is a limb" do
      hydra.ensure_neck('a')
      expect(hydra.getneck('a')).to be_a Hydra
    end
  end

  describe '#setatlas' do
    it "grows a neck with a head" do
      hydra.setatlas('a', [1])
      expect(hydra.count).to eq 1
    end

    it "has a correctly labelled limb" do
      hydra.setatlas('b', [2])
      expect(hydra.getneck('b')).to be_a Hydra
    end
  end

  describe '#getneck' do
    it "returns the limb" do
      hydra.ingest 'abc'
      expect(hydra.getneck('a')).to be_a Hydra
    end

    it "returns nil for non-existing limbs" do
      hydra.ingest 'def'
      expect(hydra.getneck('g')).to be_nil
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
      hydra.getneck('a').chophead
      expect(hydra.count).to eq 2
    end
  end

  describe '#letters' do
    it "returns the letters starting the different necks" do
      hydra.ingest ['a', 'b', 'c', 'cd', 'cde']
      expect(hydra.letters).to eq ['a', 'b', 'c']
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
      pattern = Pattern.dummy 'bac'
      expect(hydra.regest(pattern)).to eq "b2a1c"
    end

    it "doesn’t delete by default" do
      hydra.ingest ['foo9bar']
      pattern = Pattern.dummy 'foobar'
      hydra.regest(pattern)
      expect(hydra.count).to eq 1
    end

    it "works as #delete" do
      hydra.ingest ['b2a1c']
      pattern = Pattern.dummy 'bac'
      hydra.regest pattern, true
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

  describe '#ingest_file' do # TODO Allow TeX-style comments?
    it "ingests a whole file of patterns" do
      hydra.ingest_file(File.expand_path('../../files/hyph-bg.pat.txt', __FILE__))
      expect(hydra.count).to eq 1660
    end
  end
end

describe Pattern do
  describe '#new' do
    it "makes a pattern from a word and an array of digits" do
      expect(Pattern.new('bac', [0, 2, 1])).to be_a Pattern
    end
  end

  describe '.dummy' do
    it "creates a dummy pattern from a word" do
      pattern = Pattern.dummy 'abc'
      expect(pattern.get_word).to eq 'abc'
      expect(pattern.get_digits).to eq [0, 0, 0]
    end
  end

  context "with a predefined pattern" do
    describe '#index' do
      it "returns the index" do
        pattern.shift; pattern.shift
        expect(pattern.index).to eq 2
      end

      it "is zero at initialisation" do
        expect(pattern.index).to eq 0
      end
    end

    describe '#shift' do
      it "shifts the index by one" do
        pattern.shift
        expect(pattern.index).to eq 1
      end

      it "returns the pattern" do
        expect(pattern.shift).to be_a Pattern
      end
    end

    describe '#shift!' do
      it "just shifts" do
        pattern = Pattern.new 'q8u1u2x'
        pattern.shift!
        expect(pattern.index).to eq 1
      end
    end

    describe '#reset' do
      it "resets the index" do
        pattern.shift; pattern.shift
        pattern.reset
        expect(pattern.index).to eq 0
      end
    end

    describe '#letter' do
      it "returns the nth letter" do
        pattern = Pattern.new('foo9bar')
        expect(pattern.letter(3)).to eq 'b'
      end
    end

    describe '#digit' do
      it "returns the nth digit" do
        pattern = Pattern.new('foo9bar')
        expect(pattern.digit(3)).to eq 9
      end
    end

    describe '#last?' do
      it "tells when we’re on the last character of the pattern" do
        pattern = Pattern.new '1f2i4n3'
        2.times { pattern.shift }
        expect(pattern.last?).to be_truthy
      end

      it "returns false just after pattern is initialized" do
        pattern = Pattern.new '1vé2g3'
        expect(pattern.last?).to be_falsey
      end
    end

    describe '#end?' do
      it "tells whether we’re at the end of the pattern" do
        pattern = Pattern.new 'end3'
        3.times { pattern.shift }
        expect(pattern.end?).to be_truthy
      end

      it "returns false otherwise" do
        pattern = Pattern.new 'Schluß'
        3.times { pattern.shift }
        expect(pattern.end?).to be_falsey
      end
    end

    describe '#currletter' do
      it "returns the current letter" do
        pattern = Pattern.new 'a1n2a1n2a'
        3.times { pattern.shift }
        expect(pattern.currletter).to eq 'n'
      end
    end

    describe '#currdigit' do
      it "returns the current digit" do
        pattern = Pattern.new '3foo'
        expect(pattern.currdigit).to eq 3
      end
    end

    let(:pattern) { Pattern.new('bac', [0, 2, 1]) }

    describe '#to_s' do
      it "returns a string representation of the pattern" do
        expect(pattern.to_s).to eq "b2a1c"
      end
    end

    describe '.get_digits' do
      it "extracts the digits from a pattern" do
        expect(pattern.get_digits).to eq [0, 2, 1]
      end
    end

    describe '.get_word' do # For completeness!
      it "extracts the word from a pattern" do
        expect(pattern.get_word).to eq "bac"
      end
    end

    describe '#grow' do
      it "grows a letter.  I know it doesn’t make much sense, just give me a break" do
        pattern = Pattern.new 'abc'
        pattern.grow('d')
        expect(pattern.get_word).to eq 'abcd'
      end

      it "returns the pattern" do
        expect(pattern.grow('taller')).to be_a Pattern # Adding more than one letter: not recommended!
      end
    end

    describe '#grow!' do
      it "just grows" do
        pattern = Pattern.new 'f'
        pattern.grow!('g')
        expect(pattern.get_word.length).to eq 2
      end
    end

    describe '#fork' do
      it "forks the pattern on a letter" do
        pattern = Pattern.new
        pattern.grow 'f'; pattern.grow 'o'; pattern.grow 'o'
        expect(pattern.fork('b').get_word).to eq "foob"
      end

      it "returns a new pattern" do
        pattern = Pattern.new
        pattern2 = pattern.fork('b')
        expect(pattern2.object_id).to_not eq pattern.object_id
      end
    end

    describe '#copy' do
      it "returns a new pattern with the same word" do
        expect(pattern.copy([1, 2, 3])).to be_a Pattern
      end

      it "sets the digits" do
        new_pattern = pattern.copy [4, 5, 6]
        expect(new_pattern.get_digits).to eq [4, 5, 6]
      end
    end

    describe '#freeze' do
      it "freezes the pattern and sets the digits" do
        pattern.freeze [1, 2, 3]
        expect(pattern.get_digits).to eq [1, 2 , 3]
      end

      it "returns the pattern" do
        expect(pattern.freeze [4, 5, 6]).to be_a Pattern
      end
    end

    describe '#freeze!' do
      it "just sets the digits" do
        expect(pattern.freeze! [4, 5, 6]).to eq [4, 5, 6]
      end
    end
  end
end
