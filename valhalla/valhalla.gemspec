# frozen_string_literal: true
$LOAD_PATH.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "valhalla/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "valhalla"
  s.version     = Valhalla::VERSION
  s.authors     = ["Trey Pendragon"]
  s.email       = ["tpendragon@princeton.edu"]
  s.homepage    = "https://github.com/pulibrary/figgy"
  s.summary     = "Engine for creating a digital repository using Valkyrie."
  s.license     = "APACHE2"

  s.files = Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.md"]

  s.add_dependency "rails", "~> 5.1.0"
  s.add_dependency "hydra-editor"
  s.add_dependency 'font-awesome-rails', '~> 4.2'
  s.add_dependency 'jquery-ui-rails', '~> 6.0'

  s.add_development_dependency "sqlite3"
end
