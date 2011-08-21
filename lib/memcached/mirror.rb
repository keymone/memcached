module Memcached::Mirror
  def self.setup(from)
    return if from.mirrored?
    from.instance_eval { extend InstanceMethods }
    from.mirrored!
  end

  module InstanceMethods
    def get(keys, marshal=true)
      result = super

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
end
