# frozen_string_literal: true
FactoryBot.define do
  factory :csv_import do
    user { FactoryBot.create(:user) }
    manifest { Rack::Test::UploadedFile.new(Rails.root.join('spec', 'fixtures', 'csv_import', 'import_manifest.csv'), 'text/csv') }
    import_file_path { Rails.root.join('spec', 'fixtures') }
    status { 'complete' }
  end
end
