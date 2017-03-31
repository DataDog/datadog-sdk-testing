def travis_pr?
  !ENV['TRAVIS'].nil? && ENV['TRAVIS_EVENT_TYPE'] == 'pull_request'
end

def can_skip?
  return false, [] unless travis_pr?

  modified_checks = []
  puts "Comparing #{ENV['TRAVIS_PULL_REQUEST_SHA']} with #{ENV['TRAVIS_BRANCH']}"
  git_output = `git diff --name-only #{ENV['TRAVIS_BRANCH']}...#{ENV['TRAVIS_PULL_REQUEST_SHA']}`
  puts "Git diff: \n#{git_output}"
  git_output.each_line do |filename|
    filename.strip!
    puts filename
    return false, [] if filename.split('/').length < 2

    check_name = filename.split('/')[0]
    modified_checks << check_name unless modified_checks.include? check_name
  end
  [true, modified_checks]
end
