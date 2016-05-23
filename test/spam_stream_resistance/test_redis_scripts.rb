require 'minitest_helper'

# rake test TEST=test/spam_stream_resistance/test_redis_scripts.rb

class SpamStreamResistance::TestRedisScripts < Minitest::Test
  def setup
    @redis_scripts
  end

  def test_redis_script
    assert false
  end

end