module JsHelper
  def js_init(script = :default)
    script = "Vendors.Views.#{controller.controller_name.titleize}_#{controller.action_name.titleize}.init()" if script == :default
    content_for :javascripts do
      "<script type=\"text/javascript\">$(document).ready(#{script});</script>".html_safe
    end
  end
end
