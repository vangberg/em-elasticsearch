require "couchchanges"
require "elastic_search"

module Couchlastic
  class Indexer
    def initialize
      @indices = {}
      yield self if block_given?
    end

    def couch url=nil
      url ? @couch = url : @couch
    end

    def elastic url=nil
      if url
        @elastic = ElasticSearch::Client.new(url)
      else
        @elastic
      end
    end

    def index name, &block
      @indices[name] = block
    end

    def start
      changes = CouchChanges.new
      changes.update {|c|
        @indices.each {|name, block|
          res = block.call c["doc"]
          if res
            res[:index] = name
            res[:id] = c["id"]
            elastic.index(res)
          end
        }
      }
      changes.listen :url => @couch, :include_docs => true
    end
  end
end
