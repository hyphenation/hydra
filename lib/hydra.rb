require 'byebug'
require 'pp'

class Pattern
  def initialize(word = nil, digits = nil)
    if digits
      @word = word
      @digits = digits
    elsif word
      @pattern = word
    else
      @word = ''
    end
    @index = 0
  end

  def self.dummy(word)
    new word, word.length.times.map { 0 } # I’m sure there is syntactic sugar for that ...
  end

  def get_digits
    breakup unless @digits
    @digits
  end

  def get_word
    breakup unless @word
    @word
  end

  def index
    @index
  end

  def shift
    @index += 1
    self
  end

  def shift!
    @index += 1
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
    Pattern.new(@word + letter, [])
  end

  def copy(digits)
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
  end
end

class Hydra
  class ConflictingPattern < StandardError
  end

  def initialize(mode = :lax)
    @necks = { }
    @mode = mode
  end

  def strict_mode
    @mode = :strict
  end

  def ensure_neck(letter)
    @necks[letter] = Hydra.new(@mode) unless @necks[letter]
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

  def regest(pattern, mode = :search)
    digits = gethead

    if mode == :match
      if digits
        return Pattern.new(pattern.truncate(pattern.index), digits).to_s
      else
        return getneck(pattern.currletter).regest(pattern.shift, :match) if getneck(pattern.currletter)
      end
    end

    if pattern.end?
      if digits
        chophead if mode == :delete
        raise ConflictingPattern if @mode == :strict && pattern.get_digits != digits
        Pattern.new(pattern.get_word, digits).to_s
      end
    else
      letter = pattern.currletter
      if getneck(letter)
        getneck(letter).regest(pattern.shift, mode)
      end
    end
  end

  def search(pattern)
    regest(Pattern.new(pattern))
  end

  def delete(pattern)
    regest(Pattern.new(pattern), :delete)
  end

  def match(word)
    regest(Pattern.dummy(word), :match)
  end

  def dump(device = $stdout)
    PP.pp self, device
    count
  end
end
