#!/usr/bin/env rake
# encoding: utf-8

require 'bundler'
require 'bundler/gem_tasks'
require 'rake/testtask'
require 'rubocop/rake_task'
require_relative 'tasks/maintainers'

# Rubocop
desc 'Run Rubocop lint checks'
task :rubocop do
  RuboCop::RakeTask.new
end

# lint the project
desc 'Run robocop linter'
task lint: [:rubocop]

# run tests
task default: [:test, :lint]

Rake::TestTask.new do |t|
  t.libs << 'test'
  t.pattern = 'test/unit/**/*_test.rb'
  t.warning = true
  t.verbose = true
  t.ruby_opts = ['--dev'] if defined?(JRUBY_VERSION)
end

namespace :test do
  task :isolated do
    Dir.glob('test/unit/*_test.rb').all? do |file|
      sh(Gem.ruby, '-w', '-Ilib:test', file)
    end or fail 'Failures'
  end

  Rake::TestTask.new(:functional) do |t|
    t.libs << 'test'
    t.pattern = 'test/functional/**/*_test.rb'
    t.warning = true
    t.verbose = true
    t.ruby_opts = ['--dev'] if defined?(JRUBY_VERSION)
  end

  task :resources do
    tests = Dir['test/resource/*_test.rb']
    return if tests.empty?
    sh(Gem.ruby, 'test/docker_test.rb', *tests)
  end

  task :integration do
    concurrency = ENV['CONCURRENCY'] || 1
    os = ENV['OS'] || ''
    sh('sh', '-c', "cd #{path} && bundle exec kitchen test -c #{concurrency} #{os}")
  end

  task :ssh, [:target] do |_t, args|
    tests_path = File.join(File.dirname(__FILE__), 'test', 'integration', 'test', 'integration', 'default')
    key_files = ENV['key_files'] || File.join(ENV['HOME'], '.ssh', 'id_rsa')

    sh_cmd =  "bin/inspec exec #{tests_path}/"
    sh_cmd += ENV['test'] ? "#{ENV['test']}_spec.rb" : '*'
    sh_cmd += " --sudo" unless args[:target].split('@')[0] == 'root'
    sh_cmd += " -t ssh://#{args[:target]}"
    sh_cmd += " --key_files=#{key_files}"
    sh_cmd += " --format=#{ENV['format']}" if ENV['format']

    sh('sh', '-c', sh_cmd)
  end
end

# Print the current version of this gem or update it.
#
# @param [Type] target the new version you want to set, or nil if you only want to show
def inspec_version(target = nil)
  path = 'lib/inspec/version.rb'
  require_relative path.sub(/.rb$/, '')

  nu_version = target.nil? ? '' : " -> #{target}"
  puts "Inspec: #{Inspec::VERSION}#{nu_version}"

  unless target.nil?
    raw = File.read(path)
    nu = raw.sub(/VERSION.*/, "VERSION = '#{target}'.freeze")
    File.write(path, nu)
    load(path)
  end
end

# Check if a command is available
#
# @param [Type] x the command you are interested in
# @param [Type] msg the message to display if the command is missing
def require_command(x, msg = nil)
  return if system("command -v #{x} || exit 1")
  msg ||= 'Please install it first!'
  puts "\033[31;1mCan't find command #{x.inspect}. #{msg}\033[0m"
  exit 1
end

# Check if a required environment variable has been set
#
# @param [String] x the variable you are interested in
# @param [String] msg the message you want to display if the variable is missing
def require_env(x, msg = nil)
  exists = `env | grep "^#{x}="`
  return unless exists.empty?
  puts "\033[31;1mCan't find environment variable #{x.inspect}. #{msg}\033[0m"
  exit 1
end

# Check the requirements for running an update of this repository.
def check_update_requirements
  require_command 'git'
  require_command 'github_changelog_generator', "\n"\
    "For more information on how to install it see:\n"\
    "  https://github.com/skywinder/github-changelog-generator\n"
  require_env 'CHANGELOG_GITHUB_TOKEN', "\n"\
    "Please configure this token to make sure you can run all commands\n"\
    "against GitHub.\n\n"\
    "See github_changelog_generator homepage for more information:\n"\
    "  https://github.com/skywinder/github-changelog-generator\n"
end

# Show the current version of this gem.
desc 'Show the version of this gem'
task :version do
  inspec_version
end

desc 'Generate the changelog'
task :changelog do
  require_relative 'lib/inspec/version'
  system "github_changelog_generator -u chef -p inspec --future-release #{Inspec::VERSION} --since-tag 0.7.0"
end

# Update the version of this gem and create an updated
# changelog. It covers everything short of actually releasing
# the gem.
desc 'Bump the version of this gem'
task :bump_version, [:version] do |_, args|
  v = args[:version] || ENV['to']
  fail "You must specify a target version!  rake bump_version to=1.2.3" if v.empty?
  check_update_requirements
  inspec_version(v)
  Rake::Task['changelog'].invoke
end
