# frozen_string_literal: true
require 'rails_helper'

RSpec.describe CsvManifestValidator, type: :model do
  let(:validator) { described_class.new(manifest) }
  let(:manifest) { csv_import.manifest }
  let(:user) { FactoryBot.build(:user) }
  let(:csv_import) do
    import = CsvImport.new(user: user)
    File.open(csv_file) { |f| import.manifest = f }
    import
  end

  context 'a valid CSV file' do
    let(:csv_file) { File.join(fixture_path, 'csv_import', 'import_manifest.csv') }

    it 'has no errors' do
      expect(validator.errors).to eq []
    end

    it 'has no warnings' do
      expect(validator.warnings).to eq []
    end

    it 'returns the record count' do
      validator.validate
      expect(validator.record_count).to eq 3
    end
  end

  context 'a file that can\'t be parsed' do
    it 'has an error' do
      skip # TODO
    end
  end

  context 'a CSV that is missing required headers' do
    let(:csv_file) { File.join(fixture_path, 'csv_import', 'csv_files_with_problems', 'missing_title_header.csv') }

    it 'has an error' do
      missing_ark_error = 'Missing required column: Item Ark.  Your spreadsheet must have this column.  If you already have this column, please check the spelling and capitalization.'
      missing_title_error = 'Missing required column: Title.  Your spreadsheet must have this column.  If you already have this column, please check the spelling and capitalization.'
      validator.validate
      expect(validator.errors).to contain_exactly(missing_ark_error, missing_title_error)
    end
  end

  context 'a CSV that is missing required values' do
    let(:csv_file) { File.join(fixture_path, 'csv_import', 'csv_files_with_problems', 'missing_values.csv') }

    it 'has errors', :wip do
      validator.validate
      expect(validator.errors).to contain_exactly(
        'Missing required metadata in row 3: "Item Ark" field cannot be blank',
        'Missing required metadata in row 4: "Title" field cannot be blank',
        'Missing required metadata in row 5: "Object Type" field cannot be blank'
      )
    end
  end

  context 'a CSV that has extra headers' do
    let(:csv_file) { File.join(fixture_path, 'csv_import', 'csv_files_with_problems', 'extra_headers.csv') }

    it 'has a warning' do
      validator.validate
      expect(validator.warnings).to eq [
        'The field name "another_header_1" is not supported.  This field will be ignored, and the metadata for this field will not be imported.',
        'The field name "another_header_2" is not supported.  This field will be ignored, and the metadata for this field will not be imported.'
      ]
    end
  end
end
