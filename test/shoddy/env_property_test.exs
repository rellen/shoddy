defmodule Shoddy.EnvPropertyTest do
  use ExUnit.Case, async: true
  use ExUnitProperties

  alias Shoddy.Env

  setup do
    name = "SHODDY_ENV_PROPERTY_#{System.unique_integer([:positive])}"
    on_exit(fn -> System.delete_env(name) end)
    %{name: name}
  end

  describe "integer/2" do
    property "returns the integer of a set variable, and the default of an absent variable", %{name: name} do
      check all(value <- one_of([constant(nil), integer()])) do
        if value, do: System.put_env(name, Integer.to_string(value)), else: System.delete_env(name)

        assert Env.integer(name, default: :default) == (value || :default)
      end
    end
  end

  describe "boolean/2" do
    property "returns the boolean of a set variable, and the default of an absent variable", %{name: name} do
      check all(value <- member_of([nil, true, false])) do
        if is_nil(value), do: System.delete_env(name), else: System.put_env(name, to_string(value))

        assert Env.boolean(name, default: :default) == if(is_nil(value), do: :default, else: value)
      end
    end
  end
end
