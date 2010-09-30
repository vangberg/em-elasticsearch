Indexer = Couchlastic.new do |c|
  c.couch "http://localhost:5984/couchlastic"
  c.elastic "http://localhost:9200/couchlastic/test"
  
end

class TestCouchlastic < Test::Unit::TestCase
  include EventMachine::Test
end
