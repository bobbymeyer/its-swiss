require "test_helper"

# Everything vertical is a whole number of baselines, including the line
# boxes. Two ladders — one for leading, one for space — agree at a few values
# and diverge everywhere else, which is how a heading ends up impossible to
# separate from the block beneath it by the height of its own line.
class TypeTest < ActiveSupport::TestCase
  test "leading is drawn from the space ladder" do
    type = rules_in("type")
    leadings = type.scan(/line-height: ([^;]+);/).flatten

    assert_not_empty leadings
    # Zero is the one value that is not a measurement: an inline box of
    # another family brings its own ascent and descent and grows the line it
    # sits on, and taking its leading to nothing leaves the line box to the
    # strut, which is measured in baselines like everything else.
    assert_empty leadings.reject { |value| value.match?(/\Avar\(--space-\d+\)\z|\A0\z/) },
      "a line box measured in anything but baselines breaks the vertical rhythm"
    assert_no_match(/--lead-/, type, "there is one ladder, and it is the space ladder")
  end

  # The trimmed path is an enhancement, not a requirement: Firefox does not
  # trim a text box yet, and a stylesheet that assumed it would leave every
  # padded register a few pixels tall for no reason.
  test "the cap correction is zero where the browser cannot trim" do
    assert_match(/--cap-correction:\s*0px/, rules_in("tokens"),
      "the correction has to be inert before type.css gives it a value")

    trim = rules_in("type")[/@supports[^{]+\{.*/m]

    assert_not_nil trim, "the trim belongs behind @supports or it is a requirement"
    assert_match(/text-box:\s*trim-both cap alphabetic/, trim)
    assert_match(/--cap-correction:\s*calc\(round\(up, 1cap, var\(--baseline\)\) - 1cap\)/, trim,
      "the correction is the browser's cap height rounded to the ladder, not a number the library was told")
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
