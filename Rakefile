require "bundler/gem_tasks"
require "rake/testtask"

Rake::TestTask.new(:test) do |t|
  t.libs << "test"
  t.test_files = FileList["test/test_*.rb", "test/spam_stream_resistance/test_*.rb"]
end

task :default => :test

