# frozen_string_literal: true

require 'out_of_date_calculator'
require 'date_expectation_calculator'
require 'dates_string_parser'
require 'day_names'

class Event < ApplicationRecord
  audited

  belongs_to :venue
  belongs_to :class_organiser, class_name: 'Organiser', optional: true
  belongs_to :social_organiser, class_name: 'Organiser', optional: true
  has_many :events_swing_dates, dependent: :destroy
  has_many :swing_dates, -> { distinct(true) }, through: :events_swing_dates
  has_many :events_swing_cancellations, dependent: :destroy
  has_many :swing_cancellations, -> { distinct(true) }, through: :events_swing_cancellations, source: :swing_date

  validates :url, format: URI.regexp(%w[http https])

  validates :event_type, :frequency, :url, :day, presence: true

  validates :course_length, numericality: { only_integer: true, greater_than: 0, allow_nil: true }

  validate :cannot_be_weekly_and_have_dates
  validate :will_be_listed

  def cannot_be_weekly_and_have_dates
    return unless weekly? && !dates.empty?

    errors.add(:date_array, 'must be empty for weekly events')
  end

  def will_be_listed
    return if has_class? || has_social?

    errors[:base] << "Events must have either a Social or a Class, otherwise they won't be listed!"
  end

  # display constants:
  NOTAPPLICABLE = 'n/a'
  UNKNOWN_ORGANISER = 'Unknown'
  SEE_WEB = '(See Website)'

  def index_row_cache_key
    caching_key('index_row')
  end

  def status_cache_key
    caching_key("status_#{Date.today.to_s(:iso)}")
  end

  # ----- #
  # Venue #
  # ----- #

  def blank_venue
    return SEE_WEB unless url.nil?

    UNKNOWN_VENUE
  end

  # We shouldn't have any blank fields, but if we do, then display as much as possible:
  delegate :name, to: :venue, prefix: true

  delegate :area, to: :venue, prefix: true

  def one_off?
    frequency.zero?
  end

  # ---------- #
  # Event Type #
  # ---------- #

  EVENT_TYPES = %w[
    school
    dance_club
    vintage_club
    gig
    festival
  ].freeze

  # scopes to get different types of event:
  scope :classes, -> { where(has_class: true) }
  scope :socials, -> { where(has_social: true) }
  scope :weekly, -> { where(frequency: 1) }
  scope :weekly_or_fortnightly, -> { where(frequency: [1, 2]) }

  scope :gigs, -> { where(event_type: 'gig') }
  scope :non_gigs, -> { where('event_type != ?', 'gig') }

  scope :active, -> { where('last_date IS NULL OR last_date > ?', Date.local_today) }
  scope :ended, -> { where('last_date IS NOT NULL AND last_date < ?', Date.local_today) }
  scope :active_on, ->(date) { where('(first_date IS NULL OR first_date <= ?) AND (last_date IS NULL OR last_date >= ?)', date, date) }

  scope :listing_classes, -> { active.weekly_or_fortnightly.classes }
  scope :listing_classes_on_day, ->(day) { listing_classes.where(day: day) }
  scope :listing_classes_at_venue, ->(venue) { listing_classes.where(venue_id: venue.id) }
  scope :listing_classes_on_day_at_venue, ->(day, venue) { listing_classes_on_day(day).where(venue_id: venue.id) }

  scope :on_same_day_of_week, ->(date) { where(day: DayNames.name(date)) }

  # For making sections in the Events editing screens:
  scope :current, -> { active.non_gigs }
  scope :archived, -> { ended.non_gigs }

  def caching_key(suffix)
    "event_#{id}_#{suffix}"
  end

  # ----- #
  # Dates #
  # ----- #

  def dates_cache_key
    caching_key('dates')
  end

  def dates
    Rails.cache.fetch(dates_cache_key) do
      swing_dates.order('date ASC').collect(&:date)
    end
  end

  after_save :clear_dates_cache
  def clear_dates_cache
    Rails.cache.delete(dates_cache_key)
  end

  def add_date(new_date)
    swing_dates << SwingDate.find_or_initialize_by(date: new_date)
  end

  def dates=(array_of_new_dates)
    clear_dates_cache
    self.swing_dates = []
    array_of_new_dates.each { |nd| add_date(nd) }
  end

  def date_array=(date_string)
    self.dates = DatesStringParser.new.parse(date_string)
  end

  def cancellations
    swing_cancellations.collect(&:date)
  end

  def cancellations=(array_of_new_cancellations)
    self.swing_cancellations = []
    array_of_new_cancellations.each { |nc| add_cancellation(nc) }
  end

  def add_cancellation(new_cancellation)
    swing_cancellations << SwingDate.find_or_initialize_by(date: new_cancellation)
  end

  def cancellation_array=(date_string)
    self.cancellations = DatesStringParser.new.parse(date_string)
  end

  # READ METHODS #

  def date_array(future = false)
    return_array_of_dates(dates, future)
  end

  def cancellation_array(future = false)
    return_array_of_dates(cancellations, future)
  end

  private

  # Given an array of dates, return an appropriately filtered array
  def return_array_of_dates(input_dates, future = true)
    return [] if input_dates.blank?

    input_dates = filter_future(input_dates) if future
    input_dates
  end

  # Given an array of dates, return only those in the future
  def filter_future(input_dates)
    # TODO: - should be able to simply replace this with some variant of ".future?", but need to test
    input_dates.select { |d| d >= Date.local_today }
  end

  public

  def inactive?
    ended? || (out_of_date && one_off?)
  end

  # For the event listing tables:
  def status_string
    if inactive?
      'inactive'
    elsif out_of_date
      'out_of_date'
    elsif near_out_of_date
      'near_out_of_date'
    end
  end

  # TODO: these should be done in the db, not in ruby
  def self.out_of_date
    socials.non_gigs.select { |e| !e.inactive? && e.out_of_date }
  end

  def self.near_out_of_date
    socials.non_gigs.select { |e| !e.inactive? && !e.out_of_date && e.near_out_of_date }
  end

  # PRINT METHODS #

  def print_dates
    print_date_array
  end

  def print_dates_rows
    print_date_array(",\n")
  end

  def print_cancellations
    print_cancellation_array
  end

  def pretty_cancelled_dates
    print_cancellation_array(', ', :short_date, true)
  end

  def cancelled_dates_rows
    print_cancellation_array(",\n")
  end

  # -- Helper functions for Print:

  def print_date_array(sep = ',', format = :uk_date, future = false)
    print_array_of_dates(dates, sep, format, future)
  end

  def print_cancellation_array(sep = ',', format = :uk_date, future = false)
    print_array_of_dates(cancellations, sep, format, future)
  end

  private

  # Given an array of dates, return a formatted string
  def print_array_of_dates(input_dates, sep = ',', format = :uk_date, future = false)
    input_dates = filter_future(input_dates) if future
    input_dates.collect { |d| d.to_s(format) }.join(sep)
  end

  public

  # COMPARISON METHODS #

  # Are all the dates for the event in the past?
  def out_of_date(comparison_date = Date.local_today)
    return false if weekly? # Weekly events don't have date arrays, so would otherwise show as out of date
    return false if last_date
    return false unless expecting_a_date?(comparison_date)

    OutOfDateCalculator.new(latest_date, comparison_date).out_of_date?
  end

  # Does an event not have any dates not already shown in the socials list?
  def near_out_of_date
    out_of_date Date.local_today + INITIAL_SOCIALS
  end

  # What date is the next event expected on? (based on the last known date)
  def expected_date
    return self[:expected_date] if self[:expected_date] && !((latest_date && self[:expected_date] <= latest_date))
    return NoExpectedDate.new if frequency.nil? || weekly? || frequency.zero?
    return NoExpectedDate.new unless latest_date

    latest_date + frequency.weeks
  end

  def expecting_a_date?(comparison_date)
    DateExpectationCalculator.new(infrequent?, expected_date, comparison_date).expecting_a_date?
  end

  # Is the event new? (probably only applicable to classes)
  def new?
    return false if first_date.nil?

    first_date > Date.local_today - 1.month
  end

  # Has the first instance of the event happened yet?
  def started?
    return false if first_date.nil?

    first_date < Date.local_today
  end

  # Has the last instance of the event happened?
  def ended?
    return false if last_date.nil?

    last_date < Date.local_today
  end

  def intermittent?
    frequency.zero? && last_date != latest_date
  end

  def one_off?
    frequency.zero? && last_date == latest_date && first_date == latest_date
  end

  def weekly?
    frequency == 1
  end

  def infrequent?
    frequency >= 26
  end

  def less_frequent?
    frequency.zero? || frequency >= 4
  end

  def latest_date_cache_key
    caching_key('latest_date')
  end

  # What's the Latest date in the date array
  # N.B. Assumes the date array is sorted!
  def latest_date
    Rails.cache.fetch(latest_date_cache_key) do
      swing_dates.maximum(:date)
    end
  end

  after_save :clear_latest_dates_cache
  def clear_latest_dates_cache
    Rails.cache.delete(latest_date_cache_key)
  end

  ###########
  # ACTIONS #
  ###########

  def archive!
    return false if !last_date.nil? && last_date < Date.local_today

    # If there's already a last_date in the past, then the event should already be archived!

    self[:last_date] = if weekly?
                         prev_date
                       elsif dates.nil?
                         Date.new # Earliest possible ruby date
                       else
                         latest_date
                       end

    return true if save!
  end

  #################
  # CLASS METHODS #
  #################

  # Find the datetime of the most recently updated event
  def self.last_updated_datetime
    # if the db is empty, return the beginning of the epoch:
    return Time.at(0) if first.nil?

    maximum(:updated_at)
  end

  def self.socials_dates(start_date, venue = nil)
    # build up an array of events occuring on each date
    output = []

    listing_dates(start_date).each do |date|
      socials_on_date = socials_on_date(date, venue)
      output << [date, socials_on_date, cancelled_events_on_date(date)] unless socials_on_date.empty?
    end

    output
  end

  def self.socials_on_date(date, venue = nil)
    swing_date = SwingDate.find_by(date: date)

    weekly_socials = weekly.socials.active_on(date).on_same_day_of_week(date)
    if venue
      socials_on_that_date = weekly_socials.where(venue_id: venue.id)
      socials_on_that_date += swing_date.events.socials.where(venue_id: venue.id) if swing_date
    else
      socials_on_that_date = weekly_socials.includes(:venue)
      socials_on_that_date += swing_date.events.socials.includes(:venue) if swing_date
    end

    socials_on_that_date.sort_by(&:title)
  end

  def self.cancelled_events_on_date(date)
    swing_date = SwingDate.find_by(date: date)
    return [] unless swing_date

    swing_date.cancelled_events.pluck :id
  end

  def self.listing_dates(start_date)
    end_date = start_date + (INITIAL_SOCIALS - 1)
    (start_date..end_date).to_a
  end
end
