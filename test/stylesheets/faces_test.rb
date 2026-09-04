require "test_helper"

# The faces are where the baseline comes from. A line box puts its baseline
# half the leading down and then the font's ascent, and the ascent is the
# font file's — so each register is set in its family declared again with the
# ascent it needs, and these pin what that declaration has to say.
class FacesTest < ActiveSupport::TestCase
  FACE = /@font-face \{([^}]*)\}/m

  def faces
    rules_in("faces").scan(FACE).flatten.map do |body|
      body.scan(/([a-z-]+): ([^;]+);/).to_h
    end
  end

  # Ascent equal to the leading, no descent, no line gap: that is the whole
  # trick, and the baseline is the under edge of the line box only if all
  # three hold. A descent left to the font puts half of it back above the
  # baseline; a line gap left to the font is leading the ladder never gave.
  test "every face puts the baseline on the under edge of the line" do
    ItsSwiss::FACES.merge(ItsSwiss::MONO_FACE).each do |family, ratio|
      declared = faces.select { |face| face["font-family"] == %("#{family}") }

      assert_not_empty declared, "#{family} is not declared"
      declared.each do |face|
        assert_in_delta ratio * 100, face["ascent-override"].to_f, 0.001, "#{family}: the ascent is not the leading"
        assert_equal "0%", face["descent-override"], "#{family}: a descent puts half of itself above the baseline"
        assert_equal "0%", face["line-gap-override"], "#{family}: a line gap is leading the ladder did not give"
      end
    end
  end

  # Two weights, because the style leans on exactly two and synthesis is off:
  # a face declared at one weight would have every heading set regular.
  test "every register face is declared at both weights" do
    ItsSwiss::FACES.each_key do |family|
      weights = faces.select { |face| face["font-family"] == %("#{family}") }.map { |face| face["font-weight"] }

      assert_equal %w[ 400 700 ], weights.sort, "#{family} is not declared regular and bold"
    end
  end

  # The gem ships no typeface, and a face that fetched one would be shipping
  # it by another route. local() is the font already on the machine, and the
  # first name in every chain is the first name in --font-family, so the
  # fallback for a machine with none of them is the same face without the
  # baseline rather than a different face altogether.
  test "the faces are drawn from the machine, not downloaded" do
    faces.each do |face|
      assert_no_match(/url\(/, face["src"], "#{face["font-family"]} fetches a font")
      assert_match(/\Alocal\(/, face["src"], "#{face["font-family"]} is not drawn from a local font")
    end
    assert_match(/"Helvetica Neue"/, rules_in("tokens")[/--font-family: ([^;]+);/, 1])
    assert_match(/\Alocal\("Helvetica Neue"\)/, faces.first["src"])
  end

  # The ratios are not chosen; they fall out of the ladder. Every register in
  # the library is a size from the scale on a whole number of lines, and the
  # face it names has to carry exactly that ratio — a register that changed
  # its leading without changing its face would be a register with its type
  # back in the font's hands. Read from the stylesheets rather than restated
  # here, so a new register is checked the day it is written.
  test "every register names the face for its ratio of leading to size" do
    tokens = rules_in("tokens")
    line = tokens[/--line: ([\d.]+)rem;/, 1].to_f
    sizes = tokens.scan(/--size-(\d): ([\d.]+)rem;/).to_h { |n, rem| [ n, rem.to_f ] }
    ratios = tokens.scan(/--face-(\d+): "its-swiss-(\d+)";/).to_h { |token, face| [ token, face.to_f / 100 ] }

    registers = every_stylesheet.flat_map do |name, css|
      css.gsub(%r{/\*.*?\*/}m, "").scan(/([^{}]+)\{([^}]*font-size: var\(--size-\d\)[^}]*)\}/m).map do |selector, body|
        [ "#{name}.css #{selector.strip.tr("\n", " ").squeeze(" ")}", body ]
      end
    end

    assert_operator registers.size, :>=, 6
    registers.each do |where, body|
      size = sizes.fetch(body[/font-size: var\(--size-(\d)\)/, 1])
      lines = body[/line-height: var\(--line(?:-(\d))?\)/, 1]&.to_f || 1
      face = body[/font-family: var\(--face-(\d+)\), var\(--font-family\)/, 1]

      assert body.include?("line-height: var(--line"), "#{where} sets a size without a leading"
      assert face, "#{where} sets a size and a leading without the face for their ratio, so the type is the font's"
      assert_in_delta line * lines / size, ratios.fetch(face), 0.001,
        "#{where} is #{size}rem on #{lines} lines and names --face-#{face}"
    end
  end

  # The subgrid halves the line under a block of small type, which doubles
  # every ratio in it; the small register's face has to follow, and it is the
  # only one that can — twelve on twelve is the size itself, and sixteen on
  # twelve is a line its own type does not fit.
  test "the subgrid moves the small register onto the face for a half-line" do
    assert_match(/\.subgrid > \* \{\s*--line: var\(--half-line\);\s*--face-200: var\(--face-100\);\s*\}/, rules_in("type"))
  end

  # A face is per ratio, not per register, and the ratios are the ladder's.
  # Three, and no more: a fourth would be a size set on a leading the scale
  # does not produce.
  test "the faces are the ladder's ratios and nothing else" do
    assert_equal({ "its-swiss-150" => 1.5, "its-swiss-200" => 2.0, "its-swiss-100" => 1.0 }, ItsSwiss::FACES)
    assert_equal %w[ its-swiss-150 its-swiss-200 its-swiss-100 ],
      rules_in("tokens").scan(/--face-\d+: "([^"]+)";/).flatten
  end
end
