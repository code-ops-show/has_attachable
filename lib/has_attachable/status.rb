module HasAttachable
  class Status
    attr_accessor :queue_name, :klass, :id

    def initialize(queue_name, klass, id)
      @queue_name = queue_name
      @klass = klass
      @id    = id.to_i
    end

    def in_queue?
      result = filter_by :queued
      result.present? ? true : false
    end

    def retrying?
      result = filter_by :retrying
      result.present? ? true : false
    end

    def active?
      result = filter_by :active
      result.present? ? true : false
    end

    def processing?
      in_queue? or active? or retrying? ? true : false
    end

  private

    def filter_by(job_type)
      send(job_type).select do |job|
        job_klass = get_field(job, 'klass').downcase rescue 'none'
        job_id    = get_field(job, 'id').to_i rescue 0

        job_klass == klass and job_id == id
      end if send(job_type).present?
    end

    def get_field job, field
      job.has_key?("payload") ? job["payload"]["args"][1][field] : job["args"][1][field]
    end

    def active
      Sidekiq.redis do |r|
        r.smembers('workers').map do |w|
          msg = r.get("worker:#{w}")
          msg ? Sidekiq.load_json(msg) : nil
        end.compact
      end
    end

    def retrying
      Sidekiq::redis do |r|
        r.zrange('retry', 0, -1).map do |msg|
          msg ? Sidekiq.load_json(msg) : nil
        end.compact
      end
    end

    def queued
      results = Sidekiq.redis do |r|
        r.lrange("queue:#{queue_name}", 0, -1).map do |msg|
          msg ? Sidekiq.load_json(msg) : nil
        end.compact
      end
    end
  end
end
