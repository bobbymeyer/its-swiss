require "test_helper"

# The library is a base and the application is not. That is stated once, in
# the cascade rather than in a convention: everything the gem ships is inside
# a layer, and an application's own CSS is unlayered, so it wins whatever it
# says and however loosely it says it.
class LayersTest < ActiveSupport::TestCase
  test "every core stylesheet puts itself inside the library's layer" do
    every_stylesheet.each do |name, css|
      assert_match(/@layer #{ItsSwiss::LAYER}\.#{name} \{/, css,
        "#{name}.css is unlayered, so it would outrank the application that loads it")
    end
  end

  # Loading the six files with six link tags and loading the one file that
  # imports them have to resolve the same way, or the library behaves
  # differently inside Rails than outside it.
  test "the single-file entry point imports every stylesheet in layer order" do
    entry = ROOT.join("app/assets/stylesheets/its-swiss.css").read
    imported = entry.scan(%r{@import url\("its_swiss/(\w+)\.css"\)}).flatten

    assert_equal ItsSwiss::STYLESHEETS, imported
    assert_match(/\A@layer #{Regexp.escape(ItsSwiss::STYLESHEETS.map { |s| "#{ItsSwiss::LAYER}.#{s}" }.join(", "))};/,
      entry.gsub(%r{/\*.*?\*/}m, "").strip,
      "the order is stated before the first import, so a slow file cannot reorder the cascade")
  end

  test "nothing in the library reaches for !important" do
    offenders = every_stylesheet.select { |_, css| css.gsub(%r{/\*.*?\*/}m, "").include?("!important") }

    assert_equal [ "reset" ], offenders.keys,
      "a layered library never needs to shout; the reset's [hidden] is the one exception, and says why"
  end
end
