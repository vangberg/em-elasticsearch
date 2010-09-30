require "./test/helper.rb"

include Helpers

Harry = {
  :index    => "notes",
  :type     => "person",
  :id       => "harry",
  :document => {
    "name"    => "Harry Dynamite",
    "country" => "Denmark"
  }
}
Joan = {
  :index    => "notes",
  :type     => "person",
  :id       => "joan",
  :document => {
    "name"    => "Joan January",
    "country" => "USA"
  }
}

EM.describe ElasticSearch do
  it "indexes documents" do
    req = elastic.index(Harry)
    req.callback {|response|
      response["ok"].should     == true
      response["_index"].should == "notes"
      response["_type"].should  == "person"
      response["_id"].should    == "harry"
      done
    }
  end

  it "gets documents" do
    req = elastic.index(Joan)
    req.callback do
      elastic.get(:index => "notes", :type => "person", :id => "joan").callback do |response|
        response["_id"].should == "joan"
        done
      end
    end
  end

  it "searches documents" do
    elastic.index(Joan).callback do
      elastic.index(Harry).callback do
        query = {
          :index => "notes",
          :type  => "person",
          :query => {
            "term" => {
              "country" => "denmark"
            }
          }
        }
        req = elastic.search(query)
        req.callback do |response|
          hits = response["hits"]
          hits["hits"].size.should == 1

          hit = hits["hits"].first
          hit["_id"].should == "harry"
          done
        end
      end
    end
  end
end
