# frozen_string_literal: true
# require 'rails_helper'

# include Warden::Test::Helpers

# # NOTE: If you generated more than one work, you have to set "js: true"
# RSpec.describe 'Create a ChildWork', :clean, type: :system, js: true do
#   let(:admin_user) { FactoryBot.create(:admin) }
#   context 'a logged in user' do
#     let(:user_attributes) do
#       { email: 'test@example.com' }
#     end

#     let(:user) do
#       User.new(user_attributes) { |u| u.save(validate: false) }
#     end

#     include_context 'with workflow'

#     before do
#       AdminSet.find_or_create_default_admin_set_id
#       login_as admin_user
#     end

#     scenario do
#       visit '/dashboard'
#       expect(page).to have_content "Works"
#       click_link("Works")
#       click_link "Add new work"
#       choose "payload_concern", option: "ChildWork"
#       click_button "Create work"
#       expect(page).to have_content "Add New Child Work"
#       click_link "Files" # switch tab
#       expect(page).to have_content "Add files"
#       expect(page).to have_content "Add folder"
#       within('span#addfiles') do
#         attach_file("files[]", "#{Hyrax::Engine.root}/spec/fixtures/image.jp2", visible: false)
#         attach_file("files[]", "#{Hyrax::Engine.root}/spec/fixtures/jp2_fits.xml", visible: false)
#       end
#       click_link "Descriptions" # switch tab
#       fill_in('Title', with: 'My Test Work')
#       fill_in('Ark', with: 'ark:/abc/1236')
#       select('copyrighted', from: 'Copyright Status')

#       # With selenium and the chrome driver, focus remains on the
#       # select box. Click outside the box so the next line can't find
#       # its element
#       find('body').click
#       choose('child_work_visibility_open')
#       expect(page).to have_content('Please note, making something visible to the world (i.e. marking this as Public) may be viewed as publishing which could impact your ability to')
#       check('agreement')

#       click_on('Save')
#       expect(page).to have_content('My Test Work')
#       expect(page).to have_content("ark:/abc/1236")
#       expect(page).to have_content("Your files are being processed")
#       work = ChildWork.last
#       expect(work.id).to eq '6321-cba'
#     end
#   end
# end
