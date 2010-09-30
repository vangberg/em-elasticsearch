$:.unshift "lib"
require "bundler/setup"
require "bacon"
require "em-spec/bacon"
require "fiber"
require "couchlastic"

EM.spec_backend = EM::Spec::Bacon
Bacon.summary_on_exit

module SearchHelpers
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
  
  def client
    @client ||= Couchlastic::ElasticSearch::Client.new("http://127.0.0.1:9200")
  end
end
