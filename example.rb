require "couchlastic"

EM.run {
  indexer = Couchlastic::Indexer.new

  indexer.couch "http://localhost:5984/metadb"
  indexer.elastic "http://localhost:8983/solr"

  indexer.index "foo" do |doc|
    case doc["type"]
    when "user" then
      {"text" => doc["username"]}
    else
      nil
    end
  end

  indexer.start
}
