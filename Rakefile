require 'rubygems'
require 'bundler/setup'

require 'bundler/gem_tasks'

desc 'cleanup rcov, doc dirs'
task :clean do
  rm_rf 'coverage'
  rm_rf 'doc'
end

require 'rspec/core/rake_task'
RSpec::Core::RakeTask.new(:spec)
task test: :spec

require 'rubocop/rake_task'
RuboCop::RakeTask.new

require 'yard'
YARD::Rake::YardocTask.new

task default: [:spec, :rubocop]
