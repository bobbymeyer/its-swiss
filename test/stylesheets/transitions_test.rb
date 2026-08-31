require "test_helper"

# The gem names the transitions and how long they last. Which page transitions
# to which is the application's, because it depends on what the pages are.
class TransitionsTest < ActiveSupport::TestCase
  test "opts into cross-document navigation transitions" do
    assert_match(/@view-transition \{\s*navigation: auto;/, rules_in("transitions"))
  end

  # A snapshot of :root is sized to the viewport including the scrollbar while
  # the page is laid out in what is left, so for the length of every
  # navigation the document is wider than its own viewport and really does
  # scroll sideways. It settles back the moment the transition ends, which is
  # why it measures clean whenever it is asked standing still.
  test "the page crossfade is taken of the body rather than the root" do
    transitions = rules_in("transitions")

    assert_match(/:root \{\s*view-transition-name: none;/, transitions)
    assert_match(/body \{\s*view-transition-name: page;/, transitions)
  end

  test "durations are named as tokens so an application can retime them" do
    assert_match(/--transition-page:/, rules_in("tokens"))
    assert_match(/--transition-morph:/, rules_in("tokens"))
    assert_match(/animation-duration: var\(--transition-page\)/, rules_in("transitions"))
  end

  test "reduced motion turns them off" do
    transitions = rules_in("transitions")

    assert_match(/@media \(prefers-reduced-motion: reduce\)/, transitions)
    assert_match(/navigation: none/, transitions)
  end
end
