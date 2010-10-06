require "./test/helper.rb"

Indexer = Couchlastic::Indexer.new do |c|
  c.couch   = {
    :url => "http://127.0.0.1:5984/couchlastic",
    :timeout => 1
  }
  c.elastic = "http://127.0.0.1:9200"

  c.map("notes/person",
    :properties => {
      "name" => {
        "type" => "string",
        "include_in_all" => false
      },
      "age" => {
        "type" => "integer",
        "include_in_all" => false
      }
    }
  )

  c.index "notes" do |change, doc|
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

class TestIndexer < ElasticTestCase
  setup do
    couch.recreate!
    couch.save_doc Harry
    couch.save_doc Joan
    couch.save_doc Klaus
    couch.save_doc Volvo
    couch.delete_doc Klaus
  end

  def prepare &block
    elastic.cluster.delete_all_indices {
      Indexer.disconnect &block
      Indexer.start
    }
  end

  test "disconnect callback" do
    elastic.cluster.delete_all_indices {
      EM.add_timer(1) { flunk "should invoke disconnect callback" }
      Indexer.disconnect { done }
      Indexer.start
    }
  end

  test "save mapping" do
    prepare {
      request = elastic.index("notes").type("person").mapping
      request.callback {|response|
        properties = response["notes"]["person"]["properties"]
        assert ! properties["name"]["include_in_all"]
        assert ! properties["age"]["include_in_all"]
        done
      }
    }
  end

  test "index docs" do
    prepare {
      EM.add_timer(1.5) {
        request = elastic.index("notes").type("person").get("joan")
        request.callback {|response|
          assert_equal "joan", response["_id"]
          assert_equal "Joan January", response["_source"]["name"]
          assert_equal "USA", response["_source"]["country"]
          done
        }
        request.errback { flunk "didn't index doc" }
      }
    }
  end

  test "remove docs" do
    prepare {
      request = elastic.index("notes").type("person").get("klaus")
      request.callback { flunk "doc should be deleted" }
      request.errback { done }
    }
  end

  test "don't index nil returns" do
    prepare {
      request = elastic.index("notes").type("car").get("volvo")
      request.callback { flunk "doc should not be indexed" }
      request.errback { done }
    }
  end
end
