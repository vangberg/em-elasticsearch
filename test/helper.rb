$:.unshift "lib"
require "bundler/setup"
require "bacon"
require "em-spec/bacon"
require "fiber"
require "couchlastic"
require "elastic_search"
require "couchrest"

Couchlastic.options[:log_level] = Logger::WARN

EM.spec_backend = EM::Spec::Bacon
Bacon.summary_on_exit

module Helpers
  def elastic
    @elastic ||= ElasticSearch::Client.new("http://127.0.0.1:9200")
  end

  def couch
    @couch ||= CouchRest.new("http://localhost:5984").database("couchlastic")
  end
end
