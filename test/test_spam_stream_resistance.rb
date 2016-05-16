require 'minitest_helper'

class TestSpamStreamResistance < Minitest::Test
  def test_that_it_has_a_version_number
    refute_nil ::SpamStreamResistance::VERSION
  end

  def test_it_does_something_useful
  	SpamStreamResistance.new.test_method
    assert false
  end
end
