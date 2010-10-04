# Couchlastic

Make your CouchDB documents searchable with ElasticSearch.

## example.rb

    require "couchlastic"

    EM.run {
      indexer = Couchlastic::Indexer.new

      indexer.couch "http://localhost:5984/mydb"
      indexer.elastic "http://localhost:9200

      indexer.index "people" do |source, target|
        if source["type"] == "person"
          target.id = source["_id"]
          target.type = "person"
          target.source = {
            :name => doc["name"],
            :country => doc["country"]
          }
        end
      end

      indexer.start
    }
