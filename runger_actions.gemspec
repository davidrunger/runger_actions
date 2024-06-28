# frozen_string_literal: true

require_relative 'lib/runger_actions/version'

Gem::Specification.new do |spec|
  spec.name          = 'runger_actions'
  spec.version       = RungerActions::VERSION
  spec.authors       = ['David Runger']
  spec.email         = ['davidjrunger@gmail.com']

  spec.summary       = 'Organize (and validate) the business logic of your Rails application.'
  spec.description   = 'Organize (and validate) the business logic of your Rails application.'
  spec.homepage      = 'https://github.com/davidrunger/runger_actions'
  spec.license       = 'MIT'

  required_ruby_version = File.read('.ruby-version').rstrip.sub(/\A(\d+\.\d+)\.\d+\z/, '.0')
  spec.required_ruby_version = ">= #{required_ruby_version}"

  spec.metadata['rubygems_mfa_required'] = 'true'
  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = 'https://github.com/davidrunger/runger_actions'
  spec.metadata['changelog_uri'] =
    'https://github.com/davidrunger/runger_actions/blob/main/CHANGELOG.md'

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files =
    Dir.chdir(File.expand_path(__dir__)) do
      `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
    end
  spec.require_paths = ['lib']

  spec.add_runtime_dependency('memo_wise', '>= 1.7', '< 2')
  spec.add_runtime_dependency('rails', '>= 6', '< 8')
  spec.add_runtime_dependency('shaped', '>= 0.9', '< 0.13')
end
