require 'byebug'
require 'pp'

class Pattern
  def initialize(word, digits = nil)
    if digits
      @word = word
      @digits = digits
    else
      @pattern = word
    end
    @index = 0
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

  def end?
    breakup unless @word
    @index == @word.length - 1
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

  def digest(prefix = '')
    if gethead then [Pattern.new(prefix, gethead).to_s] else [] end + letters.sort.map do |letter|
      getneck(letter).digest(prefix + letter)
    end.flatten
  end

  def regest(suffix, delete = false, prefix = '', predigits = [])
    if prefix == ''
      if @mode == :strict
        predigits = Pattern.new(suffix).get_digits
      else
        predigits = []
      end
      suffix.gsub! /\d/, ''
    end

    digits = gethead
    if suffix == '' && digits
      chophead if delete
      raise ConflictingPattern if @mode == :strict && predigits != digits
      Pattern.new(prefix, digits).to_s
    else
      letter, neck = suffix[0], suffix[1..-1]
      if getneck(letter)
        getneck(letter).regest(neck, delete, prefix + letter, predigits)
      end
    end
  end

  def search(word)
    regest(word)
  end

  def delete(word)
    regest(word, true)
  end

  def dump(device = $stdout)
    PP.pp self, device
    count
  end
end
