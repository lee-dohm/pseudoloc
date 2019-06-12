defmodule Pseudoloc do
  @moduledoc """
  Creates a [pseudolocalized](https://en.wikipedia.org/wiki/Pseudolocalization) translation of
  `Gettext` data files.

  Because this module is designed to work with `Gettext`, it specifically ignores
  [interpolated](https://hexdocs.pm/gettext/Gettext.html#module-interpolation) sections of the
  strings it localizes.
  """

  @interpolation_pattern ~r/%\{[^}\s\t\n]+\}/

  @typedoc """
  A mapping of individual graphemes to a list of alternate representations.

  Both the key and all entries in the value list should be a single character.

  ## Examples

  ```
  %{
    "a" => ["à", "á", "å"],
    "b" => ["ḅ"]
  }
  ```
  """
  @type alternates :: %{optional(String.t()) => list(String.t())}

  @typedoc """
  Represents a range of text within a string by starting index and length.
  """
  @type range :: {non_neg_integer, non_neg_integer}

  @doc """
  Gets the ranges within the text that need to be localized.

  In other words, the ranges of the text that are not interpolations.

  Returns a list of tuples containing the index and length of each range to be localized.

  ## Examples

  A string with no interpolations:

  ```
  iex> Pseudoloc.get_localizable_ranges("foo")
  [{0, 3}]
  ```

  A string consisting of only interpolations:

  ```
  iex> Pseudoloc.get_localizable_ranges("%{foo}")
  []
  ```

  A string containing multiple interpolations:

  ```
  iex> Pseudoloc.get_localizable_ranges("foo%{bar}baz%{quux}quuux")
  [{0, 3}, {9, 3}, {19, 5}]
  ```
  """
  @spec get_localizable_ranges(String.t()) :: [range]
  def get_localizable_ranges(text) do
    interpolation_ranges = Regex.scan(@interpolation_pattern, text, return: :index)

    do_get_ranges(text, 0, interpolation_ranges, [])
  end

  @doc """
  Localizes the `grapheme` if there are valid `alternates`.

  ## Examples

  Returns the grapheme unchanged if there are no alternates:

  ```
  iex> Pseudoloc.localize_grapheme("a", %{"b" => ["ḅ"]})
  "a"
  ```

  Returns a random alternative if they exist:

  ```
  iex> Pseudoloc.localize_grapheme("a", %{"a" => ["α"]})
  "α"
  ```

  ```
  iex> alts = ["1", "2", "3"]
  iex> Pseudoloc.localize_grapheme("a", %{"a" => alts}) in alts
  true
  ```
  """
  @spec localize_grapheme(String.t(), alternates) :: String.t()
  def localize_grapheme(grapheme, alternates) do
    case Map.has_key?(alternates, grapheme) do
      false -> grapheme
      true -> Enum.random(alternates[grapheme])
    end
  end

  @doc """
  Localizes `text` within the `range` with the `alternates`.

  ## Examples

  ```
  iex> Pseudoloc.localize_range("foo", {1, 1}, %{"o" => ["ṓ"]})
  "fṓo"
  ```
  """
  @spec localize_range(String.t(), range, alternates) :: String.t()
  def localize_range(text, range, alternates)

  def localize_range(text, {_start, length}, _alternates) when length <= 0, do: text

  def localize_range(text, {start, length}, alternates) do
    range = Range.new(start, start + length - 1)

    {_, result} =
      Enum.reduce(range, {:cont, text}, fn elem, {_, text} ->
        {:cont, localize_grapheme_at(text, elem, alternates)}
      end)

    result
  end

  @doc """
  Localizes `text` with the default alternates.

  See `localize_string/2` for details.
  """
  @spec localize_string(String.t()) :: String.t()
  def localize_string(text), do: localize_string(text, default_alternates())

  @doc """
  Localizes `text` with the given `alternates`.

  ## Examples

  Localizing the non-interpolated sections of a string:

  ```
  iex> alternates = %{"a" => ["α"], "f" => ["ϝ"], "u" => ["ṵ"]}
  iex> text = "foo%{bar}baz%{quux}quuux"
  iex> Pseudoloc.localize_string(text, alternates)
  "ϝoo%{bar}bαz%{quux}qṵṵṵx"
  ```
  """
  @spec localize_string(String.t(), alternates) :: String.t()
  def localize_string(text, alternates) do
    ranges = get_localizable_ranges(text)

    {_, result} =
      Enum.reduce(ranges, {:cont, text}, fn range, {_, text} ->
        {:cont, localize_range(text, range, alternates)}
      end)

    result
  end

  # ----- Private functions -----

  defp cleanup_ranges(ranges) do
    ranges
    |> Enum.reverse()
    |> Enum.reject(fn elem -> match?({_, 0}, elem) end)
  end

  defp default_alternates do
    {map, _} = Code.eval_file(Path.join(:code.priv_dir(:pseudoloc), "alternates.exs"))

    map
  end

  defp do_get_ranges(text, last_pos, interpolation_ranges, translate_ranges)

  defp do_get_ranges(text, last_pos, [], translate_ranges) do
    result =
      if last_pos < String.length(text) do
        [{last_pos, String.length(text) - last_pos} | translate_ranges]
      else
        translate_ranges
      end

    cleanup_ranges(result)
  end

  defp do_get_ranges(text, last_pos, [head | tail], translate_ranges) do
    [{start, length}] = head

    do_get_ranges(text, start + length, tail, [{last_pos, start - last_pos} | translate_ranges])
  end

  defp localize_grapheme_at(text, at, alternates) do
    before_text = String.slice(text, 0, at)
    after_text = String.slice(text, at + 1, String.length(text))

    Enum.join([before_text, localize_grapheme(String.at(text, at), alternates), after_text])
  end
end
