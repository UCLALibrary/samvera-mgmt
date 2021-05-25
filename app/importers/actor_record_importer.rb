# frozen_string_literal: true

class ActorRecordImporter < Darlingtonia::HyraxRecordImporter
  include CommonRecordImporter

  DEFAULT_CREATOR_KEY = 'californica_import_user@example.com'

  ##
  # @!attribute [rw] creator
  #   @return [User]
  attr_accessor :creator

  ##
  # @param creator   [User]
  def initialize(error_stream: Darlingtonia.config.default_error_stream,
                 info_stream: Darlingtonia.config.default_info_stream,
                 attributes: {})
    @row_id = attributes[:row_id]
    super(error_stream: error_stream, info_stream: info_stream, attributes: attributes)
  end

  def import_type(object_type = nil)
    return ::ChildWork if ['ChildWork', 'Page'].include?(object_type)
    ::Work
  end

  def update_for(existing_record:, update_record:)
    info_stream << "event: record_update_started, row_id: #{@row_id}, collection_id: #{collection_id}, ark: #{existing_record.ark}\n"

    additional_attrs = {
      uploaded_files: create_upload_files(update_record),
      depositor: @depositor.user_key
    }
    existing_record.apply_depositor_metadata(@depositor.user_key)
    attrs = update_record.attributes.merge(additional_attrs)
    attrs = attrs.merge(member_of_collections_attributes: { '0' => { id: collection_id } }) if collection_id
    # Ensure nothing is passed in the files field,
    # since this is reserved for Hyrax and is where uploaded_files will be attached
    attrs.delete(:files)
    attrs.delete(:uploaded_files)
    based_near = attrs.delete(:based_near)
    attrs = attrs.merge(based_near_attributes: based_near_attributes(based_near)) unless based_near.nil? || based_near.empty?
    actor_env = Hyrax::Actors::Environment.new(existing_record,
                                               ::Ability.new(@depositor),
                                               attrs)
    terminator = Hyrax::Actors::Terminator.new
    middleware = Californica::IngestMiddlewareStack.build_stack.build(terminator)
    if middleware.update(actor_env)
      info_stream << "event: record_updated, row_id: #{@row_id}, record_id: #{existing_record.id}, collection_id: #{collection_id}, record_title: #{attrs[:title]&.first}\n"
      @success_count += 1
    else
      existing_record.errors.each do |attr, msg|
        error_stream << "event: validation_failed, row_id: #{@row_id}, collection_id: #{collection_id}, attribute: #{attr.capitalize}, message: #{msg}, record_title: record_title: #{attrs[:title] ? attrs[:title] : attrs}\n"
      end
      @failure_count += 1
    end

  rescue ActiveFedora::IllegalOperation, ActiveFedora::ObjectNotFoundError, Ldp::BadRequest, Ldp::Gone, Ldp::HttpError
    fcrepo_id = Californica::IdGenerator.id_from_ark(record.ark)
    Californica::Deleter.new(id: fcrepo_id).delete
    update_record
  end

  # Create an object using the Hyrax actor stack
  # We assume the object was created as expected if the actor stack returns true.
  def create_for(record:)
    info_stream << "event: record_import_started, row_id: #{@row_id}, ark: #{record.ark}\n"
    raise(ArgumentError, 'Title starts "DUPLICATE" – record will not be imported.') if record.mapper.title[0].to_s.start_with?('DUPLICATE')
    additional_attrs = {
      uploaded_files: create_upload_files(record),
      depositor: @depositor.user_key
    }
    object_type = record.mapper.metadata["Object Type"]
    created = import_type(object_type).new
    created.apply_depositor_metadata(@depositor.user_key)
    attrs = record.attributes.merge(additional_attrs)
    attrs = attrs.merge(member_of_collections_attributes: { '0' => { id: collection_id } }) if collection_id

    # Ensure nothing is passed in the files field,
    # since this is reserved for Hyrax and is where uploaded_files will be attached
    attrs.delete(:files)
    attrs.delete(:uploaded_files)
    based_near = attrs.delete(:based_near)
    attrs = attrs.merge(based_near_attributes: based_near_attributes(based_near)) unless based_near.nil? || based_near.empty?
    actor_env = Hyrax::Actors::Environment.new(created,
                                               ::Ability.new(@depositor),
                                               attrs)
    terminator = Hyrax::Actors::Terminator.new
    begin
      retries ||= 0
      middleware = Californica::IngestMiddlewareStack.build_stack.build(terminator)
      if middleware.create(actor_env)
        info_stream << "event: record_created, row_id: #{@row_id}, record_id: #{created.id}, ark: #{created.ark}\n"
      else
        error_messages = []
        created.errors.each do |attr, msg|
          error_stream << "event: validation_failed, row_id: #{@row_id}, attribute: #{attr.capitalize}, message: #{msg}, ark: #{attrs[:ark] ? attrs[:ark] : attrs}\n"
          error_messages << msg
        end
        # Errors raised here should be rescued in the CsvRowImportJob and the
        # message should be recorded on the CsvRow object for reporting in the UI
        raise "Validation failed: #{error_messages.join(', ')}"
      end
    rescue Ldp::BadRequest => e
      # get the id from the ark and the uri from the id then delete the tombstone
      tombstone_uri = "#{ActiveFedora::Base.id_to_uri(Californica::IdGenerator.id_from_ark(created.ark))}/fcr:tombstone"
      ActiveFedora.fedora.connection.delete(tombstone_uri)
      if (retries += 1) < 3
        retry
      else
        raise e
      end
    end

  rescue ActiveFedora::IllegalOperation, ActiveFedora::ObjectNotFoundError, Ldp::BadRequest, Ldp::Gone, Ldp::HttpError => e
    retries ||= 0
    fcrepo_id = Californica::IdGenerator.id_from_ark(record.ark)
    Californica::Deleter.new(id: fcrepo_id).delete
    if (retries += 1) < 3
      retry
    else
      raise e
    end
  end
end
