require 'rest_client'

RESPONSE_IDLE_TIME=120

uri = URI("http://0.0.0.0:8080/quiz")
data = {
  "question" => "Отчизны внемлем призыванье",
  "id"       => 6595,
  "level"    => 1
}
options = {content_type: :json, accept: :json, timeout: RESPONSE_IDLE_TIME}

RestClient.post uri.to_s, data.to_json, options
