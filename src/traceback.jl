macro start_traceback()
    esc(quote
        i, j = Int(i), Int(j)
        anchor_point = (i, j)
        op = OP_START
    end)
end

macro finish_traceback()
    esc(quote
        push!(anchors, AlignmentAnchor(anchor_point, op))
        push!(anchors, AlignmentAnchor((i - 1, j - 1), OP_START))
        reverse!(anchors)
        pop!(anchors)
    end)
end

macro anchor(ex)
    esc(quote
        if op != $ex
            push!(anchors, AlignmentAnchor(anchor_point, op))
            op = $ex
            anchor_point = (i - 1, j - 1)
        end
        if ismatchop(op)
            i -= 1
            j -= 1
        elseif isinsertop(op)
            i -= 1
        elseif isdeleteop(op)
            j -= 1
        else
            @assert false
        end
    end)
end

function traceback(::GlobalAlignment, matrix::AlignmentMatrix, s, t)
    score = matrix.match[matrix.real_height, matrix.real_width]
    i, j = Int(matrix.real_height), Int(matrix.real_width)
    anchors = Vector{AlignmentAnchor}()

    @start_traceback
    while i > 1 || j > 1
        println(i, " ", j)
        if i == 1 || matrix.match[i, j] == matrix.delete[i, j]
            @anchor OP_DELETE
        elseif j == 1 || matrix.match[i, j] == matrix.insert[i, j]
            @anchor OP_INSERT
        else
            if s[i - 1] == t[j - 1]
                @anchor OP_SEQ_MATCH
            else
                @anchor OP_SEQ_MISMATCH
            end
        end
    end
    @finish_traceback

    PairwiseAlignmentResult(score, true, AlignedSequence(s, anchors), t)
end

function traceback(::LocalAlignment, matrix::AlignmentMatrix, s, t)
    score = 0
    i, j  = 0, 0
    for i_ in 1:matrix.real_height
        for j_ in 1:matrix.real_width
            if matrix.match[i_, j_] > score
                score = matrix.match[i_, j_]
                i, j = i_, j_
            end
        end
    end

    anchors = Vector{AlignmentAnchor}()

    @start_traceback
    while matrix.match[i, j] != 0 && (i > 1 || j > 1)
        if matrix.match[i, j] == matrix.delete[i, j]
            @anchor OP_DELETE
        elseif matrix.match[i, j] == matrix.insert[i, j]
            @anchor OP_INSERT
        else
            if s[i - 1] == t[j - 1]
                @anchor OP_SEQ_MATCH
            else
                @anchor OP_SEQ_MISMATCH
            end
        end
    end
    @finish_traceback

    PairwiseAlignmentResult(score, true, AlignedSequence(s, anchors), t)
end

# function traceback(::SemiGlobalAlignment, matrix::AlignmentMatrix, s, t)
#     score = 0
#     i, j  = 0, 0
#     for i_ in 1:matrix.real_height
#         if matrix.match[i_, matrix.real_width] > score
#             score = matrix.match[i_, matrix.real_width]
#             i = i_
#             j = matrix.real_width
#         end
#     end
#     for j_ in 1:matrix.real_width
#         if matrix.match[matrix.real_height, j_] > score
#             score = matrix.match[matrix.real_height, j_]
#             i = matrix.real_height
#             j = j_
#         end
#     end
#
#     anchors = Vector{AlignmentAnchor}()
#
#     @start_traceback
#     last_anchor = AlignmentAnchor((i - 1, j - 1), i == matrix.real_height ? OP_DELETE : OP_INSERT)
#     while matrix.match[i, j] != 0 && (i > 1 || j > 1)
#         if i == 1 || matrix.match[i, j] == matrix.delete[i, j]
#             @anchor OP_DELETE
#         elseif j == 1 || matrix.match[i, j] == matrix.insert[i, j]
#             @anchor OP_INSERT
#         else
#             if s[i - 1] == t[j - 1]
#                 @anchor OP_SEQ_MATCH
#             else
#                 @anchor OP_SEQ_MISMATCH
#             end
#         end
#     end
#     @finish_traceback
#     push!(anchors, last_anchor)
#
#     PairwiseAlignmentResult(score, true, AlignedSequence(s, anchors), t)
# end
