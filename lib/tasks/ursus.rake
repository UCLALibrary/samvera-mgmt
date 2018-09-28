# frozen_string_literal: true

namespace :californica do
  desc 'Update Ursus solr index with the latest data from Californica'
  task reindex_ursus: :environment do
    unless ENV['URSUS_SOLR_URL']
      puts "Aborting reindex. Please set environment variable: URSUS_SOLR_URL"
      next
    end

    start_time = Time.zone.now
    puts "Begin reindex of Ursus solr: #{start_time}"

    reindex_service = ReindexService.new(solr: ENV['URSUS_SOLR_URL'])
    puts "Deleting all existing solr documents..."
    reindex_service.delete_all_docs
    puts "Reindexing..."
    result = reindex_service.reindex
    puts "Reindexing successful: #{result}"

    end_time = Time.zone.now
    elapsed_time = (end_time - start_time).to_i
    puts "Ursus solr reindex complete.  Elapsed time in seconds: #{elapsed_time}"
  end
end
