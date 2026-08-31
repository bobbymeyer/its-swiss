require "test_helper"

# One shape for every field: a label, a control, and — when there is something
# to say — a hint or the reason it was refused. Written by the builder rather
# than by hand, because the parts that get left out by hand are the parts
# nobody sees missing: the label's `for`, the hint's `aria-describedby`, the
# class that colours a refused rule.
class FormBuilderTest < ActionView::TestCase
  class Post
    include ActiveModel::Model
    include ActiveModel::Attributes

    attribute :title, :string
    attribute :body, :string
    attribute :published, :boolean
    attribute :kind, :string
  end

  setup do
    @post = Post.new(title: "Grid", body: nil, published: false, kind: "note")
    @builder = ItsSwiss::FormBuilder.new(:post, @post, view, {})
  end

  def field(markup) = Nokogiri::HTML5.fragment(markup).at(".field")

  test "wraps a control in a field with its label" do
    node = field(@builder.text_field(:title))

    assert_equal "Title", node.at("label").text
    assert_equal node.at("input")["id"], node.at("label")["for"],
      "a label that names nothing is a label a pointer cannot enlarge"
    assert_equal "Grid", node.at("input")["value"]
  end

  test "every control the library styles goes through the same wrapper" do
    %i[ text_field email_field password_field number_field url_field telephone_field text_area ].each do |control|
      node = field(@builder.public_send(control, :title))

      assert node, "#{control} did not produce a field"
      assert node.at("label"), "#{control} produced a field with no label"
    end
  end

  test "a hint is attached to the control rather than left floating beside it" do
    node = field(@builder.text_field(:title, hint: "As it appears in the nav."))

    assert_equal "As it appears in the nav.", node.at(".hint").text
    assert_equal node.at(".hint")["id"], node.at("input")["aria-describedby"]
  end

  test "a label the field does not need is still there for anyone listening" do
    node = field(@builder.text_field(:title, label: false))

    assert_nil node.at("label:not(.visually-hidden)")
    assert_equal "Title", node.at("input")["aria-label"]
  end

  test "a refused field says so in the markup, not only in the colour" do
    @post.errors.add(:title, "cannot be blank")
    node = field(@builder.text_field(:title))

    assert_includes node["class"].split, "field--invalid"
    assert_equal "true", node.at("input")["aria-invalid"]
    assert_equal "Title cannot be blank", node.at(".field__error").text
    assert_includes node.at("input")["aria-describedby"].to_s, node.at(".field__error")["id"]
  end

  test "a checkbox puts its label beside it rather than above it" do
    node = field(@builder.check_box(:published))

    assert node.at(".choice"), "a checkbox and its label are a pair on one line"
    assert_equal "Published", node.at(".choice label").text
  end

  test "a select is a field like any other" do
    node = field(@builder.select(:kind, [ %w[ Note note ], %w[ Essay essay ] ]))

    assert node.at("label")
    assert_equal 2, node.at("select").css("option").size
  end

  test "submitting is a primary button, and says what it does" do
    button = Nokogiri::HTML5.fragment(@builder.submit("Publish")).at("button")

    assert_equal "Publish", button.text
    assert_equal %w[ button button--primary ], button["class"].split
  end

  test "a secondary action is the same box, unfilled" do
    button = Nokogiri::HTML5.fragment(@builder.submit("Save draft", class: "button button--quiet")).at("button")

    assert_equal %w[ button button--quiet ], button["class"].split
  end
end
