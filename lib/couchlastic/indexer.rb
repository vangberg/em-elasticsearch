require "couchchanges"
require "em-elasticsearch"

module Couchlastic
  class Indexer
    def initialize
      @indices = {}
      @mappings = {}
      yield self if block_given?
    end

    attr_accessor :couch

    attr_reader :elastic

    def elastic= url
      @elastic = EventMachine::ElasticSearch::Client.new(url)
    end

    def map name, mapping
      @mappings[name] = mapping
    end

    def index name, &block
      @indices[name] = block
    end

    def start
      EM::Iterator.new(@mappings).each(
        method(:put_mapping),
        method(:listen_for_changes)
      )
    end

    private

    def put_mapping hash, iter=nil
      # This is because EM::Iterator doesn't check arity. Should patch that.
      name, type = hash[0].split("/")
      mapping    = hash[1]
      index      = elastic.index(name)

      Couchlastic.logger.info "Mapping #{name}/#{type}."

      index.create {
        index.type(type).map(mapping) {
          iter.next if iter
        }
      }
    end

    def listen_for_changes
      Couchlastic.logger.info "Listening to changes from #{@couch}"

      changes = CouchChanges.new :url => @couch, :include_docs => true
      changes.update {|change|
        Couchlastic.logger.info "Indexing update sequence #{change["seq"]}"

        doc = change.delete("doc")
        index_change change, doc
      }
      changes.listen
    end

    def index_change change, doc
      @indices.each {|name, block|
        if result = block.call(change, doc)
          type = elastic.index(name).type(result[:type])
          type.index(result[:id], result[:doc])
        end
      }
    end
  end
end
