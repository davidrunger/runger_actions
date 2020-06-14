# frozen_string_literal: true

require_relative 'lib/active_actions/version'

Gem::Specification.new do |spec|
  spec.name          = 'active_actions'
  spec.version       = ActiveActions::VERSION
  spec.authors       = ['David Runger']
  spec.email         = ['davidjrunger@gmail.com']

  spec.summary       = 'Organize (and validate) the business logic of your Rails application.'
  spec.description   = 'Organize (and validate) the business logic of your Rails application.'
  spec.homepage      = 'https://github.com/davidrunger/active_actions'
  spec.license       = 'MIT'
  spec.required_ruby_version = Gem::Requirement.new('>= 2.3.0')

  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = 'https://github.com/davidrunger/active_actions'
  spec.metadata['changelog_uri'] =
    'https://github.com/davidrunger/active_actions/blob/master/CHANGELOG.md'

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files =
    Dir.chdir(File.expand_path(__dir__)) do
      `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
    end
  spec.require_paths = ['lib']

  spec.add_runtime_dependency 'memoist', '~> 0.16'
  spec.add_runtime_dependency 'rails', '~> 6.0'
end
