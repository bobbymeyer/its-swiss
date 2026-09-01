require "application_system_test_case"

# The specimen rendered by a browser that actually resolves the cascade. Every
# assertion here is one the file-reading tests cannot make: a cascade layer
# only means something once something else is competing with it, and an OKLCH
# lightness step is only a value once a browser has converted it.
class SpecimenSystemTest < ApplicationSystemTestCase
  setup do
    needs_a_browser
    visit "/its-swiss/specimen"
  end

  test "renders" do
    assert_selector "h1.page-title", text: "its-swiss"
  end

  # The whole argument in one assertion. Both takes are the same markup and
  # the same stylesheets; the only difference between them is one custom
  # property.
  test "the accent is one property, and unset it is ink" do
    monochrome = channels("[data-specimen-take=monochrome] .nav [aria-current=page]", "color")
    accented = channels("[data-specimen-take=accent] .nav [aria-current=page]", "color")

    assert_equal channels("body", "color"), monochrome,
      "with no accent the current destination is ink, and the weight is carrying it"
    assert_not_equal monochrome, accented
  end

  # The boundary, made mechanical. An application's own stylesheet is
  # unlayered and the library is not, so the application wins without having
  # to out-specify anything or reach for !important.
  test "an application's own stylesheet outranks the library's" do
    assert_equal "6", computed(":root", "--columns")

    execute_script(<<~JS)
      const sheet = new CSSStyleSheet()
      sheet.replaceSync(":root { --columns: 12 }")
      document.adoptedStyleSheets = [ ...document.adoptedStyleSheets, sheet ]
    JS

    assert_equal "12", computed(":root", "--columns"),
      "a single unlayered declaration should beat the library's layered one"
  end

  # The steps have to be perceptually even to read as a scale, which is the
  # reason for OKLCH, and they have to actually resolve, which is the reason
  # for asking a browser.
  test "the value scale resolves to six descending steps" do
    lightnesses = (0..5).map do |step|
      luminance("[data-specimen-take=monochrome] [data-value='#{step}'] + dd .specimen__value", "background-color")
    end

    assert_equal lightnesses, lightnesses.sort.reverse, "the ladder doubles back"
    assert_operator lightnesses.first, :>, 0.9, "paper is not paper"
    assert_operator lightnesses.last, :<, 0.05, "ink is not ink"
  end

  # The slot a consumer warms the scale with. It has to turn the whole ladder,
  # not part of it: a scale where four steps are warm and two are neutral is
  # not a scale, and the way to get one is to write an oklch() somewhere that
  # does not read both properties.
  test "warming the scale turns every step of it" do
    before = (0..5).map { |step| channels("[data-value='#{step}'] + dd .specimen__value", "background-color") }

    execute_script(<<~JS)
      const sheet = new CSSStyleSheet()
      sheet.replaceSync(":root { --value-chroma: 0.02; --value-hue: 95 }")
      document.adoptedStyleSheets = [ ...document.adoptedStyleSheets, sheet ]
    JS

    after = (0..5).map { |step| channels("[data-value='#{step}'] + dd .specimen__value", "background-color") }

    before.zip(after).each_with_index do |(was, now), step|
      assert_not_equal was, now, "--value-#{step} did not warm with the rest of the ladder"
    end
  end

  # Secondary text is the step most likely to be picked for its look and then
  # be unreadable. 4.5:1 is the requirement, and this is the one value on the
  # ladder that sits near it.
  test "quiet ink clears the contrast requirement against paper" do
    assert_operator contrast([ ".hint", "color" ], [ "body", "background-color" ]), :>=, 4.5
  end

  # Every line box is a whole number of baselines, or the vertical rhythm is
  # decorative rather than real.
  test "every line box is a whole number of baselines" do
    baseline = evaluate_script("parseFloat(getComputedStyle(document.documentElement).fontSize) * 0.5")

    [ "body", "h1.page-title", "[data-specimen-take=monochrome] h2", ".hint", ".micro", ".nav a", ".button" ].each do |selector|
      leading = computed(selector, "line-height").to_f

      assert_equal 0, (leading % baseline).round(2),
        "#{selector} has a #{leading}px line box, which is #{(leading / baseline).round(2)} baselines"
    end
  end

  # A line box is not a box. Every line box here is a whole number of
  # baselines and the page was still off the grid, because the rhythm is
  # broken by what is drawn around the type: a hairline added to a padded edge
  # makes the box a pixel taller than the ladder says, and every ruled
  # component in the library did it — so the error accumulated down the column
  # instead of showing up once, and by the footer the page was seven pixels
  # out. This measures what the browser actually laid out, on a page that
  # holds one of everything.
  test "every box on the page is a whole number of baselines" do
    baseline = evaluate_script("parseFloat(getComputedStyle(document.documentElement).fontSize) * 0.5")

    offenders = evaluate_script(<<~JS)
      (() => {
        const baseline = #{baseline}
        // A browser lays out in 64ths of a pixel, and a cap height rounded up
        // to the ladder can land a 64th short of it depending on the font's
        // metrics. The tolerance is a layout unit or two, not a fudge: a real
        // error here is a whole pixel, because that is the smallest thing a
        // rule or a border can be.
        const off = (value) => {
          const over = ((value % baseline) + baseline) % baseline
          return Math.min(over, baseline - over) > 0.05
        }
        return Array.from(document.querySelectorAll("body *")).filter((el) => {
          const style = getComputedStyle(el)
          // A line box is the other assertion's business, an out-of-flow box
          // sits on no column at all, and a checkbox is drawn by the browser
          // at a size of its own on a row that is measured here regardless.
          if (style.display.startsWith("inline") && style.display !== "inline-block") return false
          if (style.position === "absolute" || style.position === "fixed") return false
          if (el.matches("input[type=checkbox], input[type=radio]")) return false

          const box = el.getBoundingClientRect()
          if (box.height === 0) return false
          // An inline-block sits on its line rather than on the column, so
          // only its height is the ladder's business.
          const inline = style.display === "inline-block"
          return (!inline && off(box.top + window.scrollY)) || off(box.height)
        }).map((el) => {
          const box = el.getBoundingClientRect()
          return el.tagName.toLowerCase() + (el.className ? "." + String(el.className).trim().split(/\\s+/).join(".") : "") +
            " starts at " + (box.top + window.scrollY) + " and is " + box.height + " tall"
        }).slice(0, 10)
      })()
    JS

    assert_empty offenders,
      "a box that is not a whole number of #{baseline}px baselines puts everything below it off the grid"
  end

  # What the grid is actually for. Boxes in step are not a baseline grid: a
  # line's baseline falls wherever the font's ascent and the leading either
  # side of it put it inside the line box, so at 0.2.0 a paragraph's baselines
  # sat a pixel off the grid, a caption's four, and the two were three pixels
  # out of register with each other.
  #
  # Trimming makes the block's under edge the baseline of its last line — that
  # is what `alphabetic` means — so measuring the box measures the baseline,
  # and every earlier line is a whole number of baselines above it because the
  # leading is. Measured rather than probed on purpose: inserting a span to
  # read a baseline directly re-lays out a trimmed page and moves the thing it
  # was measuring.
  test "the type sits on the baseline, not merely in step with it" do
    skip "this browser does not trim text boxes" unless evaluate_script(
      %(CSS.supports("text-box", "trim-both cap alphabetic"))
    )

    baseline = evaluate_script("parseFloat(getComputedStyle(document.documentElement).fontSize) * 0.5")

    offenders = evaluate_script(<<~JS)
      (() => {
        const baseline = #{baseline}
        const registers = ".page-title, h1, h2, h3, h4, p, li, dt, dd, .micro, .hint, .lede"
        return Array.from(document.querySelectorAll(registers)).filter((el) => {
          if (!el.textContent.trim()) return false
          const style = getComputedStyle(el)
          if (style.textBoxTrim !== "trim-both") return true
          const bottom = el.getBoundingClientRect().bottom + window.scrollY
          const over = ((bottom % baseline) + baseline) % baseline
          return Math.min(over, baseline - over) > 0.05
        }).map((el) => {
          const style = getComputedStyle(el)
          const bottom = el.getBoundingClientRect().bottom + window.scrollY
          return el.tagName.toLowerCase() + (el.className ? "." + String(el.className).trim().split(/\\s+/).join(".") : "") +
            " at " + el.style.fontSize + " trim=" + style.textBoxTrim + " baseline at " + bottom
        }).slice(0, 10)
      })()
    JS

    assert_empty offenders,
      "a register whose last baseline is not on a #{baseline}px line is a register in its own rhythm"
  end

  # A figure is read right-aligned against its own heading, which is what
  # .numeric is for. Setting it with the padding-inline shorthand also zeroed
  # the end padding of every numeric cell — right for one in the final column,
  # which the :last-child rule already covered, and wrong anywhere else,
  # because the next column's text then begins exactly where the number ends.
  # The specimen's table now has a numeric column that is not last, which is
  # the case that broke.
  test "a numeric column that is not last keeps the space after it" do
    numeric = "[data-specimen-take=monochrome] .table tbody td.numeric"

    assert_operator computed(numeric, "padding-inline-end").to_f, :>, 0,
      "a number runs straight into the next column"
    assert_equal computed(".table tbody td:last-child", "padding-inline-end"), "0px",
      "the last column still stops at the page"
  end

  # A page that scrolls sideways at a phone's width is a page whose grid has
  # escaped its own container, and the specimen holds every component the
  # library has.
  test "nothing escapes the page at a phone's width" do
    page.driver.browser.manage.window.resize_to(390, 844)

    assert_equal 0, evaluate_script("document.documentElement.scrollWidth - document.documentElement.clientWidth"),
      "something on the page is wider than the viewport"
  ensure
    page.driver.browser.manage.window.resize_to(*SCREEN_SIZE)
  end

  # Prose stops on a field line rather than three pixels short of one, because
  # the measure is derived from the page rather than chosen. Measured against
  # the fields the browser actually laid out, not against the same arithmetic
  # the stylesheet did — the two agreeing is the whole assertion.
  test "the measure stops on a field line" do
    fields = "[data-specimen-take=monochrome] .specimen__grid > *"
    first = rect_of("#{fields}:first-child")
    third = rect_of("#{fields}:nth-child(3)")

    assert_in_delta third["left"] + third["width"] - first["left"], computed(".hint", "max-width").to_f, 1.0
  end
end
