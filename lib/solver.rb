require 'json'
require 'logger'
require 'retryable'
require 'active_support/json'
require 'active_support/core_ext/module/delegation'
require 'active_support/core_ext/string'
require 'active_support/core_ext/array'
require 'active_support/multibyte/chars'

class Solver

  TOKEN='3e81fe7c2ae2be50eb7b034ebb637c10'
  WORD="А-Яа-яЁё0-9"
  LINE="%%"
  ADDR=URI("http://pushkin-contest.ror.by/")

  def initialize
    poems = JSON.parse(File.read(File.expand_path('../../db/poems-full.json', __FILE__)))
    @poem_names = Hash[poems.flat_map {|name, lines| lines.map {|line| [normalize(line), name]  }}]

    all_lines = poems.map {|name, lines| lines }.flatten.map{|line| normalize(line) }

    @level_2 = {}

    all_lines.each do |line|
      words = line.split(/\s+/).map {|word| normalize(word)}
      words.each {|word| @level_2[line.sub(word, '%word%')] = word }
    end

    @level_3 = {}

    0.upto(all_lines.length-1) do |i|
      first, last = all_lines[i], all_lines[i+1]

      next if first.nil? || last.nil?

      first_arr = []
      words = first.split(/\s+/).map {|word| normalize(word)}
      words.each {|word| first_arr << [first.sub(word, '%word%'), word] }

      last_arr = []
      words = last.split(/\s+/).map {|word| normalize(word)}
      words.each {|word| last_arr << [last.sub(word, '%word%'), word] }

      first_arr.each do |first_line, first_word|
        last_arr.each do |last_line, last_word|
          question = "#{first_line}\n#{last_line}"
          answer = "#{first_word},#{last_word}"
          @level_3[question] = answer
        end
      end
    end

    @poem_string = poems.map {|name, lines| lines }.flatten.map{|line| normalize(line) }.join(LINE)

    @http = Net::HTTP.new(ADDR.host)
    @http.set_debug_output $stdout
  end

  def call(env)
    params = JSON.parse(env["rack.input"].read)
    resolve(params)
    [200, {'Content-Type' => 'application/json'}, StringIO.new("Hello World!\n")]
  end

  def resolve(params)
    answer = self.send("level_#{params["level"]}", params["question"])
    send_answer(answer, params["id"])
  end

  def level_1(question)
    @poem_names[normalize(question)] || ""
  end

  def level_2(question)
    normalized = normalize(question)
    @level_2[normalized]
  end

  def level_3(question)
    normalized = question.split("\n").map {|line| normalize(line) }.join("\n")
    @level_3[normalized]
  end

  def level_4(question)
    regexp = Regexp.new(question.split("\n").map{|str| normalize(str) }.join(LINE).gsub("%word%","([#{WORD}]+)"))
    regexp.match(@poem_string)[1..3].join(',')
  end

  def level_5(question)
    normalized = normalize(question)
    words = normalized.scan(/[#{WORD}]+/)
    regexp = Regexp.new words.map { |word| normalized.sub(word, "([#{WORD}]+)")}.join('|')
    answer = regexp.match(@poem_string)[1..-1]
    index = index = answer.index {|x| !x.nil?}
    "#{answer[index]},#{words[index]}"
  end

  def normalize(string)
    downcase = string.mb_chars.downcase
    spaces = downcase.gsub(/\A[[:space:]]*/, '').gsub(/[[:space:]]*\z/, '')
    spaces.gsub(/[\.\,\!\:\;\?]+\z/, '').to_s
  end

  def send_answer(answer, task_id)
    retryable(tries: 3) do
      data = { answer: answer, token: TOKEN, task_id: task_id}
      @http.post('/quiz', data.to_json, {'Content-Type' =>'application/json'})
    end
  end

end
