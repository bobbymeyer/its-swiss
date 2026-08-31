require "test_helper"
require "selenium-webdriver"

# rack_test has no CSS, no box model and no cascade, so it will happily pass a
# page whose layout has collapsed entirely — and this library is CSS. So the
# guards that matter run in a real browser, and skip loudly when there is not
# one rather than quietly pretending to have checked.
#
#   CHROME_BINARY=/path/to/chromium CHROMEDRIVER=/path/to/chromedriver bin/test test/system
#
# Both are found on their own where they are on the path. Selenium Manager
# fetches a driver when neither is, which needs the network — hence the
# fallback rather than a hard failure: a machine with no browser should still
# be able to run the rest of the suite.
class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  SCREEN_SIZE = [ 1400, 1400 ].freeze

  CHROMIUM = %w[ /opt/pw-browsers/chromium chromium chromium-browser google-chrome ].freeze

  def self.find(candidates)
    candidates.find { |path| File.executable?(path) || system("command -v #{path} > /dev/null 2>&1") }
  end

  BROWSER = ENV["CHROME_BINARY"].presence || find(CHROMIUM)
  DRIVER = ENV["CHROMEDRIVER"].presence || find(%w[ chromedriver ])

  driver = nil

  if BROWSER
    begin
      Selenium::WebDriver::Chrome::Service.driver_path = DRIVER if DRIVER

      driven_by :selenium, using: :headless_chrome, screen_size: SCREEN_SIZE do |options|
        options.binary = BROWSER
        options.add_argument("--no-sandbox")
        options.add_argument("--disable-dev-shm-usage")
      end

      driver = :selenium
    rescue StandardError => e
      # Resolving a driver reaches the network when it has not been given one.
      # A machine that cannot is a machine these tests skip on.
      warn "  system tests: no usable browser driver (#{e.class}: #{e.message.lines.first.to_s.strip})"
    end
  end

  driven_by :rack_test unless driver

  def browser? = Capybara.current_driver != :rack_test

  def needs_a_browser
    skip "needs a real browser; set CHROME_BINARY and CHROMEDRIVER" unless browser?
  end

  # What the browser resolved, rather than what the stylesheet says. A rule on
  # the wrong selector reads correctly in the CSS and does nothing on a page,
  # and a custom property that resolves to nothing is invisible in both.
  def computed(selector, property)
    evaluate_script(
      "getComputedStyle(document.querySelector(#{selector.to_json})).getPropertyValue(#{property.to_json}).trim()"
    )
  end

  # A colour as sRGB channels. Chromium keeps a computed colour in the space
  # it was declared in — the value scale is OKLCH, so getComputedStyle hands
  # back "oklch(0.54 0 0)" and any arithmetic on those three numbers as if
  # they were channels is nonsense. So the browser is asked to paint it and
  # the pixel is read back, which is the one answer that cannot be wrong.
  def channels(selector, property)
    evaluate_script(<<~JS)
      (() => {
        const value = getComputedStyle(document.querySelector(#{selector.to_json}))
          .getPropertyValue(#{property.to_json})
        const canvas = document.createElement("canvas")
        canvas.width = canvas.height = 1
        const context = canvas.getContext("2d")
        context.fillStyle = value
        context.fillRect(0, 0, 1, 1)
        return Array.from(context.getImageData(0, 0, 1, 1).data).slice(0, 3)
      })()
    JS
  end

  # WCAG relative luminance, from channels the browser painted.
  def luminance(selector, property)
    linear = channels(selector, property).map do |value|
      channel = value.to_f / 255
      channel <= 0.04045 ? channel / 12.92 : ((channel + 0.055) / 1.055) ** 2.4
    end

    0.2126 * linear[0] + 0.7152 * linear[1] + 0.0722 * linear[2]
  end

  def contrast(one, other)
    a, b = [ luminance(*one), luminance(*other) ].minmax

    ((b + 0.05) / (a + 0.05)).round(2)
  end

  def rect_of(selector)
    evaluate_script(
      "(({top, left, width, height}) => ({top, left, width, height}))" \
      "(document.querySelector(#{selector.to_json}).getBoundingClientRect())"
    )
  end
end
