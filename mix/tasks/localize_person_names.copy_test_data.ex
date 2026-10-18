defmodule Mix.Tasks.LocalizePersonNames.CopyTestData do
  @shortdoc "Copies CLDR's person name conformance data into the test fixtures"

  @moduledoc """
  Copies CLDR's person name conformance data from the CLDR repository into
  `test/support/person_name_test_data/`.

  CLDR publishes one file of test cases per locale in
  `common/testData/personNameTest`. The fixtures are a mirror of that
  directory, so the copy clears them first: a locale that leaves CLDR leaves
  the fixtures with it, rather than lingering as a stale file whose
  expectations were written against an older release.

  The repository is read from `CLDR_REPO`, or where Localize looks for it by
  default: `cldr_repo` beside this project, or in a `cldr` directory beside
  it. Check it out at the ref the Localize release under test was generated
  from (`Localize.cldr_repo_ref/0`), since the expected results are written
  against that release's locale data.

  ## Usage

      mix localize_person_names.copy_test_data

  """

  use Mix.Task

  @source "common/testData/personNameTest"
  @destination "test/support/person_name_test_data"

  @impl Mix.Task
  def run(_args) do
    project_root = Path.dirname(Mix.Project.project_file())
    repo = cldr_repo_dir(project_root)
    source = Path.join(repo, @source)
    destination = Path.join(project_root, @destination)

    unless File.dir?(source) do
      Mix.raise("#{@source} was not found in #{repo}. Set CLDR_REPO to a CLDR checkout.")
    end

    File.rm_rf!(destination)
    File.mkdir_p!(destination)

    files = source |> File.ls!() |> Enum.filter(&File.regular?(Path.join(source, &1)))
    Enum.each(files, &File.cp!(Path.join(source, &1), Path.join(destination, &1)))

    Mix.shell().info(
      "Copied #{length(files)} files from #{@source} at #{cldr_ref(source)} to #{@destination}"
    )
  end

  defp cldr_repo_dir(project_root) do
    System.get_env("CLDR_REPO") || default_cldr_dir(project_root)
  end

  # The CLDR checkout lives either beside this project or in a `cldr` family
  # directory beside it, which is where Localize looks for it too.
  defp default_cldr_dir(project_root) do
    candidates = [
      Path.expand(Path.join([project_root, "..", "cldr_repo"])),
      Path.expand(Path.join([project_root, "..", "..", "cldr", "cldr_repo"]))
    ]

    Enum.find(candidates, hd(candidates), &File.dir?/1)
  end

  # The ref the files came from, so the copy says which release its
  # expectations belong to.
  defp cldr_ref(source) do
    case System.cmd("git", ["describe", "--tags", "--always"], cd: source, stderr_to_stdout: true) do
      {ref, 0} -> String.trim(ref)
      _not_a_git_checkout -> "an unknown ref"
    end
  end
end
