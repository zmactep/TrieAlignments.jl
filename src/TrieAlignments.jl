module TrieAlignments

export TrieNodeID, TrieNode, Trie,
       isroot, isleaf, isfork, isterminal,
       value, upper,
       AlignmentMatrix,
       triealign

using BioAlignments

include("trie.jl")
include("align.jl")
include("traceback.jl")
include("algorithm.jl")

end # module
