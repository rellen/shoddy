defmodule Shoddy.EnvTest do
  use ExUnit.Case, async: true

  import Shoddy.Env

  doctest Shoddy.Env

  setup do
    name = "SHODDY_ENV_TEST_#{System.unique_integer([:positive])}"
    on_exit(fn -> System.delete_env(name) end)
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

    test "raises System.EnvError for an absent variable without a default", %{name: name} do
      assert_raise System.EnvError, fn -> integer(name) end
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

    test "raises System.EnvError for an absent variable without a default", %{name: name} do
      assert_raise System.EnvError, fn -> boolean(name) end
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

    test "raises FunctionClauseError from boolean/2 itself for a name that is not a string" do
      for args <- [[:debug, []], ["DEBUG", :default]] do
        error = assert_raise FunctionClauseError, fn -> apply(&boolean/2, args) end
        assert {error.module, error.function} == {Shoddy.Env, :boolean}
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
      assert_raise System.EnvError, fn -> list(name) end
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
end
