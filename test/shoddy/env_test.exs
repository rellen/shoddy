defmodule Shoddy.EnvTest do
  use ExUnit.Case, async: true

  import Shoddy.Env

  doctest Shoddy.Env

  @doctest_names [
    "SHODDY_DOC_PORT",
    "SHODDY_DOC_DEBUG",
    "SHODDY_DOC_HOSTS",
    "SHODDY_DOC_HOST",
    "SHODDY_DOC_SECRET",
    "SHODDY_DOC_LOG_FORMAT",
    "SHODDY_DOC_STORAGE",
    "SHODDY_DOC_DATABASE_URL"
  ]

  setup do
    name = "SHODDY_ENV_TEST_#{System.unique_integer([:positive])}"
    on_exit(fn -> Enum.each([name | @doctest_names], &System.delete_env/1) end)
    %{name: name}
  end

  describe "integer/2" do
    test "returns the integer of the variable", %{name: name} do
      System.put_env(name, "-12")
      assert integer(name) == -12
    end

    test "returns the default for an absent, empty or blank variable", %{name: name} do
      assert integer(name, default: 1) == 1
      System.put_env(name, "")
      assert integer(name, default: 1) == 1
      System.put_env(name, " \t")
      assert integer(name, default: 1) == 1
    end

    test "returns any default with no check, also nil", %{name: name} do
      assert integer(name, default: nil) == nil
      assert integer(name, default: :off, min: 1) == :off
    end

    test "raises ArgumentError that tells that an absent variable without a default is not set", %{name: name} do
      assert_raise ArgumentError, ~s[the environment variable "#{name}" is not set], fn -> integer(name) end
    end

    test "raises ArgumentError that tells the value for a blank variable without a default", %{name: name} do
      for value <- ["", " "] do
        System.put_env(name, value)

        assert_raise ArgumentError, ~s[the environment variable "#{name}" has no value: #{inspect(value)}], fn ->
          integer(name)
        end
      end
    end

    test "removes the whitespace at the start and at the end of the value", %{name: name} do
      System.put_env(name, " 8080\n")
      assert integer(name) == 8080
    end

    test "raises ArgumentError that tells the name, the value and the reason", %{name: name} do
      System.put_env(name, "80")

      assert_raise ArgumentError, ~s[invalid value for the environment variable "#{name}": "80" (:too_small)], fn ->
        integer(name, min: 1024)
      end

      System.put_env(name, " 8 0 ")
      assert_raise ArgumentError, ~r/: " 8 0 " \(:not_an_integer\)/, fn -> integer(name, default: 1) end
    end

    test "raises ArgumentError for an unknown option", %{name: name} do
      assert_raise ArgumentError, fn -> integer(name, fallback: 1) end
    end

    test "raises ArgumentError for a wrong option also if the variable is absent", %{name: name} do
      assert_raise ArgumentError, ~r/higher than/, fn -> integer(name, default: 1, min: 10, max: 1) end
      assert_raise ArgumentError, ~r/expected an integer/, fn -> integer(name, default: 1, min: "1") end
    end

    test "raises FunctionClauseError from integer/2 itself for a name that is not a string" do
      for args <- [[:port, []], ["PORT", :default]] do
        error = assert_raise FunctionClauseError, fn -> apply(&integer/2, args) end
        assert {error.module, error.function} == {Shoddy.Env, :integer}
      end
    end
  end

  describe "boolean/2" do
    test "returns true and false for the default texts", %{name: name} do
      System.put_env(name, "true")
      assert boolean(name) == true
      System.put_env(name, "false")
      assert boolean(name, default: true) == false
    end

    test "accepts the texts of the options", %{name: name} do
      System.put_env(name, "off")
      assert boolean(name, true_values: ["on"], false_values: ["off"]) == false
    end

    test "returns the default for an absent, empty or blank variable", %{name: name} do
      assert boolean(name, default: true) == true
      System.put_env(name, "")
      assert boolean(name, default: false) == false
      System.put_env(name, "  ")
      assert boolean(name, default: false) == false
    end

    test "raises ArgumentError that tells that an absent variable without a default is not set", %{name: name} do
      assert_raise ArgumentError, ~s[the environment variable "#{name}" is not set], fn -> boolean(name) end
    end

    test "removes the whitespace at the start and at the end of the value", %{name: name} do
      System.put_env(name, "true\n")
      assert boolean(name) == true
    end

    test "raises ArgumentError for a text that is not in the lists", %{name: name} do
      System.put_env(name, "yes")
      assert_raise ArgumentError, ~r/"yes" \(:not_a_boolean\)/, fn -> boolean(name, default: false) end
    end

    test "raises ArgumentError for an unknown option", %{name: name} do
      assert_raise ArgumentError, fn -> boolean(name, min: 1) end
    end

    test "raises ArgumentError for a wrong option also if the variable is absent", %{name: name} do
      assert_raise ArgumentError, ~r/in :true_values and in :false_values/, fn ->
        boolean(name, default: false, true_values: ["x"], false_values: ["x"])
      end
    end

    test ~s(accepts "1" and "0" with digits: true, and keeps the default texts), %{name: name} do
      for {value, expected} <- [{"1", true}, {" 0\n", false}, {"true", true}, {"false", false}] do
        System.put_env(name, value)
        assert boolean(name, digits: true) == expected
      end
    end

    test "adds the digits to the lists of the options", %{name: name} do
      opts = [digits: true, true_values: ["on"], false_values: ["off"]]

      for {value, expected} <- [{"1", true}, {"0", false}, {"on", true}, {"off", false}] do
        System.put_env(name, value)
        assert boolean(name, opts) == expected
      end

      System.put_env(name, "true")
      assert_raise ArgumentError, ~r/:not_a_boolean/, fn -> boolean(name, opts) end
    end

    test ~s(rejects "1" and "0" without digits: true), %{name: name} do
      for value <- ["1", "0"] do
        System.put_env(name, value)
        assert_raise ArgumentError, ~r/:not_a_boolean/, fn -> boolean(name, default: false) end
        assert_raise ArgumentError, ~r/:not_a_boolean/, fn -> boolean(name, default: false, digits: false) end
      end
    end

    test "keeps the comparison case-sensitive with digits: true", %{name: name} do
      System.put_env(name, "TRUE")
      assert_raise ArgumentError, ~r/"TRUE" \(:not_a_boolean\)/, fn -> boolean(name, default: false, digits: true) end
    end

    test "returns the default for an absent or blank variable with digits: true", %{name: name} do
      assert boolean(name, default: false, digits: true) == false
      System.put_env(name, " ")
      assert boolean(name, default: true, digits: true) == true
    end

    test "raises ArgumentError for a wrong :digits also if the variable is absent", %{name: name} do
      for digits <- [nil, "true", 1] do
        assert_raise ArgumentError, ~r/invalid value for :digits option: expected a boolean/, fn ->
          boolean(name, default: false, digits: digits)
        end
      end
    end

    test "raises ArgumentError for a digit that is also in the other list", %{name: name} do
      assert_raise ArgumentError, ~s[the text "1" is in :true_values and in :false_values], fn ->
        boolean(name, default: false, digits: true, false_values: ["1"])
      end
    end

    test "raises ArgumentError for a wrong list with digits: true", %{name: name} do
      assert_raise ArgumentError, ~r/:true_values option: expected a list of strings/, fn ->
        boolean(name, default: false, digits: true, true_values: "yes")
      end
    end

    test "raises FunctionClauseError from boolean/2 itself for a name that is not a string" do
      for args <- [[:debug, []], ["DEBUG", :default]] do
        error = assert_raise FunctionClauseError, fn -> apply(&boolean/2, args) end
        assert {error.module, error.function} == {Shoddy.Env, :boolean}
      end
    end
  end

  describe "string/2" do
    test "returns the value without the whitespace at the start and at the end", %{name: name} do
      System.put_env(name, " secret value\n")
      assert string(name) == "secret value"
    end

    test "returns the default for an absent, empty or blank variable", %{name: name} do
      assert string(name, default: "x") == "x"
      System.put_env(name, "")
      assert string(name, default: nil) == nil
      System.put_env(name, " \n")
      assert string(name, default: "x") == "x"
    end

    test "raises ArgumentError that tells that an absent variable without a default is not set", %{name: name} do
      assert_raise ArgumentError, ~s[the environment variable "#{name}" is not set], fn -> string(name) end
    end

    test "raises ArgumentError for a blank variable without a default", %{name: name} do
      System.put_env(name, " ")
      assert_raise ArgumentError, ~s[the environment variable "#{name}" has no value: " "], fn -> string(name) end
    end

    test "accepts a value with exactly :min_bytes bytes after the trim", %{name: name} do
      System.put_env(name, " abcd ")
      assert string(name, min_bytes: 4) == "abcd"
      assert string(name, min_bytes: 0) == "abcd"
    end

    test "counts bytes and not characters for :min_bytes", %{name: name} do
      System.put_env(name, "éé")
      assert string(name, min_bytes: 4) == "éé"

      assert_raise ArgumentError, ~r/has 4 bytes, but it must have at least 5 bytes/, fn ->
        string(name, min_bytes: 5)
      end
    end

    test "raises ArgumentError without the value for a value that is too short", %{name: name} do
      System.put_env(name, " hunter2 ")

      error = assert_raise ArgumentError, fn -> string(name, min_bytes: 64, default: "x") end

      assert error.message == ~s[the environment variable "#{name}" has 7 bytes, but it must have at least 64 bytes]
      refute error.message =~ "hunter2"
    end

    test "returns the default with no check of :min_bytes", %{name: name} do
      assert string(name, default: "", min_bytes: 64) == ""
      System.put_env(name, " ")
      assert string(name, default: "", min_bytes: 64) == ""
    end

    test "raises ArgumentError for a wrong :min_bytes also if the variable is absent", %{name: name} do
      for min_bytes <- [-1, 1.5, "64", :large] do
        assert_raise ArgumentError, ~r/invalid value for :min_bytes option/, fn ->
          string(name, default: "x", min_bytes: min_bytes)
        end
      end
    end

    test "raises ArgumentError for an unknown option", %{name: name} do
      assert_raise ArgumentError, fn -> string(name, min: 1) end
    end

    test "raises FunctionClauseError from string/2 itself for a name that is not a string" do
      for args <- [[:secret, []], ["SECRET", :default]] do
        error = assert_raise FunctionClauseError, fn -> apply(&string/2, args) end
        assert {error.module, error.function} == {Shoddy.Env, :string}
      end
    end
  end

  describe "one_of/3" do
    test "returns the atom that has the trimmed value as its name", %{name: name} do
      System.put_env(name, " json\n")
      assert one_of(name, [:text, :json]) == :json
    end

    test "returns the value of the key for a keyword list", %{name: name} do
      System.put_env(name, "s3")
      assert one_of(name, local: Local, s3: S3) == S3
    end

    test "returns the default for an absent or blank variable", %{name: name} do
      assert one_of(name, [:text, :json], default: :text) == :text
      System.put_env(name, " ")
      assert one_of(name, [:text, :json], default: nil) == nil
    end

    test "raises ArgumentError that tells that an absent variable without a default is not set", %{name: name} do
      assert_raise ArgumentError, ~s[the environment variable "#{name}" is not set], fn -> one_of(name, [:text]) end
    end

    test "raises ArgumentError for a blank variable without a default", %{name: name} do
      System.put_env(name, "")
      assert_raise ArgumentError, ~r/has no value: ""/, fn -> one_of(name, [:text]) end
    end

    test "raises ArgumentError that gives the allowed names for a value that is not allowed", %{name: name} do
      System.put_env(name, "S3")

      message =
        ~s[invalid value for the environment variable "#{name}": "S3" (:not_allowed), expected one of: "local", "s3"]

      assert_raise ArgumentError, message, fn -> one_of(name, [local: Local, s3: S3], default: Local) end
      assert_raise ArgumentError, message, fn -> one_of(name, [:local, :s3]) end
    end

    test "does not make a new atom", %{name: name} do
      text = "shoddy_env_test_#{System.unique_integer([:positive])}"
      System.put_env(name, text)

      assert_raise ArgumentError, ~r/:not_allowed/, fn -> one_of(name, [:a]) end
      assert_raise ArgumentError, fn -> String.to_existing_atom(text) end
    end

    test "raises ArgumentError for a wrong list also if the variable is absent", %{name: name} do
      assert_raise ArgumentError, ~r/must be a list of atoms or a keyword list/, fn ->
        one_of(name, [:a, "b"], default: :a)
      end
    end

    test "raises ArgumentError for an unknown option", %{name: name} do
      assert_raise ArgumentError, fn -> one_of(name, [:a], fallback: :a) end
    end

    test "raises FunctionClauseError from one_of/3 itself for an argument of the wrong type" do
      for args <- [[:format, [:a], []], ["FORMAT", MapSet.new([:a]), []], ["FORMAT", [:a], :default]] do
        error = assert_raise FunctionClauseError, fn -> apply(&one_of/3, args) end
        assert {error.module, error.function} == {Shoddy.Env, :one_of}
      end
    end
  end

  describe "list/2" do
    test "splits at the separator, trims each value and removes each empty value", %{name: name} do
      System.put_env(name, " a ; b ;; ")
      assert list(name, separator: ";") == ["a", "b"]
    end

    test "returns the default for a value without a list element, and raises without a default", %{name: name} do
      for value <- [" , ", ",", " "] do
        System.put_env(name, value)
        assert list(name, default: ["x"]) == ["x"]
        assert_raise ArgumentError, ~r/has no value/, fn -> list(name) end
      end
    end

    test "returns the default for an absent or empty variable, and raises without a default", %{name: name} do
      assert list(name, default: []) == []
      System.put_env(name, "")
      assert list(name, default: nil) == nil
      assert_raise ArgumentError, ~r/has no value/, fn -> list(name) end
      System.delete_env(name)
      assert_raise ArgumentError, ~s[the environment variable "#{name}" is not set], fn -> list(name) end
    end

    test "raises ArgumentError for an unknown option", %{name: name} do
      assert_raise ArgumentError, fn -> list(name, sep: ";") end
    end

    test "raises ArgumentError for a wrong separator, also if the variable is absent", %{name: name} do
      assert_raise ArgumentError, ~r/invalid separator/, fn -> list(name, default: [], separator: "") end
      System.put_env(name, "a")
      assert_raise ArgumentError, ~r/invalid separator/, fn -> list(name, default: [], separator: [";", ""]) end
      assert_raise ArgumentError, ~r/:separator option/, fn -> list(name, default: [], separator: :comma) end
      assert_raise ArgumentError, ~r/:separator option/, fn -> list(name, default: [], separator: nil) end
    end

    test "raises FunctionClauseError from list/2 itself for a name that is not a string" do
      for args <- [[:hosts, []], ["HOSTS", :default]] do
        error = assert_raise FunctionClauseError, fn -> apply(&list/2, args) end
        assert {error.module, error.function} == {Shoddy.Env, :list}
      end
    end
  end

  describe "the option :hint" do
    @hint "Generate a value with: mix phx.gen.secret"

    test "adds the hint on a new line for an absent variable, in each function", %{name: name} do
      for read <- readers() do
        assert_raise ArgumentError, ~s[the environment variable "#{name}" is not set\n#{@hint}], fn ->
          read.(name, hint: @hint)
        end
      end
    end

    test "adds the hint on a new line for a blank value, in each function", %{name: name} do
      System.put_env(name, " ")

      for read <- readers() do
        assert_raise ArgumentError, ~s[the environment variable "#{name}" has no value: " "\n#{@hint}], fn ->
          read.(name, hint: @hint)
        end
      end
    end

    test "adds the hint on a new line for a wrong value", %{name: name} do
      System.put_env(name, "x")

      assert_raise ArgumentError,
                   ~s[invalid value for the environment variable "#{name}": "x" (:not_an_integer)\n#{@hint}],
                   fn -> integer(name, hint: @hint) end

      assert_raise ArgumentError,
                   ~s[invalid value for the environment variable "#{name}": "x" (:not_a_boolean)\n#{@hint}],
                   fn -> boolean(name, hint: @hint) end
    end

    test "adds the hint and not the value for a wrong URL", %{name: name} do
      System.put_env(name, "mysql://user:secret@db/app")

      message =
        ~s[invalid value for the environment variable "#{name}" (:scheme_not_allowed), ] <>
          ~s[expected one of: "ecto"\n#{@hint}]

      assert_raise ArgumentError, message, fn -> uri(name, schemes: ["ecto"], hint: @hint) end
    end

    test "puts the hint after the allowed names for one_of/3", %{name: name} do
      System.put_env(name, "xml")

      message =
        ~s[invalid value for the environment variable "#{name}": "xml" (:not_allowed), ] <>
          ~s[expected one of: "text", "json"\n#{@hint}]

      assert_raise ArgumentError, message, fn -> one_of(name, [:text, :json], hint: @hint) end
    end

    test "adds the hint for a value that is shorter than :min_bytes, and does not add the value", %{name: name} do
      System.put_env(name, "abcdef")

      message = ~s[the environment variable "#{name}" has 6 bytes, but it must have at least 64 bytes\n#{@hint}]
      assert_raise ArgumentError, message, fn -> string(name, min_bytes: 64, hint: @hint) end
    end

    test "adds no text for a hint of nil", %{name: name} do
      assert_raise ArgumentError, ~s[the environment variable "#{name}" is not set], fn -> integer(name, hint: nil) end
    end

    test "does not change the result for a correct value or a default", %{name: name} do
      assert integer(name, default: 1, hint: @hint) == 1
      System.put_env(name, "2")
      assert integer(name, hint: @hint) == 2
    end

    test "does not add the hint to the message for a wrong option", %{name: name} do
      error = assert_raise ArgumentError, fn -> integer(name, hint: @hint, min: :low) end
      refute error.message =~ @hint
    end

    test "raises ArgumentError for a hint that is not a string or nil, also if the variable is absent", %{name: name} do
      for read <- readers(), hint <- [:text, ~c"text", 1] do
        assert_raise ArgumentError, ~r/invalid value for :hint option: expected a string or nil/, fn ->
          read.(name, default: "x", hint: hint)
        end
      end
    end
  end

  defp readers do
    [
      &integer/2,
      &boolean/2,
      &string/2,
      &list/2,
      &one_of(&1, [:text], &2),
      &uri/2
    ]
  end

  describe "uri/2" do
    test "returns the trimmed value as a string", %{name: name} do
      System.put_env(name, " postgres://user:pw@db/app\n")
      assert uri(name) == "postgres://user:pw@db/app"
      assert uri(name, schemes: ["postgres"]) == "postgres://user:pw@db/app"
    end

    test "returns the default for an absent or blank variable, and raises without a default", %{name: name} do
      assert uri(name, default: nil) == nil
      assert_raise ArgumentError, ~s[the environment variable "#{name}" is not set], fn -> uri(name) end
      System.put_env(name, " ")
      assert uri(name, default: "http://localhost") == "http://localhost"
      assert_raise ArgumentError, ~r/has no value/, fn -> uri(name) end
    end

    test "raises ArgumentError with the reason and without the value for a wrong value", %{name: name} do
      for {value, reason} <- [
            {"secret.example.com", ":no_scheme"},
            {"secret:5432", ":no_host"},
            {"http://secret.example.com/a b", ":not_a_uri"}
          ] do
        System.put_env(name, value)
        error = assert_raise ArgumentError, fn -> uri(name, default: "http://localhost") end
        assert error.message == ~s[invalid value for the environment variable "#{name}" (#{reason})]
        refute error.message =~ "secret"
      end
    end

    test "raises ArgumentError with the permitted schemes for a scheme that is not permitted", %{name: name} do
      System.put_env(name, "mysql://user:secret@db/app")
      error = assert_raise ArgumentError, fn -> uri(name, schemes: ["ecto", "postgres"]) end

      assert error.message ==
               ~s[invalid value for the environment variable "#{name}" (:scheme_not_allowed), expected one of: "ecto", "postgres"]
    end

    test "raises ArgumentError for a wrong option, also if the variable is absent", %{name: name} do
      assert_raise ArgumentError, ~r/:schemes option/, fn -> uri(name, default: nil, schemes: "http") end
      assert_raise ArgumentError, fn -> uri(name, default: nil, scheme: ["http"]) end
    end

    test "raises FunctionClauseError from uri/2 itself for an argument of the wrong type" do
      for args <- [[:url, []], ["URL", :default]] do
        error = assert_raise FunctionClauseError, fn -> apply(&uri/2, args) end
        assert {error.module, error.function} == {Shoddy.Env, :uri}
      end
    end
  end
end
