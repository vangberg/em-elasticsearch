Gem::Specification.new do |s|
  s.name        = "em-elasticsearch"
  s.version     = "0.1"
  s.date        = "2010-10-12"
  s.summary     = "elasticsearch library for eventmachine"
  s.email       = "harry@vangberg.name"
  s.homepage    = "http://github.com/ichverstehe/em-elasticsearch"
  s.description = "elasticsearch library for eventmachine"
  s.authors  = ["Harry Vangberg"]
  s.files    = [
    "README.md",
    "LICENSE",
    "Rakefile",
		"em-elasticsearch.gemspec",
		"lib/em-elasticsearch.rb"
  ]
  s.test_files  = [
    "test/fixtures.rb",
    "test/helper.rb",
    "test/elasticsearch_test.rb",
  ]
  s.add_dependency "em-http-request", "~> 0.2.13"
  s.add_dependency "json", "~> 1.4.6"
  
  s.add_development_dependency "em-spec"
  s.add_development_dependency "contest"
  s.add_development_dependency "couchrest"
end

