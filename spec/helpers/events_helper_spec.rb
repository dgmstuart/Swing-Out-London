# frozen_string_literal: true

require 'rails_helper'

describe EventsHelper do
  describe 'school_name' do
    it 'fails if called on a non-class' do
      event = FactoryBot.create(:event, has_class: false)
      expect { helper.school_name(event) }.to raise_error(RuntimeError)
    end

    context 'when there is no organiser' do
      before do
        @class = FactoryBot.create(:class, class_organiser: nil)
      end

      it 'returns an empty string' do
        expect(helper.school_name(@class)).to be_nil
      end
    end

    context 'when there is a class organiser' do
      before do
        @organiser = FactoryBot.create(:organiser)
        @class = FactoryBot.create(:class, class_organiser: @organiser)
      end

      it "raises an error if the organiser's name is blank" do
        @organiser.name = nil
        expect { helper.school_name(@class) }.to raise_error(RuntimeError)
      end

      it "uses the name if the shortname doesn't exist" do
        @organiser.name = 'foo'
        @organiser.shortname = nil
        expect(helper.school_name(@class)).to eq('foo')
      end

      it 'uses the shortname as an abbreviation if it exists' do
        @organiser.name = 'foo'
        @organiser.shortname = 'bar'
        expect(helper.school_name(@class)).to eq(%(<abbr title="foo">bar</abbr>))
      end
    end
  end
end
