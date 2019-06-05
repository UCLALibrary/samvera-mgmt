# frozen_string_literal: true
require 'rails_helper'

RSpec.describe CsvRowImportJob, :clean do
  let(:csv_import) { FactoryBot.create(:csv_import) }

  context 'happy path' do
    let(:csv_row) { FactoryBot.create(:csv_row, status: nil, csv_import_id: csv_import.id) }

    it 'can set a status' do
      described_class.perform_now(row_id: csv_row.id)
      csv_row.reload
      expect(csv_row.status).to eq('complete')
    end
  end

  context 'error cases' do
    let(:metadata) do
      {
        "Project Name" => "Ethiopic Manuscripts",
        "Item ARK" => "",
        "Parent ARK" => "21198/zz001pz6h6",
        "Object Type" => "Page"
      }.to_json
    end
    let(:csv_row) { FactoryBot.create(:csv_row, status: nil, metadata: metadata, error_messages: nil, csv_import_id: csv_import.id) }

    it 'records an error state and error messages' do
      described_class.perform_now(row_id: csv_row.id)
      csv_row.reload
      expect(csv_row.status).to eq('error')
      expect(csv_row.error_messages).to eq 'Cannot set id without a valid ark'
    end
  end
end