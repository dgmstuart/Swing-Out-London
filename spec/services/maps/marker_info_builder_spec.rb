# frozen_string_literal: true

require 'spec_helper'
require 'app/services/maps/marker_info_builder'

RSpec.describe Maps::MarkerInfoBuilder do
  describe '#build' do
    it 'fetches the events for the venue' do
      event_finder = instance_double('Maps::Socials::FinderFromVenue', find: double)
      presenter_klass = class_double('Maps::MarkerInfo', new: double)
      builder = described_class.new(event_finder: event_finder, presenter_klass: presenter_klass)
      venue = double

      builder.build(venue)

      expect(event_finder).to have_received(:find).with(venue)
    end

    it 'builds information associated with a venue marker' do
      events = double
      event_finder = instance_double('Maps::Socials::FinderFromVenue', find: events)
      presenter_klass = class_double('Maps::MarkerInfo', new: double)
      builder = described_class.new(event_finder: event_finder, presenter_klass: presenter_klass)
      venue = double

      builder.build(venue)

      expect(presenter_klass).to have_received(:new).with(venue: venue, events: events)
    end

    it 'returns information associated with a venue marker' do
      events = double
      event_finder = instance_double('Maps::Socials::FinderFromVenue', find: events)
      info = instance_double('Maps::MarkerInfo')
      presenter_klass = class_double('Maps::MarkerInfo', new: info)
      builder = described_class.new(event_finder: event_finder, presenter_klass: presenter_klass)
      venue = double

      result = builder.build(venue)

      expect(result).to eq info
    end
  end
end
