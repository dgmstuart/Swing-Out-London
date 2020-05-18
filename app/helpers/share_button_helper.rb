# frozen_string_literal: true

module ShareButtonHelper
  SHARE_LINK = 'https://swingoutlondon.co.uk'

  def twitter_button
    twitter_url = 'https://twitter.com/intent/tweet'

    tweet_text = 'If you want to learn to swing dance, Swing Out London lists all the classes in London:'
    via = 'swingoutlondon'

    query_parameters = [
      "url=#{SHARE_LINK}",
      "text=#{tweet_text}",
      "via=#{via}"
    ].join('&')

    alt_text = 'Share Swing Out London on Twitter'

    link_to 'Tweet',
            "#{twitter_url}?#{query_parameters}",
            title: alt_text,
            alt: alt_text,
            target: '_blank',
            class: 'share_button twitter', rel: 'noopener'
  end

  def facebook_button
    facebook_url = 'https://www.facebook.com/sharer/sharer.php'

    share_title = 'Swing Out London - Lindy Hop Listings'
    share_summary = 'Swing Out London is a listing of all the swing dance classes in London, and all the places you can go to dance.'

    query_parameters = [
      's=100',
      "p[url]=#{SHARE_LINK}",
      # p[images][0] = SOME IMAGE,
      "p[title]='#{share_title}'",
      "p[summary]='#{share_summary}'"
    ].join('&')

    alt_text = 'Share Swing Out London on Facebook'

    link_to 'Share',
            "#{facebook_url}?#{query_parameters}",
            title: alt_text,
            alt: alt_text,
            target: '_blank',
            class: 'share_button facebook', rel: 'noopener'
  end

  def donate_button
    link_to 'Donate', ENV['DONATE_LINK']
  end
end
