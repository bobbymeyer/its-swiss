require "test_helper"

# The one step of a release that nothing else exercises. `rubygems/release-gem`
# runs `bundle exec rake release`, and that task is Bundler's rather than this
# Rakefile's — so a Rakefile that only defines the suite passes every check a
# release makes, mints its credentials over OIDC, and then stops at "Don't know
# how to build task 'release'". 0.2.0 and 0.3.0 both did.
class ReleaseTest < ActiveSupport::TestCase
  test "the rake task the release workflow runs exists" do
    assert_match(/^require "bundler\/gem_tasks"/, ROOT.join("Rakefile").read,
      "rake release comes from Bundler; without the require a release ends at a task that does not exist")
  end

  # A tag that disagrees with the gemspec is a release going out under a number
  # nobody chose, so the workflow checks. This is the check on the check.
  test "the release workflow holds the tag to the version" do
    workflow = ROOT.join(".github/workflows/release.yml").read

    assert_match(/GITHUB_REF_NAME#v/, workflow)
    assert_match(/ItsSwiss::VERSION/, workflow)
  end
end
