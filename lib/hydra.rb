require 'byebug'
require 'pp'

class Hydra
  def initialize
    @root = { }
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

  def self.ingest_rec(node, word)
    head = word[0]
    if head
      tail = word[1..-1]
      node[head] ||= { }
      if tail == ""
        node[head][0] = true
      else
        ingest_rec(node[head], tail)
      end
    end
  end

  def ingest(words)
    if words.is_a? Enumerable
      words.each do |word|
        ingest(word)
      end
    elsif words.is_a? String
      Hydra.ingest_rec(@root, words)
    end
  end

  def dump(device = $stdout)
    device.pp @root
  end
end
