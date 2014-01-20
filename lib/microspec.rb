module Kernel
  def describe(description, &block)
    tests = Context.new.parse(description, block)
    tests.run
  end
end
 
class Object
  def should
    Should.new(self, true)
  end
 
  def should_not
    Should.new(self, false)
  end
end
 
class Should
  def initialize(subject, value)
    @subject, @value = subject, value
  end

  def self.matcher(name, &block)
    define_method(name) do |*args|
      !(@value ^ @subject.instance_exec(*args, &block))
    end
  end

  def method_missing(method, *args)
    if method.to_s =~ /^be_(.+)$/
      !(@value ^ @subject.public_send("#{$1}?", *args))
    else
      !(@value ^ @subject.public_send(method, *args))
    end
  end

  def be(method, *args)
    !(@value ^ @subject.public_send(method, *args))
  end

  matcher(:include) { |item| include?(item) }
end

class Context
  def initialize
    @tests = {}
  end

  def parse(description, block)
    self.instance_eval(&block)
    Runner.new(description, @tests)
  end

  def it(description, &block)
    @tests[description] = block
  end
end

class Runner
  def initialize(description, tests)
    @description = description
    @tests = tests
    @success = @failures = 0
  end

  def run
    begin_time = Time.now
    puts "#{@description}"
    @tests.each_pair do |name, block|
      print " - #{name}"
      result = self.instance_eval(&block)
      result ? @success += 1 : @failure += 1
      puts result ? " PASS" : " FAIL"
    end
    @time = Time.now - begin_time
    show_results
  end

  def show_results
    puts "\nFinished tests in #{@time}s"
    puts "#{@tests.count} tests, #{@success} success, #{@failure} failure."
  end
end
