# frozen_string_literal: true
# Generated via
#  `rails generate hyrax:work ChildWork`
require 'rails_helper'

RSpec.describe Hyrax::ChildWorkForm do
  let(:form) { described_class.new(Work.new, {}, {}) }

  it 'has all the custom terms' do
    expect(form.terms).to include(
      :access_copy,
      :architect,
      :caption,
      :dimensions,
      :extent,
      :funding_note,
      :genre,
      :latitude,
      :local_identifier,
      :longitude,
      :medium,
      :named_subject,
      :normalized_date,
      :photographer,
      :preservation_copy,
      :repository,
      :rights_country,
      :rights_holder
    )
  end
end
