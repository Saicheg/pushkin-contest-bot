require 'json'
require 'logger'
require 'retryable'

class Solver

  TOKEN='3e81fe7c2ae2be50eb7b034ebb637c10'
  WORD="А-Яа-яЁё0-9"
  LINE="%LINE%"
  ADDR=URI("http://pushkin-contest.ror.by/")

  def initialize
    @poems = JSON.parse(File.read(File.expand_path('../../db/poems-full.json', __FILE__)))
    @poem_lines = @poems.map {|name, lines| lines }.flatten.map{|line| strip_punctuation(line) }
    @poem_string = @poems.map {|name, lines| lines }.flatten.map{|line| strip_punctuation(line) }.join(LINE)
    @poem_names = Hash[@poems.flat_map {|name, lines| lines.map {|line| [strip_punctuation(line), name]  }}]
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
    @poem_names[strip_punctuation(question)] || ""
  end

  def level_2(question)
    regexp = Regexp.new(strip_punctuation(question).gsub("%WORD%","([#{WORD}]+)"))
    regexp.match(@poem_string)[1] rescue nil
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
    spaces = string.gsub(/\A[[:space:]]*/, '').gsub(/[[:space:]]*\z/, '')
    # Some dirty hacks here
    spaces += ',' if spaces[-1] == '%'
    spaces.gsub(/[[:punct:]]{1}\z/, '')
  end

  def send_answer(answer, task_id)
    retryable(tries: 3) do
      data = { answer: answer, token: TOKEN, task_id: task_id}
      @http.post('/quiz', data.to_json, {'Content-Type' =>'application/json'})
    end
  end

end
