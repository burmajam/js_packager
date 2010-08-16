require 'generators/js'

module Js
  module Generators
    class ViewGenerator < Base
      source_root File.expand_path('../templates', __FILE__)

      argument :actions, :type => :array, :default => [], :banner => "action action"

      def create_js_files
        empty_directory File.join("app/javascripts/views", name.underscore)

        actions.each do |action|
          @view_name = action
          template "js_for_view.js.erb",
                   File.join("app/javascripts/views", name.underscore, "#{action}.js")
        end
      end

      def create_scss_files
        empty_directory File.join("app/stylesheets/views", name.underscore)

        actions.each do |action|
          @view_name = action
          create_file File.join("app/stylesheets/views", name.underscore, "_#{action}.scss")

          import_scss = "views/#{name.underscore}/#{action}"
          log :include_scss, import_scss
          sentinel = /\z/m

          in_root do
            inject_into_file 'app/stylesheets/screen.scss', "\n@import \"#{import_scss}\";", { :after => sentinel, :verbose => false }
          end
        end
      end
    end
  end
end
