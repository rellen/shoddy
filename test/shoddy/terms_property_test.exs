defmodule Shoddy.TermsPropertyTest do
  use ExUnit.Case, async: true
  use ExUnitProperties

  alias Shoddy.Terms

  # A secret text that no shape can contain, because each shape contains only
  # the names of kinds, of atoms and of modules.
  @secret "s3cr3t-Ada"

  defp term_with_secrets do
    leaf =
      one_of([
        constant(@secret),
        atom(:alphanumeric),
        integer(),
        float(),
        constant(%{"name" => @secret})
      ])

    tree(leaf, fn child ->
      one_of([
        list_of(child, max_length: 3),
        map(list_of(child, max_length: 3), &List.to_tuple/1),
        map(child, &%ArgumentError{message: inspect(&1)}),
        map(child, &%File.Error{reason: &1, path: @secret})
      ])
    end)
  end

  describe "shape/2" do
    property "never contains a text of the term" do
      check all(term <- term_with_secrets(), depth <- integer(0..6)) do
        refute Terms.shape(term, depth: depth, fields: [:reason, :message, :path]) =~ @secret
      end
    end
  end
end
