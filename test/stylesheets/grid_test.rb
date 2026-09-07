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

  # The field is the page's actual width divided, measured from the .page
  # container the fields are laid out in, so a field on a phone is a phone's
  # field; the measure is a count of characters taken up to whole fields.
  test "the field is the page's, and the measure is characters stopped on a field line" do
    tokens = rules_in("tokens")

    assert_match(/--field: calc\(\(100cqw - var\(--gutter\)/, tokens, "a field is the container's width less the gutters, divided")
    assert_match(/container-type: inline-size/, declarations_for_page, "the page is the container the field is measured in")
    assert_match(/--measure-characters: \d+;/, tokens, "the measure is a count of characters")
    assert_match(/--measure: min\(100%, calc\(round\(up, calc\(var\(--measure-characters\) \* 1ch\), calc\(var\(--field\) \+ var\(--gutter\)\)\)/, tokens,
      "the count is taken up to whole fields and never past the page")
    assert_no_match(/--measure: [\d.]+rem/, tokens, "a hand-picked measure lands between field lines")
  end

  # A custom property inherits, and a grid inside a spanned item would start
  # every child of its own at the parent's span.
  test "the span does not inherit" do
    grid = stylesheet("grid")

    assert_match(/@property --span \{[^}]*inherits: false;/m, grid)
    assert_no_match(/@property --span \{[^}]*initial-value/m, grid, "an initial value would stop a child that says nothing from running the whole field")
  end

  test "the module is a count of lines, and a block of modules is measured in it" do
    assert_match(/--module: \d+;/, rules_in("tokens"))
    assert_match(/\.modules \{ block-size: calc\(var\(--line\) \* var\(--module\)/, rules_in("grid"))
    assert_match(/\.figure--modular[^{]*\{[^}]*calc\(var\(--line\) \* var\(--module\)\)/m, rules_in("components"))
  end

  def declarations_for_page
    rules_in("grid")[/\.page \{([^}]*)\}/m, 1].to_s
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
