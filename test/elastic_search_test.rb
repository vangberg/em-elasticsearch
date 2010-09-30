require "./test/helper.rb"

class TestIndex < ElasticSearchTestCase
  def test_index
    EM.run {
      doc = {
        :index    => "notes",
        :type     => "person",
        :id       => "harry",
        :document => {
          "name"    => "Harry Dynamite",
          "country" => "Denmark"
        }
      }

      client.index(doc) do |response|
        assert response["ok"]
        assert_equal "notes", response["_index"]
        assert_equal "person", response["_type"]
        assert_equal "harry", response["_id"]
        EM.stop
      end
    }
  end
end

class TestSearch < ElasticSearchTestCase
  def index_persons
    harry = {
      :index    => "notes",
      :type     => "person",
      :id       => "harry",
      :document => {
        "name"    => "Harry Dynamite",
        "country" => "Denmark"
      }
    }
    joan = {
      :index    => "notes",
      :type     => "person",
      :id       => "joan",
      :document => {
        "name"    => "Joan January",
        "country" => "USA"
      }
    }

    client.index(harry) do
      client.index(joan) do
        yield
      end
    end
  end

  def test_search
    EM.run {
      index_persons do
        doc = {
          :index => "notes",
          :type  => "person",
          :query => {
            "term" => {
              "country" => "denmark"
            }
          }
        }

        client.search(doc) do |response|
          hits = response["hits"]
          assert_equal 1, hits["hits"].size

          hit = hits["hits"].first
          assert_equal "harry", hit["_id"]
          assert_equal "Harry Dynamite", hit["_source"]["name"]
          assert_equal "Denmark", hit["_source"]["country"]
          EM.stop
        end
      end
    }
  end
end
