defmodule Shoddy.TermsTest do
  use ExUnit.Case, async: true

  import Shoddy.Terms

  doctest Shoddy.Terms

  defmodule Wrapper do
    @moduledoc false
    defexception [:class, :errors, :reason, :message]
  end

  describe "shape/2" do
    test "shows the kind of each basic value" do
      ref = make_ref()

      assert shape(nil) == "nil"
      assert shape(true) == "true"
      assert shape(:ok) == ":ok"
      assert shape("text") == "binary"
      assert shape(<<1::3>>) == "bitstring"
      assert shape(7) == "integer"
      assert shape(1.5) == "float"
      assert shape(self()) == "pid"
      assert shape(ref) == "reference"
      assert shape(&Function.identity/1) == "function"
      assert Port.list() |> hd() |> shape() == "port"
    end

    test "shows an empty list, and hides the elements of another list" do
      assert shape([]) == "[]"
      assert shape(["Ada", "Grace"]) == "list"
      assert shape([1 | 2]) == "list"
    end

    test "shows the size of a map and the module of a struct" do
      assert shape(%{}) == "map(0)"
      assert shape(%{"name" => "Ada", "email" => "ada@example.com"}) == "map(2)"
      assert shape(~D[2026-11-28]) == "%Date{}"
    end

    test "opens a tuple of each size, and shows the size of a tuple at the last level" do
      assert shape({1, 2, 3, 4, 5, 6, 7}) == "{integer, integer, integer, integer, integer, integer, integer}"
      assert shape({}, depth: 0) == "tuple(0)"
    end

    test "shows the fields of an exception that contain an atom, a tuple or an exception" do
      inner = %File.Error{reason: :eacces, path: "/secret"}
      error = %Wrapper{class: :invalid, reason: {:file, inner}, message: "the email ada@example.com"}

      assert shape(error, fields: [:class, :reason, :message]) ==
               "Shoddy.TermsTest.Wrapper(class: :invalid, reason: {:file, File.Error(reason: :eacces)})"
    end

    test "does not show nil, true, false and text in a field" do
      assert shape(%Wrapper{class: true, reason: nil, message: "Ada"}, fields: [:class, :reason, :message]) ==
               "Shoddy.TermsTest.Wrapper"
    end

    test "shows each exception of a list, up to five" do
      errors = for n <- 1..7, do: %Wrapper{class: :"error_#{n}"}
      error = %Wrapper{class: :invalid, errors: errors}

      assert shape(error, fields: [:class, :errors]) ==
               "Shoddy.TermsTest.Wrapper(class: :invalid, errors: [" <>
                 Enum.map_join(1..5, ", ", &"Shoddy.TermsTest.Wrapper(class: :error_#{&1})") <>
                 ", and 2 more])"
    end

    test "shows a list of exceptions at the top level" do
      assert shape([%Wrapper{reason: :timeout}]) == "[Shoddy.TermsTest.Wrapper(reason: :timeout)]"
    end

    test "does not show a list in a field that contains other values" do
      assert shape(%Wrapper{errors: ["Ada", %Wrapper{}]}, fields: [:errors]) == "Shoddy.TermsTest.Wrapper"
    end

    test "shows only the module of an exception at the last level" do
      error = %Wrapper{reason: :timeout}

      assert shape({:error, error}, depth: 1) == "{:error, Shoddy.TermsTest.Wrapper}"
      assert shape(error, depth: 0) == "Shoddy.TermsTest.Wrapper"
    end

    test "raises ArgumentError for a wrong option" do
      assert_raise ArgumentError, fn -> shape(:ok, limit: 3) end
      assert_raise ArgumentError, ~r/:fields option/, fn -> shape(:ok, fields: ["reason"]) end
      assert_raise ArgumentError, ~r/:fields option/, fn -> shape(:ok, fields: :reason) end
      assert_raise ArgumentError, ~r/:depth option/, fn -> shape(:ok, depth: -1) end
    end
  end
end
