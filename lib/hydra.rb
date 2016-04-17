require 'byebug'
require 'pp'

class Pattern
  def initialize(word = nil, digits = nil, index = 0, cursor = 0)
    if digits
      @word = word
      @digits = digits
      raise Hydra::BadPattern unless @digits.count == @word.length + 1 || @digits.count == @word.length + 2
    elsif word
      @pattern = word
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
    new word, (word.length + 1).times.map { 0 } # I’m sure there is syntactic sugar for that ...
  end

  def self.simple(word, position, value)
    new word, (word.length + 1).times.map { |i| if i == position then value else 0 end }
  end

  def get_digits
    breakup unless @digits
    @digits
  end

  def get_word
    breakup unless @word
    @word
  end

  def length
    breakup unless @word
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

  def reset
    @index = 0
    @cursor = 0
  end

  def letter(n)
    breakup unless @word
    @word[n]
  end

  def digit(n)
    breakup unless @digits
    @digits[n]
  end

  def last?
    breakup unless @word
    @index == @word.length - 1
  end

  def end?
    breakup unless @word
    @index == @word.length
  end

  def grow(letter)
    raise Hydra::FrozenPattern if @frozen
    breakup unless @word # Shouldn’t be necessary, really
    @word += letter
    self
  end

  def grow!(letter)
    raise Hydra::FrozenPattern if @frozen
    breakup unless @word
    @word += letter
  end

  def fork(letter)
    breakup unless @word # Shouldn’t be necessary
    Pattern.dummy(@word + letter)
  end

  def copy(digits)
    breakup unless @word
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
    breakup unless @word
    @word[0..@index-1]
  end

  def word_to(n)
    breakup unless @word
    @word[@index..@index + n - 1]
  end

  def digits_to(n)
    breakup unless @word
    @digits[@index..@index + n]
  end

  def mask(a, anchor = nil)
    breakup unless @digits
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
    combine unless @pattern
    breakup unless @digits
    @initial = true
    @pattern = '.' + @pattern
    @digits = @digits[1..@digits.length - 1] if @digits.length > @word.length + 1
  end

  def final!
    combine unless @pattern
    breakup unless @digits
    @final = true
    @pattern += '.'
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
    breakup unless @word
    @word <=> other.get_word
  end

  def currletter
    breakup unless @word
    @word[@cursor]
  end

  def currdigit
    breakup unless @digits
    @digits[@cursor]
  end

  def to_s
    combine unless @pattern
    @pattern
  end

  def combine
    @pattern = ''
    @digits.each_with_index do |digit, index|
      @pattern += if digit > 0 then digit.to_s else '' end + @word[index].to_s
    end

    @pattern = '.' + @pattern if @initial
    @pattern = @pattern + '.' if @final
  end

  def breakup
    @word, i, @digits = '', 0, []
    @breakpoints = [] if is_a? Lemma
    while i < @pattern.length
      char = @pattern[i]
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
      @word += @pattern[i] if @pattern[i]
      i += 1
    end
    @digits << 0 if @digits.length == @word.length # Ensure explicit 0 after end of pattern
    @breakpoints << :no if @breakpoints
    raise BadPattern unless @digits.length == @word.length + 1
    # FIXME Test for that
  end
end

class HyphenatedWord < Pattern
  def initialize(pattern)
    @pattern = pattern
    @word, i, @digits = '', 0, []
    while i <= @pattern.length # FIXME Test for <= (was <)
      char = @pattern[i]
      if char == '-'
        @digits << :is
        i += 1
      else
        @digits << :no
      end
      @word += @pattern[i] if @pattern[i]
      i += 1
    end

    set_variables(0)
  end

  def dot(n)
    @digits[@index + n]
  end

  def mask(pattern) # TODO Something to make consecutive maskings work better
    save_index = @index # FIXME Awful # TODO Test for all that
    save_cursor = @cursor
    reset
    shift(pattern.index)
    pattern.reset # TODO Rename all that stuff: we should have a cursor and an anchor
    (pattern.length + 1).times do
      pattern_digit = pattern.currdigit
      break unless pattern_digit
      if currdigit == :is
        if pattern_digit % 2 == 1 then @digits[@index] = :found end # TODO setdigit
      elsif currdigit == :no # It really can’t be anything else, but for symmetry
        if pattern_digit % 2 == 1 then @digits[@index] = :err end
      end
      pattern.shift
      shift
    end
    @index = save_index
    @cursor = save_cursor
  end
end

class Lemma < Pattern # FIXME Plural lemmata?
  def initialize(*params)
    super(*params)
  end

  def break(n)
    breakup unless @breakpoints
    @breakpoints[@cursor + n]
  end

  def mark_breaks
    breakup unless @breakpoints
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
      pattern.reset # TODO Test that strategy thoroughly
      pattern.shift(n)
      regest(pattern, :hydrae, matches)
    end

    matches
  end

  def prehyphenate(word)
    word = Pattern.dummy(word) unless word.is_a? Pattern
    word.length.times do |n|
      word.reset
      word.shift(n)
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
            word = HyphenatedWord.new(line.strip.downcase)
            lemma = Lemma.new(line.strip.downcase)
            raise unless word.length == lemma.length
            next unless word.length >= pattern_length
            matches_as_pattern = @final_hydra.match(word.get_word)
            lemma_matches = @final_hydra.match(lemma.get_word)
            # byebug if word.get_word == "xxabcddefghixxx"
            @final_hydra.prehyphenate(lemma)
            lemma.mark_breaks
            # byebug if word.get_word == "xxabcddefghixxx"
            raise unless matches_as_pattern.map(&:to_s) == lemma_matches.map(&:to_s)
            word_start = dot
            word_end = word.length - (pattern_length - dot)
            word_start = @final_hydra.lefthyphenmin if word_start < @final_hydra.lefthyphenmin
            word_end = word.length - @final_hydra.righthyphenmin if word_end > word.length - @final_hydra.righthyphenmin
            lemma.reset
            (word_start - dot).times { word.shift; lemma.shift }
            pattern = Pattern.dummy word.get_word
            matches_as_pattern.each do |match|
              pattern.mask match
            end
            word.mask pattern
            # lemma.mark_breaks
            # lemma.mask pattern
            # raise unless word.get_digits == lemma.instance_variable_get(:@breakpoints)
            (word_start..word_end).each do
              currword = word.word_to(pattern_length)
              byebug unless currword
              count_pattern = Pattern.simple currword, dot, hyphenation_level
              # byebug if count_pattern.to_s == "2dx"
              # byebug if count_pattern.to_s == "ab1"
              # byebug if count_pattern.to_s == "b1c"
              @count_hydra.ingest count_pattern
              hydra = @count_hydra.read(currword)
              raise unless word.dot(dot) == lemma.break(dot)
              if word.dot(dot) == good then hydra.inc_good_count else hydra.inc_bad_count end
              word.shift
              lemma.shift
              raise unless word.index == lemma.cursor
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
