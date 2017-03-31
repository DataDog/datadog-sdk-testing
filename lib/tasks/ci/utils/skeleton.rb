require 'securerandom'


def sed(source, op, a, b, mods)
  cmd = "#{op}/#{a}"
  cmd = "#{cmd}/#{b}" unless b.nil? || b.empty?
  sh "sed -i '' \"#{cmd}/#{mods}\" #{source} 2> /dev/null || sed -i \"#{cmd}/#{mods}\" #{source}"
end

def copy_skeleton(source, dst, integration)
  gem_home = Bundler.rubygems.find_name('datadog-sdk-testing').first.full_gem_path
  sh "cp #{gem_home}/#{source} #{ENV['SDK_HOME']}/#{integration}/#{dst}"
end

def create_integration_path(integration)
  sh "mkdir -p #{ENV['SDK_HOME']}/#{integration}/ci"
end

def rename_skeleton(integration)
  capitalized = integration.capitalize
  Dir.glob("#{ENV['SDK_HOME']}/#{integration}/**/*") do |f|
    if File.file?(f)
      sed(f, 's', 'skeleton', integration.to_s, 'g')
      sed(f, 's', 'Skeleton', capitalized.to_s, 'g')
    end
  end
end

def replace_guid(integration)
  guid = SecureRandom.uuid
  f = "#{ENV['SDK_HOME']}/#{integration}/manifest.json"
  sed(f, 's', 'guid_replaceme', guid.to_s, 'g')
end

def move_file(src, dst)
  File.delete(dst)
  File.rename(src, dst)
end

def add_travis_flavor(flavor, version = nil)
  new_file = "#{ENV['SDK_HOME']}/.travis.yml.new"
  version = 'latest' if version.nil?
  added = false
  File.open(new_file, 'w') do |fo|
    File.foreach("#{ENV['SDK_HOME']}/.travis.yml") do |line|
      if !added && line =~ /# END OF TRAVIS MATRIX|- TRAVIS_FLAVOR=#{flavor}/
        fo.puts "    - TRAVIS_FLAVOR=#{flavor} FLAVOR_VERSION=#{version}"
        added = true
      end
      fo.puts line
    end
  end
  move_file(new_file, "#{ENV['SDK_HOME']}/.travis.yml")
end

def add_circleci_flavor(flavor)
  new_file = "#{ENV['SDK_HOME']}/circle.yml.new"
  File.open(new_file, 'w') do |fo|
    File.foreach("#{ENV['SDK_HOME']}/circle.yml") do |line|
      fo.puts "        - rake ci:run[#{flavor}]" if line =~ /bundle\ exec\ rake\ requirements/
      fo.puts line
    end
  end
  move_file(new_file, "#{ENV['SDK_HOME']}/circle.yml")
end

def generate_skeleton(integration)
  copy_skeleton('lib/config/ci/skeleton.rake', "ci/#{integration}.rake", integration)
  copy_skeleton('lib/config/manifest.json', 'manifest.json', integration)
  copy_skeleton('lib/config/check.py', 'check.py', integration)
  copy_skeleton('lib/config/test_skeleton.py', "test_#{integration}.py", integration)
  copy_skeleton('lib/config/metadata.csv', 'metadata.csv', integration)
  copy_skeleton('lib/config/requirements.txt', 'requirements.txt', integration)
  copy_skeleton('lib/config/README.md', 'README.md', integration)
  copy_skeleton('lib/config/CHANGELOG.md', 'CHANGELOG.md', integration)
  copy_skeleton('lib/config/conf.yaml.example', 'conf.yaml.example', integration)
end

def create_skeleton(integration)
  if File.directory?("#{ENV['SDK_HOME']}/#{integration}")
    puts "directory already exists for #{integration} - bailing out."
    return
  end

  puts "generating skeleton files for #{integration}"
  create_integration_path(integration.to_s)
  generate_skeleton(integration.to_s)
  rename_skeleton(integration.to_s)

  replace_guid(integration.to_s)

  add_travis_flavor(integration)
  add_circleci_flavor(integration)
end
