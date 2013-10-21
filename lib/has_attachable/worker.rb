require 'sidekiq'
require 'sidekiq-status'

module HasAttachable
  class Worker
    include Sidekiq::Worker
    include Sidekiq::Status::Worker

    sidekiq_options queue: :has_attachable
    
    def perform(method, options)
      send("#{method}", Hash[options.map{ |k, v| [k.to_sym, v] }])
    end

    def process(options)
      object = options[:klass].classify.constantize.unscoped.where(id: options[:id]).first
      object.send(options[:context]).cache_stored_file! 
      object.send(options[:context]).retrieve_from_cache!(object.send(options[:context]).cache_name)
      object.send(options[:context]).recreate_versions!
    end

    def remove(options)
      object = options[:klass].classify.constantize.unscoped.where(id: options[:id]).first
      object.send("remove_#{options[:context]}!")
    end
  end
end