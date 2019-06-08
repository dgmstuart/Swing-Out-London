# frozen_string_literal: true

module Maps
  class MarkerInfoBuilder
    def initialize(event_finder:, presenter_klass: Maps::MarkerInfo)
      @event_finder = event_finder
      @presenter_klass = presenter_klass
    end

    def build(venue)
      events = event_finder.find(venue)
      presenter_klass.new(venue: venue, events: events)
    end

    private

    attr_reader :event_finder, :presenter_klass
  end
end
