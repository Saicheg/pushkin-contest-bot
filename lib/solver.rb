require 'json'
require 'rest_client'
require 'logger'
require 'retryable'

class Solver

  TOKEN='3e81fe7c2ae2be50eb7b034ebb637c10'
  WORD="А-Яа-яЁё0-9"
  LINE="%LINE%"

  def initialize
    @poems = JSON.parse(File.read(File.expand_path('../../db/poems.json', __FILE__)))
    @poem_lines = @poems.values.flatten.map{|line| strip_punctuation(line) }
    @poem_string = @poems.values.flatten.map{|line| strip_punctuation(line) }.join(LINE)
    @poem_names = Hash[@poems.flat_map {|name, lines| lines.map {|line| [strip_punctuation(line), name]  }}]
    RestClient.log = Logger.new($stdout)
  end

  def call(env)
    params = JSON.parse(env["rack.input"].read)
    # Thread.new(params) { resolve(params) }
    resolve(params)
    [200, {'Content-Type' => 'application/json'}, StringIO.new("Hello World!\n")]
  end

  def resolve(params)
    answer = self.send("level_#{params["level"]}", params["question"])
    send_answer(answer, params["id"])
  end

  def level_1(question)
    @poem_names[strip_punctuation(question)] || ""
  end

  def level_2(question)
    regexp = Regexp.new(strip_punctuation(question).gsub("%WORD%","([#{WORD}]+)"))
    answer = regexp.match(@poem_string)[1] rescue nil
    if answer.nil?
      @poem_lines.find { |line| line =~ regexp }
      answer = $1
    end
    answer
  end

  def level_3(question)
    regexp = Regexp.new(question.split("\n").map{|str| strip_punctuation(str) }.join(LINE).gsub("%WORD%","([#{WORD}]+)"))
    (regexp.match(@poem_string) || [])[1..2].join(',')
  end

  def level_4(question)
    regexp = Regexp.new(question.split("\n").map{|str| strip_punctuation(str) }.join(LINE).gsub("%WORD%","([#{WORD}]+)"))
    regexp.match(@poem_string)[1..3].join(',')
  end

  def strip_punctuation(string)
    string.strip.gsub(/[[:punct:]]\z/, '')
  end

  def send_answer(answer, task_id)
    retryable(tries: 3) do
      uri = URI("http://pushkin-contest.ror.by/quiz")
      data = { answer: answer, token: TOKEN, task_id: task_id}
      Net::HTTP.post_form(uri, data)

      # uri = URI("http://pushkin-contest.ror.by/quiz")

      # options = {content_type: :json, accept: :json}

      # response = RestClient.post uri.to_s, data.to_json, options
      # raise if response.code.to_i != 200
    end
  end

end
