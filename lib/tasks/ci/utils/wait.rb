require 'httparty'
require 'socket'
require 'time'
require 'timeout'

# helper class to wait for TCP/HTTP services to boot
class Wait
  DEFAULT_TIMEOUT = 10

  def self.check_port(port)
    Timeout.timeout(0.5) do
      begin
        s = TCPSocket.new('localhost', port)
        s.close
        return true
      rescue Errno::ECONNREFUSED, Errno::EHOSTUNREACH, EOFError, Errno::ECONNRESET
        return false
      end
    end
  rescue Timeout::Error
    return false
  end

  def self.check_url(url)
    Timeout.timeout(0.5) do
      begin
        r = HTTParty.get(url)
        return (200...300).cover? r.code
      rescue Errno::ECONNREFUSED, Errno::EHOSTUNREACH, EOFError, Errno::ECONNRESET
        return false
      end
    end
  rescue Timeout::Error
    return false
  end

  def self.check_file(file_path)
    File.exist?(file_path)
  end

  def self.check(smth)
    if smth.is_a? Integer
      check_port smth
    elsif smth.include? 'http'
      check_url smth
    else
      check_file smth
    end
  end

  def self.for(smth, max_timeout = DEFAULT_TIMEOUT)
    start_time = Time.now
    status = false
    n = 1
    puts "Trying #{smth}"
    loop do
      puts n.to_s
      status = check(smth)
      break if status || Time.now > start_time + max_timeout
      n += 1
      sleep 0.25
    end
    raise "Still not up after #{max_timeout}s" unless status
    puts 'Found!'
    status
  end
end
