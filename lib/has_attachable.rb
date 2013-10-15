require "has_attachable/version"
require "has_attachable/processing"
require "has_attachable/worker"
require "has_attachable/status"

module HasAttachable
  extend ActiveSupport::Concern

  class NoUploaderError < StandardError
    def message
      "No Uploader found, please specify an uploader"
    end
  end

  included do 
    after_update -> {
      HasAttachable::Worker.
        perform_async('process', 
                       processing_options) if process_attachable?
      HasAttachable::Worker.
        perform_async('remove', 
                       processing_options) if remove_attachable?
    }
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

        mount_uploader field, 
                       attachable_options[field][:uploader], 
                       mount_on: "#{field}_name"

      end
    end
  end
end
