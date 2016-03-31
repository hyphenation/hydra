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
  def initialize
    @root = { }
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

  def self.digest_rec(prefix, node)
    node.keys.sort { |a, b| if a == 0 then -1 elsif b == 0 then 1 else a <=> b end }.map do |head|
      tail = node[head]
      if head == 0
        pattern = ''
        tail.each_with_index do |digit, index|
          pattern += if digit > 0 then digit.to_s else '' end + prefix[index].to_s
        end
        [pattern]
      else
        digest_rec(prefix + head, tail)
      end
    end.flatten
  end

  def digest
    Hydra.digest_rec('', @root)
  end

  def dump(device = $stdout)
    device.pp @root
  end
end
