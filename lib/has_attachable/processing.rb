module HasAttachable
  module Processing
    extend ActiveSupport::Concern

    def attachable_job
      HasAttachable::Status.new(HasAttachable::Worker.sidekiq_options["queue"].to_s, 
                        self.class.name.downcase, self.id)
    end

    def process_attachable?
      field = get_changed_attachable
      return false if field.nil?

      case attachable_options[field][:type]
      when :downloadable, :streamable then false
      else
        send("#{field}_name_changed?") and \
        send("#{field}_name").present? ? true : false
      end
    end

    def remove_attachable?
      field = get_remove_attachable
      return false if field.nil? 

      send("async_remove_#{field}") and \
      send("#{field}_name").present? ? true : false
    end

    def get_changed_attachable
      changed_attachable = nil
      attachable_fields.each do |field|
        changed_attachable = field if changes.has_key?("#{field}_name")
      end
      changed_attachable
    end

    def get_remove_attachable
      remove_attachable = nil
      attachable_fields.each do |field|
        remove_attachable = field if send("async_remove_#{field}")
      end
      remove_attachable
    end


    def processing_options
      {
        klass: self.class.name, 
        id: id, 
        context: get_changed_attachable || get_remove_attachable
      }
    end
  end
end