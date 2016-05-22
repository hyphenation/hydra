require 'byebug'
require 'pp'

class Pattern
  def initialize(word = nil, digits = nil, index = 0, cursor = 0)
    if digits
      @word = word
      @digits = digits
      raise Hydra::BadPattern unless @digits.count == @word.length + 1 || @digits.count == @word.length + 2
    elsif word
      breakup(word)
    else
      @word = ''
    end

    set_variables(index, cursor)
  end

  def cursor
    @cursor
  end

  def anchor
    @anchor
  end

  def setanchor(anchor)
    @anchor = anchor
  end

  def set_variables(index, cursor = 0)
    @index = index
    @cursor = cursor
    @good_count = @bad_count = 0
  end

  def inc_good_count
    @good_count += 1
  end

  def good_count
    @good_count
  end

  def inc_bad_count
    @bad_count += 1
  end

  def bad_count
    @bad_count
  end

  def self.dummy(word)
    new word,  [0] * (word.length + 1)
  end

  def self.simple(word, position, value)
    new word, (word.length + 1).times.map { |i| if i == position then value else 0 end }
  end

  def get_digits
    @digits
  end

  def get_word
    @word
  end

  def length
    @word.length
  end

  def index
    @index
  end

  def shift(n = 1)
    @index += n
    @cursor += n
    self
  end

  def shift!(n = 1)
    @index += n
    @cursor += n
  end

  def reset(n = 0)
    @index = n
    @cursor = n
  end

  def letter(n)
    @word[n]
  end

  def digit(n)
    @digits[n]
  end

  def last?
    @index == @word.length - 1
  end

  def end?
    @index == @word.length
  end

  def grow(letter)
    raise Hydra::FrozenPattern if @frozen
    @word += letter
    self
  end

  def grow!(letter)
    raise Hydra::FrozenPattern if @frozen
    @word += letter
  end

  def fork(letter)
    Pattern.dummy(@word + letter)
  end

  def copy(digits)
    Pattern.new(String.new(@word), digits)
  end

  def freeze(digits)
    @digits = digits
    @frozen = true
    self
  end

  def freeze!(digits)
    @frozen = true
    @digits = digits
  end

  def frozen?
    @frozen
  end

  def word_so_far
    @word[0..@index-1]
  end

  def word_to(n)
    @word[@index..@index + n - 1]
  end

  def digits_to(n)
    @digits[@index..@index + n]
  end

  def mask(a, anchor = nil)
    if a.is_a? Pattern
      mask(a.get_digits, a.anchor)
    else
      offset = a.length - 1
      if anchor
        local_anchor = anchor + offset
      else
        local_anchor = index
      end
      a.length.times do |i|
        j = local_anchor - offset + i
        @digits[j] = [a[i], @digits[j] || 0].max
      end
    end
  end

  def initial!
    @initial = true
    @digits = @digits[1..@digits.length - 1] if @digits.length > @word.length + 1
  end

  def final!
    @final = true
    @digits = @digits[0..@digits.length - 2] if @digits.length > @word.length + 1
  end

  def initial
    initial!
    self
  end

  def final
    final!
    self
  end

  def initial?
    @initial == true
  end

  def final?
    @final == true
  end

  def <=>(other)
    word_order = @word <=> other.get_word
    if word_order != 0
      word_order
    else
      @digits <=> other.get_digits
    end
  end

  def currletter
    @word[@cursor]
  end

  def currdigit
    @digits[@cursor]
  end

  def to_s
    combine
  end

  def combine
    pattern = ''
    @digits.each_with_index do |digit, index|
      pattern += if digit > 0 then digit.to_s else '' end + @word[index].to_s
    end

    pattern = '.' + pattern if @initial
    pattern = pattern + '.' if @final

    pattern
  end

  def breakup(pattern)
    @word, i, @digits = '', 0, []
    @breakpoints = [] if is_a? Lemma
    while i < pattern.length
      char = pattern[i]
      if Hydra.isdigit(char)
        @digits << char.to_i
        i += 1
      else
        if @breakpoints
          breakpoint = Hydra.isbreak(char)
          if breakpoint
            @breakpoints << breakpoint
            i += 1
          else
            @breakpoints << :no
          end
        end
        @digits << 0
      end
      @word += pattern[i] if pattern[i]
      i += 1
    end
    @digits << 0 if @digits.length == @word.length # Ensure explicit 0 after end of pattern
    @breakpoints << :no if @breakpoints
    raise BadPattern unless @digits.length == @word.length + 1
    # FIXME Test for that
  end

  def showhyphens(lefthyphenmin = 0, righthyphenmin = 0)
    output = ''
    @digits.each_with_index do |digit, index|
      if index < length 
        output += '-' if digit % 2 == 1 && index > 0 && index >= lefthyphenmin && index <= length - righthyphenmin
        output += @word[index]
      end
    end

    output
  end
end

class Lemma < Pattern # FIXME Plural lemmata?
  def initialize(*params)
    super(*params)
  end

  def break(n)
    @breakpoints[@cursor + n]
  end

  def mark_breaks
    @breakpoints.length.times do |i|
      if @breakpoints[i] == :is
        if @digits[i] % 2 == 1
          @breakpoints[i] = :found
        end
      elsif @breakpoints[i] == :no
        if @digits[i] % 2 == 1
          @breakpoints[i] = :err
        end
      end
    end
  end
end

# TODO Comparison function for Hydra.  Criterion: basically, the list of generated patterns is identical
class Hydra
  include Enumerable

  class ConflictingPattern < StandardError
  end

  class BadPattern < StandardError
  end

  class OutOfBounds < StandardError
  end

  class FrozenPattern < StandardError
  end

  def initialize(words = nil, mode = :lax, atlas = nil)
    @necks = { }
    @mode = mode
    @lefthyphenmin = 2
    @righthyphenmin = 3
    @good_count = @bad_count = 0
    @index = 0
    ingest words if words
    @atlas = atlas if atlas
  end

  def clear
    @necks = { }
  end

  def index
    @index
  end

  def shift
    @index += 1
  end

  def currdigit
    raise OutOfBounds if @index < 0
    if gethead
      gethead[@index]
    else
      nil
    end
  end

  def lefthyphenmin
    @lefthyphenmin
  end

  def righthyphenmin
    @righthyphenmin
  end

  def setlefthyphenmin(lefthyphenmin)
    @lefthyphenmin = lefthyphenmin
  end

  def setrighthyphenmin(righthyphenmin)
    @righthyphenmin = righthyphenmin
  end

  def strict_mode
    @mode = :strict
  end

  def showhyphens(word)
    pattern = prehyphenate(word)
    pattern.showhyphens(@lefthyphenmin, @righthyphenmin)
  end

  def parent
    @parent
  end

  def setparent(parent)
    @parent = parent
  end

  def depth(d = 0)
    if parent
      parent.depth(d + 1)
    else
      d
    end
  end

  def ensure_neck(letter)
    @necks[letter] = Hydra.new(nil, @mode, letter) unless @necks[letter]
    @necks[letter].setparent(self)
  end

  def setatlas(letter, digits)
    ensure_neck(letter)
    @necks[letter].sethead(digits)
  end

  def getneck(letter)
    @necks[letter]
  end

  def sethead(digits)
    @head = digits
  end

  def gethead
    @head
  end

  def chophead
    @head = nil
    @good_count = 0
    @bad_count = 0
    propagate_chop
  end

  def chopneck(letter)
    @necks.delete(letter)
  end

  def propagate_chop
    if @necks.count == 0
      if parent
        parent.chopneck(@atlas)
        parent.propagate_chop
      end
    end
  end

  def good_count
    @good_count
  end

  def inc_good_count
    @good_count += 1
  end

  def bad_count
    @bad_count
  end

  def inc_bad_count
    @bad_count += 1
  end

  def letters
    @necks.keys
  end

  def self.isdigit(char)
    char >= '0' && char <= '9'
  end

  def self.isbreak(char)
    case char
      when '-'
        :is
      when '*'
        :found
      when '.'
        :err
    end
  end

  def count
    @necks.inject(0) do |sum, neck|
      neck = neck.last
      sum += 1 if neck.gethead
      sum + if neck.is_a? Hydra then neck.count else 0 end
    end
  end

  def each(&block)
    @necks.each do |neck|
      neck = neck.last
      block.call(neck) if neck.gethead
      neck.each(&block)
    end
  end

  def ingest(words)
    if words.is_a? Enumerable
      words.each do |word|
        ingest(word)
      end
    elsif words.is_a? String
      ingest(Pattern.new(words))
    elsif words.is_a? Pattern
      pattern = words

      letter = pattern.currletter
      if letter
        ensure_neck(letter)
        if pattern.end?
          setatlas(letter, pattern.get_digits)
        else
          getneck(letter).ingest(pattern.shift)
        end
      else
        sethead(pattern.get_digits)
      end
    end
  end

  def ingest_file(filename)
    ingest(File.read(filename).split)
  end

  def digest(pattern = Pattern.new)
    if gethead then [pattern.freeze(gethead).to_s] else [] end + letters.sort.map do |letter|
      getneck(letter).digest(pattern.fork(letter))
    end.flatten
  end

  def regest(pattern, mode = :search, matches = [])
    digits = gethead

    if digits
      case mode
      when :match
        matches << Pattern.new(pattern.word_so_far, digits, -pattern.index)
      when :hydrae
        @index = pattern.index - depth
        @index += 1 if spattern =~ /^\./ # FIXME awful
        matches << self
      when :hyphenate
        pattern.mask digits
      when :search, :delete
        if pattern.end?
          chophead if mode == :delete
          raise ConflictingPattern if @mode == :strict && pattern.get_digits != digits
          return Pattern.new(pattern.get_word, digits).to_s
        end
      end
    end

    if pattern.end? && (mode == :match || mode == :hyphenate || mode == :hydrae)
      dotneck = getneck('.')
      if dotneck
        head = dotneck.gethead
        if head
          if mode == :match
            matches << Pattern.new(pattern.word_so_far, head[0..-2], -pattern.index).final
          elsif mode == :hydrae
            @index = pattern.index - depth
            @index += 1 if spattern =~ /^\./ # FIXME See above
            matches << self
          elsif mode == :hyphenate
            pattern.mask head[0..head.length - 2]
          end
        end
      end
    end

    getneck(pattern.currletter).regest(pattern.shift, mode, matches) if getneck(pattern.currletter)
  end

  def search(pattern)
    regest(Pattern.new(pattern))
  end

  def delete(pattern)
    regest(Pattern.new(pattern), :delete)
  end

  def match(word)
    matches = []
    getneck('.').regest(Pattern.dummy(word), :match, matches) if getneck('.')
    matches.each { |match| match.setanchor(0) }
    matches.each { |pattern| pattern.initial! }
    l = word.length
    l.times.each do |n|
      temp = []
      regest(Pattern.dummy(word[n..l-1]), :match, temp)
      temp.each { |match| match.setanchor(n) }
      matches += temp
    end

    matches.flatten.compact.sort
  end

  def hydrae(word)
    matches = []
    getneck('.').regest(Pattern.dummy(word), :hydrae, matches) if getneck('.')
    l = word.length
    pattern = Pattern.dummy(word)
    l.times.each do |n|
      # regest(Pattern.dummy(word[n..l-1]), :hydrae, matches)
      pattern.reset(n) # TODO Test that strategy thoroughly
      regest(pattern, :hydrae, matches)
    end

    matches
  end

  def prehyphenate(word)
    word = Pattern.dummy(word) unless word.is_a? Pattern
    getneck('.').regest(word, :hyphenate) if getneck('.')
    word.length.times do |n|
      word.reset(n)
      regest(word, :hyphenate)
    end

    word
  end

  def read(word)
    if word == ""
      self
    else
      neck = getneck(word[0])
      neck.read(word[1..-1]) if neck
    end
  end

  # Debug methods
  def spattern(sneck = "", digits = nil)
    if digits
      if parent
        parent.spattern(@atlas + sneck, digits)
      else
        Pattern.new(sneck, digits).to_s
      end
    else
      if gethead # FIXME Figure something out if current head stores e. g. "ab" and "ab."
        spattern('', gethead)
      elsif getneck('.')
        if getneck('.').gethead
          spattern('.', getneck('.').gethead)
        else
          ""
        end
      else
        ""
      end
    end
  end

  def disembowel(device = $stdout)
    PP.pp self, device
    count
  end
end

class Heracles
  def run(filename, parameters = [])
    run_array(File.read(filename).split("\n"), parameters)
  end

  def set_parameters(parameters)
    @hyphenation_level_start = parameters.shift
    @hyphenation_level_end = parameters.shift
    @count_hydra = Hydra.new
    @final_hydra = Hydra.new
  end

  def run_array(array, parameters = [])
    set_parameters(parameters)
    (@hyphenation_level_start..@hyphenation_level_end).each do |hyphenation_level|
      @hyphenation_level = hyphenation_level
      @pattern_length_start = parameters.shift
      @pattern_length_end = parameters.shift
      @good_weight = parameters.shift
      @bad_weight = parameters.shift
      @threshold = parameters.shift
      (@pattern_length_start..@pattern_length_end).each do |pattern_length|
        Heracles.organ(pattern_length).each do |dot|
          # TODO Idea: call each pass a Club, and make Heracles have many clubs?
          array.each do |line|
            lemma = Lemma.new(line.strip.downcase)
            next unless lemma.length >= pattern_length
            @final_hydra.prehyphenate(lemma)
            lemma.mark_breaks # FIXME Should ideally not be necessary
            word_start = dot
            word_end = lemma.length - (pattern_length - dot)
            word_start = @final_hydra.lefthyphenmin if word_start < @final_hydra.lefthyphenmin
            word_end = lemma.length - @final_hydra.righthyphenmin if word_end > lemma.length - @final_hydra.righthyphenmin
            lemma.reset(word_start - dot)
            (word_start..word_end).each do
              currword = lemma.word_to(pattern_length)
              count_pattern = Pattern.simple currword, dot, hyphenation_level
              @count_hydra.ingest count_pattern
              hydra = @count_hydra.read(currword)
              if lemma.break(dot) == good then hydra.inc_good_count else hydra.inc_bad_count end
              lemma.shift
            end
          end

          @count_hydra.each do |hydra|
            if hydra.good_count * @good_weight < @threshold
              @count_hydra.delete hydra.spattern
            elsif hydra.good_count * @good_weight - hydra.bad_count * @bad_weight >= @threshold
              pattern = hydra.spattern
              @final_hydra.ingest Pattern.new(pattern) # FIXME add atlas and use it instead of spattern
              @count_hydra.delete pattern
            # FIXME else clear good and bad counts?
            end
          end
        end
      end
    end
    @final_hydra
  end

  def self.organ(n)
    dot = n / 2
    dot1 = 2 * dot
    (n + 1).times.map do
      (dot, dot1 = dot1 - dot, 2 * n - dot1 - 1).first
    end
  end

  def good
    if @hyphenation_level % 2 == 1
      :is
    else
      :err
    end
  end

  def bad
    if @hyphenation_level % 2 == 1
      :no
    else
      :found
    end
  end
end
