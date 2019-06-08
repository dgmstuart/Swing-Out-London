# frozen_string_literal: true

module Maps
  class Map
    attr_reader :highlighted_venue

    def initialize(venues:, highlighted_venue_id:, marker_info_builder:, info_window_partial:, renderer:)
      @venues = venues
      @highlighted_venue_id = highlighted_venue_id
      @marker_info_builder = marker_info_builder
      @info_window_partial = info_window_partial
      @renderer = renderer
    end

    def markers
      venues.map { |venue| marker(venue) }
    end

    private

    attr_reader :venues, :highlighted_venue_id, :marker_info_builder, :info_window_partial, :renderer

    def marker(venue)
      position = { lat: venue.lat, lng: venue.lng }
      {
        id: venue.id,
        title: venue.name,
        position: position,
        infoWindowContent: info_window_content(venue)
      }.tap do |json_options|
        json_options[:icon] = highlighted_marker_icon if venue.id == highlighted_venue_id
      end
    end

    def highlighted_marker_icon
      'https://maps.google.com/mapfiles/marker_purple.png'
    end

    def info_window_content(venue)
      renderer.render_to_string(
        partial: info_window_partial,
        formats: [:html],
        locals: {
          marker_info: marker_info_builder.build(venue)
        }
      )
    end
  end
end
