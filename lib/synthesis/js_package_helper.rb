module Synthesis
  module JsPackageHelper
    
    def should_merge?
      JsPackage.merge_environments.include?(Rails.env)
    end

    def javascript_include_merged(*sources)
      options = sources.last.is_a?(Hash) ? sources.pop.stringify_keys : { }

      if sources.include?(:defaults)
        sources = sources[0..(sources.index(:defaults))] + 
          ActionView::Helpers::AssetTagHelper.javascript_expansions[:defaults] + 
          (File.exists?("#{Rails.root}/app/javascripts/application.js") ? ['application'] : []) +
          sources[(sources.index(:defaults) + 1)..sources.length]
        sources.delete(:defaults)
      end

      sources.collect!{|s| s.to_s}
      sources = (should_merge? ? 
        JsPackage.targets_from_sources(sources) :
        JsPackage.sources_from_targets(sources))
        
      sources.collect {|source| javascript_include_tag(source, options) }.join("\n")
    end
  end
end