# frozen_string_literal: true
require 'rails_helper'

RSpec.describe CsvManifestValidator, type: :model do
  let(:validator) { described_class.new(manifest) }
  let(:manifest) { csv_import.manifest }
  let(:user) { FactoryBot.build(:user) }
  let(:csv_import) do
    import = CsvImport.new(user: user, import_file_path: fixture_path)
    File.open(csv_file) { |f| import.manifest = f }
    import
  end

  before do
    allow(ENV).to receive(:[]).and_call_original
    allow(ENV).to receive(:[]).with('IMPORT_FILE_PATH').and_return(fixture_path)

    allow(File).to receive(:exist?).and_call_original
    allow(File).to receive(:exist?).with(File.join(ENV['IMPORT_FILE_PATH'], 'Masters/dlmasters/clusc_1_1_00010432a.tif')).and_return(true)
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
    let(:csv_file) { File.join(fixture_path, 'csv_import', 'import_manifest.csv') }

    it 'has an error' do
      allow(CSV).to receive(:read).and_raise(CSV::MalformedCSVError, 'abcdefg')
      validator.validate
      expect(validator.errors).to contain_exactly(
        "CSV::MalformedCSVError: abcdefg"
      )
    end
  end

  context 'a CSV that is missing required headers' do
    let(:csv_file) { File.join(fixture_path, 'csv_import', 'csv_files_with_problems', 'missing_title_header.csv') }

    it 'has an error' do
      missing_title_error = 'Missing required column: Title.  Your spreadsheet must have this column.  If you already have this column, please check the spelling and capitalization.'
      validator.validate
      expect(validator.errors).to contain_exactly(missing_title_error)
    end
  end

  context 'a CSV with duplicate headers' do
    let(:csv_file) { File.join(fixture_path, 'csv_import', 'csv_files_with_problems', 'duplicate_headers.csv') }

    it 'has an error' do
      validator.validate
      expect(validator.errors).to contain_exactly(
        'Duplicate column header: Title (used 2 times). Each column must have a unique header.'
      )
    end
  end

  context 'a CSV that is missing required values' do
    let(:csv_file) { File.join(fixture_path, 'csv_import', 'csv_files_with_problems', 'missing_values.csv') }

    it 'has warnings' do
      validator.validate
      expect(validator.warnings).to contain_exactly(
        'Row 3: Rows missing "Item ARK" cannot be imported.',
        'Row 4: Rows missing "Title" cannot be imported.',
        'Row 5: Rows missing "Object Type" cannot be imported.',
        'Row 6: Rows missing "Parent ARK" cannot be imported.',
        'Row 7: Rows missing "Rights.copyrightStatus" will have the value set to "unknown".',
        'Row 8: Rows missing "File Name" will import metadata-only.'
      )
    end
  end

  context 'a CSV that has extra headers' do
    let(:csv_file) { File.join(fixture_path, 'csv_import', 'csv_files_with_problems', 'extra_headers.csv') }

    it 'has a warning' do
      validator.validate
      expect(validator.warnings).to include(
        'The field name "another_header_1" is not supported.  This field will be ignored, and the metadata for this field will not be imported.',
        'The field name "another_header_2" is not supported.  This field will be ignored, and the metadata for this field will not be imported.'
      )
    end
  end

  context 'a CSV with invalid values in controlled-vocabulary fields' do
    let(:csv_file) { File.join(fixture_path, 'csv_import', 'csv_files_with_problems', 'invalid_values.csv') }

    it 'has warnings' do
      validator.validate
      expect(validator.warnings).to include(
        'Row 2: \'invalid rights statement\' is not a valid value for \'Rights.copyrightStatus\'',
        'Row 3, 4: \'invalid type\' is not a valid value for \'Type.typeOfResource\'',
        'Row 5: Rows with invalid Object Type "InvalidWork" cannot be imported.'
      )
    end
  end

  context 'when the csv has a missing file' do
    let(:csv_file) { 'spec/fixtures/example-missingimage.csv' }
    let(:path) { File.join(ENV['IMPORT_FILE_PATH'], 'Masters/dlmasters/missing_file.tif') }

    it 'has warnings' do
      allow(File).to receive(:exist?).with(path).and_return(false)
      validator.validate
      expect(validator.warnings).to include("Row 2: Rows contain a File Name that does not exist. Incorrect values may be imported.")
    end

    it 'doesn\'t warn about files that aren\'t missing' do
      allow(File).to receive(:exist?).with(path).and_return(true)
      validator.validate
      expect(validator.warnings).to_not include("Row 2: cannot find '#{path}'")
    end
  end
end
