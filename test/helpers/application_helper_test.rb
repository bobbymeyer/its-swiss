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
