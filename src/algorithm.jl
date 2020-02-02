function triealign(altype::BioAlignments.AbstractAlignment, trie::Trie{C, T}, sequence::S1, model::AffineGapScoreModel{Int}) where {C, T, S1}
    S2      = Vector{C}
    results = Vector{PairwiseAlignmentResult{Int, S1, S2}}()

    matrix    = AlignmentMatrix(length(sequence) + 1, trie.max_depth + 1)

    for c in sequence
        hstep!(altype, matrix, model, "", c)
    end
    current_sequence = Vector{C}(undef, trie.max_depth)

    was_leaf         = false
    depth_stack      = Vector{Tuple{TrieNodeID, Int}}()
    current_depth    = 0
    last_depth       = 0
    for (char, node_id) in trie
        node = trie[node_id]
        if was_leaf
          while length(depth_stack) > 0 && last(depth_stack)[1] != node.parent
                _, count = pop!(depth_stack)
                wpop!(matrix, count)
                current_depth -= count
            end
        end
        was_leaf = false
        current_depth += 1
        last_depth    += 1

        current_sequence[current_depth] = char
        wstep!(altype, matrix, model, sequence, char)

        if isterminal(node)
            sequence2 = current_sequence[1:current_depth]
            push!(results, traceback(altype, matrix, sequence, sequence2))
        end

        if isfork(node) || isleaf(node)
            push!(depth_stack, (node_id, last_depth))
            last_depth = 0

            if isleaf(node)
                was_leaf = true
            end
        end
    end
    return results
end
