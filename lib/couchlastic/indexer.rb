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
        Couchlastic.logger.info "Indexing sequence #{c["seq"]}"
        @indices.each {|name, block|
          target = block.call c["doc"], Document.new
          if target
            type = elastic.index(name).type(target.type)
            type.index(target.id, target.source)
          end
        }
      }
      changes.listen :url => @couch, :include_docs => true
    end
  end

  class Document < Struct.new(:id, :type, :source)
  end
end
