require "test_helper"
require_relative "../../script/specimen"

# The published specimen has to be the library, not a likeness of it. Two
# hand-written copies drifted before this existed — one declared a --baseline
# the library had renamed and a --measure it never had — so what is asserted
# here is that the page is generated from the real stylesheets and the real
# markup, and that nothing is missing from it.
class StaticSpecimenTest < ActiveSupport::TestCase
  setup { @page = ItsSwiss::StaticSpecimen.call }

  test "carries the version it was built from, where a reader and a script can see it" do
    assert_includes @page, %(data-version="#{ItsSwiss::VERSION}")
    assert_includes @page, "its-swiss #{ItsSwiss::VERSION} — specimen"
  end

  test "inlines every core stylesheet, so the page needs nothing to render" do
    ItsSwiss::STYLESHEETS.each do |name|
      assert_includes @page, "@layer #{ItsSwiss::LAYER}.#{name} {", "#{name}.css was not inlined"
    end

    assert_no_match(/<link[^>]+stylesheet/, @page, "a published specimen that fetches is one that can fail to")
  end

  test "shows every section the engine's specimen shows" do
    sections = Nokogiri::HTML5(@page).css("[data-specimen]").map { |s| s["data-specimen"] }

    assert_equal %w[ values type grid masthead buttons form figure table pairs pagination messages footer ],
      sections
  end

  # The same guard the engine's own specimen carries. A generated page is a
  # new way for a template to print its own source.
  test "emits no template delimiters" do
    %w[ <%# <%= %> ].each do |delimiter|
      assert_not_includes @page, delimiter, "#{delimiter} reached the published page"
    end
  end

  # The page is rendered once and then read by anything; a second take would
  # be a second copy of every component with no way to tell them apart.
  test "renders one take, with the accent a button rather than a second page" do
    assert_equal 1, Nokogiri::HTML5(@page).css("[data-specimen=values]").size
    assert_includes @page, %(id="accent-toggle")
    assert_includes @page, %(id="baseline-toggle")
  end

  # Cross-origin, a parent cannot measure the frame, and a height guessed at
  # one width is wrong at every other.
  test "tells whatever embeds it how tall it is" do
    assert_includes @page, "parent.postMessage"
    assert_includes @page, "ResizeObserver"
  end
end
