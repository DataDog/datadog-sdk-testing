require 'colorize'
require 'time'

require_relative 'utils/ci'
require_relative 'utils/skeleton'
require_relative 'utils/skip'
require_relative 'utils/wait'

# Colors don't work on Appveyor
String.disable_colorization = true if Gem.win_platform?

def section(name)
  timestamp = Time.now.utc.iso8601
  puts ''
  puts "[#{timestamp}] >>>>>>>>>>>>>> #{name} STAGE".black.on_white
  puts ''
end

def install_requirements(req_file, pip_options = nil, output = nil, use_venv = nil)
  pip_command = use_venv ? "#{ENV['SDK_HOME']}/venv/bin/pip" : 'pip'
  redirect_output = output ? "2>&1 >> #{output}" : ''
  pip_options = '' if pip_options.nil?
  sh "#{pip_command} install -r #{req_file} #{pip_options} #{redirect_output}"
end

def run_rake_task(task, flavor, common_task = nil)
  task_name = "ci:#{flavor}:#{task}"
  if Rake::Task.task_defined?(task_name)
    Rake::Task[task_name].invoke
  else
    task = common_task.nil? ? task : common_task
    Rake::Task["ci:common:#{task}"].invoke(flavor)
  end
end

namespace :ci do
  namespace :common do
    task :before_install do |t|
      section('BEFORE_INSTALL')
      # We use tempdir on Windows, no need to create it
      sh %(mkdir -p #{ENV['VOLATILE_DIR']}) unless Gem.win_platform?
      t.reenable
    end

    task :install, [:flavor] do |t, attr|
      section('INSTALL')

      flavor = attr[:flavor]
      use_venv = in_venv
      pip_command = use_venv ? 'venv/bin/pip' : 'pip'
      sdk_dir = ENV['SDK_HOME'] || Dir.pwd

      sh %(#{'python -m ' if Gem.win_platform?}#{pip_command} install --upgrade pip setuptools)
      install_requirements('requirements-test.txt',
                           "--cache-dir #{ENV['PIP_CACHE']}",
                           "#{ENV['VOLATILE_DIR']}/ci.log", use_venv)

      flavor_file = "#{flavor}/requirements.txt"
      reqs = if flavor && File.exist?(flavor_file)
               [flavor_file]
             else
               Dir.glob(File.join(sdk_dir, '**/requirements.txt')).reject do |path|
                 !%r{#{sdk_dir}/embedded/.*$}.match(path).nil? || !%r{#{sdk_dir}\/venv\/.*$}.match(path).nil?
               end
             end

      reqs.each do |req|
        install_requirements(req,
                             "--cache-dir #{ENV['PIP_CACHE']}",
                             "#{ENV['VOLATILE_DIR']}/ci.log", use_venv)
      end

      t.reenable
    end

    task :before_script do |t|
      section('BEFORE_SCRIPT')
      t.reenable
    end

    task :script do |t|
      section('SCRIPT')
      t.reenable
    end

    task :test, [:flavor] => :script do |_t, attr|
      flavor = attr[:flavor]
      Rake::Task['ci:common:run_tests'].invoke([flavor])
    end

    task :before_cache do |t|
      section('BEFORE_CACHE')
      t.reenable
    end

    task :cleanup do |t|
      section('CLEANUP')
      t.reenable
    end

    task :execute, [:flavor] do |_t, attr|
      exception = nil
      flavor = attr[:flavor]
      begin
        %w[before_install install before_script].each do |task|
          run_rake_task(task, flavor)
        end
        if ENV['SKIP_TEST']
          puts 'Skipping tests'.yellow
        else
          run_rake_task('script', flavor, 'test')
        end
        run_rake_task('before_cache', flavor)
      rescue => e
        exception = e
        puts "Failed task: #{e.class} #{e.message}".red
      end
      if ENV['SKIP_CLEANUP']
        puts 'Skipping cleanup, disposable environments are great'.yellow
      else
        run_rake_task('cleanup', flavor)
      end
      raise exception if exception
    end

    task :run_tests, [:flavor] do |t, attr|
      flavors = attr[:flavor]
      sdkhome = ENV['SDK_HOME'] || Dir.pwd
      filter = ENV['NOSE_FILTER'] || '1'

      nose_command = in_venv ? 'venv/bin/nosetests' : 'nosetests'
      nose = if flavors.include?('default')
               "(not requires) and #{filter}"
             else
               "(requires in ['#{flavors.join("','")}']) and #{filter}"
             end

      tests_directory, = integration_tests(sdkhome)
      flavors_group = flavors.join('|')
      unless flavors.include?('default')
        tests_directory = tests_directory.reject do |test|
          /.*(#{flavors_group}).*$/.match(test).nil?
        end
      end
      # Rake on Windows doesn't support setting the var at the beginning of the
      # command
      path = ''
      unless Gem.win_platform?
        # FIXME: make the other filters than param configurable
        # For integrations that cannot be easily installed in a
        # separate dir we symlink stuff in the rootdir
        path = %(PATH="#{ENV['INTEGRATIONS_DIR']}/bin:#{ENV['PATH']}" )
      end
      tests_directory.each do |testdir|
        sh %(#{path}#{nose_command} -s -v -A "#{nose}" #{testdir})
      end
      t.reenable
    end
  end
end
