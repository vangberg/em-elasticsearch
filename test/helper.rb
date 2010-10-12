$:.unshift "lib"
require "test/unit"
require "em-spec/test"
require "contest"
require "em-elasticsearch"
require "./test/fixtures.rb"

class ElasticTestCase < Test::Unit::TestCase
  include EM::Test

  def elastic
    EM::ElasticSearch::Client.new("http://127.0.0.1:9200")
  end

  def cluster
    elastic.cluster
  end
end
