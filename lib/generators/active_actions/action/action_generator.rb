# frozen_string_literal: true

require 'rails/generators'

module ActiveActions::Generators
  class ActionGenerator < ::Rails::Generators::NamedBase
    source_root File.expand_path('templates', __dir__)

    def create_policy
      template('action.rb', File.join('app/actions', class_path, "#{file_name}.rb"))
    end
  end
end
