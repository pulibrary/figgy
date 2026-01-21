
# Move RDF triples into a hash for easy testing
def select_triples(reader, value)
  reader.triples.select { |t| t[0].value == value }
        .map { |t| { t[1].value => t[2].value } }
        .inject do |acc, h|
    predicate = h.keys.first
    object = h.values.first
    acc[predicate] = if acc[predicate]
                        # There are multiple terms with the same predicate
                        # so add object values to an array
                        Array.wrap(acc[predicate]) << object
    else
                        # the is only only a single term with this predicate
                        # so it's is a single object value
                        object
    end

    acc
  end
end
