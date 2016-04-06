require 'spec_helper'

describe Pattern do
  describe '#new' do
    it "makes a pattern from a word and an array of digits" do
      expect(Pattern.new('bac', [0, 2, 1, 0])).to be_a Pattern
    end

    it "works with patterns with trailing digits" do
      pattern = Pattern.new('ab2')
      expect(pattern).to be_a Pattern
      expect(pattern.get_word).to eq 'ab'
      expect(pattern.get_digits).to eq [0, 0, 2]
    end
  end

  describe '.dummy' do
    it "creates a dummy pattern from a word" do
      pattern = Pattern.dummy 'abc'
      expect(pattern.get_word).to eq 'abc'
      expect(pattern.get_digits).to eq [0, 0, 0, 0]
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

      it "takes an optional number of repetitions" do
        pattern = Pattern.new('foo1bar')
        expect(pattern.shift(3).index).to eq 3
      end
    end

    describe '#shift!' do
      it "just shifts" do
        pattern = Pattern.new 'q8u1u2x'
        pattern.shift!
        expect(pattern.index).to eq 1
      end

      it "takes an optional number as argument" do
        pattern = Pattern.new('baz1quux')
        expect { pattern.shift! 2 }.to change(pattern, :index).by 2
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

    let(:pattern) { Pattern.new('bac', [0, 2, 1, 0]) }

    describe '#to_s' do
      it "returns a string representation of the pattern" do
        expect(pattern.to_s).to eq "b2a1c"
      end
    end

    describe '.get_digits' do
      it "extracts the digits from a pattern" do
        expect(pattern.get_digits).to eq [0, 2, 1, 0]
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
        pattern = Pattern.new('fo2o')
        expect(pattern.copy([1, 2, 3, 0])).to be_a Pattern
      end

      it "sets the digits" do
        pattern = Pattern.new('ba2r')
        new_pattern = pattern.copy [4, 5, 6, 0]
        expect(new_pattern.get_digits).to eq [4, 5, 6, 0]
      end
    end

    describe '#freeze' do
      it "freezes the pattern and sets the digits" do
        pattern = Pattern.new('foo5bar')
        pattern.freeze [1, 2, 3, 4, 5, 6, 7]
        expect(pattern.get_digits).to eq [1, 2, 3, 4, 5, 6, 7]
      end

      it "returns the pattern" do
        pattern = Pattern.new('ba6z5quux')
        expect(pattern.freeze [4, 5, 6, 7, 8, 9, 0, 0]).to be_a Pattern
      end
    end

    describe '#freeze!' do
      it "just sets the digits" do
        pattern = Pattern.new('1ing')
        expect(pattern.freeze! [4, 5, 6, 0]).to eq [4, 5, 6, 0]
      end
    end

    describe '#word_so_far' do # TODO word_at?
      it "returns the word up to the current index" do
        pattern = Pattern.dummy 'sandrigham'
        4.times { pattern.shift }
        expect(pattern.word_so_far).to eq 'sand'
      end
    end

    describe '#word_to' do
      it "returns the word from the current index with length n" do
        pattern = Pattern.dummy 'maskedball'
        2.times { pattern.shift }
        expect(pattern.word_to(6)).to eq 'skedba'
      end
    end

    describe '#digits_to' do # TODO #digits_so_far as well
      it "returns the digits from the current index to length n" do
        pattern = Pattern.new 'po2l3ish9en4g3lish'
        6.times { pattern.shift }
        expect(pattern.digits_to(4)).to be == [9, 0, 4, 3, 0]
      end
    end

    describe '#mask(array)' do
      it "masks the pattern’s digits with an array" do
        pattern = Pattern.dummy 'supercal'
        3.times { pattern.shift }
        pattern.mask [0, 0, 0, 3]
        expect(pattern.to_s).to eq 'sup3ercal'
      end

      it "applies several masks successively" do
        pattern = Pattern.dummy 'supercal'
        2.times { pattern.shift }
        pattern.mask [0, 0, 1] # Potentially coming from a "su1"
        pattern.shift
        pattern.mask [0, 0, 2, 3] # "su2p3"
        4.times { pattern.shift } # TODO Pattern#shift(n)!
        pattern.mask [0, 1, 2, 1] # "r1c2a"
        1.times { pattern.shift }
        pattern.mask [0, 2, 3] # "a2l3"
        expect(pattern.to_s).to eq "su2p3er1c2a2l3"
      end

      describe '#length' do
        it "returns the length of the underlying word" do
          pattern = Pattern.dummy 'abcdef'
          expect(pattern.length).to eq 6
        end
      end

      describe '#<=>' do
        it "returns -1 if first pattern’s word is lexicographically less than the second’s" do
          expect(Pattern.new('abc').<=>(Pattern.new('def'))).to eq -1
        end

        it "returns 1 if it’s the other way round" do
          expect(Pattern.new('def').<=>(Pattern.new('abc'))).to eq 1
        end

        it "returns 0 if the underlying words are the same" do # TODO sort digits!
          expect(Pattern.new('a1bc').<=>(Pattern.new('a2bc'))).to eq 0
        end
      end

      describe '#initial!' do
        it "marks a pattern as initial" do
          pattern = Pattern.new('aaabbb')
          pattern.initial!
          expect(pattern.initial?).to be_truthy
          expect(pattern.get_digits.length).to eq 7
        end
      end

      describe '#final!' do
        it "marks a pattern as final" do
          pattern = Pattern.new('cc')
          pattern.final!
          expect(pattern.final?).to be_truthy
          expect(pattern.get_digits.length).to eq 3
        end
      end

      describe '#initial' do
        it "marks a pattern as initial" do
          pattern = Pattern.new('foo3')
          pattern.initial
          expect(pattern.initial?).to be_truthy
          expect(pattern.get_digits.length).to eq 4
        end

        it "returns the pattern" do
          expect(Pattern.new('def').initial).to be_a Pattern
        end
      end

      describe '#final' do
        it "marks a pattern as final" do
          pattern = Pattern.new('5bar')
          pattern.final
          expect(pattern.final?).to be_truthy
          expect(pattern.get_digits.length).to eq 4
        end
        
        it "returns the pattern" do
          expect(Pattern.new('bac').final).to be_a Pattern
        end
      end

      describe '#initial?' do
        it "says whether a pattern is initial" do
          pattern = Pattern.new('1fo2o3')
          pattern.initial
          expect(pattern.initial?).to be_truthy
        end
      end

      describe '#final?' do
        it "says whether a pattern is final" do
         pattern = Pattern.new('3b2a4r')
         pattern.final
         expect(pattern.final?).to be_truthy
       end
     end

     describe '#to_s' do # That was clearly missing!
       it "returns the verbatim pattern in case it was fed so" do
         pattern = Pattern.new('fo2o')
         expect(pattern.to_s).to eq 'fo2o'
       end

       it "computes the pattern correctly otherwise" do
         pattern = Pattern.new('foo', [0, 0, 2, 0])
         expect(pattern.to_s).to eq 'fo2o'
       end

       it "handles dots correctly" do
         pattern = Pattern.new('foo')
         pattern.initial
         expect(pattern.to_s).to eq '.foo'
       end

       it "... even in final position" do
         pattern = Pattern.new('bar')
         pattern.final
         expect(pattern.to_s).to eq 'bar.'
       end
     end
    end
  end
end

describe HyphenatedWord do
  describe '.new' do
    it "creates a pattern from a hyphenation dictionary" do
      pattern = HyphenatedWord.new('foo-bar')
      expect(pattern.get_word).to be == "foobar"
      expect(pattern.digit(3)).to be == :is
    end
  end

  describe '#dot' do
    it "returns the dot value at position i" do
      pattern = HyphenatedWord.new('foo-bar')
      expect(pattern.dot(3)).to be == :is
    end

    it "counts from the current index" do
      pattern = HyphenatedWord.new('foo-bar')
      2.times { pattern.shift }
      expect(pattern.dot(1)).to be == :is
    end

    it "returns 0 if there’s nothing there" do
      pattern = HyphenatedWord.new('foo-bar')
      expect(pattern.dot(2)).to be == 0
    end
  end
end

describe Hydra do
  let(:hydra)  { Hydra.new }

  describe '.new' do
    it "creates a new Hydra" do
      hydra = Hydra.new
      expect(hydra).to be_a Hydra
    end

    it "sets the mode to :lax by default" do
      hydra = Hydra.new
      expect(hydra.instance_variable_get(:@mode)).to be == :lax
    end

    it "can set mode to :strict" do
      hydra = Hydra.new(nil, :strict)
      expect(hydra.instance_variable_get(:@mode)).to be == :strict
    end

    it "optionally ingests a word or list of words" do
      hydra = Hydra.new(['foo', 'bar', 'baz', 'quux'])
      expect(hydra.count).to be == 4
    end
  end

  describe '#lefthyphenmin' do
    it "is 2 by default" do
      hydra = Hydra.new
      expect(hydra.lefthyphenmin).to eq 2
    end

    it "can be set to something else" do
      hydra.setlefthyphenmin 3
      expect(hydra.lefthyphenmin).to eq 3
    end
  end

  describe '#righthyphenmin' do
    it "is 3 by default" do
      hydra = Hydra.new
      expect(hydra.righthyphenmin).to eq 3
    end

    it "can be set to something else" do
      hydra.setrighthyphenmin(4)
      expect(hydra.righthyphenmin).to eq 4
    end
  end

  describe '#setlefthyphenmin' do
    it "sets lefthyphenmin" do
      hydra.setlefthyphenmin(1)
      expect(hydra.lefthyphenmin).to eq 1
    end
  end

  describe '#setrighthyphenmin' do
    it "sets righthyphenmin" do
      hydra.setrighthyphenmin(1)
      expect(hydra.righthyphenmin).to eq 1
    end
  end

  # FIXME Maybe not the best metaphor!
  describe '#parent' do
    it "is nil by default" do
      hydra = Hydra.new
      expect(hydra.parent).to be_nil
    end

    it "knows about its parent if it has one" do
      hydra = Hydra.new 'abc'
      aneck = hydra.getneck 'a'
      expect(aneck.parent).to eq hydra
    end
  end

  describe '#setparent' do
    it "sets the parent" do
      parent = Hydra.new
      child = Hydra.new
      child.setparent(parent)
      expect(child.parent).to eq parent
    end
  end

  describe '#depth' do
    it "returns the depth" do
      hydra = Hydra.new 'abv'
      deep_water = hydra.getneck('a').getneck('b').getneck('v')
      expect(deep_water.depth).to be == 3
    end

    it "is zero for newly created hydrae" do
      hydra = Hydra.new
      expect(hydra.depth).to be == 0
    end
  end

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

  describe '.isdigit' do
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

    it "works with patterns that are prefix of each other" do
      hydra.ingest ['ba1', 'ba2r']
      expect(hydra.digest).to eq ['ba1', 'ba2r']
    end

    # TODO Specify that in non-strict modes higher-values heads take precedence
    it "really works with patterns that are prefix of each other" do
      matching_patterns = ['fo1', 'o2o', 'o1b', 'ba1', 'ba2r']
      non_matching_patterns = ['ba2', 'of3', 'mo2o']
      hydra.ingest matching_patterns
      hydra.ingest non_matching_patterns
      expect(hydra.digest).to eq ['ba2', 'ba2r', 'fo1', 'mo2o', 'o1b', 'of3', 'o2o']
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
    it "searches one digitless pattern" do
      hydra.ingest ['b2a1c']
      expect(hydra.search('bac')).to eq "b2a1c"
    end

    it "doesn’t do anything if no pattern is found" do
      hydra.ingest ['a', 'b', 'c']
      expect(hydra.search('def')).to be_nil
    end

    it "raises an exception if the digits didn’t match" do
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
      hydra.regest pattern, :delete
      expect(hydra.count).to eq 0
    end
  end

  describe '#match' do
    it "returns a simple match" do
      hydra.ingest ['foo1', 'boo2']
      matches = hydra.match('foobar')
      expect(matches.map(&:to_s)).to eq ['foo1']
    end

    it "returns an array of patterns" do
      hydra.ingest ['foo1', 'boo2', '3bar']
      matches = hydra.match('foobar')
      expect(matches).to be_an Array
      expect(matches.count).to eq 2
      expect(matches.map(&:class)).to eq [Pattern, Pattern]
    end

    it "works with patterns that are prefixes of each other" do
      hydra.ingest ['fo2', 'foo1']
      expect(hydra.match('foobar').map(&:to_s)).to eq ['fo2', 'foo1']
    end

    it "looks for matching patterns" do
      hydra = Hydra.new
      matching_patterns = ['ba1', 'ba2r', 'fo1', 'o1b', 'o2o']
      non_matching_patterns = ['ba2b', 'of3', 'mo2o']
      hydra.ingest matching_patterns
      hydra.ingest non_matching_patterns
      match = hydra.match('foobar')
      expect(match.map(&:to_s)).to eq matching_patterns
    end

    it "matches a more complex example" do
      hydra = Hydra.new
      hydra.ingest_file(File.expand_path('../../files/hyphen.txt', __FILE__))
      expect(hydra.match('hyphenation').map(&:to_s)).to eq ['he2n', 'hena4', 'hen5at', 'hy3ph', '2io', '1na', 'n2at', 'o2n', '1tio'] # According to appendix H :-)
    end

    it "matches a pattern with an initial dot", dot: true do
      hydra = Hydra.new # TODO Hydra.new(arg) → list of patterns
      hydra.ingest ['.foo']
      expect(hydra.match('foobar').map(&:to_s)).to eq ['.foo'] # TODO Matcher for that
    end

    it "matches a pattern with an initial dot and actual digits" do
      hydra = Hydra.new
      hydra.ingest '.foo1'
      expect(hydra.match('foobar').map(&:to_s)).to eq ['.foo1']
    end

    it "finds no match if pattern is in the middle of the word" do
      hydra = Hydra.new
      hydra.ingest ['.oob']
      expect(hydra.match('foobar')).to be_empty
    end

    it "finds no match if pattern is different after initial dot" do
      hydra = Hydra.new
      hydra.ingest ['.boo']
      expect(hydra.match('foobar')).to be_empty
    end

    it "matches a closing dot" do
      hydra = Hydra.new
      hydra.ingest ['bar.']
      expect(hydra.match('foobar').map(&:to_s)).to eq ['bar.']
    end

    # TODO Stupid pattern bar1.?

    it "matches a final do with actual digits in the pattern" do
      hydra = Hydra.new
      hydra.ingest '1bar.'
      expect(hydra.match('foobar').map(&:to_s)).to eq ['1bar.']
    end

    it "finds no match if pattern is in the middle of the word" do
      hydra = Hydra.new
      hydra.ingest ['oba.']
      expect(hydra.match('foobar')).to be_empty
    end

    it "finds no match if pattern is different before final dot" do
      hydra = Hydra.new
      hydra.ingest ['far.']
      expect(hydra.match('foobar')).to be_empty
    end

    it "matches a more complex example with dots" do
      hydra = Hydra.new
      hydra.ingest ['.foo3', '.fo1', 'fo2o1', '.bar1', '3ba2r.', 'ba1', '.ba3', 'a2r.', 'boo', '.ooba', '.oo3', 'o2o', 'ba.', 'fo.', 'big', 'bag', 'bug', '.boo', 'alsonotamatch']
      expect(hydra.match('foobar').map(&:to_s)).to eq ['a2r.', 'ba1', '3ba2r.', '.fo1', '.foo3', 'fo2o1', 'o2o']
    end
  end

  describe '#prehyphenate' do
    it "pre-hyphenates the string" do
      hydra.ingest ['fo1', 'fo2o3', 'ba1', 'ba2r']
      expect(hydra.prehyphenate('foobar').to_s).to eq "fo2o3ba2r"
    end

    it "... also with a final dot" do
      hydra.ingest ['fo1', 'o2o3', '5bar.']
      pattern = hydra.prehyphenate('foobar')
      expect(pattern.get_word).to be == "foobar"
      expect(pattern.get_digits).to be == [0, 0, 2, 5, 0, 0, 0]
    end

    it "and with an initial dot too, why not" do
      hydra.ingest ['.fo1', 'o2o3', '5ba4r']
      pattern = hydra.prehyphenate('foobar')
      expect(pattern.get_word).to be == "foobar"
      expect(pattern.get_digits).to be == [0, 0, 2, 5, 0, 4, 0]
    end
  end

  describe '#disembowel' do
    let(:device) { double(:output).as_null_object }

    it "dumps a string" do
      hydra.ingest(['apple', 'orange', 'lemon'])
      expect(PP).to receive :pp # TODO specify arguments
      hydra.disembowel(device)
    end

    it "returns the count" do
      hydra.ingest(['a', 'b', 'c', 'd', 'e'])
      expect(hydra.disembowel(device)).to eq 5
    end
  end
  # TODO ingest with dots, etc.
  # TODO Apply hydra!

  describe '#ingest_file' do # TODO Allow TeX-style comments?
    it "ingests a whole file of patterns" do
      hydra.ingest_file(File.expand_path('../../files/hyph-bg.pat.txt', __FILE__))
      expect(hydra.count).to eq 1660
    end

    it "works with the original hyphen.tex" do
      hydra.ingest_file(File.expand_path('../../files/hyphen.txt', __FILE__))
      expect(hydra.count).to eq 4447
    end
  end
end

describe Heracles do
  describe '#run' do
    it "runs a file of hyphenated words" do
      heracles = Heracles.new
      hydra = heracles.run(File.expand_path('../../files/words.hyphenated.refo', __FILE__), [1, 1, 2, 2, 1, 1, 1])
      expect(hydra.count).to be == 576
    end
  end

  describe '.organ' do
    it "generates an organ pipe-like sequence" do
      expect(Heracles.organ(3)).to be == [1, 2, 0, 3]
    end

    it "works for n = 2" do
      expect(Heracles.organ(2)).to be == [1, 0, 2]
    end

    it "works for n = 13" do
      expect(Heracles.organ(13)).to be == [6, 7, 5, 8, 4, 9, 3, 10, 2, 11, 1, 12, 0, 13]
    end
  end
end
