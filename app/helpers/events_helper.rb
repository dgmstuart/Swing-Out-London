# frozen_string_literal: true

module EventsHelper
  # ------------ #
  # LISTING ROWS #
  # ------------ #

  # move somewhere general?

  def day_row(day, today)
    html_options = if DayNames.same_weekday?(day, today)
                     { class: 'day_row today', id: 'classes_today' }
                   else
                     { class: 'day_row' }
                   end

    tag :li, html_options, true
  end

  def date_row(date, today)
    html_options = if date == today
                     { class: 'date_row today', id: 'socials_today' }
                   else
                     { class: 'date_row' }
                   end

    tag :li, html_options, true
  end

  def day_header(day)
    url_options = { controller: :maps,
                    action: :classes,
                    day: day }
    link_to day, url_options, title: "Click to view this day's weekly classes on a map"
  end

  def date_header(date, today)
    display = date_header_label_prefix(date, today) + date.to_s(:listing_date)

    url_options = { controller: :maps,
                    action: :socials,
                    date: date.to_s(:db) }
    link_to raw(display), url_options, title: "Click to view this date's events on a map"
  end

  def date_header_label_prefix(date, today)
    case date
    when today
      "#{today_label} "
    when today + 1
      "#{tomorrow_label} "
    else
      ''
    end
  end

  # if there are no socials on this day, we need to add a class
  def socialsh2(socials_dates, &block)
    if socials_dates.empty?
      content_tag :h2, id: 'socials_today', &block
    else
      content_tag :h2, &block
    end
  end

  def today_label
    content_tag :strong, 'Today', class: 'today_label'
  end

  def tomorrow_label
    content_tag :strong, 'Tomorrow', class: 'tomorrow_label'
  end

  def classes_on_day(classes, day)
    classes.select { |e| e.day == day }.sort_by(&:venue_area)
  end

  # ---------------- #
  # LISTING ELEMENTS #
  # ---------------- #

  def social_listing(social, cancelled, date)
    if social.title.blank?
      logger.error "[ERROR]: tried to display Event (id = #{social.id}) without a title"
      return
    end

    cancelled_part = ''
    cancelled_part = cancelled_label + ' ' if cancelled

    map_url = "map/socials/#{date.to_s(:db)}?venue_id=#{social.venue_id}" unless social.venue.lat.nil? || social.venue.lng.nil?
    postcode_part = outward_postcode(social, map_url)

    content_tag :li,
                postcode_part + ' ' +
                content_tag(:span, raw(cancelled_part + social_link(social)), class: 'details')
  end

  def social_link(event)
    new_label = ''
    new_label = new_event_label + ' ' if event.new?

    event_title = event.title
    # Highlight socials which are monthly or more infrequent:
    event_title =  content_tag(:span, event.title, class: 'social_highlight') if event.less_frequent?

    event_location = content_tag(:span, "#{event.venue_name} in #{event.venue_area}", class: 'info')

    # display = new_label + "#{event_title} - #{event_location}"
    display = raw(new_label + event_title + ' - ' + event_location)

    link_to_unless event.url.nil?, display, event.url, id: event.id
  end

  def mapinfo_social_listing(event_listing)
    if event_listing.event.title.blank?
      logger.error "[ERROR]: tried to display Event (id = #{social.id}) without a title"
      return
    end

    cancelled_part = ''
    cancelled_part = cancelled_label + ' ' if event_listing.cancelled?

    raw(cancelled_part + mapinfo_social_link(event_listing.event))
  end

  def mapinfo_social_class_info(social)
    class_info = ''
    if social.has_class? || social.has_taster?
      class_style = ''
      class_style = " #{social.class_style}" if social.class_style.present?

      class_type = if social.has_class?
                     'class'
                   else
                     'taster'
                   end

      school_info = ''
      school_info = " by #{school_name(social)}" if school_name(social)

      class_info = " (with#{class_style} #{class_type}#{school_info})"
    end

    swingclass_info(class_info)
  end

  def mapinfo_social_link(event)
    new_label = ''
    new_label = new_event_label + ' ' if event.new?

    display = raw(new_label + event.title + mapinfo_social_class_info(event))

    link_to_unless event.url.nil?, display, event.url
  end

  def swingclass_listing(swingclass, day)
    map_url = "map/classes/#{day}?venue_id=#{swingclass.venue_id}" unless swingclass.venue.lat.nil? || swingclass.venue.lng.nil?
    postcode_part = outward_postcode(swingclass, map_url)

    content_tag :li,
                postcode_part + ' ' +
                content_tag(:span, swingclass_link(swingclass) + swingclass_cancelledmsg(swingclass), class: 'details')
  end

  def swingclass_link(event)
    new_label = ''
    new_label = new_event_label + ' ' if event.new?

    start_date = ''
    start_date = " (from #{event.first_date.to_s(:short_date)})" unless event.first_date.nil? || event.started?

    class_style = ''
    class_style = " (#{event.class_style})" if event.class_style.present?

    course_length = ''
    course_length = " - #{event.course_length} week courses" unless event.course_length.nil?

    social_info = ''
    social_info = "at #{event.title} " if event.has_social?

    school_info = ''
    school_info = "with #{school_name(event)}" if school_name(event)

    # TODO: work out why this needs the "raw" on the new_label to display properly
    display = raw(
      new_label +
      event.venue_area + start_date + class_style + course_length + ' ' +
      swingclass_info(social_info + school_info)
    )

    link_to_unless event.url.nil?, display, event.url
  end

  def mapinfo_swingclass_link(event)
    new_label = ''
    new_label = new_event_label + ' ' if event.new?

    start_date = ''
    start_date = " (from #{event.first_date.to_s(:short_date)})" unless event.first_date.nil? || event.started?

    class_type = ' Class'
    class_type = " #{event.course_length} week courses" unless event.course_length.nil?

    class_style = ''
    class_style = " (#{event.class_style})" if event.class_style.present?

    social_info = ''
    social_info = "at #{event.title} " if event.has_social?

    school_info = ''
    school_info = "with #{school_name(event)}" if school_name(event)

    # TODO: work out why this needs the "raw" on the new_label to display properly
    display = raw(
      new_label + start_date +
      class_type + class_style + ' ' +
      swingclass_info(social_info + school_info)
    )

    link_to_unless event.url.nil?, display, event.url
  end

  def school_name(event)
    raise 'Tried to get class-related info from an event with no class' unless event.has_class? || event.has_taster?
    return if event.class_organiser.nil?
    raise "Invalid Organiser (##{event.class_organiser.id}): name was blank" if event.class_organiser.name.blank?

    if event.class_organiser.shortname.blank?
      event.class_organiser.name
    else
      content_tag(:abbr, event.class_organiser.shortname, title: event.class_organiser.name)
    end
  end

  def new_event_label
    content_tag(:strong, 'New!', class: 'new_label')
  end

  def cancelled_label
    content_tag(:strong, 'Cancelled', class: 'cancelled_label')
  end

  def swingclass_info(text)
    content_tag(:span, raw(text), class: 'info')
  end

  def outward_postcode(event, map_url = nil)
    # Default message:
    title = 'Bah - this event is too secret to have a postcode!'

    if event.venue.nil?
      postcode = Venue::UNKNOWN_COMPASS
      logger.warn "[WARNING]: Venue was nil for '#{event.title}' (event #{event.id})"
    else
      title = "#{event.venue.postcode} to be precise. Click to see the venue on a map" if event.venue.postcode.present?
      postcode = event.venue.outward_postcode
    end

    link_to_unless map_url.nil?, postcode, map_url, title: title, class: 'postcode' do
      content_tag :abbr, postcode, title: title, class: 'postcode'
    end
  end

  # Return a span containing a message about cancelled dates:
  def swingclass_cancelledmsg(swingclass)
    return '' if swingclass.cancellation_array(true).empty?

    content_tag(:em, "Cancelled on #{swingclass.pretty_cancelled_dates}", class: 'class_cancelled')
  end

  # ------- #
  # DISPLAY #
  # ------- #

  def commas_as_lines(s)
    # insert newlines after each comma
    s.split(',').collect(&:strip).join(",\n")
  end

  # ------- #
  # SELECTS #
  # ------- #

  def venue_select
    Venue.order(name: :asc).collect { |v| [v.name_and_area, v.id] }
  end

  def organiser_select
    Organiser.all.collect { |o| [o.name, o.id] }
  end

  # ----- #
  # LINKS #
  # ----- #

  def organiser_link(organiser)
    return Event::UNKNOWN_ORGANISER if organiser.nil?

    link_to_unless organiser.website.nil?, organiser.name, organiser.website
  end

  def venue_link(event)
    return event.blank_venue if event.venue.nil?

    link_to_unless event.venue.website.nil?, event.venue.name, event.venue.website
  end

  # --- #
  # CMS #
  # --- #

  def action_links(anchors)
    content_tag :p, class: 'actions_panel' do
      string = link_to 'New event', new_event_path
      anchors.each do |a|
        string += ' -- '
        string += link_to a.to_s, anchor: a
      end
      string
    end
  end
end
