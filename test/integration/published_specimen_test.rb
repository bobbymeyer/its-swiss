require "test_helper"

# What a pinned link depends on. Pages replaces the whole site each deploy, so
# a version-stamped page exists only for as long as some run keeps writing it.
# 0.6.0.html was published once, pinned by a post, and gone the next time main
# moved — because the step that was meant to preserve it read the live site
# rather than the repository, and so could only preserve what a deploy had not
# already dropped.
class PublishedSpecimenTest < ActiveSupport::TestCase
  PUBLISHED = ROOT.join("published")

  test "the workflow publishes the archive" do
    workflow = ROOT.join(".github/workflows/pages.yml").read

    assert_match(%r{cp published/\*\.html specimen/}, workflow,
      "without this the archive is a directory nothing reads, and every pinned link dies at the next deploy")
  end

  test "an archived specimen names the version it is filed under" do
    pages = PUBLISHED.glob("*.html")

    assert_not_empty pages, "the archive is where a pinned version lives"

    pages.each do |page|
      version = page.basename(".html").to_s

      assert_match(/#{Regexp.escape(version)}/, page.read,
        "#{page.basename} does not say it is #{version}, so pinning to it would show something else")
    end
  end
end
