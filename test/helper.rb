require "bundler/setup"
$:.unshift "lib"
require "test/unit"
require "couchlastic"

class ElasticSearchTestCase < Test::Unit::TestCase
  def client
    @client ||= Couchlastic::ElasticSearch::Client.new("http://127.0.0.1:9200")
  end
end
