# frozen_string_literal: true
require 'retries'

# Set these values on the command line when you invoke the rake task.
# CSV_FILE should point to the csv you want to import, and
# IMPORT_FILE_PATH should point to a directory containing the files to be attached.
CSV_FILE = ENV['CSV_FILE']
IMPORT_FILE_PATH = ENV['IMPORT_FILE_PATH']

namespace :californica do
  namespace :ingest do
    desc 'Ingest LADNN sample data'
    task ladnn_sample: [:environment] do
      Rake::Task["hyrax:default_admin_set:create"].invoke
      Rake::Task["hyrax:default_collection_types:create"].invoke
      Rake::Task["hyrax:workflow:load"].invoke
      csv_file = Rails.root.join('spec', 'fixtures', 'ladnn-sample.csv')
      user = User.batch_user
      manifest = Rack::Test::UploadedFile.new(csv_file, 'text/csv')
      csv_import = CsvImport.new(user: user, manifest: manifest)
      csv_import.save
      puts "------"
      puts "Benchmark for ingest of 25 sample records (elapsed real time is last):"
      puts Benchmark.measure { CalifornicaImporter.new(csv_import).import }
    end

    desc 'Ingest Connell sample data'
    task connell_sample: [:environment] do
      Rake::Task["hyrax:default_admin_set:create"].invoke
      Rake::Task["hyrax:default_collection_types:create"].invoke
      Rake::Task["hyrax:workflow:load"].invoke
      csv_file = Rails.root.join('spec', 'fixtures', 'connell_sample.csv')
      user = User.batch_user
      manifest = Rack::Test::UploadedFile.new(csv_file, 'text/csv')
      csv_import = CsvImport.new(user: user, manifest: manifest)
      csv_import.save
      puts "------"
      puts "Benchmark for ingest of 21 sample records (elapsed real time is last):"
      puts Benchmark.measure { CalifornicaImporter.new(csv_import).import }
    end

    desc 'Clean Connell sample data'
    task clean_connell_sample: [:environment] do
      csv_file = Rails.root.join('spec', 'fixtures', 'connell_sample.csv')
      puts "Removing Connell sample data"
      CalifornicaCsvCleaner.new(file: csv_file).clean
    end

    desc 'Remove data indicated by CSV_FILE'
    task clean: [:environment] do
      puts "Removing data indicated by CSV_FILE"
      file = File.open(CSV_FILE)
      CalifornicaCsvCleaner.new(file: file).clean
      file.close
    end

    # Note: This is a super-extra thorough clean out because we were hitting timeout
    # errors. Much of this might be overkill at this point and a simple ActiveFedora::Cleaner.clean!
    # should probably suffice in most development environments.
    desc "Cleanout development instance of fedora and solr"
    task clean_all: :environment do
      if Rails.env.development?
        puts "Cleaning out local fedora and solr..."
        require 'active_fedora/cleaner'
        # Re-try the cleanout process a few times in case it times out
        with_retries(max_tries: 10, base_sleep_seconds: 500, max_sleep_seconds: 1000) do
          ActiveFedora::Cleaner.clean!
        end
        with_retries(max_tries: 10, base_sleep_seconds: 1, max_sleep_seconds: 5) do
          response = remove_tombstone
          raise "tombstone not deleted" unless response.code == "404"
        end

        Hyrax::PermissionTemplate.destroy_all
        puts "Clean complete."
      else
        puts "This task is only for use in a development environment"
      end
    end

    desc "Ingest a collection -- Use CSV_FILE and IMPORT_FILE_PATH to specify data locations."
    task csv: :environment do
      unless CSV_FILE && IMPORT_FILE_PATH
        puts "Specify import parameters like this: CSV_FILE=/path/to/file.csv IMPORT_FILE_PATH=/path/to/files/ bundle exec rake californica:ingest"
        next
      end
      puts "Ingesting CSV from #{CSV_FILE} with files from #{IMPORT_FILE_PATH}"
      puts "Logging ingest to logs/ingest_$timestamp and logs/error_$timestamp"
      Rake::Task["hyrax:default_admin_set:create"].invoke
      Rake::Task["hyrax:default_collection_types:create"].invoke
      user = User.batch_user
      manifest = Rack::Test::UploadedFile.new(CSV_FILE, 'text/csv')
      csv_import = CsvImport.new(user: user, manifest: manifest)
      csv_import.save
      CalifornicaImporter.new(csv_import).import
    end

    def remove_tombstone
      # ActiveFedora::Cleaner sometimes leaves a tombstone resource in place.
      # This prevents the content from re-ingesting. If this happens, it has to be explicitly removed.
      url = "#{ActiveFedora.config.credentials[:url]}#{ActiveFedora.config.credentials[:base_path]}/fcr:tombstone"
      uri = URI(url)
      http = Net::HTTP.new(uri.host, uri.port)
      req = Net::HTTP::Delete.new(uri.path)
      req.basic_auth ActiveFedora.config.credentials[:user], ActiveFedora.config.credentials[:password]
      http.request(req)
    end
  end
end
