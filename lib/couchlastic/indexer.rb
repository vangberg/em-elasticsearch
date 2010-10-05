require "couchchanges"
require "em-elasticsearch"

module Couchlastic
  class Indexer
    def initialize
      @indices = {}
      @mappings = {}
      yield self if block_given?
    end

    def couch url=nil
      url ? @couch = url : @couch
    end

    def elastic url=nil
      if url
        @elastic = EventMachine::ElasticSearch::Client.new(url)
      else
        @elastic
      end
    end

    def map name, mapping
      @mappings[name] = mapping
    end

    def index name, &block
      @indices[name] = block
    end

    def start
      EM::Iterator.new(@mappings).map(lambda {|hash, iter|
        index, type = hash[0].split("/")
        mapping = hash[1]
        r = elastic.index(index).type(type).map(mapping) {
          p "mapped"
          iter.return true
        }
        r.errback {|h| p h.response}
      }, lambda {
        p "done"
        changes = CouchChanges.new
        changes.update {|change|
          Couchlastic.logger.info "Indexing sequence #{change["seq"]}"
          @indices.each {|name, block|
            doc = block.call change
            if doc
              type = elastic.index(name).type(doc[:type])
              type.index(doc[:id], doc[:doc])
            end
          }
        }
        changes.listen :url => @couch, :include_docs => true
      })
    end
  end
end
