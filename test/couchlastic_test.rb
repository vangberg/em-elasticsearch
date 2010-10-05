require "./test/helper.rb"

Indexer = Couchlastic::Indexer.new do |c|
  c.couch "http://127.0.0.1:5984/couchlastic"
  c.elastic "http://127.0.0.1:9200"

  c.map("notes/person",
    :properties => {
      "_id"  => {"include_in_all" => false},
      "type" => {"include_in_all" => false}
    }
  )

  c.index "notes" do |change|
    {
      :id   => change["doc"]["_id"],
      :type => change["doc"]["type"],
      :doc  => change["doc"]
    }
  end
end

class TestIndexer < ElasticTestCase
  setup do
    couch.recreate!
    couch.save_doc Harry
    couch.save_doc Joan
    couch.save_doc Klaus
    couch.delete_doc Klaus
  end

  def prepare &block
    elastic.cluster.delete_all_indices {
      Indexer.start
      EM.add_timer(2, block)
    }
  end

  test "save mapping" do
    prepare {
      request = elastic.index("notes").type("person").mapping
      request.callback {|response|
        properties = response["notes"]["person"]["properties"]
        assert_false properties["_id"]["include_in_all"]
        assert_false properties["type"]["include_in_all"]
        done
      }
    }
  end

  test "index docs" do
    prepare {
      request = elastic.index("notes").type("person").get("joan")
      request.callback {|response|
        assert_equal "joan", response["_id"]
        assert_equal "Joan January", response["_source"]["name"]
        assert_equal "USA", response["_source"]["country"]
        done
      }
      request.errback { flunk "didn't index doc" }
    }
  end

  test "remove docs" do
    prepare {
      request = elastic.index("notes").type("person").get("klaus")
      request.callback { flunk "doc should be deleted" }
      request.errback { done }
    }
  end
end
