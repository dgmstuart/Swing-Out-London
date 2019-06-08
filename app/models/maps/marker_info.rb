# frozen_string_literal: true

module Maps
  class MarkerInfo
    def initialize(venue:, events:)
      @venue = venue
      @events = events
    end

    delegate :name, to: :venue, prefix: true
    delegate :postcode, to: :venue

    def venue_url
      venue.website
    end

    def address_lines
      venue.address.split(',').map(&:strip).tap do |lines|
        lines.delete('London')
      end
    end

    def social_listings
      events.inject([]) do |listings, (date, socials_on_date, cancelled_ids)|
        listings + socials_on_date.map do |social|
          cancelled = cancelled_ids.include?(social.id)
          SocialListing.new(date, social, cancelled)
        end
      end
    end

    def class_listings
      events.inject([]) do |listings, event|
        listings << ClassListing.new(event)
      end
    end

    private

    attr_reader :venue, :events

    class SocialListing
      def initialize(date, event, cancelled)
        @date = date
        @event = event
        @cancelled = cancelled
      end

      attr_reader :event

      def when
        date.to_s(:listing_date)
      end

      def cancelled?
        cancelled
      end

      private

      attr_reader :date, :cancelled
    end
  end

  class ClassListing
    def initialize(event)
      @event = event
    end

    attr_reader :event

    def when
      event.day.pluralize
    end
  end
end
