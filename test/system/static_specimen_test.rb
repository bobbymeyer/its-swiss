require "application_system_test_case"
require "tmpdir"
require_relative "../../script/specimen"

# The published specimen, in a browser. Everything else asked of the generated
# page reads it as text — the sections are there, the stylesheets are inlined,
# no delimiter escaped — and text is exactly the wrong way to ask whether a
# page is on the grid. The engine's specimen was browser-tested and the file
# that gets published was not, so the one artefact anybody actually looks at
# was the one nothing measured.
#
# It is loaded from disk over file://, which is what the page has to survive:
# no server, no assets to fetch, nothing but the markup and the styles it
# carries.
class StaticSpecimenSystemTest < ApplicationSystemTestCase
  setup do
    needs_a_browser

    @dir = Dir.mktmpdir("its-swiss-specimen")
    path = File.join(@dir, "index.html")
    File.write(path, ItsSwiss::StaticSpecimen.call)
    visit "file://#{path}"
  end

  teardown { FileUtils.remove_entry(@dir) if @dir }

  test "renders from the file alone" do
    assert_selector "h1.page-title", text: "its-swiss"
    assert_selector "[data-specimen=footer]"
  end

  test "every box on the published page is a whole number of baselines" do
    unit = baseline

    assert_empty boxes_off_the_grid(unit),
      "the page that gets published is off the grid, whatever the engine's copy of it does"
  end

  test "every baseline on the published page is on the grid" do
    assert_empty type_off_the_grid,
      "the page that gets published has type off the grid, whatever the engine's copy of it does"
  end

  test "and without the faces too" do
    without_metric_overrides do
      assert_empty boxes_off_the_grid, "a reader whose browser ignores the faces gets a different page"
      assert_empty type_off_the_grid
    end
  end

  # The mark the trim steps in on has to be there before the first layout or
  # the page moves under the reader, and a static file has nowhere to get it
  # from but itself. Chromium honours the faces, so on this page the script
  # has run and left no mark.
  test "carries the script that tells the trim when to step in" do
    assert_includes page.html, "no-metric-overrides", "the published page does not carry the script"
    assert_not evaluate_script(%(document.documentElement.classList.contains("no-metric-overrides"))),
      "a browser that honours the faces was marked as one that does not"
  end

  # The overlay is the only reason to trust the page by eye, so it has to be
  # registered to the same origin the boxes are. It is drawn on main's padding
  # box; a padding or a border on main would move the lines and leave the type
  # where it was, and the drawing would then be of a grid the page is not on.
  test "the drawn baseline is the grid the boxes are on" do
    offset = evaluate_script(<<~JS)
      (() => {
        const main = document.querySelector("main")
        const style = getComputedStyle(main)
        return parseFloat(style.borderTopWidth) + parseFloat(style.paddingTop)
      })()
    JS

    assert_equal 0, (offset % baseline).round(2),
      "the overlay starts #{offset}px into main, so it draws a grid the column is not registered to"
  end
end
