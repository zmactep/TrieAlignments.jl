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

function hpop!(matrix::AlignmentMatrix, count::Int)
    @assert (count > 0) "Trying to decrease matrix height by negative number"
    @assert (matrix.real_height - count ≥ 1) "Trying to step out of matrix height"
    matrix.real_height -= count
end

function wpop!(matrix::AlignmentMatrix, count::Int)
    @assert (count > 0) "Trying to decrease matrix width by negative number"
    @assert (matrix.real_width - count ≥ 1) "Trying to step out of matrix width"
    matrix.real_width -= count
end

# Fill cells by Needleman-Wunsch

macro fill_matrix_nw(i, j)
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

# Fill cells by Smith-Waterman

macro fill_matrix_sw(i, j)
    esc(quote
        matrix.insert[i, j] = model.gap_extend +
                              max(matrix.insert[i - 1, j],
                                  matrix.match[i - 1, j] + model.gap_open)

        matrix.delete[i, j] = model.gap_extend +
                              max(matrix.delete[i, j - 1],
                                  matrix.match[i, j - 1] + model.gap_open)

        matrix.match[i, j] = max(0,
                                 matrix.insert[i, j],
                                 matrix.delete[i, j],
                                 matrix.match[i - 1, j - 1] + model.submat[c, d])
    end)
end

# Global alignment

function hstep!(::GlobalAlignment, matrix::AlignmentMatrix, model::AffineGapScoreModel{Int}, wseq, hchar)
    @assert (matrix.real_height < size(matrix.match)[1]) "Trying to step out of matrix height"
    matrix.real_height += 1
    i = Int(matrix.real_height)
    matrix.match[i, 1] = model.gap_open + (i - 1) * model.gap_extend
    for j in 2:matrix.real_width
        c, d = hchar, wseq[j - 1]
        @fill_matrix_nw i j
    end
end

function wstep!(::GlobalAlignment, matrix::AlignmentMatrix, model::AffineGapScoreModel{Int}, hseq, wchar)
    @assert (matrix.real_width < size(matrix.match)[2]) "Trying to step out of matrix width"
    matrix.real_width += 1
    j = Int(matrix.real_width)
    matrix.match[1, j] = model.gap_open + (j - 1) * model.gap_extend
    for i in 2:matrix.real_height
        c, d = hseq[i - 1], wchar
        @fill_matrix_nw i j
    end
end

# Semiglobal alignment

function hstep!(::SemiGlobalAlignment, matrix::AlignmentMatrix, model::AffineGapScoreModel{Int}, wseq, hchar)
    @assert (matrix.real_height < size(matrix.match)[1]) "Trying to step out of matrix height"
    matrix.real_height += 1
    i = Int(matrix.real_height)
    matrix.match[i, 1] = 0
    for j in 2:matrix.real_width
        c, d = hchar, wseq[j - 1]
        @fill_matrix_nw i j
    end
end

function wstep!(::SemiGlobalAlignment, matrix::AlignmentMatrix, model::AffineGapScoreModel{Int}, hseq, wchar)
    @assert (matrix.real_width < size(matrix.match)[2]) "Trying to step out of matrix width"
    matrix.real_width += 1
    j = Int(matrix.real_width)
    matrix.match[1, j] = 0
    for i in 2:matrix.real_height
        c, d = hseq[i - 1], wchar
        @fill_matrix_nw i j
    end
end

# Local alignment

function hstep!(::LocalAlignment, matrix::AlignmentMatrix, model::AffineGapScoreModel{Int}, wseq, hchar)
    @assert (matrix.real_height < size(matrix.match)[1]) "Trying to step out of matrix height"
    matrix.real_height += 1
    i = Int(matrix.real_height)
    matrix.match[i, 1] = 0
    for j in 2:matrix.real_width
        c, d = hchar, wseq[j - 1]
        @fill_matrix_sw i j
    end
end

function wstep!(::LocalAlignment, matrix::AlignmentMatrix, model::AffineGapScoreModel{Int}, hseq, wchar)
    @assert (matrix.real_width < size(matrix.match)[2]) "Trying to step out of matrix width"
    matrix.real_width += 1
    j = Int(matrix.real_width)
    matrix.match[1, j] = 0
    for i in 2:matrix.real_height
        c, d = hseq[i - 1], wchar
        @fill_matrix_sw i j
    end
end
