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

  # Where a candidate actually is. Selenium wants a file rather than a name —
  # given "chromedriver" it raises "not a file" — and a name is exactly what
  # the PATH lookup used to return, so a runner that had installed a driver
  # skipped every browser test as though it had none.
  def self.find(candidates)
    candidates.filter_map { |candidate| File.absolute_path?(candidate) ? executable(candidate) : on_path(candidate) }.first
  end

  def self.executable(path)
    path if File.executable?(path) && !File.directory?(path)
  end

  def self.on_path(name)
    ENV.fetch("PATH", "").split(File::PATH_SEPARATOR).filter_map { |dir| executable(File.join(dir, name)) }.first
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

  # A skipped browser test is invisible in a passing job, which is the one way
  # this suite can lie: the assertions that need a browser are the ones about
  # what the cascade and the box model actually did. So a machine without one
  # skips, and a run that was supposed to have one fails instead — CI sets
  # REQUIRE_BROWSER, and read the flag rather than guessing at CI's own.
  def needs_a_browser
    return if browser?

    message = "needs a real browser; set CHROME_BINARY and CHROMEDRIVER"

    ENV["REQUIRE_BROWSER"].present? ? flunk("#{message} — and REQUIRE_BROWSER says this run has one") : skip(message)
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

  # The interval everything vertical registers to, as the browser resolved it
  # rather than as the stylesheet spells it.
  def baseline
    evaluate_script("parseFloat(getComputedStyle(document.documentElement).fontSize) * 1.5")
  end

  # The one question asked of every page: where is it off the grid? Kept in
  # a file so the cross-engine job in CI asks a browser that is not Chromium
  # exactly the same thing.
  ON_THE_GRID = ROOT.join("test/support/on_the_grid.js").read.freeze

  def off_the_grid(unit = baseline)
    evaluate_script("(#{ON_THE_GRID})(#{unit})")
  end

  # Every block box the page laid out whose over or under edge is not on a
  # line. The column is a stack of these, and one a pixel too tall puts
  # everything below it off the grid.
  def boxes_off_the_grid(unit = baseline) = off_the_grid(unit).fetch("boxes")

  # Every run of text whose baseline is not on a line.
  def type_off_the_grid(unit = baseline) = off_the_grid(unit).fetch("type")

  # The page as a browser that ignores what a face says about its metrics
  # lays it out — Safari, which loads the face and keeps the font's own
  # ascent and descent, and which the script ahead of the stylesheets marks.
  # The faces are named through tokens, so pointing the tokens at the font
  # underneath is the same page with the font's metrics, and marking the
  # document is the trim doing the whole job. Unlayered, which is how an
  # application's own CSS wins over the library's.
  def without_metric_overrides
    execute_script(%(document.documentElement.classList.add("no-metric-overrides")))
    adopt ":root { --face-150: \"Liberation Sans\"; --face-200: \"Liberation Sans\"; " \
      "--face-100: \"Liberation Sans\"; --face-mono: \"Liberation Mono\" }"

    yield
  end

  def adopt(css)
    execute_script(<<~JS)
      const sheet = new CSSStyleSheet()
      sheet.replaceSync(#{css.to_json})
      document.adoptedStyleSheets = [ ...document.adoptedStyleSheets, sheet ]
    JS
  end
end
