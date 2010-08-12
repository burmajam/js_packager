require 'yaml'
require File.dirname(__FILE__) + '/../../lib/synthesis/js_package'

namespace :js do
  namespace :packager do

    desc "Merge and compress javascript files"
    task :build do
      Synthesis::JsPackage.build
    end

    desc "Delete all javascript builds"
    task :delete_builds do
      Synthesis::JsPackage.delete_builds
    end

    desc "Generate js_packages.yml from existing javascript files"
    task :create_yml do
      Synthesis::JsPackage.create_yml
    end

  end
end
