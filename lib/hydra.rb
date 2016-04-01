require 'byebug'
require 'pp'

class Pattern
  def initialize(word, digits = nil)
    if digits
      @word = word
      @digits = digits
    else
      break_up(word)
    end
  end

  def to_s
    pattern = ''
    @digits.each_with_index do |digit, index|
      pattern += if digit > 0 then digit.to_s else '' end + @word[index].to_s
    end
    pattern
  end

  def break_up(pattern)
    word, i, digits = '', 0, []
    while i < pattern.length
      char = pattern[i]
      if Hydra.isdigit(char)
        digits << char.to_i
        i += 1
      else
        digits << 0
      end
      word += pattern[i] if pattern[i]
      i += 1
    end
    @word = word
    @digits = digits
  end

  def get_digits
    @digits
  end

  def get_word
    @word
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

  def keys
    @necks.keys
  end

  def self.isdigit(char)
    char >= '0' && char <= '9'
  end

  def count
    @necks.inject(0) do |sum, head|
      head, tail = head.first, head.last
      sum += 1 if tail.gethead
      sum + if tail.is_a? Hydra then tail.count else 0 end
    end
  end

  def ingest(words, digits = [])
    if words.is_a? Enumerable
      words.each do |word|
        ingest(word)
      end
    elsif words.is_a? String
      word = words
      head = word[0]
      if Hydra.isdigit(head)
        digits << head.to_i
        word = word[1..-1]
        head = word[0]
      else
        digits << 0
      end

      if head
        tail = word[1..-1]
        ensure_neck(head)
        if tail == ""
          setatlas(head, digits)
        else
          getneck(head).ingest(tail, digits)
        end
      else
        sethead(digits)
      end
    end
  end

  def ingest_file(filename)
    ingest(File.read(filename).split)
  end

  def digest(prefix = '')
    words = []
    if gethead
      words << Pattern.new(prefix, gethead).to_s
    end
    keys.sort { |a, b| if a == 0 then -1 elsif b == 0 then 1 else a <=> b end }.map do |head|
      tail = getneck(head)
      words += tail.digest(prefix + head)
    end

    words
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
      head, tail = suffix[0], suffix[1..-1]
      if getneck(head)
        getneck(head).regest(tail, delete, prefix + head, predigits)
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
