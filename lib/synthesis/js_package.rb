module Synthesis
  class JsPackage
    @js_source_path    = "#{Rails.root}/app/javascripts"
    @js_packages_yml = File.exists?("#{Rails.root}/config/js_packages.yml") ? YAML.load_file("#{Rails.root}/config/js_packages.yml") : nil

    class << self
      attr_accessor :js_source_path,
                    :js_packages_yml
      attr_writer :merge_environments
    end

    

    def self.merge_environments
      @merge_environments ||= %w(development staging production)
    end

    def self.parse_path(path)
      /^(?:(.*)\/)?([^\/]+)$/.match(path).to_a
    end

    def self.find_by_type
      js_packages_yml.map { |p| self.new(p) }
    end

    def self.find_by_target(target)
      package_hash = js_packages_yml.find { |p| p.first == target }
      package_hash ? self.new(package_hash.first => package_hash.last) : nil
    end

    def self.find_by_source(source)
      path_parts = parse_path(source)
      package_hash = js_packages_yml.find do |p|
        p = { p.first => p.last }
        key = p.keys.first
        p[key].include?(path_parts[2]) && (parse_path(key)[1] == path_parts[1])
      end
      package_hash ? self.new(package_hash.first => package_hash.last) : nil
    end

    def self.targets_from_sources(sources)
      package_names = Array.new
      sources.each do |source|
        package = find_by_target(source) || find_by_source(source)
        package_names << (package ? package.current_file : source)
      end
      package_names.uniq
    end

    def self.sources_from_targets(targets)
      source_names = Array.new
      targets.each do |target|
        package = find_by_target(target)
        source_names += (package ? package.sources.collect do |src|
          package.target_dir.gsub(/^(.+)$/, '\1/') + src
        end : target.to_a)
      end
      source_names.uniq
    end



    def self.build
      self.new(js_packages_yml).build
    end

    def self.delete_builds
      self.new(js_packages_yml).delete_previous_build
    end

    def self.create_yml
      unless File.exists?("#{Rails.root}/config/js_packages.yml")
        Dir.new "#{Rails.root}/app/javascripts"
        log "app/javascripts folder is created! It is source for your .js files that should be compressed"
        File.open("#{Rails.root}/config/js_packages.yml", "w") do |out|
          out.puts <<CONTENT
---
application:
- jquery
- rails
- application
- views/**/*
CONTENT
        end

        log "config/js_packages.yml example file created!"
        log "Please specify files you want to compress in correct order."
        log "Than run js:packager:build rake task to compress your js files."
      else
        log "config/js_packages.yml already exists. Aborting task..."
      end
    end

    attr_accessor :asset_type, :target, :target_dir, :sources

    def initialize(package)
      @target = package.keys.first
      @sources = package[package.keys.first]
      @target_file_name = "#{@target}.min.js"
      @target_full_path = File.join(Rails.root, 'public', 'javascripts', @target_file_name)
    end

    def package_exists?
      File.exists?(@target_full_path)
    end

    def current_file
      build unless package_exists?
      "#{@target}.min"
    end

    def build
      delete_previous_build
      create_new_build
    end

    def delete_previous_build
      File.delete(@target_full_path) if File.exists?(@target_full_path)
    end

    private
    def create_new_build
      if File.exists?(@target_full_path)
        log "Latest version already exists: #{@target_full_path}"
      else
        File.open(@target_full_path, "w") { |f| f.write(compressed_file) }
        log "Created #{@target_full_path}"
      end
    end

    def compressed_file
      compress_js(merged_file)
    end

    def merged_file
      merged_file = ""
      @sources.each { |source|
        if source =~ /\/\*$/
          Dir.glob("#{self.class.js_source_path}/#{source}.js").each { |s| merged_file += file_content(s) }
        else
          merged_file += file_content("#{self.class.js_source_path}/#{source}.js")
        end
      }
      merged_file
    end

    def file_content(file)
      log "Merging: #{file}"
      File.open("#{file}", "r") { |f| f.read + "\n" }
    end

    def compress_js(source)
      jsmin_path = "#{Rails.root}/vendor/plugins/js_packager/lib"
      tmp_path = "#{Rails.root}/tmp/#{@target}_packaged"

      # write out to a temp file
      File.open("#{tmp_path}_uncompressed.js", "w") { |f| f.write(source) }

      # compress file with JSMin library
      `ruby #{jsmin_path}/jsmin.rb <#{tmp_path}_uncompressed.js >#{tmp_path}_compressed.js \n`

      # read it back in and trim it
      result = ""
      File.open("#{tmp_path}_compressed.js", "r") { |f| result += f.read.strip }

      # delete temp files if they exist
      File.delete("#{tmp_path}_uncompressed.js") if File.exists?("#{tmp_path}_uncompressed.js")
      File.delete("#{tmp_path}_compressed.js") if File.exists?("#{tmp_path}_compressed.js")

      result
    end

    def log(message)
      self.class.log(message)
    end

    def self.log(message)
      puts message
    end

    def self.build_file_list(path, extension)
      re = Regexp.new(".#{extension}\\z")
      file_list = Dir.new(path).entries.delete_if { |x| !(x =~ re) }.map { |x| x.chomp(".#{extension}") }
      # reverse javascript entries so prototype comes first on a base rails app
      file_list.reverse! if extension == "js"
      file_list
    end

  end
end
