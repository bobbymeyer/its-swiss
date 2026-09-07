require "test_helper"

# The helpers are the library's markup contracts. Each one exists because the
# markup it writes has a detail that is easy to leave out by hand and silent
# when it is missing.
class ApplicationHelperTest < ActionView::TestCase
  include ItsSwiss::ApplicationHelper

  # --- Stylesheets ---------------------------------------------------------

  test "writes a link tag per stylesheet, in the library's layer order" do
    hrefs = Nokogiri::HTML5.fragment(its_swiss_stylesheet_tags).css("link").map { |link| link["href"] }

    assert_equal ItsSwiss::STYLESHEETS, hrefs.map { |href| File.basename(href, ".css").sub(/-[0-9a-f]{8,}\z/, "") }
  end

  # Six link tags rather than the one file that imports the six: an @import
  # is a request the browser cannot start until it has read the file that
  # asks for it, so the single file is a waterfall six deep. It is still
  # shipped, for anything that is not Rails.
  test "tracks the stylesheets for Turbo, so a deploy that changes them reloads" do
    assert_equal ItsSwiss::STYLESHEETS.size,
      Nokogiri::HTML5.fragment(its_swiss_stylesheet_tags).css("link[data-turbo-track='reload']").size
  end

  # The faces rely on a @font-face's metric descriptors, and one browser
  # ignores them. One line of script, ahead of the stylesheets, marks the
  # document where they are not honoured so that the trim that does the same
  # job the long way can step in — inline and first, because a class added
  # after the first layout is a page that moves.
  test "writes the metric-override mark ahead of the stylesheets" do
    fragment = Nokogiri::HTML5.fragment(its_swiss_stylesheet_tags)

    assert_equal "script", fragment.children.reject { |node| node.text? && node.text.blank? }.first.name
    assert_includes fragment.at("script").text, "no-metric-overrides"
    assert_includes fragment.at("script").text, "ascentOverride"
  end

  # --- The page head -------------------------------------------------------

  test "a page head is the title, the lede and the actions, in that order" do
    html = Nokogiri::HTML5.fragment(page_head("Palettes", lede: "Every one.") { tag.a("New", href: "#", class: "button") })

    assert_equal "Palettes", html.at("header.page-head .page-head__title h1.page-title").text
    assert_equal "Every one.", html.at(".page-head__title p.lede").text
    assert_equal "New", html.at(".page-head__actions.run a.button").text
  end

  test "a page head with nothing to do has no actions and no lede" do
    html = Nokogiri::HTML5.fragment(page_head("Palettes"))

    assert_nil html.at(".page-head__actions")
    assert_nil html.at(".lede")
  end

  # The document is titled from the page unless the view has said otherwise:
  # a page that names itself twice is a page that will one day name itself
  # two different things.
  test "a page head titles the document unless the view already has" do
    page_head("Palettes")
    assert_equal "Palettes", content_for(:title)
  end

  test "a page head leaves a title the view set" do
    content_for(:title, "Palettes — Pandatone")
    page_head("Palettes")
    assert_equal "Palettes — Pandatone", content_for(:title)
  end

  # --- Filters -------------------------------------------------------------

  test "a filter register is a label and the choices, the one in force marked" do
    html = Nokogiri::HTML5.fragment(filter_register("Tagged",
      [ [ "All", "/colors", false ], [ "print", "/colors?tag=print", true ] ], name: "tag"))

    assert_equal "tag", html.at(".filter")["data-filter"]
    assert_equal "Tagged", html.at(".filter__label").text
    assert_equal %w[ All print ], html.css(".filter__choices > a").map(&:text)
    assert_equal [ "print" ], html.css(".filter__choices a[aria-current]").map(&:text),
      "the choice in force carries aria-current, which the CSS colours and weights"
  end

  test "a search form is a GET into a frame, live, with its button there for a browser without script" do
    html = Nokogiri::HTML5.fragment(search_form("/colors", frame: "colors", value: "red", keep: { tag: "print", sort: nil }))
    form = html.at("form.form.form--inline")

    assert_equal "get", form["method"]
    assert_equal "/colors", form["action"]
    assert_equal "its-swiss-live-search", form["data-controller"]
    assert_equal "colors", form["data-turbo-frame"]
    assert_equal "input->its-swiss-live-search#search", form["data-action"]

    assert_equal "red", form.at(".field.field--inline input[type=search][name=q]")["value"]
    assert_equal "q", form.at("label")["for"]
    assert_equal "print", form.at("input[type=hidden][name=tag]")["value"]
    assert_nil form.at("input[type=hidden][name=sort]"), "a choice not in force is not carried"
    assert_equal "submit", form.at("input[type=submit]")["data-its-swiss-live-search-target"]
  end

  # --- The typeface --------------------------------------------------------

  # The faces are what put every baseline on the under edge of its line, and
  # an application with a typeface of its own has to declare it the same way
  # under the same names, or its type is back in the font's hands. This
  # writes those declarations so nothing has to be worked out by hand.
  test "declares the application's typeface under the library's face names, with the library's ascents" do
    css = Nokogiri::HTML5.fragment(its_swiss_typeface(regular: "inter-regular.woff2", bold: "inter-bold.woff2")).at("style").text
    faces = css.scan(/@font-face \{([^}]*)\}/m).flatten.map { |body| body.scan(/([a-z-]+): ([^;]+);/).to_h }

    assert_equal ItsSwiss::FACES.keys.flat_map { |family| [ family ] * 2 }, faces.map { |face| face["font-family"].delete('"') }
    assert_equal %w[ 400 700 ] * 3, faces.map { |face| face["font-weight"] }
    faces.each do |face|
      ratio = ItsSwiss::FACES.fetch(face["font-family"].delete('"'))
      assert_equal "#{(ratio * 100).round}%", face["ascent-override"]
      assert_equal "0%", face["descent-override"]
      assert_equal "0%", face["line-gap-override"]
      assert_match(%r{\Aurl\("/[^"]*inter-(regular|bold)[^"]*\.woff2"\) format\("woff2"\)\z}, face["src"])
    end
  end

  test "declares a variable font once per face, across the weights" do
    css = Nokogiri::HTML5.fragment(its_swiss_typeface(variable: "inter.woff2", mono: "mono.ttf")).at("style").text
    faces = css.scan(/@font-face \{([^}]*)\}/m).flatten.map { |body| body.scan(/([a-z-]+): ([^;]+);/).to_h }

    assert_equal ItsSwiss::FACES.keys + ItsSwiss::MONO_FACE.keys, faces.map { |face| face["font-family"].delete('"') }
    assert_equal [ "100 900" ] * 3 + [ nil ], faces.map { |face| face["font-weight"] }
    assert_equal "166.6667%", faces.last["ascent-override"], "a pre is set at nine tenths of the body on the body's line"
    assert_match(/format\("truetype"\)/, faces.last["src"])
  end

  # A control's text is set in --font-family rather than on a face, so the
  # typeface has to exist under its own name too, or a field is set in the
  # machine's grotesque while the page around it is set in the application's.
  test "declares the typeface under its own name as well, when asked" do
    css = Nokogiri::HTML5.fragment(its_swiss_typeface(variable: "inter.woff2", family: "Inter")).at("style").text
    faces = css.scan(/@font-face \{([^}]*)\}/m).flatten.map { |body| body.scan(/([a-z-]+): ([^;]+);/).to_h }

    assert_equal ItsSwiss::FACES.keys + [ "Inter" ], faces.map { |face| face["font-family"].delete('"') }
    plain = faces.last
    assert_equal "100 900", plain["font-weight"]
    assert_nil plain["ascent-override"], "under its own name the font keeps its own metrics"
    assert_match(/inter\.woff2/, plain["src"])
  end

  test "refuses a typeface it cannot declare" do
    assert_raises(ArgumentError) { its_swiss_typeface }
    assert_raises(ArgumentError) { its_swiss_typeface(variable: "inter.woff2", bold: "inter-bold.woff2") }
  end

  # --- Navigation ----------------------------------------------------------

  test "marks the current destination for a screen reader as well as an eye" do
    link = Nokogiri::HTML5.fragment(nav_link_to("Page", "/page", current: true)).at("a")

    assert_equal "page", link["aria-current"]
  end

  test "leaves aria-current off everything that is not current" do
    link = Nokogiri::HTML5.fragment(nav_link_to("Other", "/other", current: false)).at("a")

    assert_nil link["aria-current"]
  end

  # --- Copy ----------------------------------------------------------------

  test "a copied value stays visible text inside the button" do
    button = Nokogiri::HTML5.fragment(copy_button("#E30613")).at("button")

    assert_equal "#E30613", button.text
    assert_equal "button", button["type"], "a button in a form that does not submit it has to say so"
    assert_equal %w[ copy ], button["class"].split, "the affordance is named for what it does"
  end

  test "a copy button names what it copies for anyone not looking at it" do
    button = Nokogiri::HTML5.fragment(copy_button("#E30613")).at("button")

    assert_equal "Copy #E30613", button["aria-label"]
    assert_equal "its-swiss-clipboard", button["data-controller"]
    assert_equal "#E30613", button["data-its-swiss-clipboard-text-value"]
  end
end
