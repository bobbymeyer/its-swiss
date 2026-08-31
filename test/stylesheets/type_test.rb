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
    assert_empty leadings.reject { |value| value.match?(/\Avar\(--space-\d+\)\z/) },
      "a line box measured in anything but baselines breaks the vertical rhythm"
    assert_no_match(/--lead-/, type, "there is one ladder, and it is the space ladder")
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
