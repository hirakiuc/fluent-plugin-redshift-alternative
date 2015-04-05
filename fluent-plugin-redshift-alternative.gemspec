Gem::Specification.new do |spec|
  spec.name          = 'fluent-plugin-redshift-alternative'
  spec.version       = '0.1.0'
  spec.authors       = ['hirakiuc']
  spec.email         = ['hirakiuc@gmail.com']

  spec.summary       = 'Amazon Redshift output plugin for Fluentd'
  spec.description   = 'Yet Another Amazon Redshift output plugin for Fluentd'
  spec.homepage      = "TODO: Put your gem's website or public repo URL here."
  spec.license       = 'MIT'

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_dependency 'fluentd', '~> 0.10.0'
  spec.add_dependency 'aws-sdk', '~> 2'
  spec.add_dependency 'pg', '~> 0.18.0'
  spec.add_development_dependency 'bundler', '~> 1.9'
  spec.add_development_dependency 'rake', '~> 10.0'
  spec.add_development_dependency 'simplecov'
  spec.add_development_dependency 'flexmock'
  spec.add_development_dependency 'timecop'

  spec.add_development_dependency 'rspec'
  spec.add_development_dependency 'rspec-mocks'
  spec.add_development_dependency 'webmock'
  spec.add_development_dependency 'rubocop'
  spec.add_development_dependency 'yard'
  spec.add_development_dependency 'pry-byebug'
end
