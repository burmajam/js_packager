require 'generators/js'

module Js
  module Generators
    class ControllerGenerator < Base
      source_root File.expand_path('../templates', __FILE__)

      argument :actions, :type => :array, :default => [], :banner => "action action"
      check_class_collision :suffix => "Controller"

      def create_controller_files
        template 'controller.rb', File.join('app/controllers', class_path, "#{file_name}_controller.rb")
      end

      def create_helper_file
        copy_file "helper.rb", "app/helpers/js_helper.rb" 
      end

      def add_routes
        actions.reverse.each do |action|
          route %{get "#{file_name}/#{action}"}
        end
      end

      hook_for :template_engine, :as => :controller
      hook_for :test_framework, :as => :controller
#      hook_for :helper, :as => :controller
      invoke "js:view", :controller => name
    end
  end
end
