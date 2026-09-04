require "test_helper"

# Everything vertical is a whole number of baselines, including the line
# boxes. Two ladders — one for leading, one for space — agree at a few values
# and diverge everywhere else, which is how a heading ends up impossible to
# separate from the block beneath it by the height of its own line.
class TypeTest < ActiveSupport::TestCase
  # The whole grid in one assertion. A leading that is not a whole number of
  # lines puts every line of type after it somewhere new — which is what a
  # label on sixteen and a section head on thirty-two did, all the way down a
  # column, for as long as eight pixels was called the baseline.
  #
  # Asked of type.css alone this passed while two registers in components.css
  # were leaded off the ladder — a footer on twenty-four by way of the space
  # step, and a field error on sixteen. Trimming hid both, because a trimmed
  # box is its cap rounded up to a line whatever the leading under it says,
  # so the page only came apart in a browser without it. A register can be
  # declared in any file, so the question has to be asked of all of them.
  test "every leading is a whole number of lines" do
    every_stylesheet.each do |name, css|
      leadings = css.scan(/line-height: ([^;]+);/).flatten - [ "0" ]

      assert_empty leadings.reject { |value| value.match?(/\Avar\(--line(-\d+)?\)\z/) },
        "#{name}.css measures a line box in something other than whole lines"
      assert_no_match(/line-height: var\(--space-/, css,
        "#{name}.css leads type off the space ladder, which is the horizontal step")
    end

    assert_not_empty rules_in("type").scan(/line-height: ([^;]+);/).flatten
  end

  # A second font on a line brings its own ascent, and the line grows to hold
  # it — by a pixel at body size, by four under the page title, and only on
  # the lines that happen to mention a token. Zero leading takes the inline
  # box out of that calculation; the glyphs still sit on the strut's
  # baseline, which is the grid's.
  test "anything that changes size inside a line gives the line back to the strut" do
    assert_match(/code, kbd, samp, small, sup, sub \{ line-height: 0; \}/, rules_in("type"))
    assert_match(/pre \{ line-height: var\(--line\); \}/, rules_in("type"), "a pre is a block, and a block with no leading has no lines")
  end

  # The faces put the baseline on the under edge in a browser that honours a
  # @font-face's metrics, and Safari does not. There every text block is
  # trimmed to its cap and its baseline and padded back up to its own
  # leading — its own, or a subhead set on two lines is trimmed to one —
  # and only there, and only when the document says so: a trimmed box is a
  # 64th short as often as not on the engine the correction is written for
  # and half a pixel out on the one it is not, and a browser on the faces
  # must never be asked to trim what it already has exact.
  test "text is trimmed to its type where the faces are not honoured, and only there" do
    type = rules_in("type")

    assert_match(/html\.no-metric-overrides \{ --cap-correction: calc\(round\(up, 1cap, 1lh\) - round\(1cap, 1px\)\); \}/, type,
      "the correction rounds the cap up to the block's own leading, less the cap as WebKit trims it")
    assert_match(/html\.no-metric-overrides :is\([^{]*\) \{\s*text-box: trim-both cap alphabetic;\s*padding-block-start: var\(--cap-correction\);/m, type,
      "the trim is asked without the document being marked, which is a page the faces had exact")
    assert_equal 1, type.scan(/text-box: trim-both cap alphabetic;/).size, "the trim is declared once, behind the mark, and nowhere else"
    assert_match(/--cap-correction: 0px;/, rules_in("tokens"), "a browser that cannot trim is owed a correction of nothing")
  end

  # A component that puts anything above trimmed type puts the correction
  # there, or the type is on the grid in one browser and a cap short of it in
  # the other. A button is not trimmed — its label is centred in a box — and
  # so is the one text-bearing component with no correction to carry.
  test "every padding above trimmed type carries the correction" do
    components = rules_in("components")

    assert_match(/padding-block: var\(--cap-correction\) calc\(var\(--line\) - var\(--rule-hair\)\)/, components, "a cell")
    assert_match(/\.copy \{[^}]*padding: var\(--cap-correction\) 0 0/m, components)
    assert_no_match(/\.button,\s*\.copy,\s*\.skip-link \{/, rules_in("type"), "a button is a box, and is not trimmed")
  end

  test "nothing is set in capitals" do
    offenders = every_stylesheet.select { |_, css| css.match?(/text-transform:\s*uppercase/) }

    assert_empty offenders.keys,
      "size and value carry the micro register; capitals are a different typographic tradition"
  end

  test "prose is held to the measure" do
    assert_match(/max-width: var\(--measure\)/, rules_in("type"))
  end

  # The library sets type flush left and ragged right. Centred type is a
  # different style, and one of the few things here worth being categorical
  # about.
  test "nothing is centred" do
    offenders = every_stylesheet.select { |_, css| css.match?(/text-align:\s*center/) }

    assert_empty offenders.keys
  end
end
