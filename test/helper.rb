$:.unshift "lib"
require "bundler/setup"
require "test/unit"
require "em-spec/test"
require "contest"
require "couchlastic"
require "em-elasticsearch"
require "couchrest"
require "./test/fixtures.rb"

Couchlastic.options[:log_level] = Logger::WARN

class ElasticTestCase < Test::Unit::TestCase
  include EM::Test

  def elastic
    EM::ElasticSearch::Client.new("http://127.0.0.1:9200")
  end

  def cluster
    elastic.cluster
  end

  def couch
    @couch ||= CouchRest.new("http://localhost:5984").database("couchlastic")
  end
end
