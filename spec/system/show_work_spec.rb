# frozen_string_literal: true
require 'rails_helper'
include Warden::Test::Helpers

RSpec.describe 'Display a Work', type: :system, js: true do
  let(:work) { FactoryBot.create(:work) }
  let(:admin) { FactoryBot.create(:admin) }

  context "as an admin" do
    it "displays expected fields" do
      login_as admin
      visit("/concern/works/#{work.id}")
      expect(page).to have_content work.title.first
      expect(page).to have_content work.subject.first
      expect(page).to have_content work.ark
    end
  end
end
