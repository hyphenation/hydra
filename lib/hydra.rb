require 'pp'

class CoreExt
  def self.max2(a, b)
    if a > b
      a
    else
      b
    end
  end

  def self.min2(a, b)
    if a < b
      a
    else
      b
    end
  end
end

# TODO ingest_tex_file
class Array
  class MismatchedLength < StandardError
  end

  def mask(other)
    raise MismatchedLength unless length == other.length
    each_with_index do |value, index|
      self[index] = [value, other[index]].max
    end
  end
end

class Pattern
  attr_reader :digits, :word

  def initialize(word = nil, digits = nil)
    @cursor = 0
    @good_count = @bad_count = 0

    if word
      word = word.downcase
      if word =~ /^\./
        word.gsub!(/^\./, '')
        digits = digits[1..-1] if digits && digits.length > word.length + 1
        @initial = true
        @cursor = -1
      end

      if word =~ /\.$/
        word.gsub!(/\.$/, '')
        digits = digits[0..-2] if digits && digits.length > word.length + 1
        @final = true
      end

      if digits
        @word = word
        @digits = digits
        raise Hydra::BadPattern unless @digits.count == @word.length + 1
      else
        breakup(word)
      end
    else
      @word = ''
      @digits = [0]
    end
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
    new(word, [0] * (word.length + 1))
  end

  def self.simple(word, position, value)
    new(word, (word.length + 1).times.map do |i|
      if i == position then value else 0 end
    end)
  end

  def length
    @word.length
  end

  def shift(n = 1)
    @cursor += n
    self
  end

  def shift!(n = 1)
    @cursor += n
  end

  def reset(n = 0)
    @cursor = n
  end

  def letter(n) # FIXME  See #digit below: merge #currletter into this
    @word[n]
  end

  def digit(n) # FIXME  Integrate with #currdigit and
    @digits[@cursor + n]
  end

  def last?
    @cursor == @word.length - 1
  end

  def end?
    if @final
      @cursor == @word.length + 1
    else
      @cursor == @word.length
    end
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
    pattern = Pattern.dummy(@word + letter)
    pattern.initial! if @initial
    pattern
  end

  def copy
    Pattern.new(String.new(@word), Array.new(@digits))
  end

  def freeze(digits, depth = 0)
    @digits = digits[depth..-1]
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
    @word[0..@cursor-1]
  end

  def word_to(n)
    start = if @cursor == -1 then 0 else @cursor end
    subword = @word[start..@cursor + n - 1]
    if @cursor == -1
      subword = '.' + subword
    end
    subword += '.' if @cursor + n == length + 1

    subword
  end

  def digits_to(n)
    @digits[@cursor..@cursor + n]
  end

  def mask(a)
    offset = @cursor - a.length + 1
    a.length.times do |i|
      j = offset + i
      @digits[j] = [a[i], @digits[j]].max
    end
  end

  def initial!
    @initial = true
    @digits = @digits[1..-1] if @digits.length > @word.length + 1
  end

  def final!
    @final = true
    @digits = @digits[0..-2] if @digits.length > @word.length + 1
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
    word_order = @word <=> other.word
    if word_order != 0
      word_order
    else
      @digits <=> other.digits
    end
  end

  def currletter
    if @initial && @cursor == -1
      '.'
    elsif @final && @cursor == @word.length
      '.'
    else
      @word[@cursor]
    end
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
    raise Hydra::BadPattern unless @digits.length == @word.length + 1
    # FIXME Test for that
  end

  def showhyphens(lefthyphenmin = 0, righthyphenmin = 0)
    output = ''
    @digits.each_with_index do |digit, index|
      if index >= [1, lefthyphenmin].max && index <= length - [1, righthyphenmin].max
        if is_a? Lemma
          output += '-' if self.break(index) == :is
        elsif digit % 2 == 1
          output += '-'
        end
      end
      output += @word[index] if index < length
    end

    output
  end
end

class Lemma < Pattern # FIXME Plural lemmata?
  def initialize(*params)
    super(*params)
  end

  def break(n)
    i = @cursor + n
    breakpoint = @breakpoints[i]
    if @digits[i] % 2 == 1
      if breakpoint == :is
        breakpoint = :found
      elsif breakpoint == :no
        breakpoint = :err
      end
    end

    breakpoint
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
    @conflicts = []
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

  def star
    if parent then parent.star else self end
  end

  def prominens(letter = nil)
    if parent then parent.prominens(@atlas) else letter end
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
    self
  end

  def gethead
    @head
  end

  def chophead
    @head = nil
    @good_count = 0
    @bad_count = 0
    @sources = nil
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

  def clear_good_and_bad_counts
    @good_count = @bad_count = 0
  end

  def add_source(source)
    @sources ||= []
    @sources << source
  end

  def sources
    @sources
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

  def heads
    @necks.inject(0) do |sum, letter_and_neck|
      neck = letter_and_neck.last
      sum += 1 if neck.gethead
      sum + if neck.is_a? Hydra then neck.heads else 0 end
    end
  end

  def knuckles
    1 + @necks.inject(0) do |sum, letter_and_neck|
      neck = letter_and_neck.last
      sum + if neck.is_a? Hydra then neck.knuckles else 0 end
    end
  end

  def each(&block)
    @necks.each do |letter_and_neck|
      neck = letter_and_neck.last
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
        getneck(letter).ingest(pattern.shift) unless pattern.end?
      else
        if gethead
          message = "Pattern #{pattern.to_s} conflicts with earlier pattern #{self.pattern}"
          raise ConflictingPattern.new(message) if @mode == :strict
          star.add_conflict(Pattern.new(self.pattern), pattern.copy)
          sethead(pattern.digits.mask(gethead))
        else
          sethead(pattern.digits)
        end
      end
    end
  end

  def ingest_file(filename)
    file = File.open(filename, 'r')
    file.each_line do |line|
      ingest(line.gsub(/%.*$/, '').strip.split)
    end
    file.close
  end

  def digest(pattern = Pattern.new, depth = nil)
    unless depth
      depth = if prominens == '.' then self.depth - 1 else self.depth end
      depth = 0 if depth < 0
    end
    if gethead then [pattern.freeze(gethead, depth).to_s] else [] end +
    letters.sort.map do |letter|
      getneck(letter).digest(pattern.fork(letter), depth)
    end.flatten
  end

  def regest(pattern, mode = :search, matches = [])
    digits = gethead

    if digits
      case mode
      when :match
        matches << Pattern.new(pattern.word_so_far, digits)
      when :hydrae
        @index = pattern.cursor - depth
        @index += 1 if prominens == '.'
        matches << self
      when :hyphenate
        pattern.mask digits
      when :search, :delete
        if pattern.end?
          chophead if mode == :delete
          raise ConflictingPattern if @mode == :strict && pattern.digits != digits
          return Pattern.new(pattern.word, digits).to_s
        end
      end
    end

    if pattern.end? && (mode == :match || mode == :hyphenate || mode == :hydrae)
      dotneck = getneck('.')
      if dotneck
        head = dotneck.gethead
        if head
          if mode == :match
            matches << Pattern.new(pattern.word_so_far, head).final
          elsif mode == :hydrae
            index = pattern.cursor - depth
            index += 1 if prominens == '.'
            index.times { dotneck.shift }
            matches << dotneck
          elsif mode == :hyphenate
            pattern.mask head
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
    word.length.times.each do |n|
      temp = []
      regest(Pattern.dummy(word[n..-1]), :match, temp)
      temp.each { |match| match.setanchor(n) }
      matches += temp
    end

    matches.flatten.compact.sort
  end

  def hydrae(word)
    matches = []
    getneck('.').regest(Pattern.dummy(word), :hydrae, matches) if getneck('.')
    pattern = Pattern.dummy(word)
    word.length.times.each do |n|
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

  def transplant(other)
    ingest other.pattern.to_s
    other.chophead
  end

  def add_pattern(pattern, length, dot, level)
    ingest Pattern.simple(pattern.word_to(length), dot, level)
  end

  def add_conflict(original, conflicting)
    @conflicts << [original, conflicting]
  end

  def conflicts
    @conflicts.map do |conflict|
      [conflict.first.to_s, conflict.last.to_s]
    end
  end

  # Debug methods # FIXME No longer relevant.  But rename method below!
  def pattern(neck = "", digits = nil)
    if digits
      if parent
        parent.pattern(@atlas + neck, digits)
      else
        Pattern.new(neck, digits).to_s
      end
    else
      digits = if gethead then gethead else [0] * (depth + 1) end
      pattern('', digits)
    end
  end

  def disembowel(device = $stdout)
    PP.pp self, device
    heads
  end

  def start_file(filename)
    File.read(filename).each_line do |line|
      word = line.strip.gsub(/%.*$/, '').gsub(/-/, '')
      pattern = Pattern.new(word)
      word.length.times do |i|
        pattern.reset(i)
        ingest(pattern)
      end
    end
  end
end

class Heracles
  def initialize(output = $stdout)
    @output = output
    @output.puts "This is Hydra, a Ruby implementation of patgen"

    @count_hydra = Hydra.new
    @final_hydra = Hydra.new

    @knockouts = { }
  end

  def set_parameters(hyphenmins = [2, 3], parameters = [1, 2, 5, 1, 1, 1], output = $stdout)
    @hyphenation_level = parameters.shift
    @pattern_length_start = parameters.shift
    @pattern_length_end = parameters.shift
    @good_weight = parameters.shift
    @bad_weight = parameters.shift
    @threshold = parameters.shift
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

  def knockout(locations)
    locations.each do |location|
      # byebug if location[:line] == 1 && location[:column] + location[:dot] == 2
      currpos = [location[:line], location[:column] + location[:dot]]
      @knockouts[currpos] ||= []
      @knockouts[currpos] << [location[:column], location[:length]]
    end
  end

  def knocked_out?(lineno, column, dot, length)
    knocks = @knockouts[[lineno, column + dot]]
    knocks && knocks.any? do |knock|
      knockcol = knock.first
      knocklen = knock.last
      column <= knockcol && knockcol + knocklen <= column + length
    end
  end

  def collect_patterns(dot) # TODO Document / spec out
    hopeless = good = unsure = 0
    @count_hydra.each do |hydra|
      if hydra.good_count * @good_weight < @threshold
        hopeless += 1
        knockout(hydra.sources)
        hydra.chophead
      elsif hydra.good_count * @good_weight - hydra.bad_count * @bad_weight >= @threshold
        good += 1
        knockout(hydra.sources)
        @final_hydra.transplant hydra
      else
        unsure += 1
        hydra.chophead
        hydra.clear_good_and_bad_counts
      end
    end
    @output.write "  #{good} good, #{hopeless} hopeless, #{unsure} unsure"
    if good + unsure == 0
      @dots_knocked_out << dot
      @output.write ": dot position knocked out"
    end
    @output.puts ''
  end

  def set_input(filename)
    @final_hydra.ingest_file(filename)
  end

  def pass(dictionary)
    @output.puts "Generating one pass for hyphenation level #{@hyphenation_level} ..."

    @knockouts = { }
    @dots_knocked_out = []

    (@pattern_length_start..@pattern_length_end).each do |pattern_length|
      Heracles.organ(pattern_length).each do |dot|
        @output.write "hyph_level = #{@hyphenation_level}, pat_len = #{pattern_length}, pat_dot = #{dot}"
        @output.puts " – knocked out" if @dots_knocked_out.include?(dot) && next
        @output.puts ''
        lineno = knocked_out = 0
        dictionary.each do |line|
          lineno += 1
          lemma = Lemma.new(line.gsub(/%.*$/, '').strip.downcase)
          next unless lemma.length >= pattern_length
          @final_hydra.prehyphenate(lemma)
          word_start = [dot - 1, @final_hydra.lefthyphenmin].max
          word_end = lemma.length - [pattern_length - dot - 1, @final_hydra.righthyphenmin].max
          lemma.reset(word_start - dot - 1)
          (word_start..word_end).each do
            lemma.shift
            knocked_out += 1 if knocked_out?(lineno, lemma.cursor, dot, pattern_length) && next
            node = @count_hydra.add_pattern(lemma, pattern_length, dot, @hyphenation_level)
            node.add_source(line: lineno, column: lemma.cursor, dot: dot, length: pattern_length)
            if lemma.break(dot) == good
              node.inc_good_count
            elsif lemma.break(dot) == bad
              node.inc_bad_count
            end
          end
        end

        @output.puts "  #{@count_hydra.heads} patterns in count trie, #{knocked_out} skipped" # TODO Specify that
        collect_patterns(dot)
      end
    end
  end

  def run_file(filename, parameters = [], hyphenmins = [2, 3])
    run(File.read(filename).split("\n"), parameters, hyphenmins)
  end

  def run(array, params = [], hyphenmins = [2, 3])
    @final_hydra.setlefthyphenmin(hyphenmins.first)
    @final_hydra.setrighthyphenmin(hyphenmins.last)
    hyphenation_level_start = params.shift
    hyphenation_level_end = params.shift

    knocked_out_levels = []

    (hyphenation_level_start..hyphenation_level_end).each do |hyphenation_level|
      if knocked_out_levels.include? hyphenation_level - 2
        knocked_out_levels << hyphenation_level
        @output.puts "Hyphenation level #{hyphenation_level} knocked out"
        next
      end
      pattern_length_start, pattern_length_end = params.shift, params.shift
      good_weight, bad_weight, thresh = params.shift, params.shift, params.shift
      pattern_lengths = [pattern_length_start, pattern_length_end]
      set_parameters(hyphenmins, [hyphenation_level, pattern_length_start, pattern_length_end, good_weight, bad_weight, thresh])
      old_head_count = @final_hydra.heads
      pass(array)
      if old_head_count == @final_hydra.heads && @count_hydra.heads == 0
        knocked_out_levels << hyphenation_level
        @output.puts "Hyphenation level #{hyphenation_level} didn’t yield any new patterns, knocked out"
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
end

class Labour
  class InvalidInput < StandardError
  end

  def initialize(dictionary = '/dev/zero', input_patterns = '/dev/zero', output_patterns = '/dev/null', translate = '/dev/zero', device = $stdout)
    @dictionary = dictionary
    @input_patterns = input_patterns
    @output_patterns = output_patterns
    @translate = translate
    @device = device
    raise InvalidInput unless File.exists?(@dictionary)
    raise InvalidInput unless File.exists?(@input_patterns)
    raise InvalidInput unless Dir.exists?(File.dirname(@output_patterns))
    raise InvalidInput unless File.exists?(@translate)
  end

  def parse_translate(filename)
    line = File.read(filename, 4)
    [line[1].to_i, line[3].to_i]
  end

  def run(parameters)
    hyphenmins = parse_translate(@translate)
    @lefthyphenmin = hyphenmins.first
    @righthyphenmin = hyphenmins.last
    @heracles = Heracles.new(@device)
    @heracles.set_input(@input_patterns) # TODO Spec out
    @hydra = @heracles.run_file(@dictionary, parameters, hyphenmins)
    output = File.open(@output_patterns, 'w')
    output.write(@hydra.digest.join "\n")
    output.close

    @hydra
  end
end
