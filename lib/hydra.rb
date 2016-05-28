require 'byebug'
require 'pp'
require 'unicode_utils'

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
  def initialize(word = nil, digits = nil)
    @cursor = 0
    @good_count = @bad_count = 0

    if word
      word = UnicodeUtils.downcase(word)
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
    new word, [0] * (word.length + 1)
  end

  def self.simple(word, position, value)
    new word, (word.length + 1).times.map { |i| if i == position then value else 0 end }
  end

  def get_digits
    @digits
  end

  def get_word
    @word
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

  def letter(n)
    @word[n]
  end

  def digit(n)
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

  def copy(digits)
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
    @digits = @digits[1..@digits.length - 1] if @digits.length > @word.length + 1
  end

  def final!
    @final = true
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
    word_order = @word <=> other.get_word
    if word_order != 0
      word_order
    else
      @digits <=> other.get_digits
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
    raise BadPattern unless @digits.length == @word.length + 1
    # FIXME Test for that
  end

  def showhyphens(lefthyphenmin = 0, righthyphenmin = 0)
    output = ''
    @digits.each_with_index do |digit, index|
      output += '-' if digit % 2 == 1 && index > 0 && index >= lefthyphenmin && index <= length - [1, righthyphenmin].max
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

  def prominens
    if parent then parent.prominens else self end
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
        if gethead
          sethead(pattern.get_digits.mask(gethead))
        else
          sethead(pattern.get_digits)
        end
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
        matches << Pattern.new(pattern.word_so_far, digits)
      when :hydrae
        @index = pattern.cursor - depth
        @index += 1 if self.pattern.to_s =~ /^\./ # FIXME awful
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
            matches << Pattern.new(pattern.word_so_far, head).final
          elsif mode == :hydrae
            index = pattern.cursor - depth
            index += 1 if self.pattern.to_s =~ /^\./ # FIXME See above
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

  # Debug methods
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
    count
  end
end

class Club
  def initialize(hyph_level = 1, pat_lens = [2, 5], good = 1, bad = 1, thresh = 1, output = $stdout)
    @hyphenation_level = hyph_level
    @pattern_length_start = pat_lens.first
    @pattern_length_end = pat_lens.last
    @good_weight = good
    @bad_weight = bad
    @threshold = thresh

    @output = output
    @output.puts "Generating one pass ..."

    @knockouts = { }
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

  def pass(dictionary, count_hydra, final_hydra = Hydra.new, hyphenmins = [2, 3])
    unless final_hydra # TODO Document that
      final_hydra = Hydra.new
      final_hydra.setlefthyphenmin(hyphenmins.first)
      final_hydra.setrighthyphenmin(hyphenmins.last)
    end

    (@pattern_length_start..@pattern_length_end).each do |pattern_length|
      Heracles.organ(pattern_length).each do |dot|
        lineno = 0
        dictionary.each do |line|
          lineno += 1
          # print "\rRunning dictionary: pattern_length = #{@pattern_length}, dot = #{dot}, #{n}"
          lemma = Lemma.new(UnicodeUtils.downcase(line.gsub(/%.*$/, '').strip))
          next unless lemma.length >= pattern_length
          final_hydra.prehyphenate(lemma)
          word_start = dot - 1
          word_end = lemma.length - (pattern_length - dot) + 1
          hyph_start = final_hydra.lefthyphenmin
          hyph_end = lemma.length - final_hydra.righthyphenmin
          word_start = hyph_start if word_start < hyph_start
          word_end = hyph_end if word_end > hyph_end
          lemma.reset(word_start - dot)
          (word_start..word_end).each do |column|
            knocks = @knockouts[[lineno, lemma.cursor + dot]]
            # byebug if 
            if knocks
              knocks.each do |knock|
                knockcol = knock.first
                knocklen = knock.last
                if lemma.cursor <= knockcol && knockcol + knocklen <= lemma.cursor + pattern_length
                  # byebug
                  # @output.puts "Position knocked out!"
                  # next
                end
              end
            end
            currword = lemma.word_to(pattern_length)
            count_pattern = Pattern.simple(currword, dot, @hyphenation_level)
            count_hydra.ingest count_pattern
            patterns = { "a1k" => "good", "1ar" => "good", "e1c" => "good", "i1t" => "good", "k1k" => "good", "1len." => "good", "r1b" => "good", "s1b" => "good", "1se" => "good", "s1m" => "good", "t1n" => "good", # Intersection
            "1ent" => "missing", "h1m" => "missing", "n1d" => "missing", "1sc" => "missing", "1ste" => "missing", # Missing
            "l1e" => "spurious", "l1s" => "spurious", # Should no be there
            }
            s = count_pattern.to_s
            p = patterns[s]
            # puts "#{s} (#{p})" if p
            hydra = count_hydra.read(currword)
            # byebug if s == "a1c" || s == "a1ch"
            hydra.add_source(line: lineno, column: lemma.cursor, dot: dot, length: pattern_length)
            # byebug if s == "1er" || s == "1e2r" || currword == "er"
            # byebug if s == "2ck"
            # byebug if s == "be1"
            # byebug if s == "l1b"
            # byebug if s == "1st"
            if lemma.break(dot) == good then hydra.inc_good_count elsif lemma.break(dot) == bad then hydra.inc_bad_count end
            lemma.shift
          end
        end

        hopeless = good = unsure = 0
        n = 0
        # byebug
        @output.puts "hyph_level = #{@hyphenation_level}, pat_len = #{pattern_length}, pat_dot = #{dot}, #{count_hydra.count} patterns in count trie" # TODO Specify that # And TODO: Output that to a “device” so that by default it doesn’t clutter the standard output.
        # print "count_hydra: "
        count_hydra.each do |hydra|
          # byebug if hydra.pattern.to_s == "1er" || hydra.pattern.to_s == "e1r"
          n += 1
          # print "\rcount_hydra: #{n}"
          if hydra.good_count * @good_weight < @threshold
            hopeless += 1
            knockout(hydra.sources)
            hydra.chophead
            # hydra.reset_good_and_bad_counts
          elsif hydra.good_count * @good_weight - hydra.bad_count * @bad_weight >= @threshold
            good += 1
            # byebug if hydra.pattern.to_s == "a1c"
            knockout(hydra.sources)
            final_hydra.transplant hydra
          else # FIXME else clear good and bad counts? – definitely ;-)
            unsure += 1
            hydra.chophead
            hydra.clear_good_and_bad_counts
          end
        end
        @output.puts "#{good} good, #{hopeless} hopeless, #{unsure} unsure"
      end
    end

    final_hydra
  end
end

class Heracles
  def initialize(output = $stdout)
    @output = output
    @output.puts "This is Hydra, a Ruby implementation of patgen"
  end

  def run_file(filename, parameters = [], hyphenmins = [2, 3])
    run(File.read(filename).split("\n"), parameters, hyphenmins)
  end

  def run(array, parameters = [], hyphenmins = [2, 3])
    hyphenation_level_start = parameters.shift
    hyphenation_level_end = parameters.shift
    count_hydra = Hydra.new

    (hyphenation_level_start..hyphenation_level_end).each do |hyphenation_level|
      pattern_length_start = parameters.shift
      pattern_length_end = parameters.shift
      good_weight = parameters.shift
      bad_weight = parameters.shift
      threshold = parameters.shift
      pattern_lengths = [pattern_length_start, pattern_length_end]
      club = Club.new(hyphenation_level, pattern_lengths, good_weight, bad_weight, threshold, @output)
      @final_hydra = club.pass(array, count_hydra, @final_hydra, hyphenmins)
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
    @hydra = @heracles.run_file(@dictionary, parameters, hyphenmins)
    output = File.open(@output_patterns, 'w')
    output.write(@hydra.digest.join "\n")
    output.close

    @hydra
  end
end
