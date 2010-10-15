require "eventmachine"
require "em-http-request"
require "json"

module EventMachine
  class ElasticSearch
    class MissingNameError < StandardError; end

    module HTTP
      def request method, path="/", options={}, &block
        options[:head] ||= {}
        options[:head].merge! "content-type" => "application/json; charset=UTF-8"
        options[:timeout] ||= 1
        http = EM::HttpRequest.new(base_url + path).send(method, options)
        req  = EM::DefaultDeferrable.new

        http.callback {
          if http.response_header.status >= 400
            yield http.response, true if block_given?
            req.fail http
          else
            response = JSON.parse(http.response)
            yield response if block_given?
            req.succeed response
          end
        }
        http.errback { req.fail http }

        req
      end
    end

    class Client
      include HTTP

      attr_accessor :base_url

      def initialize url
        @base_url = url
      end

      def flush &block
        request :post, "/_flush", &block
      end

      def status &block
        request :get, "/_status", &block
      end

      def bulk operations, &block
        body = operations.map {|o| o.to_json + "\n"}.join
        request :post, "/_bulk", :body => body, &block
      end

      def cluster
        @cluster ||= Cluster.new self
      end

      def index name
        Index.new self, name
      end
    end

    class Cluster
      include HTTP

      attr_reader :client

      def initialize client
        @client = client
      end

      def base_url
        @client.base_url + "/_cluster"
      end

      def state &block
        request :get , "/state", &block
      end

      def indices
        state {|response|
          result = {}
          response["metadata"]["indices"].keys.map {|name|
            result[name] = Index.new(@client, name)
          }
          yield result
        }
      end

      def delete_all_indices &block
        indices {|response|
          EM::Iterator.new(response.keys).map(lambda {|name, iter|
            @client.request(:delete, "/" + name) {iter.return name}
          }, block)
        }
      end
    end

    class Index
      include HTTP

      attr_reader :client, :name

      def initialize client, name
        raise ArgumentError, "#{name} is not a valid name" unless name
        @client = client
        @name   = name
      end

      def base_url
        @client.base_url + "/" + @name
      end

      def type name
        Type.new self, name
      end

      def create options={}, &block
        request :put, "/", :body => options.to_json, &block
      end

      def status &block
        request :get, "/_status", &block
      end

      def delete &block
        request :delete, &block
      end
    end

    class Type
      include HTTP

      attr_reader :elastic_index, :name

      def initialize elastic_index, name
        raise ArgumentError, "#{name} is not a valid name" unless name

        @elastic_index = elastic_index
        @name = name
      end

      def base_url
        @elastic_index.base_url + "/" + @name
      end

      def index id, doc, options={}, &block
        request :put, "/#{id}", :body => doc.to_json, :query => options, &block
      end

      def get id, &block
        request :get, "/#{id}", &block
      end

      def mapping &block
        request :get, "/_mapping", &block
      end

      def map mapping, options={}, &block
        body = { @name => mapping }.to_json
        request :put, "/_mapping", :body => body, :query => options, &block
      end
    end
  end
end
