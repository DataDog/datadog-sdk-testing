def sleep_for(secs)
  puts "Sleeping for #{secs}s".blue
  sleep(secs)
end

def wait_on_docker_logs(c_name, max_wait, *include_array)
  count = 0
  logs = `docker logs #{c_name} 2>&1`
  puts "Waiting for #{c_name} to come up"

  until count == max_wait || include_array.any? { |phrase| logs.include?(phrase) }
    sleep(1)
    logs = `docker logs #{c_name} 2>&1`
    count += 1
  end

  if include_array.any? { |phrase| logs.include?(phrase) }
    puts "#{c_name} is up!"
  else
    sh %(docker logs #{c_name} 2>&1)
    raise
  end
end

def in_venv
  ENV['RUN_VENV'] && ENV['RUN_VENV'] == 'true' ? true : false
end

def test_files(sdk_dir)
  Dir.glob(File.join(sdk_dir, '**/test_*.py')).reject do |path|
    !%r{#{sdk_dir}/embedded/.*$}.match(path).nil? || !%r{#{sdk_dir}\/venv\/.*$}.match(path).nil?
  end
end

def integration_tests(root_dir)
  sdk_dir = ENV['SDK_HOME'] || root_dir
  integrations = []
  untested = []
  testable = []
  test_files(sdk_dir).each do |check|
    integration_name = /test_((\w|_)+).py$/.match(check)[1]
    integrations.push(integration_name)
    if Dir.exist?(File.join(sdk_dir, integration_name))
      testable.push(check)
    else
      untested.push(check)
    end
  end
  [testable, untested]
end

def check_travis_flavor(flavor, version = nil)
  version = 'latest' if version.nil?
  File.foreach("#{ENV['SDK_HOME']}/.travis.yml") do |line|
    return false if line =~ /- TRAVIS_FLAVOR=#{flavor} FLAVOR_VERSION=#{version}/
  end
  true
end
