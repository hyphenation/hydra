require 'spec_helper'

describe CoreExt do
  describe '.max2' do
    it "returns the max of two elements" do
      expect(CoreExt::max2(2, 1)).to eq 2
    end
  end

  describe '.min2' do
    it "returns the min of two elements" do
      expect(CoreExt::min2(2, 3)).to eq 2
    end
  end
end

describe Array do
  describe '#mask' do
    it "masks an array with another array of equal length" do
      expect([1, 2, 5].mask([3, 4, 0])).to eq [3, 4, 5]
    end

    it "raises an exception if the arrays don’t have the same length" do
      expect { [1, 2, 3].mask [4, 5, 6, 7] }.to raise_exception Array::MismatchedLength
    end
  end
end

describe Pattern do
  describe '.new' do
    it "makes a pattern from a word and an array of digits" do
      expect(Pattern.new('bac', [0, 2, 1, 0])).to be_a Pattern
    end

    it "works with patterns with trailing digits" do
      pattern = Pattern.new('ab2')
      expect(pattern).to be_a Pattern
      expect(pattern.word).to eq 'ab'
      expect(pattern.digits).to eq [0, 0, 2]
    end

    it "handles initial dots correctly" do
      pattern = Pattern.new '.foo'
      expect(pattern).to be_initial # RSpec calls pattern.initial?
      expect(pattern.word).to eq 'foo'
      expect(pattern.digits).to eq [0] * 4
    end

    it "handles final dots correctly" do
      pattern = Pattern.new 'bar.'
      expect(pattern).to be_final
      expect(pattern.word).to eq 'bar'
      expect(pattern.digits).to eq [0] * 4
    end

    it "handle simultaneous initial and final dots correctly" do
      pattern = Pattern.new '.foobar.'
      expect(pattern).to be_initial
      expect(pattern).to be_final
      expect(pattern.word).to eq 'foobar'
      expect(pattern.digits).to eq [0] * 7
    end

    it "initialises the pattern with '', [0] by default" do
      pattern = Pattern.new
      expect(pattern.word).to eq ''
      expect(pattern.digits).to eq [0] # TODO Ensure digits.length = word.length + 1 always
    end

    it "normalises everything to lowercase" do
      pattern = Pattern.new 'cA2b'
      expect(pattern.word).to eq 'cab'
    end

    it "... even non-ASCII characters" do
      pattern = Pattern.new 'Öl', [1, 2, 3]
      expect(pattern.word).to eq 'öl'
    end

    it "needs some work for Turkish" do
      pattern = Pattern.new 'İSTANBUL'
      expect(pattern.word).to eq 'i̇stanbul' # FIXME That’s NFD!
    end
  end

  describe '.dummy' do
    it "creates a dummy pattern from a word" do
      pattern = Pattern.dummy 'abc'
      expect(pattern.word).to eq 'abc'
      expect(pattern.digits).to eq [0, 0, 0, 0]
    end
  end

  describe '.simple' do
    it "returns a simple pattern" do
      pattern = Pattern.simple 'abc', 2, 1
      expect(pattern.word).to eq 'abc'
      expect(pattern.digits).to be == [0, 0, 1, 0]
    end
  end

  describe '#cursor' do
    it "returns the cursor" do
      pattern = Pattern.dummy 'abc'
      pattern.instance_variable_set :@cursor, 3
      expect(pattern.cursor).to be == 3
    end

    it "is -1 initially for patterns with initial dots" do
      pattern = Pattern.dummy '.foo'
      expect(pattern.cursor).to eq -1
    end

    it "works with dual-dotted patterns too" do
      pattern = Pattern.dummy '.foobar.'
      expect(pattern.cursor).to eq -1
    end
  end

  describe '#anchor' do
    it "returns the anchor" do
      pattern = Pattern.new 'foo3'
      pattern.instance_variable_set :@anchor, 4
      expect(pattern.anchor).to be == 4
    end
  end

  describe '#setanchor' do
    it "sets the anchor" do
      pattern = Pattern.new '5bar'
      pattern.setanchor(5)
      expect(pattern.instance_variable_get :@anchor).to be == 5
    end
  end

  describe '#shift' do
    it "shifts the cursor by one" do
      pattern = Pattern.new
      expect { pattern.shift }.to change(pattern, :cursor).by(1)
    end

    it "returns the pattern" do
      pattern = Pattern.new
      expect(pattern.shift).to be_a Pattern
    end

    it "takes an optional number of repetitions" do
      pattern = Pattern.new('foo1bar')
      expect(pattern.shift(3).cursor).to eq 3
    end
  end

  describe '#shift!' do
    it "just shifts" do
      pattern = Pattern.new 'q8u1u2x'
      pattern.shift!
      expect(pattern.cursor).to eq 1
    end

    it "also shifts the cursor" do
      pattern = Pattern.new
      expect { pattern.shift }.to change(pattern, :cursor).by(1)
    end

    it "takes an optional number as argument" do
      pattern = Pattern.new('baz1quux')
      expect { pattern.shift! 2 }.to change(pattern, :cursor).by 2
    end
  end

  describe '#reset' do
    it "resets the cursor" do
      pattern = Pattern.new
      pattern.shift(2)
      pattern.reset
      expect(pattern.cursor).to eq 0
    end

    it "resets the cursor too" do
      pattern = Pattern.new
      pattern.shift(2)
      pattern.reset
      expect(pattern.cursor).to be == 0
    end

    it "takes an optional argument" do
      pattern = Pattern.new
      pattern.shift(3)
      pattern.reset(2)
      expect(pattern.cursor).to be == 2
      expect(pattern.cursor).to be == 2
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

    it "takes the curent cursor into account" do
      pattern = Pattern.new('foo9ba8r')
      pattern.shift(3)
      expect(pattern.digit(2)).to eq 8
    end
  end

  describe '#last?' do
    it "tells when we’re on the last character of the pattern" do
      pattern = Pattern.new '1f2i4n3'
      pattern.shift(2)
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
      pattern.shift(3)
      expect(pattern.end?).to be_truthy
    end

    it "returns false otherwise" do
      pattern = Pattern.new 'Schluß'
      pattern.shift(3)
      expect(pattern.end?).to be_falsey
    end

    it "works with dotted patterns" do
      pattern = Pattern.new '.конец.'
      pattern.reset(5)
      expect(pattern.end?).to be_falsey
      pattern.shift
      expect(pattern.end?).to be_truthy
    end

    it "also with a simpler one" do
      pattern = Pattern.new 'loppu.'
      pattern.reset(5)
      expect(pattern.end?).to be_falsey
      pattern.shift
      expect(pattern.end?).to be_truthy
    end
  end

  describe '#currletter' do
    it "returns the current letter" do
      pattern = Pattern.new 'a1n2a1n2a'
      pattern.shift(3)
      expect(pattern.currletter).to eq 'n'
    end

    it "returns . at the beginning of a dotted pattern" do
      pattern = Pattern.new '.foo'
      expect(pattern.currletter).to eq '.'
    end

    it "returns . at the end of a dotted pattern" do
      pattern = Pattern.new 'bar.'
      pattern.shift(3)
      expect(pattern.currletter).to eq '.'
    end

    it "returns . at both the beginning and the end of a dotted pattern" do
      pattern = Pattern.new '.foobar.'
      expect(pattern.currletter).to eq '.'
      pattern.shift(7)
      expect(pattern.currletter).to eq '.'
    end

    it "handles case correctly" do
      pattern = Pattern.new 'aB'
      pattern.shift
      expect(pattern.currletter).to eq 'b'
    end
  end

  describe '#currdigit' do
    it "returns the current digit" do
      pattern = Pattern.new '3foo'
      expect(pattern.currdigit).to eq 3
    end
  end

  describe '#to_s' do
    it "returns a string representation of the pattern" do
      pattern = Pattern.new('bac', [0, 2, 1, 0])
      expect(pattern.to_s).to eq "b2a1c"
    end

    it "works with initial patterns too" do
      pattern = Pattern.new 'foobar', [0, 0, 0, 3, 0, 0, 0]
      pattern.initial!
      expect(pattern.to_s).to eq '.foo3bar'
    end

    it "also works with final patterns" do
      pattern = Pattern.new 'foobar', [0, 0, 0, 7, 0, 0, 0]
      pattern.final!
      expect(pattern.to_s).to eq 'foo7bar.'
    end

    it "works when used with a dotted pattern as first argument" do
      pattern = Pattern.new '.foo'
      expect(pattern.initial).to be_truthy
      expect(pattern.length).to eq 3
      expect(pattern.to_s).to eq '.foo'
    end

    it "works when used with a finally dotted pattern as first argument" do
      pattern = Pattern.new 'bar.'
      expect(pattern.final).to be_truthy
      expect(pattern.length).to eq 3
      expect(pattern.to_s).to eq 'bar.'
    end

    it "works when used with a single-argument pattern with both initial and final dot" do
      pattern = Pattern.new '.foobar.'
      expect(pattern.initial).to be_truthy
      expect(pattern.final).to be_truthy
      expect(pattern.length).to eq 6
      expect(pattern.to_s).to eq '.foobar.'
    end
  end

  describe '#digits' do
    it "extracts the digits from a pattern" do
      pattern = Pattern.new('bac', [0, 2, 1, 0])
      expect(pattern.digits).to eq [0, 2, 1, 0]
    end
  end

  describe '#word' do # For completeness!
    it "extracts the word from a pattern" do
      pattern = Pattern.new('bac', [0, 2, 1, 0])
      expect(pattern.word).to eq "bac"
    end
  end

  describe '#grow' do
    it "grows a letter.  I know it doesn’t make much sense, just give me a break" do
      pattern = Pattern.new 'abc'
      pattern.grow('d')
      expect(pattern.word).to eq 'abcd'
    end

    it "returns the pattern" do
      pattern = Pattern.new
      expect(pattern.grow('taller')).to be_a Pattern # Adding more than one letter: not recommended!
    end

    it "raises an exception if pattern is frozen" do
      pattern = Pattern.new 'def'
      pattern.freeze [0, 1, 2, 3]
      expect { pattern.grow('g') }.to raise_exception Hydra::FrozenPattern
    end
  end

  describe '#grow!' do
    it "just grows" do
      pattern = Pattern.new 'f'
      pattern.grow!('g')
      expect(pattern.word.length).to eq 2
    end

    it "raises and exception if pattern is frozen" do
      pattern = Pattern.new 'ijk'
      pattern.freeze [4, 6, 7, 8]
      expect { pattern.grow 'l' }.to raise_exception Hydra::FrozenPattern
    end
  end

  describe '#fork' do
    it "forks the pattern on a letter" do
      pattern = Pattern.new
      pattern.grow 'f'; pattern.grow 'o'; pattern.grow 'o'
      expect(pattern.fork('b').word).to eq "foob"
    end

    it "returns a new pattern" do
      pattern = Pattern.new
      pattern2 = pattern.fork('b')
      expect(pattern2.object_id).to_not eq pattern.object_id
    end

    it "copies the initial state of the pattern" do
      pattern = Pattern.new.initial
      copy = pattern.fork('a')
      expect(copy.initial?).to be_truthy
    end

    it "marks the new pattern as non-initial if the original one was" do
      pattern = Pattern.new
      copy = pattern.fork('b')
      expect(copy.initial?).to be_falsey
    end
  end

  describe '#copy' do
    it "returns a new pattern with the same word" do
      pattern = Pattern.new('fo2o')
      expect(pattern.copy).to be_a Pattern
    end

    it "sets the same digits" do
      pattern = Pattern.new('ba2r')
      new_pattern = pattern.copy
      expect(new_pattern.digits).to eq [0, 0, 2, 0]
    end

    it "creates a new array so it doesn’t overlap" do
      pattern = Pattern.new('foo3')
      new_pattern = pattern.copy
      new_pattern.freeze([0, 0, 0, 5])
      expect(pattern.to_s).to eq "foo3"
      expect(new_pattern.to_s).to eq "foo5"
    end
  end

  describe '#freeze' do
    it "freezes the pattern and sets the digits" do
      pattern = Pattern.new('foo5bar')
      pattern.freeze [1, 2, 3, 4, 5, 6, 7]
      expect(pattern.digits).to eq [1, 2, 3, 4, 5, 6, 7]
    end

    it "returns the pattern" do
      pattern = Pattern.new('ba6z5quux')
      expect(pattern.freeze [4, 5, 6, 7, 8, 9, 0, 0]).to be_a Pattern
    end

    it "actually freezes" do
      pattern = Pattern.new('foo5bar')
      pattern.freeze [0, 1, 2, 3, 4, 5, 6]
      expect(pattern.instance_variable_get :@frozen).to be_truthy
    end

    it "works with initial dots" do
      pattern = Pattern.new('.foo')
      pattern.freeze [4, 3, 2, 1]
      expect(pattern.to_s).to eq ".4f3o2o1"
    end

    it "works with final dots" do
      pattern = Pattern.new('bar.')
      pattern.freeze [1, 2, 3, 4]
      expect(pattern.to_s).to eq "1b2a3r4."
    end

    it "works with both initial and final dots" do
      pattern = Pattern.new('.foobar.')
      pattern.freeze([4, 3, 2, 1, 2, 3, 4])
      expect(pattern.to_s).to eq ".4f3o2o1b2a3r4."
    end

    it "takes an optional depth argument" do
      # Imagining a “fo1o2” with cursor = 2
      pattern = Pattern.new('o')
      pattern.freeze([0, 0, 1, 2], 2)
      expect(pattern.to_s).to eq '1o2' # Will return ‘o12’ otherwise
    end
  end

  describe '#freeze!' do
    it "just sets the digits" do
      pattern = Pattern.new('1ing')
      expect(pattern.freeze! [4, 5, 6, 0]).to eq [4, 5, 6, 0]
    end

    it "actually freezes" do
      pattern = Pattern.new('t1t2ing')
      pattern.freeze! [0, 1, 2, 0, 0, 0]
      expect(pattern.instance_variable_get :@frozen).to be_truthy
    end
  end

  describe '#frozen?' do
    it "says whether the pattern is frozen" do
      pattern = Pattern.new 'abc'
      pattern.freeze! [0, 1, 2, 3]
      expect(pattern.frozen?).to be_truthy
    end

    it "returns nil on initialisation" do
      pattern = Pattern.new
      expect(pattern.frozen?).to be_falsey
    end
  end

  describe '#word_so_far' do # TODO word_at?
    it "returns the word up to the current cursor" do
      pattern = Pattern.dummy 'sandrigham'
      pattern.shift(4)
      expect(pattern.word_so_far).to eq 'sand'
    end
  end

  describe '#word_to' do
    it "returns the word from the current cursor with length n" do
      pattern = Pattern.dummy 'maskedball'
      pattern.shift(2)
      expect(pattern.word_to(6)).to eq 'skedba'
    end

    it "optionally crosses boundaries, starting at '.'" do
      pattern = Pattern.dummy 'balloinmaschera'
      pattern.shift(-1)
      expect(pattern.word_to(5)).to eq '.ball'
    end

    it "optionally crosses boundaries, stopping at '.'" do
      pattern = Pattern.dummy 'daverdi'
      pattern.shift(2)
      expect(pattern.word_to(6)).to eq 'verdi.'
    end

    it "crosses boundaries at both ends" do
      pattern = Pattern.dummy 'unballo'
      pattern.shift(-1)
      expect(pattern.word_to(9)).to eq '.unballo.'
    end
  end

  describe '#digits_to' do # TODO #digits_so_far as well
    it "returns the digits from the current cursor to length n" do
      pattern = Pattern.new 'po2l3ish9en4g3lish'
      pattern.shift(6)
      expect(pattern.digits_to(4)).to be == [9, 0, 4, 3, 0]
    end
  end

  describe '#mask(array)' do
    it "masks the pattern’s digits with an array" do
      pattern = Pattern.dummy 'supercal'
      pattern.shift(3)
      pattern.mask [0, 0, 0, 3]
      expect(pattern.to_s).to eq 'sup3ercal'
    end

    it "applies several masks successively" do
      pattern = Pattern.dummy 'supercal'
      pattern.shift(2)
      pattern.mask [0, 0, 1] # Potentially coming from a "su1"
      pattern.shift
      pattern.mask [0, 0, 2, 3] # "su2p3"
      pattern.shift(4)
      pattern.mask [0, 1, 2, 1] # "r1c2a"
      pattern.shift
      pattern.mask [0, 2, 3] # "a2l3"
      expect(pattern.to_s).to eq "su2p3er1c2a2l3"
    end
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

    it "compares the digits if the underlying words are the same" do
      expect(Pattern.new('a1bc').<=>(Pattern.new('a2bc'))).to eq -1
    end

    it "returns 0 if the underlying words and digits are the same" do
      expect(Pattern.new('abc3').<=>(Pattern.new('abc3'))).to eq 0
    end
  end

  describe '#initial!' do
    it "marks a pattern as initial" do
      pattern = Pattern.new('aaabbb')
      pattern.initial!
      expect(pattern.initial?).to be_truthy
      expect(pattern.digits.length).to eq 7
    end
  end

  describe '#final!' do
    it "marks a pattern as final" do
      pattern = Pattern.new('cc')
      pattern.final!
      expect(pattern.final?).to be_truthy
      expect(pattern.digits.length).to eq 3
    end
  end

  describe '#initial' do
    it "marks a pattern as initial" do
      pattern = Pattern.new('foo3')
      pattern.initial
      expect(pattern.initial?).to be_truthy
      expect(pattern.digits.length).to eq 4
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
      expect(pattern.digits.length).to eq 4
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

  describe '#inc_good_count' do
    it "increases the good count by 1" do
      pattern = Pattern.new
      pattern.inc_good_count
      expect(pattern.instance_variable_get :@good_count).to be == 1
    end
  end

  describe '#good_count' do
    it "returns the good count" do
      pattern = Pattern.new
      4.times { pattern.inc_good_count }
      expect(pattern.good_count).to be == 4
    end
  end

  describe '#inc_bad_count' do
    it "increases the bad count by 1" do
      pattern = Pattern.new
      pattern.inc_bad_count
      expect(pattern.instance_variable_get :@bad_count).to be == 1
    end
  end

  describe '#bad_count' do
    it "returns the bad count" do
      pattern = Pattern.new
      2.times { pattern.inc_bad_count }
      expect(pattern.bad_count).to be == 2
    end

    it "works independently of #good_count" do
      pattern = Pattern.new
      2.times { pattern.inc_good_count }
      pattern.inc_bad_count
      expect(pattern.good_count).to be == 2
      expect(pattern.bad_count).to be == 1
    end
  end

  describe '#add_source' do
    it "adds one source for the pattern being inserted" do
      hydra = Hydra.new
      hydra.add_source [242, 3]
      expect(hydra.instance_variable_get :@sources).to eq [[242, 3]]
    end
  end

  describe '#sources' do
    it "returns the sources for the current hydra node" do
      hydra = Hydra.new
      hydra.add_source [10, 3]
      hydra.add_source [15, 5]
      hydra.add_source [20, 7]
      expect(hydra.sources).to eq [[10, 3], [15, 5], [20, 7]]
    end
  end

  describe '#showhyphens' do
    it "shows the current hyphens" do
      pattern = Pattern.new 'fo2o3bar5qu6ux'
      expect(pattern.showhyphens).to eq 'foo-bar-quux'
    end

    it "takes care of edge cases" do
      pattern = Pattern.new '1foo'
      expect(pattern.showhyphens).to eq 'foo'
    end

    it "correctly handles the other edge case" do
      pattern = Pattern.new 'bar3'
      expect(pattern.showhyphens).to eq 'bar'
    end

    it "optionally takes lefthyphenmin and righthyphenmin" do
      pattern = Pattern.new 'f1oo3ba1r'
      expect(pattern.showhyphens(2, 2)).to eq 'foo-bar'
    end

    it "behaves correctly at the border" do
      pattern = Pattern.new 'fo1ba'
      expect(pattern.showhyphens(2, 2)).to eq 'fo-ba'
    end
  end
end

describe Lemma do
  describe '.new' do
    it "creates a new dictionary word" do
      lemma = Lemma.new
      expect(lemma).to be_a Lemma # FIXME Should test the superclass eventually.  Name?
    end

    it "sets all digits to 0 initially" do
      lemma = Lemma.new 'foo-bar'
      expect(lemma.digits).to be == [0] * 7 # FIXME Refactor rename digits
    end

    it "sets all breakpoints to :no initially" do
      lemma = Lemma.new 'foobar'
      expect(lemma.instance_variable_get :@breakpoints).to be == [:no] * 7
    end

    it "sets actual breakpoints to :is" do
      lemma = Lemma.new 'foo-bar'
      expect(lemma.instance_variable_get :@breakpoints).to be == [:no, :no, :no, :is, :no, :no, :no]
    end
  end

  describe '#break' do
    it "returns the breakpoint at the given position" do
      lemma = Lemma.new 'foo-bar'
      expect(lemma.break(3)).to be == :is
    end

    it "takes the cursor position into account" do
      lemma = Lemma.new 'foo-bar'
      lemma.shift(2)
      expect(lemma.break(1)).to be == :is
    end
  end

  describe '#showhyphens' do
    it "returns the actual hyphens" do
      lemma = Lemma.new 'foo-bar'
      expect(lemma.showhyphens).to be == 'foo-bar'
    end

    # TODO Figure out what to do with the other “dot” types
  end
end

describe Hydra do
  let(:hydra)  { Hydra.new }
  let(:complex_hydra) { Hydra.new ['.foo3', '.fo1', 'fo2o1', '.bar1', '3ba2r.', 'ba1', '.ba3', 'a2r.', 'boo', '.ooba', '.oo3', 'o2o', 'ba.', 'fo.', 'big', 'bag', 'bug', '.boo', 'alsonotamatch'] }
  let(:povsod_patterns) { ["o1d", "o1v", "po1", ".po4v5s"] } # From Matjaž Vrečko’s Slovenian patterns

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
      expect(hydra.heads).to be == 4
    end

    it "optionally sets the atlas vertebra that supports the head" do
      hydra = Hydra.new([], :lax, 'a')
      expect(hydra.instance_variable_get :@atlas).to be == 'a'
    end

    it "optionally takes a parameter hash" do
      hydra = Hydra.new([], :lax, 'a', 'hyphenmins' => { 'typesetting' => { 'left' => 1, 'right' => 2 } })
      expect(hydra.lefthyphenmin).to eq 1
      expect(hydra.righthyphenmin).to eq 2
    end

    it "doesn’t crash if the parameter argument is not a hash" do
      expect { Hydra.new [], :lax, 'z', "useless metadata" }.not_to raise_exception
    end
  end

  describe '#clear' do
    it "clears the hydra" do
      hydra = Hydra.new ['a', 'b', 'c', 'd', 'e']
      hydra.clear
      expect(hydra.heads).to eq 0
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

  describe '#showhyphens' do
    it "shows the hyphenation points" do
      hydra = Hydra.new ['fo1', 'fo2o3', 'qu1', 'qu2u3', 'quu4x', 'bar3']
      expect(hydra.showhyphens('foobarquux')).to eq 'foo-bar-quux'
    end

    it "takes hyphenmins into account" do
      hydra = Hydra.new ['o1d', 'o1v', 'po1', '.po4v5s']
      hydra.setlefthyphenmin(2)
      hydra.setrighthyphenmin(2)
      expect(hydra.showhyphens('povsod')).to eq 'pov-sod'
    end

    it "handles case correctly" do
      hydra = Hydra.new 'Öl1'
      hydra.setrighthyphenmin 2
      expect(hydra.showhyphens('ölet')).to eq 'öl-et'
      expect(hydra.showhyphens('Völker')).to eq 'völ-ker' # FIXME Will need more work!
    end

    it "works correctly on uppercase input" do
      hydra = Hydra.new 'öl1'
      hydra.setrighthyphenmin 2
      expect(hydra.showhyphens('Ölet')).to eq 'öl-et' # FIXME See above
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
      deep_water = hydra.read('abv')
      expect(deep_water.depth).to be == 3
    end

    it "is zero for newly created hydrae" do
      hydra = Hydra.new
      expect(hydra.depth).to be == 0
    end
  end

  # The star is the multiple spinous process at the base of the necks.
  # This is a well-known fact of hydra anatomy.
  describe '#star' do
    it "goes back to the base of the hydra" do
      hydra = Hydra.new 'foo'
      fooneck = hydra.read 'foo'
      expect(fooneck.star).to eq hydra
    end
  end

  # Vertebra prominens is the base of the neck (C7)
  describe '#prominens' do
    it "returns the first letter of the current neck" do
      hydra = Hydra.new ['abc', 'abd', 'abe', 'fgh', 'jklm']
      abneck = hydra.read('abe')
      expect(abneck.prominens).to eq 'a'
    end
  end

  describe '#ensure_neck' do
    it "ensures there is a neck" do
      hydra.ensure_neck('a')
      expect(hydra.getneck('a')).to be_a Hydra
    end
  end

  describe '#setatlas' do
    it "grows a neck with a head" do
      hydra.setatlas('a', [1])
      expect(hydra.heads).to eq 1
    end

    it "has a correctly labelled neck" do
      hydra.setatlas('b', [2])
      expect(hydra.getneck('b')).to be_a Hydra
    end
  end

  describe '#getneck' do
    it "returns the neck" do
      hydra.ingest 'abc'
      expect(hydra.getneck('a')).to be_a Hydra
    end

    it "returns nil for non-existing necks" do
      hydra.ingest 'def'
      expect(hydra.getneck('g')).to be_nil
    end
  end

  describe '#sethead' do
    it "sets the head" do
      hydra.sethead [1, 2, 3]
    end

    it "returns the hydra" do
      expect(hydra.sethead([1, 2, 3])).to eq hydra
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
      expect(hydra.heads).to eq 2
    end

    it "resets the good and bad counts" do
      hydra.ingest ['abc', 'def', 'klm']
      neck = hydra.read('abc')
      3.times { neck.inc_good_count }
      2.times { neck.inc_bad_count }
      neck.chophead
      expect(neck.good_count).to eq 0
      expect(neck.bad_count).to eq 0
    end

    it "clears the sources" do
      hydra.ingest ['bac', 'def']
      neck = hydra.read('bac')
      neck.add_source(foo: 'bar', baz: 'quux')
      neck.chophead
      expect(neck.sources).to be_nil
    end
  end

  describe '#chopneck' do
    it "chops off a neck of the hydra" do
      hydra = Hydra.new ['abc', 'def']
      hydra.chopneck('a')
      expect(hydra.letters).to be == ['d']
    end
  end

  describe '#good_count' do
    it "returns the good count" do
      hydra = Hydra.new ['abc', 'def', 'ghi']
      3.times { hydra.read('abc').inc_good_count }
      expect(hydra.read('abc').good_count).to be == 3
    end

    it "returns 0 for new heads" do
      hydra = Hydra.new 'g'
      gneck = hydra.getneck('g')
      expect(gneck.good_count).to be ==  0
    end
  end

  describe '#inc_good_count' do
    it "increases the good count" do
      hydra = Hydra.new 'f'
      fneck = hydra.getneck('f')
      fneck.inc_good_count
      expect(fneck.instance_variable_get :@good_count).to be == 1
    end
  end

  describe '#bad_count' do
    it "returns the bad count" do
      hydra = Hydra.new 'ooo'
      3.times { hydra.read('ooo').inc_bad_count }
      expect(hydra.read('ooo').bad_count).to be == 3
    end

    it "returns 0 for new heads" do
      hydra = Hydra.new 'b'
      bneck = hydra.getneck 'b'
      expect(bneck.bad_count).to be == 0
    end
  end

  describe '#inc_bad_count' do
    it "increases the bad count" do
      hydra = Hydra.new 'f'
      fneck = hydra.getneck 'f'
      fneck.inc_bad_count
      expect(fneck.bad_count).to be == 1
    end

    it "works independently of #inc_good_count" do
      hydra = Hydra.new
      4.times { hydra.inc_good_count }
      2.times { hydra.inc_bad_count }
      expect(hydra.good_count).to be == 4
      expect(hydra.bad_count).to be == 2
    end
  end

  describe '#clear_good_and_bad_counts' do
    it "resets the good and bad counts" do
      hydra = Hydra.new
      3.times { hydra.inc_good_count }
      2.times { hydra.inc_bad_count }
      hydra.clear_good_and_bad_counts
      expect(hydra.good_count).to eq 0
      expect(hydra.bad_count).to eq 0
    end
  end

  describe '#letters' do
    it "returns the letters starting the different necks" do
      hydra.ingest ['a', 'b', 'c', 'cd', 'cde']
      expect(hydra.letters).to eq ['a', 'b', 'c']
    end
  end

  describe '#heads' do
    it "returns the number of heads (digit arrays)" do
      hydra.ingest(['a', 'b', 'c'])
      expect(hydra.heads).to eq 3
    end
  end

  describe '#knuckles' do
    it "returns the number of knuckles (nodes with or without heads)" do
      hydra.ingest(['abc', 'd', 'e', 'f'])
      expect(hydra.knuckles).to eq 7
    end
  end

  describe '#each' do
    it "iterates over the hydra" do
      hydra = Hydra.new ['α', 'β', 'γ', 'δ']
      n = 0
      hydra.each { n += 1 }
      expect(n).to be == 4
    end

    it "can work as “digest”" do
      initial_words = ['abc', 'def', 'ghij', 'klm']
      hydra = Hydra.new initial_words
      words = []
      hydra.each { |h| words << h.pattern.to_s }
      words.sort!
      expect(words).to be == initial_words
    end
  end

  describe '#map' do
    it "works as an enumerable" do
      hydra = Hydra.new ['bac', 'def', 'gijk']
      expect(hydra.map { |head| head.pattern.to_s.upcase }).to eq ['BAC', 'DEF', 'GIJK']
    end
  end

  describe '#select' do
    it "selects heads from a hydra" do
      hydra = Hydra.new ['abc', 'abz', 'def', 'defz', 'xyz']
      zheads = hydra.select { |head| head.pattern.to_s =~ /z$/ }
      expect(zheads.map(&:pattern).map(&:to_s)).to eq ['abz', 'defz', 'xyz']
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

  describe '.isbreak' do
    it "says - is a nobreak" do
      expect(Hydra.isbreak('-')).to be == :is
    end

    it "says * is a found break" do
      expect(Hydra.isbreak('*')).to be == :found
    end

    it "says . is an error break" do
      expect(Hydra.isbreak('.')).to be == :err
    end
  end

  describe '#ingest' do
    it "works with a single word" do
      hydra.ingest('bac')
      expect(hydra.heads).to eq 1
    end

    it "works with an array of words" do
      hydra.ingest(['democrat', 'democracy', 'democratic'])
      expect(hydra.heads).to eq 3
    end

    it "works with an actual pattern" do
      hydra.ingest('1a2b3c4')
      expect(hydra.heads).to eq 1
    end

    it "works with patterns that are prefix of each other" do
      hydra.ingest ['ba1', 'ba2r']
      expect(hydra.digest).to eq ['ba1', 'ba2r']
    end

    # TODO Specify that in non-strict modes higher-values heads take precedence
    it "really works with patterns that are prefix of each other" do
      hydra.ingest ['fo1', 'o2o', 'o1b', 'ba1', 'ba2r']
      hydra.ingest ['ba2', 'of3', 'mo2o']
      expect(hydra.digest).to eq ['ba2', 'ba2r', 'fo1', 'mo2o', 'o1b', 'of3', 'o2o']
    end

    it "uses higer values to mask lower ones" do
      hydra = Hydra.new '1ba'
      hydra.ingest 'b2a'
      expect(hydra.digest).to eq ['1b2a']
    end

    # TODO More tests with conflicting patterns

    it "works with patterns that have dots at both end" do
      hydra = Hydra.new '.bac.'
      expect(hydra.read('.bac').letters).to eq ['.']
    end

    it "... and with a dot only at one end" do
      hydra = Hydra.new 'zyx.'
      expect(hydra.read('zyx').letters).to eq ['.']
    end

    it "returns the tip of the hydra just inserted" do
      hydra = Hydra.new ['abc', 'def', 'ghij']
      node = hydra.ingest 'klm'
      expect(node.pattern.to_s).to eq 'klm'
    end

    it "warns about conflicting patterns in strict mode" do
      hydra = Hydra.new ['a1b', 'b1c'], :strict
      expect { hydra.ingest('a2b') }.to raise_error Hydra::ConflictingPattern
    end

    it "gives a helpful message in case of conflicting patterns" do
      hydra = Hydra.new ['a1b', 'b1c'], :strict
      begin
        hydra.ingest('a2b')
      rescue Hydra::ConflictingPattern => error
        expect(error.message).to eq "Pattern a2b conflicts with earlier pattern a1b"
      end
    end

    it "stores the conflicting pattern together with the original one, just in ecase" do
      hydra = Hydra.new ['a1b', 'b1c']
      hydra.ingest 'a2b'
      expect(hydra.conflicts).to eq [['a1b', 'a2b']]
    end
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

    it "takes dots into account correctly" do
      hydra = Hydra.new ['.abc', 'def', 'gijk']
      expect(hydra.digest).to eq ['.abc', 'def', 'gijk']
    end

    it "takes final dots into account too" do
      hydra = Hydra.new ['klm', 'pqr', 'xyz.']
      expect(hydra.digest).to eq ['klm', 'pqr', 'xyz.']
    end

    it "works with both initial and final dots" do
      hydra = Hydra.new ['.abc', 'def', 'gijk', 'xyz.', '.klm.']
      expect(hydra.digest).to eq ['.abc', '.klm.', 'def', 'gijk', 'xyz.']
    end

    it "works from a hydra with a non-zero depth" do
      hydra = Hydra.new ['1a2b3c4d5']
      abcneck = hydra.read('abc')
      expect(abcneck.digest).to eq ['4d5']
    end

    it "works with initial and final dots, and the cursor mid-way" do
      hydra = Hydra.new '.1a2b3c4d5'
      dotabcneck = hydra.read('.abc')
      expect(dotabcneck.digest).to eq ['4d5']
    end

    it "works on a more complex example" do
      hydra = Hydra.new ['.nad5h4', '.na5d4nes.', '.nad5p4', '.na5d4p4.', '.nad5d4ŕ4.', '.na5d4robno.']
      dotnadhydra = hydra.read('.nad')
      dig = ['5d4ŕ4.', '5h4', '4nes.', '5p4', '4p4.', '4robno.']
      expect(hydra.digest.map { |s| s.gsub(/^\.na\d?d/, '') }).to eq dig
      dotnadhhydra = dotnadhydra.getneck('h')
      expect(dotnadhhydra.digest).to eq ['4']
      expect(dotnadhydra.digest).to eq dig
    end
  end

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
      expect(hydra.heads).to eq 0
    end

    it "deletes one full-fledged pattern" do
      hydra.ingest ['b2a1c']
      hydra.delete('b2a1c')
      expect(hydra.heads).to eq 0
    end

    it "raises" do
      hydra.strict_mode
      hydra.ingest 'b2a1c'
      expect { hydra.delete 'ba4c3' }.to raise_exception Hydra::ConflictingPattern
    end

    it "also deletes good and bad counts" do
      hydra = Hydra.new ['abc', 'def']
      cneck = hydra.read('abc')
      cneck.inc_good_count
      hydra.delete "abc"
      expect(cneck.good_count).to be == 0
    end

    it "deletes the whole neck if it doesn’t have any other descendants" do
      hydra = Hydra.new ['abc', 'abcd', 'def', 'ghi']
      hydra.delete "def"
      expect(hydra.getneck('d')).to be_nil
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
      expect(hydra.heads).to eq 1
    end

    it "works as #delete" do
      hydra.ingest ['b2a1c']
      pattern = Pattern.dummy 'bac'
      hydra.regest pattern, :delete
      expect(hydra.heads).to eq 0
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
      hydra = Hydra.new ['.foo']
      expect(hydra.match('foobar').map(&:to_s)).to eq ['.foo'] # TODO Matcher for that
    end

    it "matches a pattern with an initial dot and actual digits" do
      hydra = Hydra.new '.foo1'
      expect(hydra.match('foobar').map(&:to_s)).to eq ['.foo1']
    end

    it "finds no match if pattern is in the middle of the word" do
      hydra = Hydra.new ['.oob']
      expect(hydra.match('foobar')).to be_empty
    end

    it "finds no match if pattern is different after initial dot" do
      hydra = Hydra.new ['.boo']
      expect(hydra.match('foobar')).to be_empty
    end

    it "matches a closing dot" do
      hydra = Hydra.new ['bar.']
      expect(hydra.match('foobar').map(&:to_s)).to eq ['bar.']
    end

    # TODO Stupid pattern bar1.?

    it "matches a final do with actual digits in the pattern" do
      hydra = Hydra.new '1bar.'
      expect(hydra.match('foobar').map(&:to_s)).to eq ['1bar.']
    end

    it "finds no match if pattern is in the middle of the word" do
      hydra = Hydra.new ['oba.']
      expect(hydra.match('foobar')).to be_empty
    end

    it "finds no match if pattern is different before final dot" do
      hydra = Hydra.new ['far.']
      expect(hydra.match('foobar')).to be_empty
    end

    it "matches a more complex example with dots" do
      expect(complex_hydra.match('foobar').map(&:to_s).sort).to eq ['.fo1', '.foo3', '3ba2r.', 'a2r.', 'ba1', 'fo2o1', 'o2o']
    end

    it "... also with a final dot" do
      hydra.ingest ['fo1', 'o2o3', '5bar.']
      pattern = hydra.prehyphenate('foobar')
      expect(pattern.word).to be == "foobar"
      expect(pattern.digits).to be == [0, 0, 2, 5, 0, 0, 0]
    end

    it "and with an initial dot too, why not" do
      hydra.ingest ['.fo1', 'o2o3', '5ba4r']
      pattern = hydra.prehyphenate('foobar')
      expect(pattern.word).to be == "foobar"
      expect(pattern.digits).to be == [0, 0, 2, 5, 0, 4, 0]
    end

    it "sets the anchor correctly" do
      hydra = Hydra.new ['oba']
      match = hydra.match('foobar').first
      expect(match.anchor).to be == 2
    end

    it "... also with initial dot" do
      hydra = Hydra.new '.foo'
      match = hydra.match('foobar').first
      expect(match.anchor).to be == 0
    end

    it "... and final dots" do
      hydra = Hydra.new 'bar.'
      match = hydra.match('foobar').first
      expect(match.anchor).to be == 3
    end

    it "... and dots at both ends" do
      hydra = Hydra.new '.foo.'
      match = hydra.match('foo').first
      expect(match.anchor).to be == 0
    end

    it "works correctly with dotted patterns" do
      hydra = Hydra.new povsod_patterns
      expect(hydra.match('povsod').map(&:to_s)).to eq povsod_patterns
    end
  end

  describe '#prehyphenate' do
    it "pre-hyphenates the string" do
      hydra.ingest ['fo1', 'fo2o3', 'ba1', 'ba2r']
      expect(hydra.prehyphenate('foobar').to_s).to eq "fo2o3ba2r"
    end

    it 'works with dotted patterns' do
      hydra = Hydra.new povsod_patterns
      pattern = hydra.prehyphenate('povsod')
      expect(pattern.to_s).to eq 'po4v5so1d'
    end
  end

  describe '#hydrae' do
    it "returns matches as hydrae" do
      matches = complex_hydra.hydrae('foobar')
      expect(matches.map(&:pattern).map(&:to_s).sort).to eq ['.fo1', '.foo3', '3ba2r.', 'a2r.', 'ba1', 'fo2o1', 'o2o']
    end

    it "sets the index correctly ..." do
      hydra = Hydra.new ['a1b', 'c1de', 'fg1hi']
      matches = hydra.hydrae('xxabcdefghixxx')
      expect(matches.count).to be == 3
      expect(matches[0].index).to be == 2
      expect(matches[1].index).to be == 4
      expect(matches[2].index).to be == 7
    end

    it "... even with initial dots ..." do
      hydra = Hydra.new '.ab1'
      matches = hydra.hydrae('abcdxxx')
      expect(matches.count).to be == 1
      expect(matches.first.index).to be == 0
    end

    it "... and trailing ones." do
      hydra = Hydra.new 'a1bcd.'
      matches = hydra.hydrae('xxabcd')
      expect(matches.count).to be == 1
      expect(matches.first.index).to be == 2
    end

    it "And even at both ends :-)" do
      hydra = Hydra.new '.ab1cde.'
      matches = hydra.hydrae('abcde')
      expect(matches.count).to be == 1
      expect(matches.first.index).to be == 0
    end
  end

  describe '#index' do
    it "returns the current index" do
      hydra = Hydra.new
      3.times { hydra.shift }
      expect(hydra.index).to be == 3
    end

    it "is 0 at initialisation" do
      hydra = Hydra.new
      expect(hydra.index).to be == 0
    end
  end

  describe '#shift' do
    it "shifts the index by one" do
      expect { hydra.shift }.to change(hydra, :index).by(1)
    end
  end

  describe '#currdigit' do
    it "returns the digit at the current index position" do
      hydra = Hydra.new 'ab3c'
      chydra = hydra.read('abc')
      2.times { chydra.shift }
      expect(chydra.currdigit).to be == 3
    end

    it "raises an OutOfBound exception if index is negative" do
      hydra = Hydra.new
      hydra.instance_variable_set :@index, -2
      expect { hydra.currdigit }.to raise_exception(Hydra::OutOfBounds)
    end

    # FIXME Also if larger than end of digits array
  end

  describe '#read' do
    it "reads a word, returning a hydra" do
      hydra = Hydra.new 'abc'
      chydra = hydra.getneck('a').getneck('b').getneck('c')
      expect(hydra.read('abc')).to be == chydra
    end

    it "returns nil if word isn’t found" do
      hydra = Hydra.new 'foo'
      expect(hydra.read('bar')).to be_nil
    end
  end

  describe '#transplant' do # This metaphor brought to you while watching House M. D. ;-)
    it "transplants a part of another hydra" do
      patient = Hydra.new ['abc', 'def', 'ghi']
      donor = Hydra.new ['zyx', 'klm']
      graft = donor.read 'klm'
      patient.transplant graft
      expect(patient.digest).to eq ['abc', 'def', 'ghi', 'klm']
    end

    it "handles digits correctly" do
      donor = Hydra.new 'foo3'
      patient = Hydra.new
      graft = donor.read 'foo'
      patient.transplant graft
      expect(patient.digest).to eq ['foo3']
    end

    it "removes the head from the source hydra" do
      donor = Hydra.new ['foo', 'bar']
      patient = Hydra.new
      graft = donor.read 'foo'
      patient.transplant graft
      expect(donor.digest).to eq ['bar']
    end
  end

  describe '#add_pattern' do
    it "adds a new pattern with the parameters provided" do
      hydra = Hydra.new
      pattern = Pattern.new 'fo2o3'
      hydra.add_pattern(pattern, 2, 1, 3)
      expect(hydra.digest).to eq ['f3o']
    end
  end

  describe '#pattern' do
    it "returns the pattern associated with that head, as string" do
      hydra = Hydra.new '5fo2o3'
      fooneck = hydra.read('foo')
      expect(fooneck.pattern.to_s).to eq "5fo2o3"
    end

    it "returns string to current node even if no head" do
      hydra = Hydra.new 'abc'
      bneck = hydra.read('ab')
      expect(bneck.pattern.to_s).to be == "ab"
    end

    it "works with initial dots" do
      hydra = Hydra.new '.ba2'
      aneck = hydra.read('.ba')
      expect(aneck.pattern.to_s).to be == ".ba2"
    end

    it "works with final dots" do
      hydra = Hydra.new 'f4o.'
      oneck = hydra.read('fo.')
      expect(oneck.pattern.to_s).to be == "f4o."
    end

    it "but not the way it used to" do
      hydra = Hydra.new 'fo.'
      oneck = hydra.read('fo')
      expect(oneck.pattern.to_s).to be == 'fo'
    end

    it "works correctly if both “ab” and “ab.” are stored" do
      hydra = Hydra.new ['ab', 'ab.']
      dothead = hydra.read 'ab.'
      nodothead = hydra.read 'ab'
      expect(dothead.pattern.to_s).to eq 'ab.'
      expect(nodothead.pattern.to_s).to eq 'ab'
      expect(hydra.pattern.to_s).to eq ''
    end

    it "works correctly if only “ab.” is stored and we’re at the b head" do
      hydra = Hydra.new 'ab.'
      bhead = hydra.read 'ab'
      expect(bhead.pattern.to_s).to eq 'ab'
    end

    it "works correctly with non-heads location" do
      hydra = Hydra.new 'abc'
      bhead = hydra.read 'ab'
      expect(bhead.pattern.to_s).to eq 'ab'
    end
  end

  describe '#add_conflict' do
    it "adds an element to the list of conflicting patterns" do
      hydra.add_conflict(Pattern.new('fo1'), Pattern.new('fo2'))
      expect(hydra.instance_variable_get(:@conflicts).count).to eq 1
    end
  end

  describe '#conflicts' do
    it "returns the list of conflicts" do
      hydra.instance_variable_set(:@conflicts, [[Pattern.new('a1b'), Pattern.new('a2b')]])
      expect(hydra.conflicts).to eq [['a1b', 'a2b']]
    end

    it "doesn’t get confused" do
      hydra = Hydra.new ['1a2b', 'a3b']
      expect(hydra.conflicts).to eq [['1a2b', 'a3b']]
    end
  end

  describe '#disembowel' do
    let(:device) { double(:output).as_null_object }

    it "dumps a string" do
      hydra.ingest(['apple', 'orange', 'lemon'])
      expect(device).to receive(:puts).at_least(:once) # TODO specify arguments
      hydra.disembowel(device)
    end

    it "prints nicely" do
      hydra.ingest(['abc', 'abd', 'e', 'f'])
      ['.', '  a', '    b', '      c', '      d', '  e', '  f'].each do |line|
        expect(device).to receive(:puts).with(line)
      end
      hydra.disembowel(device)
    end

    it "returns the head count" do
      hydra.ingest(['a', 'b', 'c', 'd', 'e'])
      expect(hydra.disembowel(device)).to eq 5
    end
  end

  # TODO Some kind of input validation?  “cand.mag.” :-)
  describe '#ingest_file' do # TODO Allow TeX-style comments?
    it "ingests a whole file of patterns" do
      hydra.ingest_file(File.expand_path('../../files/hyph-bg.pat.txt', __FILE__))
      expect(hydra.heads).to eq 1660
    end

    it "works with the original hyphen.tex" do
      hydra.ingest_file(File.expand_path('../../files/hyphen.txt', __FILE__))
      expect(hydra.heads).to eq 4447
    end

    it "hyphenates a word" do
      hydra.ingest_file(File.expand_path('../../files/hyph-de-1996.pat.txt', __FILE__))
      hydra.setrighthyphenmin 2
      expect(hydra.showhyphens('Zwangsvollstreckungsmaßnahme')).to eq 'zwangs-voll-stre-ckungs-maß-nah-me'
    end

    it "accepts comments" do
      Dir.mktmpdir 'hydra' do |dir|
        filename = File.join(dir, 'words')
        file = File.open(filename, 'w')
        file.puts "% Here are some patterns\nfo1\nfo2o3% I like this one\n5bar7"
        file.close
        hydra.ingest_file(filename)
        expect(hydra.heads).to eq 3
        FileUtils.remove filename
      end
    end
  end

  describe '#start_file' do # FIXME Terrible method name
    it "initialize the hydra with all strings and substrings in the file" do
      Dir.mktmpdir 'hydra' do |dir|
        filename = File.join(dir, 'words')
        file = File.open(filename, 'w')
        file.puts "% Here are some words\nfoo\nbar\nbazquux"
        file.close
        hydra.start_file(filename)
        expect(hydra.digest).to eq ['foo', 'oo', 'o', 'bar', 'ar', 'r', 'bazquux', 'azquux', 'zquux', 'quux', 'uux', 'ux', 'x'].sort
      end
    end

    it "ignores hyphen for the moment" do
      Dir.mktmpdir 'hydra' do |dir|
        filename = File.join(dir, 'hyphenated-words')
        file = File.open(filename, 'w')
        file.puts "foo-bar"
        file.close
        hydra.start_file(filename)
        expect(hydra.digest).to eq ['foobar', 'oobar', 'obar', 'bar', 'ar', 'r'].sort
      end
    end

    it "ignores whitespace too" do
      Dir.mktmpdir 'hydra' do |dir|
        hydra = Hydra.new(nil, true)
        filename = File.join(dir, 'really-hyphenated-words')
        file = File.open(filename, 'w')
        file.puts "Here-by are whole-some long-words\nfoo\nbar\nbaz-quux"
        file.close
        hydra.start_file(filename)
        expect(hydra.count).to eq 39
      end
    end
  end
end

describe Heracles do
  let(:complex_dictionary_bare) { ['a-b', 'a-b-c', 'ab-cd', 'a-b-c-d-e', 'abc-def', 'ab-cd-ef-gh', 'abc-def-ghi'] }
  let(:complex_dictionary) { complex_dictionary_bare.map { |word| word = 'xx' + word + 'xxx' } }
  let(:output) { double("null output").as_null_object }
  let(:heracles) { Heracles.new(output) }

  # TODO A standard_parameters method that yields on demand

  describe '.new' do
    it "creates an instance of Heracles" do
      heracles = Heracles.new(output)
      expect(heracles).to be_a Heracles
    end

    it "takes an optional device as argument" do
      fd = IO.sysopen('/dev/null', 'w')
      io = IO.new(fd)
      expect(io).to receive(:puts).with("This is Hydra, a Ruby implementation of patgen")
      heracles = Heracles.new(io)
    end
  end

  describe '#set_input' do
    it "sets the input dictionary" do
      Dir.mktmpdir 'hydra' do |dir|
        filename = File.join(dir, 'simple.hydra')
        file = File.open(filename, 'w')
        file.puts "foo1\nbar2\nbaz3quux"
        file.close
        heracles.set_input(filename)
      end
      expect(heracles.instance_variable_get(:@final_hydra).heads).to eq 3
    end
  end

  describe '#pass' do
    it "prints one line to the output" do
      heracles.instance_variable_set(:@hyphenation_level, 1)
      heracles.instance_variable_set(:@pattern_length_start, 2)
      heracles.instance_variable_set(:@pattern_length_end, 5)
      heracles.instance_variable_set(:@count_hydra, Hydra.new)
      heracles.instance_variable_set(:@final_hydra, Hydra.new)
      heracles.instance_variable_set(:@good_weight, 1)
      heracles.instance_variable_set(:@bad_weight, 1)
      heracles.instance_variable_set(:@threshold, 1)
      expect(output).to receive(:puts).with("Generating one pass for hyphenation level 1 ...")
      heracles.pass ['ba-ba', 'bla-ck', 'she-ep']
    end
  end

  describe '#good' do
    it "returns :is when hyphenation level is odd" do
      heracles.instance_variable_set :@hyphenation_level, 1
      expect(heracles.good).to be == :is
    end

    it "returns :err when hyphenation level is even" do
      heracles.instance_variable_set :@hyphenation_level, 2
      expect(heracles.good).to be == :err
    end
  end

  describe '#bad' do
    it "returns :no when hyphenation level is odd" do
      heracles.instance_variable_set :@hyphenation_level, 1
      expect(heracles.bad).to be == :no
    end

    it "returns :hyph when hyphenation level is even" do
      heracles.instance_variable_set :@hyphenation_level, 2
      expect(heracles.bad).to be == :found
    end
  end

  describe '#knockout' do
    it "knocks out a position" do
      heracles.knockout([{ line: 12, column: 3, dot: 2, length: 5 }])
      expect(heracles.instance_variable_get :@knockouts).to eq([12, 5] => [[3, 5]])
    end

    it "can knock out several locations at once"  do
      heracles.knockout([{ line: 5, column: 7, dot: 1, length: 2 }, { line: 12, column: 3, dot: 2, length: 5 }])
      expect(heracles.instance_variable_get :@knockouts).to eq([5, 8] => [[7, 2]], [12, 5] => [[3, 5]])
    end

    it "stores reference to several sources" do
      heracles.knockout([{ line: 1, column: 1, dot: 1, length: 2 }, { line: 1, column: 0, dot: 2, length: 2 }])
      positions = heracles.instance_variable_get :@knockouts
      expect(positions).to eq([1, 2] => [[1, 2], [0, 2]])
    end
  end

  describe '#knocked_out?' do
    it "tells whether a position is knocked out or not" do
      heracles.knockout([{ line: 6, column: 1, dot: 1, length: 2 }])
      expect(heracles.knocked_out? 6, 1, 1, 3).to be_truthy
    end

    it "says no when it is not" do
      heracles.knockout([{ line: 1, column: 1, dot: 1, length: 2 }])
      expect(heracles.knocked_out? 1, 2, 0, 3).to be_falsey
    end

    it "says no when it is definitely not" do
      heracles.knockout([{ line: 1, column: 1, dot: 1, length: 2 }])
      expect(heracles.knocked_out? 2, 0, 2, 3).to be_falsey
    end
  end

  describe '#run_file' do
    it "runs a file of hyphenated words" do
      hydra = heracles.run_file(File.expand_path('../../files/dummy1.dic', __FILE__), [1, 1, 2, 2, 1, 1, 1])
      expect(hydra.digest).to be == ['b1c', 'd1d', 'e1f', 'g1h']
    end

    it "runs a slightly longer file" do
      hydra = heracles.run_file(File.expand_path('../../files/100.dic.utf8', __FILE__), [1, 2, 2, 5, 1, 1, 1, 2, 5, 1, 2, 1], [2, 2])
      expect(hydra).to be_a Hydra
      out = File.open(File.expand_path('../../files/100.out2.utf8', __FILE__), 'w')
      hydra.each do |node|
        out.puts(node.pattern.to_s)
      end
      out.close
      expect(hydra.heads).to eq 83
    end

    it "runs a full set of hyphenation levels on a small file", slow: true do
      heracles = Heracles.new
      hydra = heracles.run_file(File.expand_path('../../files/100.dic.utf8', __FILE__), [1, 9, 2, 5, 1, 1, 1, 2, 5, 1, 2, 1, 2, 6, 1, 1, 1, 2, 6, 1, 4, 1, 2, 7, 1, 1, 1, 2, 7, 1, 6, 1, 2, 13, 1, 4, 1, 2, 13, 1, 8, 1, 2, 13, 1, 16, 1], [2, 2])
      expect(hydra).to be_a Hydra
      pattfile = File.open(File.expand_path('../../files/100.pattern.ruby.9' ,__FILE__), 'w')
      hydra.digest.each do |pattern|
        pattfile.puts(pattern)
      end
      pattfile.close
      expect(hydra.heads).to eq 83
    end

    it "runs a large file", slow: true do
      heracles = Heracles.new
      hydra = heracles.run_file(File.expand_path('../../files/10k.dic.utf8', __FILE__), [1, 2, 2, 5, 1, 1, 1, 2, 5, 1, 2, 1], [2, 2])
      expect(hydra).to be_a Hydra
      pattfile = File.open(File.expand_path('../../files/10k.patterns', __FILE__), 'w')
      hydra.each do |node|
        pattfile.puts(node.pattern.to_s)
      end
      pattfile.close
      expect(hydra.heads).to eq 1619
    end

    it "runs the full file with one level and one length", slow: true do
      heracles = Heracles.new
      hydra = heracles.run_file(File.expand_path('../../files/words.hyphenated.refo', __FILE__), [1, 1, 2, 2, 1, 1, 1], [2, 2])
      pattfile = File.open(File.expand_path('../../files/pattern.ruby.1,2', __FILE__), 'w')
      pattfile.puts hydra.digest.join "\n"
      pattfile.close
      expect(hydra.heads).to eq 576
    end

    it "runs a full set of hyphenation levels on a large file", slow: true do
      heracles = Heracles.new
      hydra = heracles.run_file(File.expand_path('../../files/10k.dic.utf8', __FILE__), [1, 9, 2, 5, 1, 1, 1, 2, 5, 1, 2, 1, 2, 6, 1, 1, 1, 2, 6, 1, 4, 1, 2, 7, 1, 1, 1, 2, 7, 1, 6, 1, 2, 13, 1, 4, 1, 2, 13, 1, 8, 1, 2, 13, 1, 16, 1], [2, 2])
      expect(hydra).to be_a Hydra
      pattfile = File.open(File.expand_path('../../files/10k.pattern.ruby.9' ,__FILE__), 'w')
      hydra.digest.each do |pattern|
        pattfile.puts(pattern)
      end
      pattfile.close
      expect(hydra.heads).to eq 1778
    end

    it "runs level 1 on the full German dictionary", slow: true do
      heracles = Heracles.new
      hydra = heracles.run_file(File.expand_path('../../files/words.hyphenated.refo', __FILE__), [1, 9, 2, 5, 1, 1, 1, 2, 5, 1, 2, 1, 2, 6, 1, 1, 1, 2, 6, 1, 4, 1, 2, 7, 1, 1, 1, 2, 7, 1, 6, 1, 2, 13, 1, 4, 1, 2, 13, 1, 8, 1, 2, 13, 1, 16, 1], [2, 2])
      pattfile = File.open(File.expand_path('../../files/pattern.ruby.1', __FILE__), 'w')
      pattfile.puts hydra.digest.join "\n"
      pattfile.close
      expect(hydra.heads).to eq 5130
    end
  end

  describe '#run' do
    it "runs an array of hyphenated words" do
      dictionary = ['ab-cd-de-fg-hi', 'ab-cd-de', 'ab-cd', 'b-c', 'd-d', 'e-f']
      dictionary.map! { |word| word = 'xx' + word + 'xxx' } # TODO Helper function for that
      hydra = heracles.run(dictionary, [1, 1, 2, 2, 1, 1, 1])
      expect(hydra.digest).to be == ['b1c', 'd1d', 'e1f', 'g1h']
    end

    it "runs another array" do
      final = heracles.run(['xxa-b-cxxx', 'xxabc-defxxx', 'xxab-cd-fg-hixxx'], [1, 1, 2, 5, 1, 1, 1])
      expect(final).to be_a Hydra
      expect(final.digest).to eq ['b1c', '1bcx', '1de', 'd1f', 'g1h']
    end

    it "correctly ignores commments" do
      dictionary = ['xxa-b-cxxx % f-o-o', 'xxab-cd-fg-hixxx % b-a-r', 'xxabc-defxxx % baz quux', '% I’m a c-o-m-m-e-n-t']
      hydra = heracles.run(dictionary, [1, 1, 2, 2, 1, 1, 1])
      expect(hydra.digest).to eq ['b1c', '1de', 'd1f', 'g1h']
    end

    it "runs a slightly more complex list of words" do
      hydra = heracles.run(complex_dictionary, [1, 1, 2, 5, 1, 1, 1])
      expect(hydra.digest).to be == ['b1c', '1bcdex', '1bcx', '1bx', 'c1d', '1efghx', '1ex', 'f1g']
    end

    it "handles hyphenmins correctly" do
      dictionary = ['a-b', 'a-b-cxxx']
      hydra = heracles.run(dictionary, [1, 1, 2, 5, 1, 1, 1])
      expect(hydra.digest).to be == ['b1c']
    end

    it "handles hyphenmins correctly on a more complex example" do
      dictionary = ['a-b', 'a-b-c', 'a-b-c-d', 'a-b-c-d-e', 'a-b-c-d-e-f', 'a-b-c-d-e-f-g', 'a-b-c-d-e-f-g-h']
      hydra = heracles.run(dictionary, [1, 1, 2, 5, 1, 1, 1])
      expect(hydra.digest).to be == ['b1c', 'c1d', 'd1e', 'e1f']
    end

    it "generates level 2" do
      hydra = heracles.run(complex_dictionary, [1, 2, 2, 5, 1, 1, 1, 2, 5, 1, 2, 1])
      expect(hydra.digest).to be == ['b1c', '1bcdex', '1bcx', '1bx', 'c1d', '2cdefx', '2dx', '1efghx', '1ex', 'f1g']
    end

    it "generates level 3" do
      hydra = heracles.run(complex_dictionary, [1, 3, 2, 5, 1, 1, 1, 2, 5, 1, 2, 1, 2, 6, 1, 1, 1])
      expect(hydra.digest).to be == ['b1c', '1bcdex', '1bcx', '1bx', 'c1d', '2cdefx', '2dx', '1efghx', '1ex', 'f1g']
    end

    it "generates level 4" do
      hydra = heracles.run(complex_dictionary, [1, 4, 2, 5, 1, 1, 1, 2, 5, 1, 2, 1, 2, 6, 1, 1, 1, 2, 6, 1, 4, 1])
      expect(hydra.digest).to be == ['b1c', '1bcdex', '1bcx', '1bx', 'c1d', '2cdefx', '4defghx', '2dx', '1efghx', '1ex', 'f1g']
    end

    it "generates level 5" do
      hydra = heracles.run(complex_dictionary, [1, 5, 2, 5, 1, 1, 1, 2, 5, 1, 2, 1, 2, 6, 1, 1, 1, 2, 6, 1, 4, 1, 2, 7, 1, 1, 1])
      expect(hydra.digest).to be == ['b1c', '1bcdex', '1bcx', '1bx', 'c1d', '2cdefx', '4defghx', '2dx', '1efghx', '1ex', 'f1g']
    end

    it "generates level 6" do
      hydra = heracles.run(complex_dictionary, [1, 5, 2, 5, 1, 1, 1, 2, 5, 1, 2, 1, 2, 6, 1, 1, 1, 2, 6, 1, 4, 1, 2, 7, 1, 1, 1, 2, 7, 1, 6, 1])
      expect(hydra.digest).to be == ['b1c', '1bcdex', '1bcx', '1bx', 'c1d', '2cdefx', '4defghx', '2dx', '1efghx', '1ex', 'f1g']
    end

    it "runs a very small extract of a real-life file" do
      hydra = heracles.run(['Aal-fang-er-geb-nis', 'Aal-fang-er-geb-nis-se', 'Aal-fang-er-geb-nis-sen', 'Aal-fang-er-geb-nis-ses', 'Aal-fi-let', 'Aal-fi-scher', 'Aal-glät-te', 'Aal-haut', 'Aal-hof', 'Aal-kopf'], [1, 2, 2, 5, 1, 1, 1, 2, 5, 1, 2, 1], [2, 2])
      expect(hydra.heads).to eq 12
      expect(hydra.digest).to eq ['b1n', '1er', 'h2e', 'i1l', 'l1f', 'l1g', 'l1h', 'l1k', 'r1g', '1sc', 's1s', 't1t']
    end

    it "runs a to level 3" do
      hydra = heracles.run(['Aal-fang-er-geb-nis', 'Aal-fang-er-geb-nis-se', 'Aal-fang-er-geb-nis-sen', 'Aal-fang-er-geb-nis-ses', 'Aal-fi-let', 'Aal-fi-scher', 'Aal-glät-te', 'Aal-haut', 'Aal-hof', 'Aal-kopf'], [1, 3, 2, 5, 1, 1, 1, 2, 5, 1, 2, 1, 2, 6, 1, 1, 1], [2, 2])
      expect(hydra.heads).to eq 12
      expect(hydra.digest).to eq ['b1n', '1er', 'h2e', 'i1l', 'l1f', 'l1g', 'l1h', 'l1k', 'r1g', '1sc', 's1s', 't1t']
    end

    it "runs a somewhat smarter extract" do
      hydra = heracles.run(['Aa-len', 'Aal-ent-nah-me', 'Aal-schok-ker', 'Aals-meer', 'Aalst', 'Aal-ste-cher', 'Aas-ban-de', 'Aa-see', 'Aba-kus', 'Ab-ar-bei-tens'], [1, 2, 2, 5, 1, 1, 1, 2, 5, 1, 2, 1], [2, 2])
      expect(hydra.heads).to eq 16
      expect(hydra.digest).to eq ['a1k', '1ar', 'e1c', '1ent', 'h1m', 'i1t', 'k1k', '1len.', 'n1d', 'r1b', 's1b', '1sc', '1se', 's1m', '1ste', 't1n']
    end

    it "runs to level 1 only" do # Level 1 now works, let’s check the rest
      hydra = heracles.run(['Aa-len', 'Aal-ent-nah-me', 'Aal-schok-ker', 'Aals-meer', 'Aalst', 'Aal-ste-cher', 'Aas-ban-de', 'Aa-see', 'Aba-kus', 'Ab-ar-bei-tens'], [1, 1, 2, 5, 1, 1, 1], [2, 2])
      expect(hydra.heads).to eq 16
      expect(hydra.digest).to eq ['a1k', '1ar', 'e1c', '1ent', 'h1m', 'i1t', 'k1k', '1len.', 'n1d', 'r1b', 's1b', '1sc', '1se', 's1m', '1ste', 't1n']
    end

    it "runs yet another example" do
      hydra = heracles.run(['Aal-fang-er-geb-nis', 'Aal-fang-er-geb-nis-se', 'Aal-fang-er-geb-nis-sen', 'Aal-fang-er-geb-nis-ses', 'Ab-bag-ge-rung'], [1, 2, 2, 5, 1, 1, 1, 2, 5, 1, 2, 1], [2, 2])
      expect(hydra.digest).to eq ['b1b', 'b1n', '1er', 'g1g2', 'l1f', 'r1g', '1ru', 's1s'] # Works now!
    end

    it "runs a 20-word example" do
      hydra = heracles.run(['Aa-chen', 'Aa-che-ner', 'Aa-che-ne-rin', 'Aa-che-nern', 'Aa-che-ners', 'Aa-chens', 'Aa-dorf', 'Aal-bau-er', 'Aal-beck', 'Aal-be-stand', 'Aal-be-stän-de', 'Aal-borg', 'Aal-bor-ger', 'Aal-ders', 'Aa-le', 'Aa-len', 'Aa-le-ner', 'Aa-le-nern', 'Aa-le-ners', 'Aa-lens'], [1, 2, 2, 5, 1, 1, 1, 2, 5, 1, 2, 1], [2, 2])
      expect(hydra.digest).to eq ['a1c', 'a1d', 'e1n', 'e1s', 'l1b', 'l1d', '1le', 'n1d', '2ns', 'r1g', '1ri', 'u1e']
    end

    it "runs a 30-word example" do
      hydra = heracles.run(['Aa-chen', 'Aa-che-ner', 'Aa-che-ne-rin', 'Aa-che-nern', 'Aa-che-ners', 'Aa-chens', 'Aa-dorf', 'Aal-bau-er', 'Aal-beck', 'Aal-be-stand', 'Aal-be-stän-de', 'Aal-borg', 'Aal-bor-ger', 'Aal-ders', 'Aa-le', 'Aa-len', 'Aa-le-ner', 'Aa-le-nern', 'Aa-le-ners', 'Aa-lens', 'Aal-ent-nah-me', 'Aal-ent-nah-men', 'Aa-ler', 'Aa-les', 'Aal-eskor-te', 'Aal-eskor-ten', 'Aal-fang', 'Aal-fang-er-geb-nis', 'Aal-fang-er-geb-nis-se', 'Aal-fang-er-geb-nis-sen'], [1, 2, 2, 5, 1, 1, 1, 2, 5, 1, 2, 1], [2, 2])
      expect(hydra.digest).to eq ['a1c', 'a1d', 'b1n', 'e1n', '1ent', '2es.', 'h1m', 'l1b', 'l1d', '1le', '2lent', 'l1es', '2lesk', 'l1f', 'n1d', 'ng1', '2ns', '2nt', 'r1g', '1ri', 'r1t', 's1s', '1st', 't1n', 'u1e']
    end

    it "runs a 50-word example" do
      hydra = heracles.run(['Aa-chen', 'Aa-che-ner', 'Aa-che-ne-rin', 'Aa-che-nern', 'Aa-che-ners', 'Aa-chens', 'Aa-dorf', 'Aal-bau-er', 'Aal-beck', 'Aal-be-stand', 'Aal-be-stän-de', 'Aal-borg', 'Aal-bor-ger', 'Aal-ders', 'Aa-le', 'Aa-len', 'Aa-le-ner', 'Aa-le-nern', 'Aa-le-ners', 'Aa-lens', 'Aal-ent-nah-me', 'Aal-ent-nah-men', 'Aa-ler', 'Aa-les', 'Aal-eskor-te', 'Aal-eskor-ten', 'Aal-fang', 'Aal-fang-er-geb-nis', 'Aal-fang-er-geb-nis-se', 'Aal-fang-er-geb-nis-sen', 'Aal-fang-er-geb-nis-ses', 'Aal-fi-let', 'Aal-fi-scher', 'Aal-glät-te', 'Aal-haut', 'Aal-hof', 'Aal-kopf', 'Aal-mous-se', 'Aal-mut-ter', 'Aal-re-gat-ta', 'Aal-reu-sen', 'Aal-räu-che-rei', 'Aal-räu-che-rei-en', 'Aals', 'Aal-schok-ker', 'Aals-meer', 'Aalst', 'Aal-ste-cher', 'Aal-stra-ße', 'Aal-stras-se'], [1, 2, 2, 5, 1, 1, 1, 2, 5, 1, 2, 1], [2, 2])
      expect(hydra.digest).to eq ['a1c', 'a1d', 'a1ß', 'b1n', 'e1g', 'e1n', '1ent', '2es.', 'h1m', 'i1e', 'i1l', 'k1k', 'l1b', 'l1d', '1le', '2lent', 'l1es', '2lesk', 'l1f', 'l1g', 'l1h', 'l1k', 'l1m', 'l1r', 'l1s', 'n1d', 'ng1', '2ns', '2nt', '1re', 'r1g', '1ri', 'r1t', '1sc', '1se', '2s1m', 's1s', '1st', '2st.', 'te1', 't1n', 't1t', 'u1c', 'u1e'] # Works now!
    end

    it "correctly folds cases of Unicode characters" do
      hydra = heracles.run(['Zö-li-bat', 'GE-GRÖ-LE'], [1, 1, 2, 5, 1, 1, 1], [1, 2])
      expect(hydra.digest).to eq ['e1g', 'i1b', 'ö1l']
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

describe Labour do
  let(:output) { double("output device").as_null_object }
  let(:dictionary) { File.expand_path('../../files/100.dic.utf8', __FILE__) }
  let(:empty_file) { File.expand_path('../../files/empty', __FILE__) }
  let(:output_patterns) { '/tmp/output' } # TODO Use Dir.mktmpdir
  let(:translate) { File.expand_path('../../files/german.tr', __FILE__) }

  describe '.initialize' do
    it "is initialised without any argument by default" do
      labour = Labour.new
      expect(labour).to be_a Labour
    end

    it "can optionally be called with a device as an argument" do
      fd = IO.sysopen('/dev/null', 'w')
      device = IO.new(fd)
      labour = Labour.new(device)
      expect(labour.instance_variable_get(:@device)).to eq device
    end
  end

  describe '#parse_translate' do
    it "parses the translate file.  Or rather just the first line" do
      labour = Labour.new
      hyphenmins = labour.parse_translate(File.expand_path('../../files/german.tr', __FILE__))
      expect(hyphenmins).to eq [2, 2]
    end
  end

  describe '#run' do
    it "sets the four command-line parameters" do
      labour = Labour.new(output)
      labour.run([dictionary, empty_file, output_patterns, translate])
      expect(labour.instance_variable_get(:@dictionary)).to eq dictionary
      expect(labour.instance_variable_get(:@input_patterns)).to eq empty_file
      expect(labour.instance_variable_get(:@output_patterns)).to eq output_patterns
      expect(labour.instance_variable_get(:@translate)).to eq translate
    end

    it "raises an exception if called to operate on an inexistent file" do
      labour = Labour.new(output)
      expect { labour = labour.run(['/some/file/that/does/not/exist']) }.to raise_exception Labour::InvalidInput
    end

    it "sets a default parameter array" do
      labour = Labour.new(output)
      labour.run([dictionary, empty_file, output_patterns, translate])
      bounds_weights = labour.instance_variable_get(:@boundaries_and_weights)
      expect(bounds_weights).to be_an Array
      expect(bounds_weights[0..16]).to eq [1, 9, 2, 5, 1, 1, 1, 2, 5, 1, 2, 1, 2, 6, 1, 1, 1]
    end

    it "works with a single argument" do
      labour = Labour.new(output)
      hydra = labour.run([dictionary])
      expect(hydra.count).to eq 83
    end

    it "runs the pattern generator" do
      labour = Labour.new(output)
      hydra = labour.run(['files/100.dic.utf8', 'files/empty', '/tmp/output', 'files/german.tr', [1, 1, 2, 5, 1, 1, 1]])
      expect(hydra).to be_a Hydra
      expect(hydra.heads).to eq 71
      output = File.read('/tmp/output')
      expect(output).to eq hydra.digest.join "\n"
    end

    it "returns a hydra" do
      labour = Labour.new(output)
      hydra = labour.run([dictionary, empty_file, output_patterns, translate])
      expect(hydra).to be_a Hydra
    end

    # FIXME Actually use the input patterns!
    # Also FIXME Output the current list as hyphenated by the generated patterns, optionally
  end
end
