require "test_helper"

# The token layer is the whole library in miniature: a value scale, one accent
# slot the gem never fills, and a type and space ladder everything else
# measures itself against. These pin the decisions that the rest of the CSS
# would otherwise be free to drift away from.
class TokensTest < ActiveSupport::TestCase
  # --- The value scale -----------------------------------------------------

  test "the value scale is declared as OKLCH lightness steps" do
    steps = rules_in("tokens").scan(/--value-(\d): oklch\(([\d.]+)% /)

    assert_equal %w[ 0 1 2 3 4 5 ], steps.map(&:first),
      "the ladder is numbered from paper to ink with no gaps"
    assert_equal steps.map(&:last), steps.map(&:last).sort.reverse,
      "the steps descend in lightness; a ladder that doubles back is not a ladder"
  end

  # Paper and ink are the two ends of the same ladder, not two colors that
  # happen to sit near it. Naming them as aliases is what keeps them there:
  # otherwise the day someone darkens the ground, the ladder says one thing
  # and the page shows another.
  test "paper and ink are the ends of the value scale rather than values of their own" do
    assert_match(/--paper: var\(--value-0\)/, rules_in("tokens"))
    assert_match(/--ink: var\(--value-5\)/, rules_in("tokens"))
  end

  # Hue is the application's business — the boundary says so, and a library
  # that shipped a warm gray would be shipping a palette. So the scale is
  # neutral, and warmth arrives through two slots a consumer can set once.
  test "the value scale carries no hue of its own" do
    tokens = rules_in("tokens")

    assert_match(/--value-chroma: 0;/, tokens, "the gem's own ladder is neutral")
    assert_match(/--value-hue: 0;/, tokens)
    assert_equal 6, tokens.scan(/oklch\(\s*[\d.]+% var\(--value-chroma\) var\(--value-hue\)\s*\)/).size,
      "every step is drawn through the same two slots, or warming the scale warms part of it"
  end

  # --- The accent ----------------------------------------------------------

  # The one rule the library is built on. If the gem picks the accent, every
  # application using it looks like the same application.
  test "the gem declares the accent slot without filling it" do
    tokens = rules_in("tokens")

    assert_match(/--accent:/, tokens, "the slot is named here so a consumer knows what to set")
    assert_match(/--accent: var\(--ink\)/, tokens,
      "an unset accent falls back to ink, so a page with no accent still reads"
    )
    assert_no_match(/--accent: (?:#|oklch\(\s*\d)/, tokens,
      "a literal accent in the gem is a palette, and palettes stay in the app")
  end

  test "no core stylesheet states a color outside the value scale and the accent" do
    literals = every_stylesheet.transform_values do |css|
      css.gsub(%r{/\*.*?\*/}m, "").scan(/#[0-9a-fA-F]{3,8}\b|\brgba?\(|\bhsla?\(/)
    end.reject { |_, found| found.empty? }

    assert_empty literals, "color enters the library through --value-* and --accent, nothing else"
  end

  # --- The ladders ---------------------------------------------------------

  test "the space ladder is derived from the baseline and nothing else" do
    steps = rules_in("tokens").scan(/--space-(\d+): calc\(var\(--baseline\) \* (\d+)\)/)

    assert_operator steps.size, :>=, 6, "a ladder of five values is a list of margins"
    steps.each { |name, multiple| assert_equal name, multiple, "--space-#{name} is not #{name} baselines" }
  end

  test "the type scale is a modular scale rather than a list of sizes" do
    sizes = rules_in("tokens").scan(/--size-(\d): ([\d.]+)rem/).map { |_, value| value.to_f }

    assert_equal 5, sizes.size
    assert_equal sizes, sizes.sort, "the scale ascends"
    ratios = sizes.each_cons(2).map { |small, large| (large / small).round(2) }
    assert ratios.all? { |ratio| ratio.between?(1.2, 1.6) },
      "a modular scale has a ratio; #{ratios.inspect} is a set of chosen numbers"
  end

  # The typeface is a consumer's, for the same reason the accent is: a library
  # that ships a font ships a voice, and it ships a binary too.
  test "the gem names the family it sets type in without shipping one" do
    assert_match(/--font-family:/, rules_in("tokens"))
    assert_empty Dir.glob(ROOT.join("app/assets/fonts/*")),
      "a typeface is the application's to host"
  end
end
