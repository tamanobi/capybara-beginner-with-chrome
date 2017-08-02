#! /usr/bin/ruby
require 'capybara/dsl'
require 'selenium-webdriver'

Capybara.register_driver :selenium do |app|
  Capybara::Selenium::Driver.new(app,
    :browser => :chrome,
    :desired_capabilities => Selenium::WebDriver::Remote::Capabilities.chrome(
      'chromeOptions' => {
        'args' => [
          "--window-size=1280,720",
          "--user-agent='Mozilla/5.0"
        ]
      }
    )
  )
end

Capybara.default_driver = :selenium
Capybara.save_path = ''

module MyModule
  include Capybara::DSL
  @@num = 0
  @@max_num = 40
  @@tweets = []
  @@name = 'tamanobi'

  def url
      "https://twitter.com/#{@@name}/media"
  end

  def ensure_browser_size(width = 1280, height = 720)
    Capybara.current_session.driver.browser.manage.window.resize_to(width, height)
  end

  def scroll
    Capybara.page.execute_script "window.scrollBy(0,10000)"
    Capybara.page.find '.timeline-end'
    @@num = Capybara.page.evaluate_script "document.querySelectorAll('.stream-item[data-item-type=\"tweet\"]').length"
    sleep 3
  end

  def getTweetIds
    a = Capybara.page.evaluate_script "Array.from(document.querySelectorAll('.stream-item[data-item-type=\"tweet\"]'),  e => e.dataset.itemId);"
    a.to_a
  end

  def getStatusUrls(name, tweet_ids)
    tweet_ids.map {|x|
        "https://twitter.com/#{name}/status/#{x}"
    }
  end

  def getImageUrls(urls)
    urls.map {|url|
      visit url
      #Capybara.page.first('.Tombstone-action').click
      a = Capybara.page.evaluate_script "Array.from(document.querySelectorAll('[data-image-url]'), e => e.dataset.imageUrl);"
      puts a
      a.to_a
    }
  end

  def zuttoScroll
    urls = []
    while(scroll())
      puts "# #{@@num}"
      tw = getTweetIds
      @@tweets = @@tweets.concat tw
      @@tweets.uniq!
      if @@num > @@max_num
        urls = getStatusUrls @@name, @@tweets
        break
      end
    end
    urls
  end
end

class MyTest
  include MyModule

  def test
    visit url
    ensure_browser_size
    #scroll
    a = zuttoScroll
    puts getImageUrls a
    save_screenshot 'screenshot.png'
  end
end

MyTest.new.test
