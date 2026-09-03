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

  test "and without trimming too" do
    unit = baseline

    without_trimmed_text_boxes do
      assert_empty boxes_off_the_grid(unit),
        "a reader whose browser does not trim gets a different page"
    end
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
