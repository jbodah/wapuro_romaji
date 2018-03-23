# wapuro_romaji

A solution to [Wāpuro Rōmaji](https://gist.github.com/grantovich/4aa38233fb3862301cb1285e18ce57ee) written in Elixir

## Usage

```
brew install elixir
elixir wapuro_romaji.exs
```

## Explanation

This solution relies on Elixir's function head pattern-matching:

```ex
defmodule MyModule do
  def greet_me("Josh") do
    "Hi Josh"
  end

  def greet_me("Lauren") do
    "Hey Lauren"
  end
end

names = ["Josh", "Lauren"]
Enum.map(names, fn name ->
  MyModule.greet_me(name)
end
#=> ["Hi Josh", "Hey Lauren"]
```

Pattern-matching makes it very easy for us to create complex business rules by allowing us
to write different functions that match each of the cases.

Since we're parsing sequential keyboard input we can safely keep pattern-matching from the head
of the input string building up an accumulator

We use make heavy use of Elixir's metaprogramming features. This just makes it so we don't have
to explicitly type out every single case but can batch up cases (e.g. we can write a single function
definition for the special digraph cases for "sh", "ch", and "j")
