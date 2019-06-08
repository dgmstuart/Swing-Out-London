# frozen_string_literal: true

class MapsController < ApplicationController
  layout 'map'

  caches_action :socials, :classes,
                cache_path: proc { |c| c.params.permit(:day, :date, :venue_id) },
                layout: true,
                expires_in: 1.hour,
                race_condition_ttl: 10

  def classes
    # Varnish will cache the page for 3600 seconds = 1 hour:
    response.headers['Cache-Control'] = 'public, max-age=3600'

    @day = Maps::Classes::DayParser.parse(params[:day], today)
    venues = Maps::Classes::VenueQuery.new(@day).venues

    marker_info_builder = Maps::MarkerInfoBuilder.new(
      event_finder: Maps::Classes::FinderFromVenue.new(day: @day)
    )
    @map =
      Maps::Map.new(
        venues: venues,
        highlighted_venue_id: params[:venue_id].to_i,
        marker_info_builder: marker_info_builder,
        info_window_partial: 'classes_map_info',
        renderer: self
      )
  rescue Maps::Classes::DayParser::NonDayError
    flash[:warn] = 'We can only show you classes for days of the week'
    logger.warn("Not a recognised day: #{@day}")
    redirect_to map_classes_path
  end

  def socials
    # Varnish will cache the page for 3600 seconds = 1 hour:
    response.headers['Cache-Control'] = 'public, max-age=3600'

    @map_dates = Maps::Socials::Dates.new(params[:date], today)

    venues = Maps::Socials::VenueQuery.new(@map_dates.display_dates).venues
    marker_info_builder = Maps::MarkerInfoBuilder.new(
      event_finder: Maps::Socials::FinderFromVenue.new(date: @map_dates.selected_date, today: today)
    )
    @map =
      Maps::Map.new(
        venues: venues,
        highlighted_venue_id: params[:venue_id].to_i,
        marker_info_builder: marker_info_builder,
        info_window_partial: 'socials_map_info',
        renderer: self
      )
  rescue Maps::Socials::Dates::DateOutOfRangeError
    flash[:warn] = 'We can only show you events for the next 14 days'
    logger.warn("Not a date in the visible range: #{@date}")
    redirect_to map_socials_path
  end
end
