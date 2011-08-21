
require File.expand_path("#{File.dirname(__FILE__)}/../test_helper")

class MirroringTest < Test::Unit::TestCase
  def setup
    @cache  = Memcached.new('localhost:43042|localhost:43043|100')
    @mirror = Memcached.new('localhost:43043')
  end

  def test_get_sets_data_on_mirror
    @cache.set("key", "value")
    assert_raises Memcached::NotFound do
      @mirror.get("key")
    end

    @cache.get("key")
    assert_equal "value", @mirror.get("key")
  end

  def test_get_multiple_keys_should_set_data_on_mirror
    @cache.set("key1", "value1")
    @cache.set("key2", "value2")
    @cache.set("key3", "value3")

    @mirror.set("key2", "value2")
    @mirror.set("key3", "value4")
    
    result1 = @cache.get(%w{key1 key2 key3 key4})
    result2 = @mirror.get(%w{key1 key2 key3 key4})

    result1.keys.each do |k|
      assert_equal result1[k], result2[k]
    end
  end

  def test_mirroring_should_respect_rate
    @cache.set("fail", "rand")
    Kernel.stubs(:rand).returns(1.1)
    @cache.get("fail")
    assert_raises Memcached::NotFound do
      puts @mirror.get("fail")
    end
  end

  def test_mirroring_should_preserve_realiasing_of_commands
    Memcached.class_eval do
      def get_with_hello(*args, &block)
        get_without_hello(*args, &block)
        "hello"
      rescue
        "hello"
      end

      alias :get_without_hello :get
      alias :get :get_with_hello
    end
    
    cache = Memcached.new('localhost:43042')
    assert_equal 'hello', cache.get('w/e')

    cache = Memcached.new('localhost:43042|localhost:43043')
    assert_equal 'hello', cache.get('w/e')

    Memcached.class_eval do
      alias :get :get_without_hello
    end
  end
end
