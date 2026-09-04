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
