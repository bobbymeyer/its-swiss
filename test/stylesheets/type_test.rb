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

  # 0.5.0 trimmed every register to its cap and its baseline and rounded the
  # cap up to a line, which registered the type in the one browser that
  # trims and left the rest to their fonts. The faces do the same job in
  # every browser, and a trim left behind would be applied on top of them —
  # to a box that is already exactly its type.
  test "nothing is trimmed and nothing is corrected" do
    every_stylesheet.each do |name, css|
      css = css.gsub(%r{/\*.*?\*/}m, "")

      assert_no_match(/text-box/, css, "#{name}.css trims a text box the faces already register")
      assert_no_match(/cap-correction|1cap/, css, "#{name}.css still measures a cap the faces made irrelevant")
    end
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
