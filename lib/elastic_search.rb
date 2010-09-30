require "em-http-request"
require "json"

class ElasticSearch
  class Client
    def initialize url
      @url = url
    end

    def index options
      request :put, options, :body => options[:document].to_json
    end

    def get options
      request :get, options
    end

    def search options
      options[:action] = "_search"
      request :post, options, :body => {"query" => options[:query]}.to_json
    end

    def request method, doc, options={}
      path = doc.values_at(:index, :type, :id, :action).compact.join("/")
      http = EM::HttpRequest.new(@url + "/" + path).send(method, options)
      req  = EM::DefaultDeferrable.new

      http.callback {
        if http.response_header.status >= 400
          req.fail http
        else
          response = JSON.parse(http.response)
          req.succeed response
        end
      }
      http.errback { req.fail http }
      req
    end
  end
end
