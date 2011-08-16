class Memcached::Mirror
  def self.setup(from, to, rate = 100)
    rate = rate / 100.0

    from.instance_eval do
      alias :get_without_mirroring :get

      def get(keys, marshal=true)
        result1 = get_without_keys(keys, marshal=true)

        if rand <= rate
          result2 = to.get(keys, marshal)

          if keys.is_a? Array
            keys.reject{|k| result1[k] == result2[k]}.each do |k|
              next unless result1[k]
              to.set(k, result1[k])
            end
          else
            to.set(k, result1) if result1 && result2.nil?
          end
        end

        result1
      end
    end
  end

  def self.teardown(from)
    from.instance_eval do
      alias :get :get_without_mirroring
    end
  end
end
