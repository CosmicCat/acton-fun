require "problem1"

RSpec.describe Problem1::Permutations do

  it "shows all permutations of string" do
    p1 = Problem1::Permutations.new
    permutations = p1.permutations('abc').sort

    expect(permutations).to eq([
                                 "abc",
                                 "acb",
                                 "bac",
                                 "bca",
                                 "cab",
                                 "cba",
                               ])
  end

  it "works on length 1 strings" do
    p1 = Problem1::Permutations.new
    permutations = p1.permutations('a').sort

    expect(permutations).to eq([
                                 "a",
                               ])
  end

  it "returns an empty list given an empty string" do
    p1 = Problem1::Permutations.new
    permutations = p1.permutations('')

    expect(permutations).to eq([
                               ])    
  end

  it "swaps specified characters in a string" do
    p1 = Problem1::Permutations.new
    expect(p1.swap('foobar', 0, 2)).to eq('oofbar')
  end

end
