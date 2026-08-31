require "test_helper"

# The specimen is the documentation and the regression fixture: if a component
# is in the library it is on this page, and if it stops rendering the suite
# says so. There are no pixel tests — this asserts that every component is
# present and that the page renders at all.
class SpecimenTest < ActionDispatch::IntegrationTest
  setup { get "/its-swiss/specimen" }

  def html = Nokogiri::HTML5(response.body)

  test "renders" do
    assert_response :success
  end

  # Rendered twice: once with the accent slot left as the library ships it,
  # once with an accent set. If the page reads correctly with the accent
  # collapsed onto ink, the values are doing the work — which is the whole
  # argument the library makes, so the page has to make it.
  test "renders every component twice, with the accent unset and set" do
    takes = html.css("[data-specimen-take]")

    assert_equal %w[ monochrome accent ], takes.map { |take| take["data-specimen-take"] }
    assert_match(/--accent:/, takes.last["style"].to_s)
    assert_nil takes.first["style"], "the first take shows the library exactly as it ships"
  end

  test "shows every component the library ships" do
    %w[ masthead nav footer table pairs form field button pagination errors ].each do |component|
      assert html.at(".#{component}"), "the specimen does not show .#{component}"
    end
  end

  # Scoped to one take, because everything on this page is on it twice.
  test "shows the type scale, the value scale and the grid primitives" do
    take = html.at("[data-specimen-take=monochrome]")

    assert_equal 5, take.css("[data-specimen=type] [data-size]").size, "five sizes, one per rung"
    assert_equal 6, take.css("[data-specimen=values] [data-value]").size, "six steps, paper to ink"
    assert take.at("[data-specimen=grid] .grid"), "the grid primitives are not shown"
  end

  # Every component appears in both takes, or the second take is not a
  # comparison — it is a different page.
  test "the two takes hold the same components" do
    takes = html.css("[data-specimen-take]").map { |take| take.css("[data-specimen]").map { |s| s["data-specimen"] } }

    assert_equal takes.first, takes.last
    assert_operator takes.first.size, :>=, 8
  end

  test "is refused where the configuration has not asked for it" do
    ItsSwiss.config.specimen = false

    assert_raises(ActionController::RoutingError) { get "/its-swiss/specimen" }
  ensure
    ItsSwiss.config.specimen = nil
  end
end
