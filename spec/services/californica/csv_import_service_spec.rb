# frozen_string_literal: true
require 'rails_helper'

RSpec.describe Californica::CsvImportService do
  let(:csv_import) do
    csv_import = FactoryBot.create(:csv_import)
    FactoryBot.create(:csv_row, csv_import_id: csv_import.id, metadata: '{"Item ARK": "ark:/abc/123456"}')
    FactoryBot.create(:csv_row, csv_import_id: csv_import.id, metadata: '{"Item ARK": "ark:/abc/654321"}')
    FactoryBot.create(:csv_row, csv_import_id: csv_import.id, metadata: '{"Item ARK": "ark:/abc/918274"}')
    csv_import
  end
  let(:service) { described_class.new csv_import }
  let(:expected_csv) do
    <<~HEREDOC
      Object Type,Title,Item ARK,Parent ARK,Rights.copyrightStatus,File Name,Import Status
      Work,Apple,ark:/abc/123456,ark:/abc/7890123,copyrighted,clusc_1_1_00010432a.tif,queued
      Work,Banana,ark:/abc/654321,ark:/abc/7890123,copyrighted,clusc_1_1_00010432a.tif,error
    HEREDOC
  end

  describe '#csv' do
    before do
      allow(csv_import.csv_rows[0]).to receive(:status).and_return('queued')
      allow(csv_import.csv_rows[1]).to receive(:status).and_return('error')
      allow(csv_import.csv_rows[2]).to receive(:status).and_return('complete')
    end

    it 'appends each row\'s import status' do
      expect(service.csv.to_s).to match expected_csv
    end
  end
end
