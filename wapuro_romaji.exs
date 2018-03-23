defmodule WapuroRamaji.Digraph do
  def supports_digraph?("yo"), do: false
  def supports_digraph?("ya"), do: false
  def supports_digraph?("yu"), do: false
  def supports_digraph?("w" <> _rest), do: false
  def supports_digraph?("i" <> _rest), do: false
  def supports_digraph?(str), do: String.ends_with?(str, "i")

  def y_digraph?("j" <> _rest), do: false
  def y_digraph?("ch" <> _rest), do: false
  def y_digraph?("sh" <> _rest), do: false
  def y_digraph?(_), do: true
end

defmodule WapuroRamaji do
  ## Setup Constants

  {:ok, f} = File.open("wapuro_romaji.txt", [:read, :utf8])

  mapping =
    IO.stream(f, :line)
    |> Enum.map(fn line ->
      [hiragana, romaji] = String.split(line)
      {romaji, hiragana}
    end)
    |> Enum.sort_by(fn {k, _v} -> -String.length(k) end)

  @mapping mapping
  @geminates ~w(kk ss tt pp cch)
  @digraph_suffixes %{
    "a" => "ゃ",
    "u" => "ゅ",
    "o" => "ょ",
  }

  @debug System.get_env("DEBUG") == "1"

  ## Translation

  def translate(str) do
    _translate(str, "")
  end

  defp _translate("", acc) do
    acc
  end

  ## Handle Geminates
  Enum.each(@geminates, fn geminate ->
    defp _translate(unquote(" " <> geminate) <> _rest, _acc) do
      :error
    end

    defp _translate(unquote(geminate) <> rest, acc) do
      if @debug, do: IO.inspect {:geminate, unquote(geminate)}
      {_, last} = String.split_at(unquote(geminate), 1)
      _translate(last <> rest, acc <> "っ")
    end
  end)

  defp _translate(" " <> rest, acc) do
    _translate(rest, acc)
  end

  Enum.each(@mapping, fn {k, v} ->
    ## Handle Digraphs
    if WapuroRamaji.Digraph.supports_digraph?(k) do
      Enum.each(@digraph_suffixes, fn {digraph_k, digraph_v} ->
        new_k = String.trim_trailing(k, "i")
        if WapuroRamaji.Digraph.y_digraph?(k) do
          defp _translate(unquote(new_k <> "y" <> digraph_k) <> rest, acc) do
            _translate(rest, acc <> unquote(v <> digraph_v))
          end
        else
          defp _translate(unquote(new_k <> "y" <> digraph_k ) <> _rest, _acc) do
            :error
          end

          defp _translate(unquote(new_k <> digraph_k) <> rest, acc) do
            _translate(rest, acc <> unquote(v <> digraph_v))
          end
        end
      end)
    end
  end)

  Enum.each(@mapping, fn {k, v} ->
    defp _translate(unquote(k) <> rest, acc) do
      if @debug, do: IO.inspect {unquote(k), unquote(v)}
      _translate(rest, acc <> unquote(v))
    end
  end)

  defp _translate(_, _) do
    :error
  end
end

defmodule Test do
  def assert_translates(str, expected) do
    IO.inspect("=== Testing #{str} => #{expected} ===")
    case WapuroRamaji.translate(str) do
      ^expected -> IO.inspect {:passed, str, expected}
      actual -> IO.inspect {:failed, str, expected, actual}
    end
  end
end

basic_test_cases = %{
  "konnichiha" => "こんにちは",
  "oyasuminasai" => "おやすみなさい",
  "yoroshiku ne" => "よろしくね",
  "kana" => "かな",
  "kan a" => "かんあ",
  "exodia" => :error,
  "cheese" => :error
}
Enum.each(basic_test_cases, fn {k, v} -> Test.assert_translates(k, v) end)

geminate_test_cases = %{
  "matte" => "まって",
  "hippu" => "ひっぷ",
  "kocchi" => "こっち",
  "summo" => :error,
  "ma tte" => :error
}
Enum.each(geminate_test_cases, fn {k, v} -> Test.assert_translates(k, v) end)

digraph_test_cases = %{
  "kya" => "きゃ",
  "ju" => "じゅ",
  "cho" => "ちょ",
  "wya" => :error,
  "nye" => :error,
  "tya" => :error,
  "shyo" => :error
}
Enum.each(digraph_test_cases, fn {k, v} -> Test.assert_translates(k, v) end)

