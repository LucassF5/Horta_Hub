# Permite encadear verificações de que nada mudou: `to not_change(A, :count).and not_change(B, :count)`.
RSpec::Matchers.define_negated_matcher :not_change, :change
