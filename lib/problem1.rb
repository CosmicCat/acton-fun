require 'thor'

module Problem1

  class Permutations
    attr_accessor :output
    
    def permutations(input)
      return [] if input.empty?
      [permute(0,input)].flatten
    end

    def permute(level, input)
      return [input] if level == input.length - 1

      results = []
      for i in level..(input.length-1)
        foo = permute(level+1, swap(input, level, i))
        results << foo
      end
      results
    end

    def swap(input, position1, position2)
      output = input.clone
      output[position2] = input[position1]
      output[position1] = input[position2]
      output
    end
    
  end

  class PermutationsCli < Thor
    desc "permutations -s STRING", "Print all permutations of given string"
    option :string, :required => true, :aliases => :s, :desc => 'input string'
    option :ignore, :aliases => :i, :desc => "filter dupes on output" 
    def permutations()
      results = Permutations.new.permutations(options[:string].dup)
      results = results.uniq if options[:ignore]
      results.each {|r| puts r}
    end
  end
  
end

Problem1::PermutationsCli.start(ARGV) unless ENV['INSIDE_TEST']
