# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Adding a new event' do
  it 'with a dance class' do
    visit '/events'

    click_on 'Log in with Facebook'

    click_on 'New Venue'

    fill_in 'Name', with: 'The Savoy Ballroom'
    fill_in 'Address', with: '596 Lenox Avenue'
    fill_in 'Postcode', with: 'WC2R 0EZ'
    fill_in 'Area', with: 'Harlem'
    fill_in 'Nearest tube', with: '145 St'
    fill_in 'Latitude', with: '40.817529'
    fill_in 'Longitude', with: '73.938456'
    fill_in 'Website', with: 'https://www.savoyballroom.com'

    click_on 'Create'

    click_on 'New Organiser'

    fill_in 'Name', with: 'Herbert White'
    fill_in 'Shortname', with: 'Whitey'
    fill_in 'Website', with: 'https://hoppingmainacs.org'
    fill_in 'Description', with: "Architect of Whitey's Lindy Hoppers"

    click_on 'Update'

    click_on 'New Organiser'

    fill_in 'Name', with: 'Frankie Manning'
    fill_in 'Shortname', with: 'Frankie'

    click_on 'Update'

    click_on 'New Event'

    fill_in 'Title', with: 'Stompin at the Savoy'
    select 'The Savoy Ballroom', from: 'Venue'
    select 'Herbert White', from: 'Social organiser'
    select 'Frankie Manning', from: 'Class organiser'
    select 'dance_club', from: 'Event type'
    uncheck 'Has a taster?'
    check 'Has a class?'
    check 'Has social?'
    fill_in 'Class style', with: 'Savoy Style'
    fill_in 'Course length', with: ''
    select 'Saturday', from: 'Day'
    fill_in 'event_frequency', with: 1
    fill_in 'Dates', with: ''
    fill_in 'Cancelled dates', with: '11/10/1958'
    fill_in 'First date', with: '12/03/1926'
    fill_in 'Next expected', with: ''
    fill_in 'Last date', with: ''
    fill_in 'Url', with: 'https://www.savoyballroom.com/stompin'

    Timecop.freeze('01/01/1937') do
      click_on 'Create'

      click_on 'Swing Out London'
    end

    venue_id = Venue.first.id

    within '#social_dances' do
      within page.all('.date_row')[0] do
        expect(page).to have_content 'Saturday 2nd January'
        expect(page).to have_link 'WC2R', href: "map/socials/1937-01-02?venue_id=#{venue_id}"
        expect(page).to have_link 'Stompin at the Savoy - The Savoy Ballroom in Harlem', href: 'https://www.savoyballroom.com/stompin'
      end

      within page.all('.date_row')[1] do
        expect(page).to have_content 'Saturday 9th January'
        expect(page).to have_link 'WC2R', href: "map/socials/1937-01-09?venue_id=#{venue_id}"
        expect(page).to have_link 'Stompin at the Savoy - The Savoy Ballroom in Harlem', href: 'https://www.savoyballroom.com/stompin'
      end
    end

    within '#classes' do
      within page.all('.day_row')[5] do
        expect(page).to have_content 'Saturday'
        expect(page).to have_link 'WC2R', href: "map/classes/Saturday?venue_id=#{venue_id}"
        expect(page).to have_link 'Harlem (Savoy Style) at Stompin at the Savoy with Frankie', href: 'https://www.savoyballroom.com/stompin'
        expect(page).to have_content 'Cancelled on 11th Oct'
      end
    end

    expect(page).not_to have_content('<')
    expect(page).not_to have_content('>')
    expect(page).not_to have_content('abbr title=')
  end
end
