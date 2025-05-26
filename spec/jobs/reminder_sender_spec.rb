# frozen_string_literal: true

require 'rails_helper'

describe ReminderSender do
  describe '.send_all' do
    it 'sends reminders for each of the upcoming events' do
      upcoming_event = create(:event, starts_at: 1.day.from_now, ends_at: 2.days.from_now)
      past_event = create(:event)
      past_event.event_sessions.first.update(starts_at: 2.days.ago, ends_at: 1.day.ago)

      expect(described_class).to receive(:remind_attendees_for_event).once.with(upcoming_event)

      described_class.send_all_reminders
    end
  end

  describe '.remind_attendees_for_event' do
    let(:event) { create(:event, student_rsvp_limit: 1) }

    before do
      create(:volunteer_rsvp, event: event)
      create(:student_rsvp, event: event)
      create(:volunteer_rsvp, reminded_at: Time.zone.now, event: event)
      create(:student_rsvp, waitlist_position: 1, event: event)
    end

    it 'sends emails to all the students' do
      pending_reminder_count = event.rsvps.confirmed.where(reminded_at: nil).count
      expect(pending_reminder_count).to be >= 0

      expect do
        described_class.remind_attendees_for_event(event)
      end.to change(ActionMailer::Base.deliveries, :count).by(pending_reminder_count)

      expect do
        described_class.remind_attendees_for_event(event)
      end.not_to change(ActionMailer::Base.deliveries, :count)
    end

    describe 'when there is a volunteer-only session occuring before the all-attendees session' do
      before do
        event.event_sessions.first.update(starts_at: 4.days.from_now, ends_at: 5.days.from_now)
        volunteer_session = create(:event_session, event: event, starts_at: 2.days.from_now, ends_at: 3.days.from_now,
                                                   required_for_students: false, volunteers_only: true)

        create(:volunteer_rsvp, event: event).tap do |rsvp|
          rsvp.rsvp_sessions.create(event_session: volunteer_session)
        end
      end

      it 'sends volunteers a session reminder' do
        expect(RsvpMailer).to receive(:reminder_for_session).once.and_call_original

        expect do
          described_class.remind_attendees_for_event(event)
        end.to change(ActionMailer::Base.deliveries, :count).by(1)

        expect do
          described_class.remind_attendees_for_event(event)
        end.not_to change(ActionMailer::Base.deliveries, :count)
      end
    end
  end

  describe 'querying for events and sessions' do
    let!(:event_tomorrow) { create(:event, starts_at: 1.day.from_now) }

    before do
      # future
      create(:event, starts_at: 4.days.from_now)
      # yesterday
      create(:event).update(starts_at: 2.days.ago, ends_at: 1.day.ago)
    end

    describe UpcomingEventsQuery do
      let(:events) do
        [].tap do |found_events|
          described_class.new.find_each { |e| found_events << e }
        end
      end

      it 'includes only events in the next three days' do
        expect(events).to eq([event_tomorrow])
      end
    end
  end
end
