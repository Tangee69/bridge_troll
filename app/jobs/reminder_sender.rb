# frozen_string_literal: true

class ReminderSender
  def self.send_all_reminders
    UpcomingEventsQuery.new.find_each do |event|
      remind_attendees_for_event(event)
    end
  end

  def self.remind_attendees_for_event(event)
    event.event_sessions.where(volunteers_only: true).each do |event_session|
      remind_attendees_for_session(event_session)
    end

    first_everybody_session = event.event_sessions.find_by(volunteers_only: false)
    return unless first_everybody_session
    return unless first_everybody_session.starts_at < 3.days.from_now

    due_reminders = event.rsvps.confirmed.where(reminded_at: nil)
    puts "Sending #{due_reminders.count} reminders for #{event.title}..." unless Rails.env.test?
    due_reminders.find_each do |rsvp|
      RsvpMailer.reminder(rsvp).deliver_now
      rsvp.update!(reminded_at: Time.zone.now)
    end
  end

  def self.remind_attendees_for_session(event_session)
    due_reminders = event_session.rsvp_sessions.where(reminded_at: nil)
    unless Rails.env.test?
      puts "Sending #{due_reminders.count} reminders for #{event_session.event.title} - #{event_session.name}..."
    end
    due_reminders.find_each do |rsvp_session|
      RsvpMailer.reminder_for_session(rsvp_session).deliver_now
      rsvp_session.update!(reminded_at: Time.zone.now)
    end
  end
end

class UpcomingEventsQuery
  def initialize(relation = Event.all)
    @relation = relation
  end

  def find_each(&)
    @relation
      .where('events.starts_at > ?', Time.zone.now)
      .where(events: { starts_at: ...3.days.from_now })
      .find_each(&)
  end
end
