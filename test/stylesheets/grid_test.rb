require "test_helper"

# The gem ships the machinery for a grid and never a grid. An application
# declares how many fields its problem has; the library only knows how to
# divide a page into them and how wide one of them is.
class GridTest < ActiveSupport::TestCase
  test "the field count is a slot the application fills" do
    grid = rules_in("grid")

    assert_match(/repeat\(var\(--columns[,)]/, grid)
    assert_no_match(/repeat\(\s*\d+\s*,/, grid, "a number of columns in the gem is a fixed grid")
  end

  test "nothing sizes a track from the space available" do
    offenders = every_stylesheet.select { |_, css| css.match?(/repeat\(\s*auto-(?:fill|fit)/) }

    assert_empty offenders.keys,
      "auto-fill sizes tracks from available width, which cannot line up with a field"
  end

  test "the measure is derived from the field rather than chosen" do
    tokens = rules_in("tokens")

    assert_match(/--field: calc\(/, tokens, "one field's width is the unit the helpers are built from")
    assert_match(/--measure: calc\(var\(--field\)/, tokens)
    assert_match(/var\(--page-inset\) \* 2/, tokens,
      "the page's own margin comes out before the fields are divided, or every helper is a gutter too wide")
    assert_no_match(/--measure: [\d.]+rem/, tokens, "a hand-picked measure lands between field lines")
  end

  # Spanning is what an application does with the grid, so it is a slot too:
  # one class reading one property, rather than a set of .span-1 .. .span-12
  # the library would have to guess the length of.
  test "spanning a run of fields is a property, not a class per width" do
    grid = rules_in("grid")

    assert_match(/grid-column: span var\(--span[,)]/, grid)
    assert_no_match(/\.span-\d/, grid)
  end
end
