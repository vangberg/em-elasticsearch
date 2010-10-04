require "./test/helper.rb"

Harry = {
  "name"    => "Harry Dynamite",
  "country" => "Denmark"
}
Joan = {
  "name"    => "Joan January",
  "country" => "USA"
}

class TestHTTP < ElasticTestCase
  include ElasticSearch::HTTP

  def base_url
    "http://localhost:9200"
  end

  test "explicit callback" do
    req = request(:get, "/")
    req.callback {|response|
      assert response["ok"]
      done
    }
  end

  test "implicit callback" do
    req = request(:get, "/") {|response|
      assert response["ok"]
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
            assert indices["foo"].is_a? ElasticSearch::Index
            assert indices["bar"].is_a? ElasticSearch::Index
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

  test "#index" do
    cluster.delete_all_indices {
      @notes.index("person", "harry", Harry) {|response|
        assert response["ok"]
        assert_equal "notes", response["_index"]
        assert_equal "person", response["_type"]
        assert_equal "harry", response["_id"]
        done
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

#class EM::HttpClient
  #alias :old_receive :receive_data
  #alias :old_send :send_data

  #def receive_data d
    #puts "<#{d}"
    #old_receive d
  #end

  #def send_data d
    #puts ">#{d}"
    #old_send d
  #end
#end
