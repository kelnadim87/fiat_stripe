module FiatStripe
  class Engine < ::Rails::Engine
    isolate_namespace FiatStripe

    # This allows an app to override model / controller code using decorator pattern: https://edgeguides.rubyonrails.org/engines.html#a-note-on-decorators-and-loading-code
    config.to_prepare do
      Dir.glob(Rails.root + "app/decorators/**/*_decorator*.rb").each do |c|
        require_dependency(c)
      end
    end

    initializer :append_migrations do |app|
      unless app.root.to_s.match root.to_s
        config.paths["db/migrate"].expanded.each do |expanded_path|
          app.config.paths["db/migrate"] << expanded_path
        end
      end
    end
  end
end
