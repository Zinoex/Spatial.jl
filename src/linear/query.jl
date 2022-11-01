Base.iterate(index::LinearIndex) = iterate(index.container)
Base.iterate(index::LinearIndex, state) = iterate(index.container, state)

function findfirst(query, index::LinearIndex) 
    for elem in index
        if satisfy(query, elem)
            return elem
        end
    end

    return nothing
end

findall(query, index::LinearIndex) = [elem for elem in index if satisfy(query, elem)]