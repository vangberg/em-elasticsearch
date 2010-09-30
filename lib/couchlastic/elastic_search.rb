require "em-http-request"
require "json"

module Couchlastic
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

        http.callback {
          response = JSON.parse(http.response)
          yield response
        }
        http.errback { raise "err from index" }
      end

      def search options
        path = options.values_at(:index, :type).join("/")
        http = EM::HttpRequest.new(@url + "/" + path + "/_search").post(
          :body => {"query" => options[:query]}.to_json
        )

        http.callback {
          response = JSON.parse(http.response)
          yield response
        }
        http.errback { raise "err from search" }
      end
    end
  end
end
