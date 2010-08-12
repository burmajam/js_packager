require File.dirname(__FILE__) + '/../../../../config/environment'
require 'test/unit'
require 'mocha'

class JsPackagerTest < Test::Unit::TestCase
  include Synthesis
  
  def setup
    Synthesis::JsPackage.js_base_path    = "#{Rails.root}/vendor/plugins/js_packager/test/javascripts"
    Synthesis::JsPackage.js_packages_yml = YAML.load_file("#{Rails.root}/vendor/plugins/js_packager/test/js_packages.yml")

    Synthesis::JsPackage.any_instance.stubs(:log)
    Synthesis::JsPackage.build_all
  end
  
  def teardown
    Synthesis::JsPackage.delete_all
  end
  
  def test_find_by_type
    js_asset_packages = Synthesis::JsPackage.find_by_type("javascripts")
    assert_equal 2, js_asset_packages.length
    assert_equal "base", js_asset_packages[0].target
    assert_equal ["prototype", "effects", "controls", "dragdrop"], js_asset_packages[0].sources
  end
  
  def test_find_by_target
    package = Synthesis::JsPackage.find_by_target("javascripts", "base")
    assert_equal "base", package.target
    assert_equal ["prototype", "effects", "controls", "dragdrop"], package.sources
  end
  
  def test_find_by_source
    package = Synthesis::JsPackage.find_by_source("javascripts", "controls")
    assert_equal "base", package.target
    assert_equal ["prototype", "effects", "controls", "dragdrop"], package.sources
  end
  
  def test_delete_and_build
    Synthesis::JsPackage.delete_all
    js_package_names = Dir.new(Synthesis::JsPackage.js_base_path).entries.delete_if { |x| ! (x =~ /\A\w+_packaged.js/) }
    css_subdir_package_names = Dir.new("#{Synthesis::JsPackage.js_base_path}/stylesheets/subdir").entries.delete_if { |x| ! (x =~ /\A\w+_packaged.css/) }

    assert_equal 0, js_package_names.length

    Synthesis::JsPackage.build_all
    js_package_names = Dir.new(Synthesis::JsPackage.js_base_path).entries.delete_if { |x| ! (x =~ /\A\w+_packaged.js/) }.sort
    
    assert_equal 2, js_package_names.length
    assert js_package_names[0].match(/\Abase_packaged.js\z/)
    assert js_package_names[1].match(/\Asecondary_packaged.js\z/)
  end
  
  def test_js_names_from_sources
    package_names = Synthesis::JsPackage.targets_from_sources("javascripts", ["prototype", "effects", "noexist1", "controls", "foo", "noexist2"])
    assert_equal 4, package_names.length
    assert package_names[0].match(/\Abase_packaged\z/)
    assert_equal package_names[1], "noexist1"
    assert package_names[2].match(/\Asecondary_packaged\z/)
    assert_equal package_names[3], "noexist2"
  end
  
  def test_should_return_merge_environments_when_set
    Synthesis::JsPackage.merge_environments = ["staging", "production"]
    assert_equal ["staging", "production"], Synthesis::JsPackage.merge_environments
  end

  def test_should_only_return_production_merge_environment_when_not_set
    assert_equal ["production"], Synthesis::JsPackage.merge_environments
  end
  
end
