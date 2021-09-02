function triealign(altype::BioAlignments.AbstractAlignment, trie::Trie{C, T}, sequence::S1, model::AffineGapScoreModel{Int}, callback::Function) where {C, T, S1}
    matrix = AlignmentMatrix(length(sequence) + 1, trie.max_depth + 1)

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
            value = trie[node_id].value
            callback(only_score -> traceback(altype, matrix, sequence, sequence2; only_score = only_score), value)
        end

        if isfork(node) || isleaf(node)
            push!(depth_stack, (node_id, last_depth))
            last_depth = 0

            if isleaf(node)
                was_leaf = true
            end
        end
    end
end


function triealign(altype::BioAlignments.AbstractAlignment, trie::Trie{C, T}, sequence::S1, model::AffineGapScoreModel{Int}) where {C, T, S1}
    S2      = Vector{C}
    results = Vector{PairwiseAlignmentResult{Int, S1, S2}}()

    callback(get_result, _) = push!(results, get_result(false))
    triealign(altype, trie, sequence, model, callback)

    return results
end

function triealign(altype::BioAlignments.AbstractAlignment, trie1::Trie{C1, T1}, trie2::Trie{C2, T2}, model::AffineGapScoreModel{Int}, callback::Function) where {C1, C2, T1, T2}
    matrix  = AlignmentMatrix(trie1.max_depth + 1, trie2.max_depth + 1)

    # trie1 -> hstep/hpop
    # trie2 -> wstep/wpop

    
end