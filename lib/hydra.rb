require 'byebug'
require 'pp'

class Knuckle
  def initialize(letter, digit = 0)
    @digit = digit
    @letter = letter
  end

  def digit
    @digit
  end

  def letter
    @letter
  end
end

class Hydra
  class ConflictingPattern < StandardError
  end

  def initialize
    @root = { }
    @limbs = @root
    @mode = :lax
  end

  def strict_mode
    @mode = :strict
  end

  def [] index
    @limbs[index]
  end

  def []= index, value
    @limbs[index] = value
  end

  def inject init, &block
    @limbs.inject(init, &block)
  end

  def sethead(digits)
    @head = digits
  end

  def chophead
    # @head = nil
    @limbs.delete(0)
  end

  def gethead
    @head
  end

  def keys
    @limbs.keys
  end

  def self.isdigit(char)
    char >= '0' && char <= '9'
  end

  def self.count_rec(node)
    node.inject(0) do |sum, head|
      head, tail = head.first, head.last
      sum += 1 if head == 0
      sum + if tail.is_a? Hash then count_rec(tail) else 0 end
    end
  end

  def count
    Hydra.count_rec(@root)
  end

  def self.ingest_rec(node, word, digits)
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
      node[head] ||= { }
      if tail == ""
        node[head][0] = digits
      else
        ingest_rec(node[head], tail, digits)
      end
    else
      node ||= { }
      node[0] = digits
    end
  end

  def ingest(words)
    if words.is_a? Enumerable
      words.each do |word|
        ingest(word)
      end
    elsif words.is_a? String
      Hydra.ingest_rec(@root, words, [])
    end
  end

  def ingest_file(filename)
    ingest(File.read(filename).split)
  end

  def self.digest_rec(prefix, node)
    node.keys.sort { |a, b| if a == 0 then -1 elsif b == 0 then 1 else a <=> b end }.map do |head|
      tail = node[head]
      if head == 0
        [Hydra.make_pattern(prefix, tail)]
      else
        digest_rec(prefix + head, tail)
      end
    end.flatten
  end

  def digest
    Hydra.digest_rec('', @root)
  end

  def regest_rec(prefix, suffix, node, delete = false, predigits = [])
    if prefix == ''
      predigits = Hydra.get_digits(suffix)
      suffix.gsub! /\d/, ''
    end

    digits = node[0]
    if suffix == '' && digits
      node.delete(0) if delete
      raise Hydra::ConflictingPattern if @mode == :strict && predigits != digits
      Hydra.make_pattern(prefix, digits)
    else
      head, tail = suffix[0], suffix[1..-1]
      if node[head]
        regest_rec(prefix + head, tail, node[head], delete, predigits)
      end
    end
  end

  def search(word)
    regest_rec('', word, @root)
  end

  def delete(word)
    regest_rec('', word, @root, true, [])
  end

  def regest(word, delete = true)
    regest_rec('', word, @root, delete, [])
  end

  def dump(device = $stdout)
    PP.pp @root, device
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
