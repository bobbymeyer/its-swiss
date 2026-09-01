require "bundler/setup"

# build, install and release. The release workflow runs `rake release`, which
# is defined here and nowhere else: without it the whole of a release — the
# credentials minted over OIDC, the version checked against the tag, the suite
# — ends at a rake task that does not exist.
require "bundler/gem_tasks"

require "rake/testtask"

Rake::TestTask.new(:test) do |t|
  t.libs << "test"
  t.libs << "lib"
  t.test_files = FileList["test/**/*_test.rb"]
  t.warning = false
end

task default: :test
