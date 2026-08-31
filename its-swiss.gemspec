require_relative "lib/its_swiss/version"

Gem::Specification.new do |spec|
  spec.name = "its-swiss"
  spec.version = ItsSwiss::VERSION
  spec.authors = [ "Bobby Meyer" ]
  spec.email = [ "bobby@bobbymeyer.com" ]

  spec.summary = "A Swiss typographic style for Rails applications."
  spec.description = <<~TEXT.strip
    Tokens, reset, typography, grid primitives and components in the spirit of
    the International Typographic Style, as plain CSS plus a Rails engine that
    ships it. Monochrome by default: the value scale does the work and the one
    accent is the consuming application's to set.
  TEXT
  spec.homepage = "https://github.com/bobbymeyer/its-swiss"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.2.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = "#{spec.homepage}/blob/main/CHANGELOG.md"
  spec.metadata["rubygems_mfa_required"] = "true"

  spec.files = Dir[
    "app/**/*", "config/**/*", "lib/**/*",
    "CHANGELOG.md", "LICENSE", "README.md"
  ]
  spec.require_paths = [ "lib" ]

  spec.add_dependency "railties", ">= 8.0"
  spec.add_dependency "actionview", ">= 8.0"
  spec.add_dependency "propshaft", ">= 1.0"
  spec.add_dependency "importmap-rails", ">= 2.0"
end
