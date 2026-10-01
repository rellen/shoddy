# Paginate a list

This guide shows how to show a long list in pages, with a page number from
the user. It uses `Shoddy.Numbers.ceil_div/2` for the number of pages and
`Shoddy.Numbers.clamp/3` for the page number. The examples use an alias:

```elixir
alias Shoddy.Numbers
```

## Calculate the number of pages

Divide the number of items by the size of a page, and round up. A last page
that is not full is still a page:

```elixir
Numbers.ceil_div(23, 10)
#=> 3

Numbers.ceil_div(20, 10)
#=> 2
```

For no items, the result is 0 pages.

## Keep the page number in the range

A user can ask for page 0 or page 99. Keep the number from 1 to the number
of pages:

```elixir
Numbers.clamp(99, 1, 3)
#=> 3
```

For no items, there are 0 pages, and the range from 1 to 0 contains no
number. `Shoddy.Numbers.clamp/3` raises `ArgumentError` for such a range.
Use `max(pages, 1)` as the maximum, so that an empty list has one empty
page.

## Show one page

Combine the steps. `Shoddy.Parse.integer/2` reads the page number, and
`Shoddy.Result.unwrap/2` gives page 1 for incorrect text:

```elixir
items = Enum.to_list(1..23)
per_page = 10
pages = Numbers.ceil_div(length(items), per_page)

page =
  %{"page" => "7"}
  |> Map.get("page", "1")
  |> Shoddy.Parse.integer()
  |> Shoddy.Result.unwrap(1)
  |> Numbers.clamp(1, max(pages, 1))

Enum.slice(items, (page - 1) * per_page, per_page)
#=> [21, 22, 23]
```
