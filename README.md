# Couchlastic

Make your CouchDB documents searchable with ElasticSearch. This is a work in
progress. Come back in a couple of weeks. Or months.


## example.rb

    EM.run {
      indexer = Couchlastic::Indexer.new do |i|
        i.couch   = "http://localhost:5984/mydb"
        i.elastic = "http://localhost:9200"

        i.map("notes/person", :properties => {
          "name" => {
            "type" => "string",
            "include_in_all" => false
          },
          "age" => {
            "type" => "integer",
            "include_in_all" => false
          }
        })

        i.index "people" do |change, doc|
          if doc["type"] == "person"
            {
              :id   => doc["_id"],
              :type => doc["type"],
              :doc  => {
                "name"    => doc["name"],
                "age"     => doc["age"],
                "country" => doc["country"]
              }
            }
          end
        end
      end

      indexer.start
    }
