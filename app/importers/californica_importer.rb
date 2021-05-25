# frozen_string_literal: true

# Import CSV files according to UCLA ingest rules
class CalifornicaImporter
  attr_reader :error_stream, :info_stream, :depositor_id, :import_file_path

  # @param [CsvImport] csv_import
  def initialize(csv_import, error_stream: Darlingtonia.config.default_error_stream, info_stream: Darlingtonia.config.default_info_stream)
    @info_stream = info_stream
    @error_stream = error_stream
    @csv_import = csv_import
    @csv_file = csv_import.manifest.to_s
    @import_file_path = csv_import.import_file_path
    @depositor_id = csv_import.user_id
    raise "Cannot find expected input file #{@csv_file}" unless File.exist?(@csv_file)
  end

  def import
    raise "Cannot find expected input file #{@csv_file}" unless File.exist?(@csv_file)
    log_start

    attrs = {
      depositor_id: @depositor_id,
      batch_id: @csv_import.id
    }

    record_importer = ::RecordImporter.new(error_stream: @error_stream, info_stream: @info_stream, attributes: attrs)
    raise "CSV file #{@csv_file} did not validate" unless parser.validate
    csv_table = CSV.parse(File.read(@csv_file), headers: true)
    record_importer.csv_table = csv_table

    # Running darlingtonia w/ our RecordImporter just creates CsvRow objects
    Darlingtonia::Importer.new(parser: parser, record_importer: record_importer, info_stream: @info_stream, error_stream: @error_stream).import

    @csv_import.csv_rows.where(status: ['in progress', 'deleting child works', 'error']).update_all(status: 'queued')
    @csv_import.csv_rows.where(status: 'queued').each do |csv_row|
      CsvRowImportJob.perform_now(row_id: csv_row.id)
    end

    finalize_import
    log_end
    @info_stream << @csv_import
  end

  def finalize_import
    parser.order_child_works
    parser.reindex_collections
    @csv_import.csv_rows.where(status: 'pending finalization').update_all(status: 'complete')
  end

  def log_end
    @csv_import.status = 'complete'
    @csv_import.end_time = Time.zone.now.round
    @csv_import.elapsed_time = @csv_import.end_time - @csv_import.start_time
    @csv_import.elapsed_time_per_record = @csv_import.elapsed_time / parser.records.count
    @csv_import.save
  end

  def log_start
    @csv_import.status = 'in progress'
    # if the job fails and restarts, there will already be a start_time that we want to keep
    @csv_import.start_time = @csv_import.start_time || Time.zone.now.round
    @csv_import.save
  end

  def parser
    @parser ||=
      CalifornicaCsvParser.new(file: File.open(@csv_file),
                               csv_import_id: @csv_import.id,
                               import_file_path: @import_file_path,
                               error_stream: @error_stream,
                               info_stream: @info_stream)
  end

  def timestamp
    @timestamp ||= Time.zone.now.strftime('%Y-%m-%d-%H-%M-%S')
  end
end
