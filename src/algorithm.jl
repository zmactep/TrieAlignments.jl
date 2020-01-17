function triealign(trie::Trie{C, T}, sequence::S1, model::AffineGapScoreModel{Int}) where {C, T, S1}
    S2      = Vector{C}
    results = Vector{PairwiseAlignmentResult{Int, S1, S2}}()

    max_depth = 100
    matrix    = AlignmentMatrix(max_depth, max_depth)

    for c in sequence
        hstep!(matrix, model, "", c)
    end

    was_leaf         = false
    depth_stack      = Vector{Tuple{TrieNodeID, Int}}()
    current_sequence = Vector{C}(undef, max_depth)
    current_pointer  = 0
    last_depth       = 0
    for (char, node_id) in trie
        node = trie[node_id]
        if was_leaf
            while last(depth_stack)[1] != node.parent
                _, count = pop!(depth_stack)
                wpop!(matrix, count)
                current_pointer -= count
            end
        end
        was_leaf = false

        current_pointer += 1
        last_depth      += 1
        current_sequence[current_pointer] = char
        wstep!(matrix, model, sequence, char)

        if isfork(node) || isleaf(node)
            push!(depth_stack, (node_id, last_depth))
            last_depth = 0

            if isleaf(node)
                was_leaf = true
                sequence2 = current_sequence[1:current_pointer]
                push!(results, traceback(matrix, sequence, sequence2))
            end

        end
    end
    return results
end
