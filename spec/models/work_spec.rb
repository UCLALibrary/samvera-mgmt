# frozen_string_literal: true
require 'rails_helper'

RSpec.describe Work do
  subject(:work) { described_class.new }

  describe '#genre' do
    let(:values) { ['SciFi'] }

    it 'can set a genre' do
      expect { work.genre = values }
        .to change { work.genre.to_a }
        .to contain_exactly(*values)
    end

    it 'sets to edm:hasType' do
      expect { work.genre = values }
        .to change { work.resource.predicates }
        .to include RDF::Vocab::EDM.hasType
    end
  end

  it "has extent" do
    work = described_class.new
    work.extent = ['1 photograph']
    expect(work.extent).to include '1 photograph'
    expect(work.resource.dump(:ttl)).to match(/purl.org\/dc\/elements\/1.1\/format/)
  end
end
