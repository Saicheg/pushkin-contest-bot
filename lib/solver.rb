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

    @poem_string = poems.map {|name, lines| lines }.flatten.map{|line| normalize(line) }.join(LINE)

    @http = Net::HTTP.new(ADDR.host)
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
    question.split("\n").map {|line| @level_2[normalize(line)] }.join(',')
  end

  def level_4(question)
    question.split("\n").map {|line| @level_2[normalize(line)] }.join(',')
  end

  def level_5(question)
    normalized = normalize(question)
    words = normalized.scan(/[#{WORD}]+/)
    strings = words.map {|word| normalized.sub(word, "%word%") }
    answers = strings.map {|string| @level_2[string]}
    index = answers.index {|x| !x.nil?}
    "#{answers[index]},#{words[index]}"
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
