# frozen_string_literal: true

require 'rails_helper'
include Warden::Test::Helpers

RSpec.feature 'Create a new collection', :clean, js: true do
  DatabaseCleaner.strategy = :truncation
  DatabaseCleaner.start

  let(:admin) { FactoryBot.create :admin }
  let(:title) { "My Test Collection" }
  let(:ark)   { "ark:/abc/1234" }

  include_context 'with workflow'

  before do
    Hyrax::CollectionType.find_or_create_default_collection_type
    Hyrax::CollectionType.find_or_create_admin_set_type
  end

  context 'logged in as an admin user' do
    before { login_as admin }

    scenario 'successfully edits the work' do
      visit "/dashboard/my/collections"
      click_on 'New Collection'
      choose('User Collection')
      click_on 'Create collection'
      fill_in('Title', with: title)
      fill_in('Ark', with: ark)
      click_on 'Save'
      expect(page).to have_content title
      expect(find_field('Ark').value).to eq ark
      expect(page).to have_content 'Collection was successfully created.'
    end
  end
end
