# This script reads the JSON report of muex and writes a summary for GitHub
# Actions. It also writes a warning annotation for each mutant that survives
# and for each mutant that no test runs.
#
# The script always exits with the status 0, also for a report that it cannot
# read and for an error of its own. Thus it cannot make a check fail.
#
# The first argument is the path of the report. An optional second argument
# is the path of a file. The script writes the same summary into that file,
# and the workflow posts that file as a comment on the pull request.

defmodule MuexSummary do
  @moduledoc false

  @rows [
    {"Killed", "killed"},
    {"Survived", "survived"},
    {"No coverage", "no_coverage"},
    {"Invalid", "invalid"},
    {"Timeout", "timeout"},
    {"Equivalent", "equivalent"},
    {"Total", "total"}
  ]

  @gaps %{"survived" => "survived", "no_coverage" => "has no test that runs it"}

  def main(args) do
    run(args)
  rescue
    error -> IO.puts("::warning::" <> escape_data("The summary script failed: " <> Exception.message(error)))
  end

  defp run([path]), do: run([path, nil])

  defp run([path, copy]) do
    case File.read(path) do
      {:ok, json} -> json |> decode() |> report(copy)
      {:error, _reason} -> write_note("Muex did not write a report.", copy)
    end
  end

  defp run(args) do
    raise ArgumentError, "expected a path of a report and an optional path of a copy, got: #{inspect(args)}"
  end

  defp decode(json) do
    case JSON.decode(json) do
      {:ok, %{"summary" => summary, "mutations" => mutations}} when is_map(summary) and is_list(mutations) ->
        {:ok, summary, Enum.filter(mutations, &is_map/1)}

      {:ok, _other} ->
        {:error, "the report has no summary or no list of mutants"}

      {:error, reason} ->
        {:error, "the report is not valid JSON: #{inspect(reason)}"}
    end
  end

  defp report({:error, reason}, copy), do: write_note("This script cannot read the report of muex: #{reason}.", copy)

  defp report({:ok, summary, mutations}, copy) do
    gaps = Enum.filter(mutations, &Map.has_key?(@gaps, &1["status"]))
    rows = Enum.map_join(@rows, "\n", fn {label, key} -> "| #{label} | #{cell(summary[key])} |" end)

    write_summary(
      """
      ## Mutation testing

      This check reports the result only. It does not make a check fail.

      | Result | Count |
      |---|---|
      #{rows}

      Mutation score: #{cell(summary["mutation_score_low"])}%

      Do not trust the invalid count. Muex sometimes reports a mutant as invalid,
      although the mutant compiles and the tests kill it.
      #{gaps_section(gaps)}
      """,
      copy
    )

    Enum.each(gaps, &annotate/1)
  end

  defp gaps_section([]), do: "\nNo mutant survived, and each mutant has a test that runs it.\n"

  defp gaps_section(gaps) do
    rows =
      Enum.map_join(gaps, "\n", fn mutant ->
        "| #{place(mutant)} | #{cell(@gaps[mutant["status"]])} | #{cell(mutant["description"])} |"
      end)

    """

    ### Gaps in the tests

    No test kills the mutants below.

    | Location | Result | Change |
    |---|---|---|
    #{rows}
    """
  end

  defp annotate(mutant) do
    message = escape_data("A mutant #{@gaps[mutant["status"]]}: #{mutant["description"]}")

    case mutant["location"] do
      %{"file" => file, "line" => line} ->
        IO.puts("::warning file=#{escape_property(to_string(file))},line=#{line}::#{message}")

      _other ->
        IO.puts("::warning::#{message}")
    end
  end

  defp place(mutant) do
    case mutant["location"] do
      %{"file" => file, "line" => line} -> "`#{cell(file)}:#{cell(line)}`"
      _other -> "unknown"
    end
  end

  defp write_note(note, copy) do
    write_summary(
      """
      ## Mutation testing

      #{note} Examine the log of the step that runs muex.
      """,
      copy
    )

    IO.puts("::warning::" <> escape_data(note))
  end

  defp write_summary(text, copy) do
    case System.get_env("GITHUB_STEP_SUMMARY") do
      nil -> IO.write(text)
      file -> File.write!(file, text, [:append])
    end

    if copy do
      File.mkdir_p!(Path.dirname(copy))
      File.write!(copy, text)
    end
  end

  defp cell(value) do
    value
    |> to_string()
    |> String.replace("|", "\\|")
    |> String.replace(~r/\s*\R\s*/, " ")
  end

  defp escape_data(text) do
    text
    |> String.replace("%", "%25")
    |> String.replace("\r", "%0D")
    |> String.replace("\n", "%0A")
  end

  defp escape_property(text) do
    text
    |> escape_data()
    |> String.replace(":", "%3A")
    |> String.replace(",", "%2C")
  end
end

MuexSummary.main(System.argv())
