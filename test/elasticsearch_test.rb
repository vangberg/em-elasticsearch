require "./test/helper.rb"

class TestHTTP < ElasticTestCase
  include EventMachine::ElasticSearch::HTTP

  def base_url
    "http://localhost:9200"
  end

  test "successful explicit callback" do
    req = request(:get, "/")
    req.callback {|response|
      assert response["ok"]
      done
    }
  end

  test "successful implicit callback" do
    req = request(:get, "/") {|response|
      assert response["ok"]
      done
    }
  end

  test "successful implicit callback with error arg" do
    req = request(:get, "/") {|response, err|
      assert response["ok"]
      assert_nil err
      done
    }
  end

  test "failing explicit callback" do
    req = request(:get, "/_non-existing")
    req.callback { flunk "should fail on /_non-existing"; done }
    req.errback {|err|
      assert_not_nil err
      done
    }
  end

  test "failing implicit callback with error arg" do
    req = request(:get, "/_non-existing") {|response, err|
      assert_not_nil err
      done
    }
  end
end

class TestClient < ElasticTestCase
  test "#base_url" do
    assert_equal "http://127.0.0.1:9200", elastic.base_url
    done
  end

  test "#status" do
    elastic.status {|response|
      assert response["ok"]
      done
    }
  end

  test "#bulk" do
    cluster.delete_all_indices {
      ops = [
        {"index" => {"index" => "notes", "type" => "person", "id" => "harry"}},
        {"person" => {"name" => "Harry", "country" => "Denmark"}},
        {"delete" => {"index" => "notes", "type" => "person", "id" => "harry"}}
      ]
      elastic.bulk(ops) {|response|
        assert_equal 2, response["items"].size
        assert_equal "index", response["items"][0].keys[0]
        assert_equal "delete", response["items"][1].keys[0]
        done
      }
    }
  end
end

class TestCluster < ElasticTestCase
  test "#base_url" do
    assert_equal "http://127.0.0.1:9200/_cluster", cluster.base_url
    done
  end

  test "#state" do
    cluster.state {|state|
      assert_not_nil state["cluster_name"]
      done
    }
  end

  # this test doesn't really test we get indices from cluster, though.
  test "#indices" do
    cluster.delete_all_indices {
      elastic.index("foo").create {
        elastic.index("bar").create {
          cluster.indices {|indices|
            assert_equal 2, indices.size
            assert indices["foo"].is_a? EventMachine::ElasticSearch::Index
            assert indices["bar"].is_a? EventMachine::ElasticSearch::Index
            done
          }
        }
      }
    }
  end

  test "#delete_all_indices" do
    cluster.delete_all_indices {
      cluster.state {|response|
        assert_equal 0, response["metadata"]["indices"].size
        done
      }
    }
  end
end

class TestIndex < ElasticTestCase
  setup do
    @notes = elastic.index("notes")
  end

  test "require name" do
    begin
      elastic.index(nil)
      flunk "should raise ArgumentError"
    rescue ArgumentError
      done
    end
  end

  test "#base_url" do
    assert_equal "http://127.0.0.1:9200/notes", @notes.base_url
    done
  end

  test "#create" do
    cluster.delete_all_indices {
      @notes.create {|response|
        assert response["ok"]
        done
      }
    }
  end

  test "#create with settings" do
    cluster.delete_all_indices {
      @notes.create(:index => {:number_of_shards => 2}) {|response|
        assert response["ok"]
        done
      }
    }
  end

  test "#status" do
    cluster.delete_all_indices {
      @notes.create {
        @notes.status {|response|
          assert response["ok"]
          assert_not_nil response["_shards"]
          done
        }
      }
    }
  end

  test "#delete" do
    cluster.delete_all_indices {
      @notes.create {
        @notes.delete {
          cluster.indices {|response|
            assert_nil response["notes"]
            done
          }
        }
      }
    }
  end
end

class TestType < ElasticTestCase
  setup do
    @notes = elastic.index("notes")
    @person = @notes.type("person")
  end

  test "require name" do
    begin
      @notes.type(nil)
      flunk "should raise ArgumentError"
    rescue ArgumentError
      done
    end
  end

  test "#base_url" do
    assert_equal "http://127.0.0.1:9200/notes/person", @person.base_url
    done
  end

  test "#index" do
    cluster.delete_all_indices {
      @person.index("harry", Harry) {|response|
        assert response["ok"]
        assert_equal "notes", response["_index"]
        assert_equal "person", response["_type"]
        assert_equal "harry", response["_id"]
        done
      }
    }
  end

  test "#get" do
    cluster.delete_all_indices {
      @person.index("harry", Harry, :refresh => true) {
        @person.get("harry") {|response|
          assert_equal "notes", response["_index"]
          assert_equal "person", response["_type"]
          assert_equal "harry", response["_id"]
          assert_equal "Denmark", response["_source"]["country"]
          done
        }
      }
    }
  end

  STRING_MAPPING = {
    "properties" => {
      "name" => {"type" => "string"}
    }
  }

  INTEGER_MAPPING = {
    "properties" => {
      "name" => {"type" => "integer"}
    }
  }

  test "#map/#mapping" do
    cluster.delete_all_indices {@notes.create {
      @person.map(STRING_MAPPING) {|response|
        assert response["ok"]
        @person.mapping {|response|
          type = response["notes"]["person"]["properties"]["name"]["type"]
          assert_equal "string", type
          done
        }
      }
    }}
  end

  test "#map with conflict" do
    cluster.delete_all_indices {@notes.create {
      @person.map(STRING_MAPPING) {
        request = @person.map(INTEGER_MAPPING)
        request.callback { flunk "should fail with merge conflict"; done }
        request.errback { done }
      }
    }}
  end
end

#class EM::HttpClient
  #alias :old_receive :receive_data
  #alias :old_send :send_data

  #def receive_data d
    #puts "<<<<<\n#{d}"
    #old_receive d
  #end

  #def send_data d
    #puts ">>>>>\n#{d}"
    #old_send d
  #end
#end
