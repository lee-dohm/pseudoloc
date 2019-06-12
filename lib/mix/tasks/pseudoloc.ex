defmodule Mix.Tasks.Pseudoloc do
  @moduledoc """
  Mix task for pseudolocalizing the `Gettext` data files.

  ```
  $ mix pseudoloc priv/gettext
  ```
  """

  use Mix.Task

  alias Gettext.PO
  alias Gettext.PO.{PluralTranslation, Translation}
  alias Mix.Shell

  @shortdoc "Creates a pseudolocalized translation"

  @impl Mix.Task
  @doc false
  def run(args)

  def run([]) do
    Mix.raise(
      "Must be supplied with the directory where the gettext POT files are stored, typically priv/gettext"
    )
  end

  def run(args) do
    gettext_path = hd(args)
    pseudo_path = Path.join(gettext_path, "ps/LC_MESSAGES")
    File.mkdir_p!(pseudo_path)

    Mix.Task.run("gettext.extract")
    Mix.Task.run("gettext.merge", args)

    pseudo_path
    |> get_source_files()
    |> Enum.each(&localize_file/1)
  end

  # ----- Private functions -----

  defp get_source_files(path) do
    path
    |> Path.join("*.po")
    |> Path.wildcard()
  end

  defp localize_file(path) do
    Shell.IO.info("Pseduolocalize #{path}")

    data =
      path
      |> PO.parse_file!()
      |> update_translations()
      |> PO.dump()

    File.write!(path, data)
  end

  defp update_translation(translation = %Translation{}) do
    localized_text = Pseudoloc.localize_string(hd(translation.msgid))

    %Translation{translation | msgstr: [localized_text]}
  end

  defp update_translation(translation = %PluralTranslation{}) do
    localized_singular = Pseudoloc.localize_string(hd(translation.msgid))
    localized_plural = Pseudoloc.localize_string(hd(translation.msgid_plural))

    {_, localized_msgstr} =
      Enum.reduce(Map.keys(translation.msgstr), {:cont, %{}}, fn key, {_, map} ->
        if key == 0 do
          {:cont, Map.put(map, 0, [localized_singular])}
        else
          {:cont, Map.put(map, key, [localized_plural])}
        end
      end)

    %PluralTranslation{translation | msgstr: localized_msgstr}
  end

  defp update_translations(po = %PO{}) do
    localized = Enum.map(po.translations, fn translation -> update_translation(translation) end)

    %PO{po | translations: localized}
  end
end
