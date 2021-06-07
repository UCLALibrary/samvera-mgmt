# frozen_string_literal: true

module Californica
  class Deleter
    attr_reader :id, :logger

    def initialize(id: nil, record: nil, logger: Rails.logger)
      @id = id || record.id
      @record = record
      @logger = logger

      raise ArgumentError "id #{@id} does not match record #{@record}" if @record && @record.id != @id
    rescue NoMethodError
      raise ArgumentError 'Californica::Deleter must be initialized with a fcrepo id or a Californica record object (Collection, Work, or ChildWork).'
    end

    def delete
      destroy_and_eradicate
    end

    def delete_with_children(of_type: nil)
      # Delete the record _first_, or sever its connection to children
      # so that each child deletion doesnt trigger a save / reindex
      record&.member_ids&.each do |child_id|
        Californica::Deleter.new(id: child_id, logger: logger)
                            .delete_with_children(of_type: of_type)
      end
      delete if record.is_a?(of_type)
    end

    def delete_children(of_type: nil)
      record.members.each do |child|
        Californica::Deleter.new(record: child, logger: logger)
                            .delete_with_children(of_type: of_type)
      end
    end

    private

      def destroy_and_eradicate
        record_name = "#{record.class} #{record.ark}"
        record&.destroy&.eradicate
        Hyrax.config.callback.run(:after_destroy, record.id, User.batch_user)
      end

      def delete_from_fcrepo
        ActiveFedora.fedora.connection.delete(ActiveFedora::Base.id_to_uri(id))
        Rollbar.info("Forced delete of #{id} from Fedora")
      rescue Ldp::NotFound
        nil # Everything's good, we just wanted to make sure there wasn't a record in fedora not indexed to solr
      end

      def record
        @record ||= ActiveFedora::Base.find(id)

      rescue ActiveFedora::ObjectNotFoundError
        delete_from_fcrepo
      end
  end
end
