require 'byebug'
require 'pp'

class Hydra
  class ConflictingPattern < StandardError
  end

  def initialize(mode = :lax)
    @limbs = { }
    @mode = mode
  end

  def strict_mode
    @mode = :strict
  end

  def grow_limb(letter)
    @limbs[letter] = Hydra.new(@mode) unless @limbs[letter]
  end

  def grow_head(letter, digits)
    grow_limb(letter)
    @limbs[letter].sethead(digits)
  end

  def getlimb(letter)
    @limbs[letter]
  end

  def inject init, &block
    @limbs.inject(init, &block)
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
    @limbs.keys
  end

  def self.isdigit(char)
    char >= '0' && char <= '9'
  end

  def count
    inject(0) do |sum, head|
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
        grow_limb(head)
        if tail == ""
          grow_head(head, digits)
        else
          getlimb(head).ingest(tail, digits)
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
      words << Hydra.make_pattern(prefix, gethead)
    end
    keys.sort { |a, b| if a == 0 then -1 elsif b == 0 then 1 else a <=> b end }.map do |head|
      tail = getlimb(head)
      words += tail.digest(prefix + head)
    end

    words
  end

  def regest(suffix, delete = false, prefix = '', predigits = [])
    if prefix == ''
      predigits = Hydra.get_digits(suffix)
      suffix.gsub! /\d/, ''
    end

    digits = gethead
    if suffix == '' && digits
      chophead if delete
      raise Hydra::ConflictingPattern if @mode == :strict && predigits != digits
      Hydra.make_pattern(prefix, digits)
    else
      head, tail = suffix[0], suffix[1..-1]
      if getlimb(head)
        getlimb(head).regest(tail, delete, prefix + head, predigits)
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

  def self.make_pattern(word, digits)
    pattern = ''
    digits.each_with_index do |digit, index|
      pattern += if digit > 0 then digit.to_s else '' end + word[index].to_s
    end
    pattern
  end

  def self.get_digits(pattern)
    i, digits = 0, []
    while i < pattern.length
      char = pattern[i]
      if Hydra.isdigit(char)
        digits << char.to_i
        i += 1
      else
        digits << 0
      end
      i += 1
    end
    digits
  end

  def self.get_word(pattern)
    pattern.gsub /\d/, ''
  end
end
