# frozen_string_literal: true

module ListingsHelper
  def social_listing(social, cancelled, date)
    if social.title.blank?
      logger.error "[ERROR]: tried to display Event (id = #{social.id}) without a title"
      return
    end

    map_url = "map/socials/#{date.to_s(:db)}?venue_id=#{social.venue_id}" unless social.venue.lat.nil? || social.venue.lng.nil?
    postcode_part = outward_postcode(social, map_url)

    details = tag.span class: 'details' do
      if cancelled
        concat cancelled_label
        concat ' '
      end
      concat social_link(social)
    end

    tag.li do
      concat postcode_part
      concat details
    end
  end

  def social_link(event)
    # example: NEW! Awesome swing event - Dalston
    text = capture do
      if event.new?
        concat new_event_label
        concat ' '
      end
      concat social_title(event)
      concat ' - '
      concat tag.span("#{event.venue_name} in #{event.venue_area}", class: 'info')
    end

    if event.url.nil?
      tag.span text, id: event.id
    else
      link_to text, event.url, id: event.id
    end
  end

  def social_title(event)
    # Highlight socials which are monthly or more infrequent by applying a 'social_highlight' class
    if event.less_frequent?
      tag.span(event.title, class: 'social_highlight')
    else
      event.title
    end
  end

  def mapinfo_social_listing(social, cancelled, date = nil)
    if social.title.blank?
      logger.error "[ERROR]: tried to display Event (id = #{social.id}) without a title"
      return
    end

    date_info = tag.span class: 'social_date' do
      concat link_to date.to_s(:listing_date), date: date.to_s(:db)
      concat ': '
    end

    social_details = mapinfo_social_details(social, cancelled)

    wrapped_social_details = tag.span class: 'event_details' do
      concat social_details
    end

    capture do
      if date
        concat date_info
        concat wrapped_social_details
      else
        concat social_details
      end
    end
  end

  def mapinfo_social_details(social, cancelled)
    capture do
      if cancelled
        concat cancelled_label
        concat ' '
      end
      concat mapinfo_social_link(social)
      if social.has_class? || social.has_taster?
        concat ' '
        concat mapinfo_class_info_tag(social)
      end
    end
  end

  def mapinfo_class_info_tag(social)
    class_info = capture do
      if social.class_style.present?
        concat social.class_style
        concat ' '
      end

      class_type =
        if social.has_class?
          'class'
        else
          'taster'
        end
      concat class_type

      if school_name(social)
        concat ' by '
        concat school_name(social)
      end
    end

    tag.span class: 'info' do
      concat '('
      concat class_info
      concat ')'
    end
  end

  def mapinfo_social_link(event)
    text = capture do
      if event.new?
        concat new_event_label
        concat ' '
      end
      concat event.title
    end

    link_to_unless event.url.nil?, text, event.url
  end

  def swingclass_listing(swingclass, day)
    map_url = "map/classes/#{day}?venue_id=#{swingclass.venue_id}" unless swingclass.venue.lat.nil? || swingclass.venue.lng.nil?
    postcode_part = outward_postcode(swingclass, map_url)

    details = tag.span class: 'details' do
      concat swingclass_link(swingclass)
      concat swingclass_cancelledmsg(swingclass)
    end

    tag.li do
      concat postcode_part
      concat details
    end
  end

  def swingclass_link(event)
    text = capture do
      concat swingclass_details(event)
      concat tag.span swingclass_info(event), class: 'info' if swingclass_info(event)
    end

    if event.url.nil?
      text
    else
      link_to text, event.url
    end
  end

  def swingclass_details(event)
    details = []
    details << new_event_label if event.new?
    details << event.venue_area
    details << "(from #{event.first_date.to_s(:short_date)})" unless event.first_date.nil? || event.started?
    details << "(#{event.class_style})" if event.class_style.present?
    details << "- #{event.course_length} week courses" unless event.course_length.nil?
    details.join(' ')
  end

  def swingclass_info(event)
    capture do
      if event.has_social?
        concat ' '
        concat "at #{event.title}"
      end

      if school_name(event)
        concat ' with '
        concat school_name(event)
      end
    end
  end

  def mapinfo_swingclass_link(event)
    text = capture do
      concat mapinfo_swingclass_details(event)
      concat tag.span swingclass_info(event), class: 'info' if swingclass_info(event)
    end

    if event.url.nil?
      text
    else
      link_to text, event.url
    end
  end

  def mapinfo_swingclass_details(event)
    details = []
    details << new_event_label if event.new?
    details << "(from #{event.first_date.to_s(:short_date)})" unless event.first_date.nil? || event.started?
    details << "(#{event.class_style})" if event.class_style.present?
    details << "- #{event.course_length} week courses" unless event.course_length.nil?
    details.join(' ')
  end

  def school_name(event)
    raise 'Tried to get class-related info from an event with no class' unless event.has_class? || event.has_taster?
    return if event.class_organiser.nil?
    raise "Invalid Organiser (##{event.class_organiser.id}): name was blank" if event.class_organiser.name.blank?

    if event.class_organiser.shortname.blank?
      event.class_organiser.name
    else
      tag.abbr(event.class_organiser.shortname, title: event.class_organiser.name)
    end
  end

  def new_event_label
    tag.strong('New!', class: 'new_label')
  end

  def cancelled_label
    tag.strong('Cancelled', class: 'cancelled_label')
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
      tag.abbr(postcode, title: title, class: 'postcode')
    end
  end

  # Return a span containing a message about cancelled dates:
  def swingclass_cancelledmsg(swingclass)
    return '' if swingclass.cancellation_array(future: true).empty?

    tag.em("Cancelled on #{swingclass.pretty_cancelled_dates}", class: 'class_cancelled')
  end
end
