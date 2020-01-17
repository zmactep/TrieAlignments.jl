mutable struct AlignmentMatrix
    match::Array{Int, 2}
    insert::Array{Int, 2}
    delete::Array{Int, 2}
    real_width::UInt
    real_height::UInt

    AlignmentMatrix(max_height, max_width) =
      new(zeros(Int, max_height, max_width),
          fill(typemin(Int), max_height, max_width),
          fill(typemin(Int), max_height, max_width),
          1, 1)
end

macro fill_matrix(i, j)
    esc(quote
        matrix.insert[i, j] = model.gap_extend +
                              max(matrix.insert[i - 1, j],
                                  matrix.match[i - 1, j] + model.gap_open)

        matrix.delete[i, j] = model.gap_extend +
                              max(matrix.delete[i, j - 1],
                                  matrix.match[i, j - 1] + model.gap_open)

        matrix.match[i, j] = max(matrix.insert[i, j],
                                 matrix.delete[i, j],
                                 matrix.match[i - 1, j - 1] + model.submat[c, d])
    end)
end

function hpop!(matrix::AlignmentMatrix, count::Int)
    @assert (count > 0) false
    @assert (matrix.real_height - count ≥ 1) false
    matrix.real_height -= count
end

function wpop!(matrix::AlignmentMatrix, count::Int)
    @assert (count > 0) false
    @assert (matrix.real_width - count ≥ 1) false
    matrix.real_width -= count
end

function hstep!(matrix::AlignmentMatrix, model::AffineGapScoreModel{Int}, wseq, hchar)
    @assert (matrix.real_width < size(matrix.match)[2]) false
    matrix.real_height += 1
    i = Int(matrix.real_height)
    matrix.match[i, 1] = model.gap_open + (i - 1) * model.gap_extend
    for j in 2:matrix.real_width
        c, d = hchar, wseq[j - 1]
        @fill_matrix i j
    end
end

function wstep!(matrix::AlignmentMatrix, model::AffineGapScoreModel{Int}, hseq, wchar)
    @assert (matrix.real_height < size(matrix.match)[1]) false
    matrix.real_width += 1
    j = Int(matrix.real_width)
    matrix.match[1, j] = model.gap_open + (j - 1) * model.gap_extend
    for i in 2:matrix.real_height
        c, d = hseq[i - 1], wchar
        @fill_matrix i j
    end
end

macro start_traceback()
    esc(quote
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

function traceback(matrix::AlignmentMatrix, s, t)
    score = matrix.match[matrix.real_height, matrix.real_width]
    i, j = Int(matrix.real_height), Int(matrix.real_width)
    anchors = Vector{AlignmentAnchor}()

    @start_traceback
    while i > 1 || j > 1
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
