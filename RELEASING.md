# Releasing

Versions go out from a tag, built and pushed by
`.github/workflows/release.yml`. **No RubyGems API key exists in this
repository or in its secrets**, and none should be created: the workflow
authenticates over OIDC, with a short-lived credential RubyGems mints for
this repository and this workflow file alone.

## Cutting a version

1. `lib/its_swiss/version.rb` — set the version.
2. `CHANGELOG.md` — turn the unreleased section into the version, with a date.
3. Merge to `main`.
4. Tag it, from `main`:

   ```sh
   git tag v0.1.0
   git push origin v0.1.0
   ```

The workflow checks that the tag and `ItsSwiss::VERSION` agree, runs Rubocop
and the suite, builds, pushes to RubyGems and opens a GitHub release. A tag
that disagrees with the gemspec fails before anything is published.

## One-time setup on rubygems.org

Trusted publishing has to be configured once before the first release, and
because `its-swiss` does not exist yet this is the **pending** publisher flow
— RubyGems lets you register a publisher for a name that has never been
pushed, which then creates the gem on the first run.

Under your rubygems.org profile, in the trusted publishers section, add a
GitHub Actions publisher with:

| Field | Value |
| --- | --- |
| Gem name | `its-swiss` |
| Repository owner | `bobbymeyer` |
| Repository name | `its-swiss` |
| Workflow filename | `release.yml` |
| Environment | leave empty |

Docs: <https://guides.rubygems.org/trusted-publishing/>

## The manual path

If trusted publishing is not set up, or a release has to go out from a
machine rather than from CI:

```sh
gem build its-swiss.gemspec
gem push its-swiss-0.1.0.gem
```

The gemspec sets `rubygems_mfa_required`, so this prompts for an OTP. Keep it
that way — it is the reason an API key on its own cannot publish this gem.

## What is checked before a push

`bin/test` covers the library. Two guards are specifically about what ships:

- `EngineTest#test_the_gem_ships_everything_it_needs_at_runtime` asserts the
  gemspec's manifest holds every file the library loads at runtime. A
  stylesheet added and not shipped is otherwise silent until an application
  gets a 404.
- `EngineTest#test_the_declared_stylesheets_are_the_stylesheets_that_ship`
  asserts `ItsSwiss::STYLESHEETS` and the files on disk are the same set.

Worth doing by hand before a first release, since it catches what a manifest
test cannot — that the built package installs:

```sh
gem build its-swiss.gemspec
GEM_HOME=/tmp/gemcheck gem install ./its-swiss-0.1.0.gem --local --no-document --ignore-dependencies
GEM_HOME=/tmp/gemcheck ruby -e 'gem "its-swiss"; require "its_swiss"; puts ItsSwiss::VERSION'
```
