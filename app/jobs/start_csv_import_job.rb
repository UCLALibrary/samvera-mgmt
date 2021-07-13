# frozen_string_literal: true

class StartCsvImportJob < ApplicationJob
  queue_as Hyrax.config.ingest_queue_name
  rescue_from StandardError, with: :log_exception

  def perform(csv_import_id)
    @csv_import = CsvImport.find csv_import_id
    setup_logging
    @info_stream << "StartCsvImportJob ~ Starting import with batch ID: #{csv_import_id}"
    importer = CalifornicaImporter.new(@csv_import, info_stream: @info_stream, error_stream: @error_stream)
    importer.import
  end

  def ingest_log_filename
    Rails.root.join('log', "ingest_#{@csv_import.id}.log").to_s
  end

  def setup_logging
    @ingest_log   = Logger.new(ingest_log_filename)
    @info_stream  = CalifornicaLogStream.new(logger: @ingest_log, severity: Logger::INFO)
    @error_stream = CalifornicaLogStream.new(logger: @ingest_log, severity: Logger::ERROR)
  end

private

  def log_exception(e)
    Rollbar.error(e, csv_import: csv_import_id)
    @error_stream << "#{e.class}: #{e.message}\n#{e.backtrace.inspect}"
    @row&.update(status: 'error',
                 end_time: Time.current,
                 ingest_duration: @row.start_time - Time.current)

    retry_job(wait: 600) if e.is_a? Mysql2::Error::ConnectionError
  end
end
