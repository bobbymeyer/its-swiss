require "test_helper"

# The shell is the one piece of the library an application cannot help using,
# so what it writes into <head> is a contract. Each of these is something that
# is invisible when it is missing and expensive to notice later.
class ShellTest < ActionDispatch::IntegrationTest
  setup { get "/page" }

  def html = Nokogiri::HTML5(response.body)

  test "renders the page inside the shell" do
    assert_response :success
    assert_equal "A page", html.at("title").text
    assert_equal "A page", html.at("main h1").text
  end

  test "falls back to the application's name when a page does not title itself" do
    get "/other"

    assert_equal "Dummy", html.at("title").text
  end

  test "opts every same-origin navigation into view transitions" do
    assert_equal "same-origin", html.at("meta[name=view-transition]")["content"]
  end

  test "links every core stylesheet" do
    linked = html.css("head link[rel=stylesheet]").map { |link| link["href"] }

    ItsSwiss::STYLESHEETS.each do |name|
      assert linked.any? { |href| href.include?("its_swiss/#{name}") }, "#{name}.css was not linked"
    end
  end

  test "leaves room in the head for what the application has to add" do
    assert html.at("meta[name=dummy-said-this]"), "yield :head reached nothing"
  end

  test "the page's main region is reachable without scrolling through the nav" do
    skip_link = html.at("body a[href='#main']")

    assert skip_link, "there is no way past the masthead for a keyboard"
    assert html.at("main#main")
  end

  # The masthead is not rendered at all when an application has given it
  # nothing to hold: a library that insisted on a bar across the top would be
  # insisting on a shape rather than offering one.
  test "the masthead carries the mark and the destinations the application gave it" do
    assert_equal "Dummy", html.at(".masthead__mark").text.strip
    assert_equal [ "A page", "Another page" ], html.css(".nav a").map(&:text)
  end

  test "marks the destination you are already at" do
    current = html.css(".nav a[aria-current=page]")

    assert_equal [ "A page" ], current.map(&:text)
  end

  test "renders no masthead for an application that asked for none" do
    get "/bare"

    assert_nil html.at(".masthead")
    assert_nil html.at(".footer")
  end

  test "says what happened, in the register the library keeps for it" do
    get "/page?notice=Saved"
    assert_equal "Saved", html.at("[role=status]").text
    assert_nil html.at(".errors")

    get "/page?alert=Refused"
    assert_equal "Refused", html.at("[role=alert] .errors__title").text
  end
end
