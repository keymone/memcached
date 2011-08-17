class Memcached::Mirror
  def self.setup(from)
    return if from.mirrored?

    from.instance_eval do
      alias :get_without_mirroring :get

      def get(keys, marshal=true)
        result = get_without_mirroring(keys, marshal=true)

        if Kernel.rand <= mirroring_rate
          splat = keys.is_a?(Array) ? result : {keys => result}
          keys  = [*keys]
          
          keys.each do |k|
            next if splat[k].nil?

            mirror = mirror_by_key(k)
            next unless mirror
            
            value_on_mirror = mirror.get(k) rescue nil
            next if splat[k] == value_on_mirror
            
            mirror.set(k, splat[k])
          end
        end

        result
      end
    end

    from.mirrored!
  end

  def self.teardown(from)
    from.instance_eval do
      alias :get :get_without_mirroring
    end
  end
end
