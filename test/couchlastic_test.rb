require "./test/helper.rb"

include Helpers

harry = {
  "_id"     => "harry",
  "type"    => "person",
  "name"    => "Harry Dynamite",
  "country" => "Denmark"
}

joan = {
  "_id"     => "joan",
  "type"    => "person",
  "name"    => "Joan January",
  "country" => "USA"
}

klaus = {
  "_id"     => "klaus",
  "type"    => "person",
  "name"    => "Klaus Denn",
  "country" => "Germany"
}

Indexer = Couchlastic::Indexer.new do |c|
  c.couch "http://localhost:5984/couchlastic"
  c.elastic "http://localhost:9200"

  c.index "persons" do |doc|
    {
      :type     => "person",
      :document => doc
    }
  end
end

EM.describe Indexer do
  before do
    couch.recreate!
    couch.save_doc harry
    couch.save_doc joan
    couch.save_doc klaus
    couch.delete_doc klaus
    Indexer.start
  end

  it "indexes docs" do
    EM.add_timer(0.5) {
      elastic.get(:index => "notes", :type => "person", :id => "joan") do |response|
        response["_id"].should == "joan"
        response["_source"].should == {
          "name"    => "Joan January",
          "country" => "USA"
        }
        done
      end
    }
  end
end
