require "em-http-request"
require "json"

class ElasticSearch
  class Client
    def initialize url
      @url = url
    end

    def index options
      path = options.values_at(:index, :type, :id).join("/")
      http = EM::HttpRequest.new(@url + "/" + path).put(
        :body => options[:document].to_json
      )
      req = EM::DefaultDeferrable.new

      http.callback {
        response = JSON.parse(http.response)
        req.succeed response
      }
      http.errback { raise "err from index: #{http.response}" }
      req
    end

    def get options
      path = options.values_at(:index, :type, :id).join("/")
      http = EM::HttpRequest.new(@url + "/" + path).get
      req = EM::DefaultDeferrable.new

      http.callback {
        response = JSON.parse(http.response)
        req.succeed response
      }
      http.errback { raise "err from get: #{http.response}" }
      req
    end

    def search options
      path = options.values_at(:index, :type).join("/")
      http = EM::HttpRequest.new(@url + "/" + path + "/_search").post(
        :body => {"query" => options[:query]}.to_json
      )
      req = EM::DefaultDeferrable.new

      http.callback {
        response = JSON.parse(http.response)
        req.succeed response
      }
      http.errback { raise "err from search: #{http.response}" }
      req
    end
  end

  class Request
    include EventMachine::Deferrable
  end
end
