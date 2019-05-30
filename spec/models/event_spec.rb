# frozen_string_literal: true

require 'rails_helper'

describe Event do
  before do
    @event = described_class.new
  end

  describe '.dates' do
    it 'returns an ordered list of dates' do
      recent_date = FactoryBot.create(:swing_date, date: Time.zone.today)
      old_date = FactoryBot.create(:swing_date, date: Time.zone.today - 1.year)

      event = FactoryBot.create(:event)
      event.swing_dates << recent_date
      event.swing_dates << old_date
      event.save!

      expect(event.reload.dates).to eq([Time.zone.today - 1.year, Time.zone.today])
    end
  end

  describe '.self.socials_dates' do
    context 'when there is only one social' do
      it 'returns the correct array when that social has only one date in the future' do
        one_date = Time.zone.today + 7
        event = FactoryBot.create(:intermittent_social, dates: [one_date])
        expect(described_class.socials_dates(Time.zone.today).length).to eq(1)
        expect(described_class.socials_dates(Time.zone.today)[0][0]).to eq(one_date)
        expect(described_class.socials_dates(Time.zone.today)[0][1]).to eq([event])
      end

      it 'returns the correct array when that social has two dates in the future' do
        later_date = Time.zone.today + 7
        earlier_date = Time.zone.today + 1
        event = FactoryBot.create(:intermittent_social, dates: [later_date, earlier_date])

        expect(described_class.socials_dates(Time.zone.today).length).to eq(2)
        expect(described_class.socials_dates(Time.zone.today)[0][0]).to eq(earlier_date)
        expect(described_class.socials_dates(Time.zone.today)[0][1]).to eq([event])
        expect(described_class.socials_dates(Time.zone.today)[1][0]).to eq(later_date)
        expect(described_class.socials_dates(Time.zone.today)[1][1]).to eq([event])
      end

      it 'returns the correct array when that social has one date today, one at the limit and one outside the limit' do
        lower_limit_date = Time.zone.today
        upper_limit_date = Time.zone.today + 13
        outside_limit_date = Time.zone.today + 14
        event = FactoryBot.create(:intermittent_social, dates: [upper_limit_date, outside_limit_date, lower_limit_date])

        expect(described_class.socials_dates(Time.zone.today).length).to eq(2)
        expect(described_class.socials_dates(Time.zone.today)).to eq([[lower_limit_date, [event], []], [upper_limit_date, [event], []]])
      end

      it 'returns the correct array when that social has one date in the future and one in the past' do
        past_date = Time.zone.today - 1.month
        future_date = Time.zone.today + 5
        event = FactoryBot.create(:intermittent_social, dates: [past_date, future_date])

        expect(described_class.socials_dates(Time.zone.today).length).to eq(1)
        expect(described_class.socials_dates(Time.zone.today)).to eq([[future_date, [event], []]])
      end
    end

    pending 'add more tests for socials_dates which return multiple events'
    pending 'add tests including weekly events!'

    context 'in a complex scenario' do
      def d(n)
        Time.zone.today + n
      end

      pending 'do more complex examples!'

      # class_with_social = FactoryBot.create(:class, :event_type =>"class_with_social", :day => "Tuesday")

      # rubocop:disable RSpec/ExampleLength
      it 'returns the correct array with a bunch of classes and socials' do
        # create one class for each day, starting on monday. None of these should be included
        FactoryBot.create_list(:class, 7)

        # not included events:
        FactoryBot.create(:intermittent_social, dates: [d(-10)])
        FactoryBot.create(:intermittent_social, dates: [d(-370)])
        FactoryBot.create(:intermittent_social, dates: [d(20)])

        # included events:
        event_d1 = FactoryBot.create(:intermittent_social, dates: [d(1)])
        event_d10_d11 = FactoryBot.create(:social, frequency: 4, dates: [d(10), d(11)])
        event_1_d8 = FactoryBot.create(:social, frequency: 4, dates: [d(8)], title: 'A')
        event_2_d8 = FactoryBot.create(:social, frequency: 2, dates: [d(8)], title: 'Z')

        expect(described_class.socials_dates(Time.zone.today)).to eq(
          [
            [d(1), [event_d1], []],
            [d(8), [event_1_d8, event_2_d8], []],
            [d(10), [event_d10_d11], []],
            [d(11), [event_d10_d11], []]
          ]
        )
      end
      # rubocop:enable RSpec/ExampleLength
    end
  end

  # ultimately do away with date_array and test .dates= instead"
  describe '.date_array =' do
    before do
      @event = FactoryBot.create(:event)
    end

    describe 'empty strings' do
      it 'handles an event with with no dates and adding no dates' do
        @event.date_array = ''
        expect(@event.swing_dates).to eq([])
      end

      it 'handles an event with with no dates and adding nil dates' do
        @event.date_array = nil
        expect(@event.swing_dates).to eq([])
      end

      it 'handles an event with no dates and adding unknown dates' do
        @event.date_array = 'Unknown'
        expect(@event.swing_dates).to eq([])
      end

      it 'handles an event with no dates and a weekly event' do
        @event.date_array = 'Weekly'
      end
    end

    it 'successfully adds one valid date to an event' do
      @event.date_array = '01/02/2012'
      expect(@event.dates).to eq([Date.new(2012, 2, 1)])
    end

    it 'successfully adds two valid dates to an event with no dates and orders them' do
      @event.date_array = '01/02/2012, 30/11/2011'
      expect(@event.dates).to eq([Date.new(2011, 11, 30), Date.new(2012, 2, 1)])
    end

    it 'blanks out a date array where there existing dates' do
      @event = FactoryBot.create(:event, date_array: '01/02/2012, 30/11/2011')
      expect(@event.dates).to eq([Date.new(2011, 11, 30), Date.new(2012, 2, 1)])
      @event.date_array = ''
      expect(@event.dates).to eq([])
    end

    it 'does not create multiple instances of the same date' do
      event1 = FactoryBot.create(:event)
      event1.date_array = '05/05/2005'
      event1.save!
      event2 = FactoryBot.create(:event)
      event2.date_array = '05/05/2005'
      event2.save!
      expect(SwingDate.where(date: Date.new(2005, 5, 5)).length).to eq(1)
    end

    pending 'multiple valid dates, one invalid date on the end'
    pending 'multiple valid dates, one invalid date in the middle'
    pending 'blanking out where there are existing dates'
    pending 'fails to add an invalid date to an event'

    pending 'save with an invalid dates array'

    pending 'test with multiple dates, different orders, whitespace'
  end

  describe '.cancellation_array = ' do
    describe 'empty strings' do
      it 'handles an event with with no cancellations and adding no cancellations' do
        @event.cancellation_array = ''
        expect(@event.swing_cancellations).to eq([])
      end

      it 'handles an event with with no cancellations and adding nil cancellations' do
        @event.cancellation_array = nil
        expect(@event.swing_cancellations).to eq([])
      end

      it 'handles an event with no cancellations and adding unknown cancellations' do
        @event.cancellation_array = 'Unknown'
        expect(@event.swing_cancellations).to eq([])
      end

      it 'handles an event with no cancellations and a weekly event' do
        @event.cancellation_array = 'Weekly'
        expect(@event.swing_cancellations).to eq([])
      end
    end

    it 'successfully adds one valid cancellation to an event with no cancellations' do
      @event.cancellation_array = '01/02/2012'
      expect(@event.cancellations).to eq([Date.new(2012, 2, 1)])
    end

    it 'successfully adds two valid cancellations to an event with no cancellations and orders them' do
      @event.cancellation_array = '01/02/2012, 30/11/2011'
      expect(@event.cancellations).to eq([Date.new(2012, 2, 1), Date.new(2011, 11, 30)])
    end

    it 'blanks out a cancellation array where there existing dates' do
      event = FactoryBot.create(:event, cancellation_array: '01/02/2012')
      expect(event.cancellations).to eq([Date.new(2012, 2, 1)])
      event.cancellation_array = ''
      expect(event.cancellations).to eq([])
    end

    pending 'multiple valid cancellations, one invalid date on the end'
    pending 'multiple valid cancellations, one invalid date in the middle'
    pending 'fails to add an invalid date to an event'

    pending 'save with an invalid cancellations array'

    pending 'test with multiple cancellations, different orders, whitespace'
  end

  describe 'active.classes' do
    it "returns classes with no 'last date'" do
      event = FactoryBot.create(:class, last_date: nil)
      expect(described_class.active.classes).to eq([event])
    end

    it "does not return classes with a 'last date' in the past" do
      FactoryBot.create(:class, last_date: Time.zone.today - 1)
      expect(described_class.active.classes).to eq([])
    end

    it 'does not return non-classes' do
      FactoryBot.create(:event, last_date: nil, has_class: 'false')
      FactoryBot.create(:event, last_date: nil, has_taster: 'true')

      expect(described_class.active.classes).to eq([])
    end

    # rubocop:disable RSpec/ExampleLength
    it 'returns the correct list of classes' do
      FactoryBot.create(:social, last_date: nil)
      FactoryBot.create(:class, last_date: Time.zone.today - 5)
      returned = [
        FactoryBot.create(:class),
        FactoryBot.create(:class, last_date: nil),
        FactoryBot.create(:class, last_date: Time.zone.today + 1)
      ]
      FactoryBot.create(:social)
      FactoryBot.create(:event, has_class: 'false', has_taster: 'true')

      expect(described_class.active.classes.length).to eq(returned.length)
      expect(returned).to include(described_class.active.classes[0])
      expect(returned).to include(described_class.active.classes[1])
      expect(returned).to include(described_class.active.classes[2])
    end
    # rubocop:enable RSpec/ExampleLength
  end

  describe '(validations)' do
    it 'is invalid if it has neither a class nor a social nor a taster' do
      expect(FactoryBot.build(:event, has_taster: false, has_social: false, has_class: false)).not_to be_valid
    end
    it 'is invalid if it has a taster but no class or social' do
      expect(FactoryBot.build(:event, has_taster: true, has_social: false, has_class: false)).not_to be_valid
    end
    it 'is valid if it has a class but no taster or social (and everything else is OK)' do
      expect(FactoryBot.build(:event, has_taster: false, has_social: false, has_class: true)).to be_valid
    end
    it 'is valid if it has a social but no taster or class (and everything else is OK)' do
      expect(FactoryBot.build(:event, has_taster: false, has_social: true, has_class: false)).to be_valid
    end

    it 'is invalid with no venue' do
      event = FactoryBot.build(:event, venue_id: nil)
      event.valid?
      expect(event.errors.messages).to eq(venue: ['must exist'])
    end

    it 'is valid with an empty date array' do
      expect(FactoryBot.build(:event, date_array: '')).to be_valid
    end

    it 'is invalid with an invalid date array' do
      expect(FactoryBot.build(:event, date_array: '100')).not_to be_valid
    end

    it 'is valid with an empty cancellation array' do
      expect(FactoryBot.build(:event, cancellation_array: '')).to be_valid
    end

    it 'is invalid with an invalid cancellation array' do
      expect(FactoryBot.build(:event, cancellation_array: '100')).not_to be_valid
    end
  end

  describe 'expected_date' do
    it 'is a month after the previous date for monthly events' do
      event = FactoryBot.build(:event, frequency: 4)
      # FIXME: EVIL!!!: Stubbing object under test
      allow(event).to receive(:latest_date).and_return Date.new(1970, 1, 1)
      expect(event.expected_date).to eq Date.new(1970, 1, 29)
    end

    it 'is a year after the previous date for monthly events' do
      event = FactoryBot.build(:event, frequency: 52)
      # FIXME: EVIL!!!: Stubbing object under test
      allow(event).to receive(:latest_date).and_return Date.new(1970, 1, 1)
      expect(event.expected_date).to eq Date.new(1970, 12, 31)
    end

    it 'is after a far-future date if there are no dates' do
      event = FactoryBot.build(:event, frequency: 4) # No dates by default
      expect(event.expected_date).to be > Time.zone.today + 1.year
    end

    it 'is after a far-future date if the event is weekly' do
      event = FactoryBot.build(:event, frequency: 1)
      expect(event.expected_date).to be > Time.zone.today + 1.year
    end

    it 'is after a far-future date if the event has frequency 0 and other dates' do
      event = FactoryBot.build(:event, frequency: 0)
      # FIXME: EVIL!!!: Stubbing object under test
      allow(event).to receive(:latest_date).and_return Date.new(1970, 1, 1)
      expect(event.expected_date).to be > Time.zone.today + 1.year
    end
  end
end
