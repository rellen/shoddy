defmodule Shoddy.TaggingPropertyTest do
  use ExUnit.Case, async: true
  use ExUnitProperties

  alias Shoddy.Tagging

  defp simple, do: one_of([integer(), atom(:alphanumeric), string(:alphanumeric), boolean()])

  describe "tag/2" do
    property "puts the tag in the first position and the value in the second" do
      check all(value <- simple(), tag <- atom(:alphanumeric)) do
        assert {^tag, ^value} = Tagging.tag(value, tag)
      end
    end

    property "makes a tuple of two elements" do
      check all(value <- simple(), tag <- atom(:alphanumeric)) do
        assert tuple_size(Tagging.tag(value, tag)) == 2
      end
    end

    property "keeps the value with no change" do
      check all(value <- simple(), tag <- atom(:alphanumeric)) do
        assert value |> Tagging.tag(tag) |> elem(1) == value
      end
    end
  end

  describe "tag/3" do
    property "puts the tag first, then the value, then the extra value" do
      check all(value <- simple(), extra <- simple(), tag <- atom(:alphanumeric)) do
        assert {^tag, ^value, ^extra} = Tagging.tag(value, extra, tag)
      end
    end

    property "makes a tuple of three elements" do
      check all(value <- simple(), extra <- simple(), tag <- atom(:alphanumeric)) do
        assert tuple_size(Tagging.tag(value, extra, tag)) == 3
      end
    end
  end

  describe "the named functions agree with tag/2" do
    property "each named function of arity 1 returns the same tuple as tag/2" do
      check all(value <- simple()) do
        assert Tagging.ok(value) == Tagging.tag(value, :ok)
        assert Tagging.error(value) == Tagging.tag(value, :error)
        assert Tagging.noreply(value) == Tagging.tag(value, :noreply)
        assert Tagging.cont(value) == Tagging.tag(value, :cont)
        assert Tagging.halt(value) == Tagging.tag(value, :halt)
        assert Tagging.reply(value) == Tagging.tag(value, :reply)
        assert Tagging.stop(value) == Tagging.tag(value, :stop)
      end
    end
  end

  describe "the named functions agree with tag/3" do
    property "each named function of arity 2 returns the same tuple as tag/3" do
      check all(value <- simple(), extra <- simple()) do
        assert Tagging.noreply(value, extra) == Tagging.tag(value, extra, :noreply)
        assert Tagging.reply(value, extra) == Tagging.tag(value, extra, :reply)
        assert Tagging.stop(value, extra) == Tagging.tag(value, extra, :stop)
      end
    end
  end

  describe "agreement with Shoddy.Result" do
    property "Result.ok? is true for every tuple that ok/1 makes" do
      check all(value <- simple()) do
        assert value |> Tagging.ok() |> Shoddy.Result.ok?()
      end
    end

    property "Result.error? is true for every tuple that error/1 makes" do
      check all(value <- simple()) do
        assert value |> Tagging.error() |> Shoddy.Result.error?()
      end
    end

    property "Result.unwrap! returns the value that ok/1 received" do
      check all(value <- simple()) do
        assert value |> Tagging.ok() |> Shoddy.Result.unwrap!() == value
      end
    end
  end
end
