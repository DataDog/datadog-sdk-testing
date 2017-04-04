Gem::Specification.new do |s|
  s.name          = 'datadog-sdk-testing'
  s.version       = '0.6.1'
  s.summary       = 'Datadog Integration SDK testing/scaffolding facilities.'
  s.description   = 'Datadog Integration SDK testing/scaffolding gem'
  s.authors       = ['Jaime Fullaondo']
  s.email         = 'jaime.fullaondo@datadoghq.com'
  s.require_paths = ['lib/tasks/']
  s.files         = Dir['lib/**/*'] + ['README.md', 'LICENSE']
  s.homepage      = 'https://rubygems.org/gems/datadog-sdk-testing'
  s.license       = 'MIT'
  s.add_runtime_dependency 'colorize', '~> 0.8'
  s.add_runtime_dependency 'httparty', '~> 0.14'
  s.add_runtime_dependency 'rake', '~> 11.0'
  s.add_runtime_dependency 'rubocop', '~> 0.38'
end
