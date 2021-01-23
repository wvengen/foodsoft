$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "foodsoft_mollie/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "foodsoft_mollie"
  s.version     = FoodsoftMollie::VERSION
  s.authors     = ["wvengen"]
  s.email       = ["dev-foodsoft@willem.engen.nl"]
  s.homepage    = "https://github.com/foodcoop-adam/foodsoft"
  s.summary     = "Mollie payment plugin for foodsoft."
  s.description = "Integration with Mollie payments."

  s.files = Dir["{app,config,db,lib}/**/*"] + ["LICENSE", "Rakefile", "README.md"]

  s.add_dependency "rails"
  s.add_dependency "mollie-api-ruby"
  s.add_dependency "deface", "~> 1.0"
end
