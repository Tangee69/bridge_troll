# frozen_string_literal: true

require 'rails_helper'

describe 'Event Organizers page' do
  let(:event) { create(:event) }
  let(:user1) { create(:user, email: 'user1@mail.com', first_name: 'Joe', last_name: 'Cairo') }

  before do
    user_organizer = create(:user, email: 'orgainzer@mail.com', first_name: 'Sam', last_name: 'Spade')

    event.organizers << user_organizer

    sign_in_as(user_organizer)
  end

  it 'displays the existing organizers name and email address' do
    visit "/events/#{event.id}/organizers"

    expect(page).to have_content('Organizer Assignments')
    expect(page).to have_content('orgainzer@mail.com')
    expect(page).to have_content('Sam Spade')
  end

  it 'allows an organizer to assign another user as an organizer', :js do
    visit "/events/#{event.id}/organizers"

    expect(page).to have_select('event_organizer[user_id]')

    fill_in_select2(user1.full_name)

    click_button 'Assign'

    expect(page).to have_content('user1@mail.com')
    expect(page).to have_content('Joe Cairo')
    expect(page).to have_select('event_organizer[user_id]', options: [''])
  end

  describe 'removing an organizer' do
    before do
      event.organizers << user1
    end

    it 'allows an organizer to remove another user from the list of organizers' do
      visit "/events/#{event.id}/organizers"

      expect(page).to have_content('user1@mail.com')
      expect(page).to have_button('Remove')

      within page.find("tr:contains('#{user1.full_name}')") do
        click_button 'Remove'
      end

      expect(page).not_to have_content('user1@mail.com')
      expect(page).not_to have_button('Remove')
    end
  end
end
