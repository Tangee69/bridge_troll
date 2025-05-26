# frozen_string_literal: true

require 'rails_helper'

describe 'checking in attendees' do
  let(:event) { create(:event) }

  before do
    event.event_sessions.first.update(name: 'Unique Session Name')
  end

  describe 'as an organizer' do
    let!(:attendee_rsvp) { create(:volunteer_rsvp, event: event) }

    before do
      organizer = create(:user)
      event.organizers << organizer
      sign_in_as(organizer)
    end

    it 'can assign another user as a checkiner', :js do
      visit event_checkiners_path(event)

      select(attendee_rsvp.user.full_name, from: 'event_checkiner_rsvp_id')

      click_button 'Assign'

      expect(page).to have_content(attendee_rsvp.user.email)
      expect(page).to have_content(attendee_rsvp.user.full_name)
      expect(page).to have_select('event_checkiner[rsvp_id]', options: [''])
    end

    describe 'when a user is assigned as a checkiner' do
      before do
        attendee_rsvp.update(checkiner: true)
      end

      it 'can remove checkiner status from the user' do
        visit event_checkiners_path(event)

        expect(page).to have_content(attendee_rsvp.user.email)
        expect(page).to have_button('Remove')

        click_button 'Remove'

        expect(page).not_to have_content(attendee_rsvp.user.email)
        expect(page).not_to have_button('Remove')
      end
    end
  end

  describe 'as a checkiner' do
    before do
      rsvp = create(:volunteer_rsvp, event: event, checkiner: true)
      sign_in_as(rsvp.user)
    end

    let!(:student_rsvp_session) do
      create(:student_rsvp, event: event).rsvp_sessions.first
    end

    it 'lets the user check in attendees', :js do
      visit event_event_sessions_path(event)

      click_link 'Check in for Unique Session Name'

      expect(page).to have_content('Check-ins for Unique Session Name')

      within "#rsvp_session_#{student_rsvp_session.id}" do
        within '.create' do
          click_on 'Check In'
        end
        expect(page).to have_content('Checked In!')
      end

      within '.checkin-counts' do
        expect(page).to have_content('1')
      end
    end
  end
end
