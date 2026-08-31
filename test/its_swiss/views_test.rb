require "test_helper"

# The views the library ships, as source. The one guard here is the rule the
# rendered-specimen test enforces from the other side.
class ViewsTest < ActiveSupport::TestCase
  VIEWS = ROOT.glob("app/views/**/*.erb").freeze

  test "there are views to check" do
    assert_operator VIEWS.size, :>=, 10
  end

  # An ERB comment ends at the first `%>` it meets, including one belonging to
  # an example written inside it. So a comment that quotes ERB is a comment
  # that stops early, and every line after the example is emitted as page
  # content — silently, and looking like prose the author meant to write.
  #
  # A comment about ERB cannot quote ERB. Examples belong in the README.
  test "no comment quotes the syntax it is a comment about" do
    offenders = VIEWS.flat_map do |view|
      view.read.scan(/<%#(.*?)%>/m).flatten
        .select { |body| body.include?("<%") }
        .map { |body| "#{view.basename}: #{body.strip.lines.first.to_s.strip}" }
    end

    assert_empty offenders,
      "an ERB example inside an ERB comment closes the comment at its own %>"
  end
end
