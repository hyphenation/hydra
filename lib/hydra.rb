require 'byebug'
require 'pp'

class Pattern
  def initialize(word = nil, digits = nil)
    if digits
      @word = word
      @digits = digits
      raise Hydra::BadPattern unless @digits.count == @word.length + 1 || @digits.count == @word.length + 2
    elsif word
      @pattern = word
    else
      @word = ''
    end
    @index = 0
  end

  def self.dummy(word)
    new word, (word.length + 1).times.map { 0 } # I’m sure there is syntactic sugar for that ...
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
    self
  end

  def shift!(n = 1)
    @index += n
  end

  def reset
    @index = 0
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
    breakup unless @word # Shouldn’t be necessary, really
    @word += letter
    self
  end

  def grow!(letter)
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

  def freeze(digits) # FIXME Actually freeze!
    @digits = digits
    self
  end

  def freeze!(digits)
    @digits = digits
  end

  def truncate(n)
    breakup unless @word
    @word[0..n-1]
  end

  def mask(a)
    offset = a.length - 1
    a.length.times do |i|
      j = index - offset + i
      @digits[j] = [a[i], @digits[j] || 0].max
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
    @word[@index]
  end

  def currdigit
    breakup unless @digits
    @digits[@index]
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
    while i < @pattern.length
      char = @pattern[i]
      if Hydra.isdigit(char)
        @digits << char.to_i
        i += 1
      else
        @digits << 0
      end
      @word += @pattern[i] if @pattern[i]
      i += 1
    end
    @digits << 0 if @digits.length == @word.length # Ensure explicit 0 after end of pattern
    raise BadPattern unless @digits.length == @word.length + 1
    # FIXME Test for that
  end
end

class HyphenatedWord < Pattern
  def initialize(pattern)
    @pattern = pattern
    @word, i, @digits = '', 0, []
    while i < @pattern.length
      char = @pattern[i]
      if char == '-'
        @digits << :is
        i += 1
      else
        @digits << 0
      end
      @word += @pattern[i] if @pattern[i]
      i += 1
    end
  end
end

class Hydra
  class ConflictingPattern < StandardError
  end

  class BadPattern < StandardError
  end

  def initialize(words = nil, mode = :lax)
    @necks = { }
    @mode = mode
    @lefthyphenmin = 2
    @righthyphenmin = 3
    ingest words if words
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
    @necks[letter] = Hydra.new(nil, @mode) unless @necks[letter]
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
  end

  def letters
    @necks.keys
  end

  def self.isdigit(char)
    char >= '0' && char <= '9'
  end

  def count
    @necks.inject(0) do |sum, neck|
      neck = neck.last
      sum += 1 if neck.gethead
      sum + if neck.is_a? Hydra then neck.count else 0 end
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
        matches << Pattern.new(pattern.truncate(pattern.index), digits)
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

    if pattern.end? && mode == :match || mode == :hyphenate
      dotneck = getneck('.')
      if dotneck
        head = dotneck.gethead
        if head
          if mode == :match
            matches << Pattern.new(pattern.truncate(pattern.index), head).final
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
    matches.map { |pattern| pattern.initial }
    e = word.length - 1
    (e + 1).times.each do |n|
      regest(Pattern.dummy(word[n..e]), :match, matches)
    end

    matches.flatten.compact.sort
  end

  def prehyphenate(word)
    pattern = Pattern.dummy(word)
    word.length.times do |n|
      pattern.reset
      pattern.shift(n)
      regest(pattern, :hyphenate)
    end

    pattern
  end

  def disembowel(device = $stdout)
    PP.pp self, device
    count
  end
end

class Heracles
  def self.organ(n)
    dot = n / 2
    dot1 = 2 * dot
    (n + 1).times.map do
      (dot, dot1 = dot1 - dot, 2 * n - dot1 - 1).first
    end
  end
end
