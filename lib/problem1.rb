#!/usr/bin/env ruby

require 'thor'

#### source algorithm
# http://www.geeksforgeeks.org/write-a-c-program-to-print-all-permutations-of-a-given-string/

# creates a tree of string possibilities. Each parent creates sub-permutations of the strings used to
# create them. Leaf nodes contain the solutions.
module Problem1

  ## prints all permutations of a given string
  class Permutations
    attr_accessor :output

    ## entry point - starts the recursion
    def permutations(input)
      return [] if input.empty?
      [permute(0,input)].flatten
    end

    ## does a sub-permutation of given string, starting at given position.
    ## we are a leaf node when we are at the end of the string and no more sub-permutations
    ## are necessary
    ## params
    # input - input string
    # level - position in input to start sub-permutation
    def permute(level, input)
      return [input] if level == input.length - 1

      results = []
      for i in level..(input.length-1)
        foo = permute(level+1, swap(input, level, i))
        results << foo
      end
      results
    end

    ## swap two characters in a string and output the result
    ## do not modify the input string
    def swap(input, position1, position2)
      output = input.clone
      output[position2] = input[position1]
      output[position1] = input[position2]
      output
    end
    
  end

  ## command line parsing
  ## enables `problem1 help` on the command line
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

# entry point when this is run as a script
Problem1::PermutationsCli.start(ARGV) unless ENV['INSIDE_TEST']
