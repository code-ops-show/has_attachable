require "has_attachable/version"
require "has_attachable/processing"
require "has_attachable/worker"

module HasAttachable
  extend ActiveSupport::Concern

  class NoUploaderError < StandardError
    def message
      "No Uploader found, please specify an uploader"
    end
  end

  included do 
    after_update :run_process_attachable, if: :process_attachable?
    after_update :run_remove_attachable,  if: :remove_attachable?
    
    include HasAttachable::Processing
  end

  module ClassMethods
    def has_attachable(*attachable_options)
      field = attachable_options[0]
      options = attachable_options[1]
      options[:type] = :graphic unless options[:type].present?
      initialize_attachable(field, options)
    end

    private 

    def initialize_attachable(field, options)
      class_attribute :attachable_options unless defined? self.attachable_options
      self.attachable_options ||= {}
      self.attachable_options[field] = options

      class_attribute :attachable_fields unless defined? self.attachable_fields
      self.attachable_fields ||= []
      self.attachable_fields << field

      raise NoUploaderError          unless attachable_options[field][:uploader].present?
      attachable_field = :attachable unless field.present?
      

      class_eval do 
        attr_accessor "async_remove_#{field}".to_sym

        define_method("#{field}_processing?") { 
          if self.send("#{field}_job_id").present? 
            not Sidekiq::Status::complete? self.send("#{field}_job_id")
          else
            false
          end
        }

        mount_uploader field, 
                       attachable_options[field][:uploader], 
                       mount_on: "#{field}_name"

      end
    end
  end
end
