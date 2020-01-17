module TrieAlign

export TrieNodeID, TrieNode, Trie,
       AlignmentMatrix,
       triealign

using BioAlignments

include("trie.jl")
include("align.jl")
include("algorithm.jl")

end # module
