module TrieAlignments

export TrieNodeID, TrieNode, Trie,
       AlignmentMatrix,
       triealign

using BioAlignments

include("trie.jl")
include("align.jl")
include("traceback.jl")
include("algorithm.jl")

end # module
