TrieAlignments
==============


Description
-----------

TrieAlignments provides rapid trie-based multiple pairwise alignments using [[Yakovlev P., 2019](https://link.springer.com/article/10.1134/S1064562419010198)]. This package is fully-compatible with a great [BioJulia](https://biojulia.net/) infrastructure.

Installation
------------

Install using general Julia process:
```julia
using Pkg
add("https://github.com/zmactep/TrieAlignments.jl.git")
```

Example
-------

```julia
using BioAlignments
using TrieAlignments

trie = Trie{Char, Int}()

trie["PLEASANTLY"] = 1
trie["PRTWPSEIN"] = 42

seq = "MEANLY"

model = AffineGapScoreModel(BLOSUM62, gap_open = -10, gap_extend = -1)

print(triealign(LocalAlignment(), trie, seq, model))
```

This will return:
```julia
PairwiseAlignmentResult{Int64,String,Array{Char,1}}[PairwiseAlignmentResult{Int64,String,Array{Char,1}}:
  score: 10
  seq: 2 EAN 4
         | |
  ref: 7 EIN 9
, PairwiseAlignmentResult{Int64,String,Array{Char,1}}:
  score: 12
  seq: 1 MEAN 4
          ||
  ref: 2 LEAS 5
]
```
