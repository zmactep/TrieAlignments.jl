TrieNodeID = UInt

mutable struct TrieNode{C,T}
    value::Union{T,Nothing}
    parent::TrieNodeID
    terminal::Bool
    children::Dict{C,TrieNodeID}

    TrieNode{C,T}(parent = 0) where {C,T} = new(nothing, parent, false, Dict{C,TrieNodeID}())
end

function Base.setproperty!(n::TrieNode{C,T}, name::Symbol, v) where {C,T}
    if name != :value && name != :terminal
        error("setfield! immutable struct of type TrieNode cannot be changed")
    end
    setfield!(n, name, v)
end

Base.getindex(n::TrieNode{C,T}, key::C) where {C,T} = n.children[key]

Base.setindex!(n::TrieNode{C,T}, nid, key::C) where {C,T} = n.children[key] = nid

Base.haskey(n::TrieNode{C,T}, key::C) where {C,T} = haskey(n.children, key)

isleaf(n::TrieNode{C,T}) where {C,T} = isempty(n.children)

isfork(n::TrieNode{C,T}) where {C,T} = length(n.children) > 1

isroot(n::TrieNode{C, T}) where {C, T} = n.parent == 0

isterminal(n::TrieNode{C, T}) where {C, T} = n.terminal

value(n::TrieNode{C, T}) where {C, T} = n.value

mutable struct Trie{C,T}
    nodes::Vector{TrieNode{C,T}}
    max_depth::UInt

    Trie{C,T}() where {C,T} = new([TrieNode{C,T}()], 0)
end

Trie() = Trie{Char,Any}()

root(t::Trie{C,T}) where {C,T} = t[1]

Base.getindex(t::Trie{C,T}, key) where {C,T} = t.nodes[key]
Base.setindex!(t::Trie{C,T}, value::T, key) where {C,T} = push!(t, key, value)

Base.length(t::Trie{C,T}) where {C,T} = length(t.nodes)
Base.size(t::Trie{C,T}, dim) where {C,T} = size(t.nodes)
Base.eltype(::Type{Trie{C,T}}) where {C,T} = Tuple{Char, TrieNodeID}

function Base.push!(t::Trie{C,T}, key, value::T) where {C,T}
    node_id = 1
    for c in key
        node = t[node_id]
        if !haskey(node, c)
            push!(t.nodes, TrieNode{C,T}(node_id))
            node[c] = length(t)
        end
        node_id = node[c]
    end
    if t.max_depth < length(key)
        t.max_depth = length(key)
    end
    t[node_id].terminal = true
    t[node_id].value = value
end

macro fill_iterator_state(node_id)
    esc(quote
        for (child_char, child_id) in t[$node_id].children
            push!(state, (child_char, child_id))
        end
    end)
end

function Base.iterate(t::Trie{C,T}) where {C,T}
    state = Tuple{Char, TrieNodeID}[]

    @fill_iterator_state 1
    return iterate(t, state)
end

function Base.iterate(t::Trie{C,T}, state) where {C,T}
    isempty(state) && return nothing

    char, node_id = pop!(state)
    @fill_iterator_state node_id
    return (char, node_id), state
end
