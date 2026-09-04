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
    baseline = evaluate_script("parseFloat(getComputedStyle(document.documentElement).fontSize) * 1.5")

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
    assert_empty boxes_off_the_grid,
      "a box that is not a whole number of #{baseline}px baselines puts everything below it off the grid"
  end

  # What the grid is actually for. Boxes in step are not a baseline grid: a
  # line's baseline falls wherever the font's ascent and the leading either
  # side of it put it inside the line box, so at 0.2.0 a paragraph's baselines
  # sat a pixel off the grid, a caption's four, and the two were three pixels
  # out of register with each other. 0.5.0 trimmed the boxes to the type,
  # which put the type on the grid in the one browser that trims and left the
  # others to their fonts.
  #
  # Now the face carries the leading as its ascent and no descent, so the
  # baseline is the under edge of the line box in any browser that honours a
  # @font-face descriptor — and the run of text a browser reports is exactly
  # one leading tall with its under edge on the baseline, which is what this
  # reads. Every run of text on the page, not a list of registers: a
  # register missed here is a register nobody measured.
  test "every baseline on the page is on the grid" do
    assert_empty type_off_the_grid,
      "a run of type whose baseline is not on a #{baseline}px line is type in its own rhythm"
  end

  # The masthead in particular, because it is where a page most often puts a
  # block of type beside a flex container, and because for as long as this
  # row aligned on a baseline nothing measured where its two halves actually
  # landed.
  test "the wordmark and the nav end on the same line" do
    unit = baseline
    mark = rect_of(".masthead__mark")
    nav = rect_of(".masthead .nav")

    assert_in_delta mark["top"] + mark["height"], nav["top"] + nav["height"], 0.05,
      "the mark and the nav are on different baselines, which makes the row taller than the lines it is given"
    assert_equal 0, (rect_of(".masthead")["height"] % unit).round(2),
      "the masthead is not a whole number of lines, so everything below it is off the grid"
  end

  # The faces are what put the baseline on the under edge, and a face is a
  # thing a browser can decline: a local() it cannot match, a descriptor it
  # does not know. Both leave the page readable and in step and quietly
  # unregistered — so the type check above would catch it, and this says
  # which of the two it was.
  test "the faces the page is set in loaded" do
    faces = evaluate_script(<<~JS)
      Array.from(document.fonts).filter((face) => face.family.startsWith("its-swiss")).map((face) =>
        [ face.family, face.weight, face.status ])
    JS

    assert_includes faces, [ "its-swiss-150", "400", "loaded" ], "the body's own face did not load: #{faces.inspect}"
    assert_includes faces, [ "its-swiss-200", "400", "loaded" ], "the small register's face did not load: #{faces.inspect}"
    assert_empty faces.select { |_, _, status| status == "error" }, "a face the page asked for failed"
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

  # The case that nearly does not transfer from print. A picture's height is
  # its fluid width over its ratio, which is a fraction that changes as the
  # window does — so without rounding, one picture puts the whole column
  # below it off the grid at every width but a few.
  test "a picture takes a whole number of lines at any width" do
    line = evaluate_script("parseFloat(getComputedStyle(document.documentElement).fontSize) * 1.5")

    [ 1400, 1100, 903, 712 ].each do |width|
      page.driver.browser.manage.window.resize_to(width, 1400)
      height = rect_of("[data-specimen=figure] .figure > svg")["height"]

      assert_equal 0, (height % line).round(2),
        "at #{width}px the picture is #{height}px, which is #{(height / line).round(2)} lines"
    end
  ensure
    page.driver.browser.manage.window.resize_to(*SCREEN_SIZE)
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
