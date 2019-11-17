# frozen_string_literal: true

class AdminMailer < ActionMailer::Base
  default from: 'swingoutlondon@gmail.com'

  def outdated
    report = OutdatedEventReport.new
    @out_of_date_events = report.out_of_date_events
    @near_out_of_date_events = report.near_out_of_date_events

    if report.all_in_date?
      subject  = 'All events in date'
      template = 'all_in_date'
    else
      subject = report.summary
      template = 'outdated'
    end

    mail to: 'swingoutlondon@gmail.com', subject: subject, template_name: template
  end
end
