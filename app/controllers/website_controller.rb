class WebsiteController < ApplicationController
  
  require 'rubygems'
  require 'twitter'
  
  before_filter :get_updated_times
  caches_action :index
  
  def index
    @classes = Event.active_classes
    
    if (Date.local_today.midnight)  > Time.local_now.ago(4.hours) # Would be great to just use 4.hours.ago, but timezones would screw it up??
      @today = Date.local_yesterday
    else
      @today = Date.local_today
    end
      
    @socials_dates = Event.socials_dates(@today)  
    
    # The call to the twitter api fails if it can't reach twitter, so we need to handle this
    begin
      @latest_tweet = Twitter.user_timeline("swingoutlondon").first
    rescue Exception => msg
      @latest_tweet = nil
      logger.error "[ERROR]: Failed to get latest tweet with message '#{msg}'"
    end
  end
  
  #TODO: move into a different file?
  def get_updated_times
    @last_updated_time = Event.last_updated_datetime.to_s(:timepart)
    @last_updated_date = Event.last_updated_datetime.to_s(:listing_date)
    @last_updated_datetime = Event.last_updated_datetime
  end
  
end
