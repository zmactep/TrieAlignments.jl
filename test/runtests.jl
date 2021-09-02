using Test
using BioSequences
using BioAlignments
using TrieAlignments

trie = Trie{DNA, Int}()
trie[dna"CAGCACTTGGATTCTCGG"] = 1
sequence = dna"CAGCGTGG"

model = AffineGapScoreModel(match = 1, mismatch = -1, gap_open = 0, gap_extend = -1)

result = triealign(SemiGlobalAlignment(), trie, sequence, model)[1]
print(result)