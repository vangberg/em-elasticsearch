Gem::Specification.new do |s|
  s.name        = "couchlastic"
  s.version     = "0.1"
  s.date        = "2010-09-30"
  s.summary     = "index couch docs in elasticsearch"
  s.email       = "harry@vangberg.name"
  s.homepage    = "http://github.com/ichverstehe/couchlastic"
  s.description = "index couch docs in elasticsearch"
  s.authors  = ["Harry Vangberg"]
  s.files    = [
    "README.md",
    "LICENSE",
    "Rakefile",
		"couchlastic.gemspec",
		"lib/couchlastic.rb"
  ]
  s.test_files  = [
    "test/couchlastic_test.rb",
  ]
  s.add_dependency "em-http-request", "~> 0.2.13"
  s.add_dependency "json", "~> 1.4.6"
  
  s.add_development_dependency "em-spec"
  s.add_development_dependency "contest"
  s.add_development_dependency "couchrest"
end

