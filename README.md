# Couchlastic

Make your CouchDB documents searchable with ElasticSearch.

## example.rb

    require "couchlastic"

    EM.run {
      indexer = Couchlastic::Indexer.new

      indexer.couch "http://localhost:5984/mydb"
      indexer.elastic "http://localhost:9200

      indexer.index "people" do |doc|
        case doc["type"]
        when "person" then
          {
            :type    => "person",
            :name    => doc["name"],
            :country => doc["country"]
          }
        else
          nil
        end
      end

      indexer.start
    }
