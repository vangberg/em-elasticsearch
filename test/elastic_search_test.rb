require "./test/helper.rb"

include SearchHelpers

EM.describe "index" do
  it "indexes documents" do
    client.index(Harry) do |response|
      response["ok"].should     == true
      response["_index"].should == "notes"
      response["_type"].should  == "person"
      response["_id"].should    == "harry"
      done
    end
  end
end

EM.describe "search" do
  it "finds hits" do
    client.index(Joan) do
      client.index(Harry) do
        query = {
          :index => "notes",
          :type  => "person",
          :query => {
            "term" => {
              "country" => "denmark"
            }
          }
        }
        client.search(query) do |response|
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
