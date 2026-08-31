require "test_helper"

# The house rules, as guards. Each of these is a decision that reads as a
# detail in the stylesheet and as a usability failure on the page.
class ComponentsTest < ActiveSupport::TestCase
  # A reader who cannot separate the accent from the quiet gray would have no
  # current state at all. Every signal the library gives carries a second one.
  test "no signal rests on colour alone" do
    [ '.nav [aria-current="page"]', ".pagination [aria-current]" ].each do |selector|
      declarations = declarations_for(selector)

      assert_not_empty declarations, "expected #{selector} to say where you are"
      assert_match(/color: var\(--accent\)/, declarations)
      assert_match(/font-weight: 700/, declarations, "#{selector} says it in colour and nothing else")
    end
  end

  # A keyboard reaches these and touch never hovers at all.
  test "everything that answers hover answers focus" do
    components = rules_in("components")

    assert_match(/\.button--danger:hover,\s*\.button--danger:focus-visible/, components)
    assert_match(/\.copy:hover::after,\s*\.copy:focus-visible::after/, components)
  end

  # A reader scanning the row has not hovered anything yet, so hover cannot be
  # the only thing separating reordering from destroying.
  test "destroying is set apart at rest, not only on hover" do
    declarations = declarations_for(".run > .button--danger")

    assert_not_empty declarations, "expected a destructive action in a run of them to be set apart"
    assert_match(/margin-inline-start: var\(--space-\d+\)/, declarations,
      "an auto margin puts the gap at whatever is left over, which across a page is most of a page")
  end

  # No cards, no rounded corners, no shadows. The whole style is hairlines and
  # whitespace, and each of these is what quietly replaces them.
  test "separation is done with hairlines and whitespace" do
    every_stylesheet.each do |name, css|
      css = css.gsub(%r{/\*.*?\*/}m, "")

      assert_no_match(/border-radius/, css, "#{name}.css rounds a corner")
      assert_no_match(/box-shadow:(?!\s*inset)/, css, "#{name}.css casts a shadow")
    end
  end

  # A component that placed itself on the page's field would break the moment
  # an application decided its problem had eight fields rather than six.
  test "no component places itself on the application's grid" do
    assert_no_match(/grid-column/, rules_in("components"),
      "components lay themselves out; the field is the application's")
  end

  # Every filled area on a page is ink, paper or the accent. A component that
  # invents a fill is a component inventing a value.
  test "every fill comes from the value scale or the accent" do
    fills = rules_in("components").scan(/background(?:-color)?:\s*([^;]+);/).flatten
    scale = /\A(transparent|none|var\(--(?:paper|paper-shaded|rule|rule-strong|ink|ink-quiet|accent|value-\d)\))\z/

    assert_empty fills.reject { |fill| fill.match?(scale) },
      "a fill outside the scale is a colour the library invented"
  end

  private
    # Every declaration that applies to a selector, across every rule that
    # names it: grouped selectors are how this stylesheet says a thing once,
    # so the first rule mentioning one is rarely the rule about it.
    def declarations_for(selector)
      rules_in("components").scan(/([^{}]+)\{([^}]*)\}/m)
        .select { |selectors, _| selectors.split(",").map(&:strip).include?(selector) }
        .map(&:last).join
    end
end
