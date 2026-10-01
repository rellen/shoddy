# The design of Shoddy

This page tells why the functions of Shoddy behave as they do. For the rules
themselves, see [The conventions of the functions](../reference/conventions.md).

## The purpose

Some small patterns occur frequently in Elixir code. Some examples are a
change to a value only if the value is present, a map with optional entries,
and a list of sources for one value. Each pattern needs only a few lines.
But those lines often stop a pipeline, because the code must bind a variable
and write an `if` expression:

```elixir
name = params["name"]
name = if name, do: String.trim(name), else: name
```

Shoddy gives each pattern a function with a name. The pipeline continues,
and the name tells the reader the purpose of the step:

```elixir
name = Shoddy.then_if(params["name"], &String.trim/1)
```

## No runtime dependencies

A project that uses Shoddy gets no other package. Shoddy uses only the
standard library of Elixir. Each dependency in `mix.exs` is for development
or for tests only.

## The value is the first argument

The pipe operator `|>` puts a value into the first argument of the next
function. The modules `Map`, `MapSet` and `Enum` take the value first for the
same reason. Shoddy obeys the same rule, so each function can be a step of a
pipeline.

`Shoddy.Tagging.tag/2` also obeys this rule. The tag is the last argument,
although the tag is the first element of the tuple.

## The condition is truthiness

`Shoddy.then_if/2` and `Shoddy.Maps.put_if/3` examine whether a value is
truthy. A truthy value is a value that is not `nil` and not `false`. The
macro `if` and the operators `&&` and `||` use the same rule. Thus a reader
who knows `if` also knows the rule of these functions.

This rule has a cost. `Shoddy.Maps.put_if/3` never puts `false` into a map.
Thus `Shoddy.Maps.put_present/3` has the rule of `Shoddy.coalesce/2`, and
it ignores only `nil`.
For the same reason, `Shoddy.then_present/3` ignores only `nil`, and it calls
the function for `false`. It also gives a default for `nil`. A default for
`Shoddy.then_if/2` would be ambiguous, because the function would return
the default for `false` too.
[Build a map from optional data](../how-to/build-a-map-from-optional-data.md#keep-a-field-that-can-be-false)
shows when to use each function.

## Why coalesce rejects only nil

The expression `a || b` already returns the first truthy value.
`Shoddy.coalesce/2` has a different rule. By default, it rejects only `nil`.

This difference is important for a boolean option. For example, a user sets
an option to `false`, and the default of the option is `true`:

```elixir
false || true
#=> true

Shoddy.coalesce([false, true])
#=> false
```

With `||`, the choice of the user has no effect. `Shoddy.coalesce/2` keeps
it.

The option `:reject` adds other values, such as the empty string. The
function compares with `===/2`. Thus `reject: [0]` does not reject `0.0`.

The operator `||` does not evaluate its right side if the left side is
truthy. A list is different, because Elixir evaluates each element of a list
before the function receives the list. Thus `Shoddy.coalesce/2` calls a
function of arity 0 in the list, and the function can delay an expensive
operation. The option `call_functions?: false` is for a list in which a
function is the value.

`Shoddy.coalesce/2` does not examine the value of the option `:default`, and
it does not call it. Thus the default can be any value, such as `nil` or a
function.

`Shoddy.Maps.get_present/3` and `Shoddy.Keywords.get_present/3` follow the
same rule for one key. An absent key and the value `nil` get the default,
and `false` stays. `Map.get/3` gives its default only for an absent key, so
an entry with the value `nil` still gives `nil`. The code then often adds
`|| default`, and that operator replaces `false` too.

## Pipelines and with

`Shoddy.Result` gives a pipeline for a sequence of operations that can fail.
Each step receives the value of the step before it. An error goes to the end
with no change, unless a step recovers from it.

`Shoddy.Result.then_ok/2` continues the pipeline after an ok result.
`Shoddy.Result.recover/2` continues the pipeline after an error. It gives the
error to the next step, and an ok result goes to the end with no change.

The special form `with` does the same work as such a pipeline. Use `with` if
a step needs more than one earlier value, or if each error needs a different
treatment in the `else` clause. Use a pipeline of `Shoddy.Result` if each
step needs only the value of the step before it.

```elixir
with {:ok, text} <- Shoddy.Result.from_nil(params["age"], :no_age),
     {:ok, age} <- parse_age(text) do
  {:ok, age + 1}
end

params["age"]
|> Shoddy.Result.from_nil(:no_age)
|> Shoddy.Result.then_ok(&parse_age/1)
|> Shoddy.Result.map_ok(&(&1 + 1))
```

The two forms return the same result.

## Results in four forms

Elixir returns a result in more than one form. For example, `File.write/2`
returns `:ok` or `{:error, reason}`. `Map.fetch/2` returns `{:ok, value}` or
`:error`. `Shoddy.Result` accepts each of these forms, so it can operate on
the return value of each of these functions.

Most functions of `Shoddy.Result` raise `FunctionClauseError` for an input
that is not a result. Such an input is a defect in the program. An error at
the place of the defect is easier to find than a wrong value at a later
place.

The predicates `Shoddy.Result.ok?/1` and `Shoddy.Result.error?/1` are
different. They return `false` for each input that is not a result. Thus you
can use them with `Enum.filter/2` on a list of any values.

The names of the functions end in `_ok` or `_error`, as in
`Shoddy.Result.map_ok/2`. The name thus tells which form the function
changes. An import of the module also does not bring a general name, such as
`map`, into the scope.

## A stream for collect

Code often calls an operation that can fail for each element of a list, and
must stop at the first error. A function that takes the list and the
operation would do this work. But `Stream.map/2` already applies the
operation one element at a time, and only when the next step reads that
element.

Thus `Shoddy.Result.collect/2` accepts a stream, and Shoddy has no second
function for the same work. With `on_error: :halt`, the function reads no
element after the first error. The stream then does not call the operation
for a later element. The caller selects the behavior: `Enum.map/2` calls the
operation for each element, and `Stream.map/2` stops at the first error.

The function does not accept a map. A map is enumerable, but its elements
are key-value tuples. A map as the first argument is thus a mistake, and
`FunctionClauseError` tells the caller at once.

## A reduction that can fail

`Shoddy.Result.collect/2` makes a list of independent values. Some work is
different: each step needs the result of the step before it. An example is
a stock that each order reduces. `Enum.reduce_while/3` can do this work, but
each call needs the same `case` expression. That expression changes each
result into `{:cont, acc}` or `{:halt, error}`. `Shoddy.Result.reduce_ok/3`
contains this expression.

The function accepts a map, but `Shoddy.Result.collect/2` does not. The
elements of `Shoddy.Result.collect/2` must be results, and the elements of a
map are key-value tuples. The elements of `Shoddy.Result.reduce_ok/3` are
input to the function, so a key-value tuple is a correct element.

For a bare `:ok`, the new accumulator is `nil`. This follows the rule of the
other functions of `Shoddy.Result`: a bare `:ok` has the value `nil`.

## Each error of a map

`Shoddy.Result.collect_map/1` returns each error, but `Shoddy.Result.collect/2`
stops at the first error by default. A list has an order, so its first
error has a meaning. A map has no order that a program can use, so a
"first" error would depend on the way that the runtime stores the map.
The usual map of results is a form, and a form shows each error at one
time. Thus the function returns a map of reasons with the same keys.

## Why attempt needs a list of exceptions

`Shoddy.Result.attempt/2` rescues only the exceptions in its option
`:rescue`. A function that rescued each exception would also convert a
defect, such as a `FunctionClauseError` from a wrong call, into an error
result. The program would then continue with a wrong assumption, and the
defect would be difficult to find. The list states which failures are
expected. Each other exception continues with its stacktrace.

## Keyword lists in a separate module

`Access` reads maps and keyword lists in the same way, but a put is different.
`Keyword.put/3` deletes each entry for the key and puts the new entry at the
start of the list. One function for the two types would hide that
difference.

Thus `Shoddy.Keywords` is a separate module with the same function names as
`Shoddy.Maps`. The name of each module tells the type of its first argument,
and the documentation of each function tells its effect on that type. The
specifications stay exact: a map goes in and a map comes out, and a keyword
list goes in and a keyword list comes out.

## Structs in Shoddy.Maps

A struct is a map, so `Shoddy.Maps.put_if/3` and `Shoddy.Maps.put_present/3`
accept it. But `Map.put/3` can add a key that is not a field of the struct.
The result then is not a correct struct. For example, a wrong key such as
`:emial` makes a `%User{}` with an extra key, and no error occurs.

Thus the functions accept only a field of the struct as the key. They raise
`KeyError` for another key, as the update syntax `%{struct | key: value}`
does. They raise this error also if they do not put the value. A wrong key
then causes an error at the first call, and not only when the value is
present.

## The values that deep_merge merges

`Shoddy.Maps.deep_merge/2` merges two values only if they are plain maps. It
does not merge a struct, a list or a keyword list. The value of the right
side replaces it.

A struct is a map, but its fields belong together. For example, a `Date`
from the left side with the month of the right side can be a date that does
not exist. A merge of two structs of different types makes a value that is
not a correct struct.

A list has no keys, so a merge of two lists has no single meaning. The
result could join the lists, or remove the duplicates, or replace the list.
A keyword list has keys, but it can contain a key more than one time, and
its order can be important. Each rule is correct for some data and wrong for
other data. Thus the function does not select a rule. `Map.merge/3` takes a
function, and the caller can give each rule there.

`Config.Reader.merge/2` merges nested keyword lists, but it accepts only a
configuration: a keyword list of applications, each with a keyword list. It
does not accept a map.

An empty map on the right side does not remove the nested map of the left
side. This rule follows from the merge: an empty map has no keys to change.
To replace a nested map, put the new map after the merge.

## New names in take_as

`Shoddy.Maps.take_as/2` converts the parameters of a web form, which have
string keys, into a map with atom keys. The user controls the keys of the
parameters. Thus the function never makes an atom from the input. Only the
values of the mapping become keys, and your code contains the mapping.

If two keys of the mapping have the same new name, the two values compete
for one key. The value in the result would then depend on the order in which
the function reads the mapping, and the contract of a map gives no order.
Thus the function raises `ArgumentError`. The message names each shared new
name with all of its keys, so you can correct the mapping in one step.

The new name `:__struct__` would make a result that looks like a struct but
has only some of its fields. Code that matches on the struct would then
accept an incorrect value. Thus the function raises `ArgumentError` for that
name, and the result is always a plain map.

The mapping must be a plain map. The guard rejects a struct with
`FunctionClauseError`, as for each other argument of the wrong type. Without
the guard, most structs would cause `Protocol.UndefinedError`, because they
do not implement `Enumerable`.

`Shoddy.Maps.map_keys/2` follows the same rule. If the function gives two
keys the same new key, one value goes, and the order of the map decides
which. Thus `Shoddy.Maps.map_keys/2` raises `ArgumentError`, and the message
names each such new key with its keys.

## One element for each call of toggle

A map set can contain a list as an element. If `Shoddy.MapSets.toggle/2`
toggled each element of a list, then no call could toggle a list that is an
element. Thus `Shoddy.MapSets.toggle/2` always toggles one element, and
`Shoddy.MapSets.toggle_all/2` toggles each element of a list.

## One toggle for each element of the list

`Shoddy.MapSets.toggle_all/2` toggles an element one time, also if the list
contains the element more than one time. A list of elements to toggle often
contains a duplicate by accident, for example after `++/2`. If the function
toggled the element one time for each occurrence, two occurrences would
cancel and the element would not change. The function would not tell you
about this.

With one toggle for each element, the result of
`Shoddy.MapSets.toggle_all/2` is equal to the result of
`MapSet.symmetric_difference/2` with a map set of the list. The function is
also fast for a short list and a large map set. On Elixir 1.19 and 1.20,
`MapSet.symmetric_difference/2` reads each element of the larger map set,
also for a list of a few elements.

To toggle an element one time for each occurrence, for example to apply a
list of events, call `Shoddy.MapSets.toggle/2` for each element with
`Enum.reduce/3`.

## How has_duplicates? finds a duplicate

`Shoddy.Lists.has_duplicates?/1` must be fast for two types of list. In a
list with a duplicate near the start, the function can stop at that
duplicate. In a list with no duplicates, the function must read each
element.

Two methods are available:

- A walk puts each element into a map, and stops at the first element that
  is already in the map.
- `:maps.from_keys/2` makes a map from all the elements in one call. The
  function then compares the size of the map with the length of the list.
  `:maps.from_keys/2` is a built-in function of the runtime, so it is
  approximately 4 times faster than the walk. But it cannot stop early.

Thus the function uses the two methods in sequence. It walks the first 1024
elements. If it finds no duplicate there, it calls `:maps.from_keys/2` for
the full list. This table shows the times for a list of 1 000 000 integers,
on OTP 28 (median of 7 runs):

| List | Walk | `:maps.from_keys/2` | `has_duplicates?/1` |
| --- | --- | --- | --- |
| No duplicates | 1144 ms | 283 ms | 282 ms |
| One duplicate at the end | 1105 ms | 303 ms | 257 ms |
| Many duplicates | 0.12 ms | 326 ms | 0.13 ms |
| One duplicate at index 1100 | 0.15 ms | 253 ms | 247 ms |

The last row shows the cost of this method. A duplicate just after the first
1024 elements gets the time of `:maps.from_keys/2`, although a walk would
stop soon after the first 1024 elements. In each other case,
`has_duplicates?/1` gets the time of the faster method.

`Shoddy.Lists.duplicates/1` must read each element in each case, so it does
not use this method.

## Two errors from single

`Shoddy.Lists.single/1` has two different errors. An empty list usually
means that a record does not exist. More than one element usually means
that a condition is not specific enough, or that the data is not correct.
The caller must often do a different thing for each error, so the reasons
are different.

`List.first/1` does not tell these cases. It returns `nil` for an empty
list, and it ignores each element after the first. A second element is thus
not visible. The error `{:many, count}` makes it visible, and the count
tells the size of the problem.

The function returns a result and does not raise an exception. A list of the
wrong length is usually an error in the data, not a defect in the program.
If a different length is a defect, match the pattern `[element]`.

## Why extend_precision never lowers the precision

The precision of a time value is part of its struct, and `==` compares the
structs. Thus two values of the same point in time are unequal if their
precision is different.

Elixir can already make the precision higher. A call to `DateTime.add/4` with
an amount of 0 returns a value with the precision of the unit. But the name
`add` does not tell the reader the purpose of the call.
`Shoddy.DateTimes.extend_precision/2` returns the same value, and its name
tells the purpose.

The function never lowers the precision, because a lower precision can
discard digits. `DateTime.truncate/2` and the functions of the same name in
`NaiveDateTime` and `Time` already do that operation, and their name tells
the reader about the loss.

The function refuses the precision `:second`. A precision of 0 digits is the
lowest precision, so a call with `:second` can never change a value. Such a
call is always a mistake.

## Why floor accepts only UTC

`Shoddy.DateTimes.floor/2` sets the fields below the unit to zero. For a
`NaiveDateTime`, a `Time` and a `DateTime` in UTC, the result is always a
correct value.

A time zone with daylight saving time is different. On the day of a change,
the clock skips some local times, or it shows some local times two times.
In some zones, the change occurs at midnight, so the start of that day does
not exist. The correct result then needs a time zone database, which tells
the offset of each local time. Shoddy has no runtime dependencies, so it
has no such database.

Thus the function raises `FunctionClauseError` for a `DateTime` in another
time zone, and it does not return a value that can be wrong. The caller
selects the rule. A conversion to UTC rounds the moment in UTC. A
conversion to a `NaiveDateTime` rounds the local wall time.

## Why ceil does not accept a Time

`Shoddy.DateTimes.ceil/2` returns a value that is not before its argument.
A `Time` has no day, so this rule fails near the end of the day. The next
hour after `~T[23:30:00]` is midnight of the next day, and a `Time` cannot
show that day. `Time.add/3` goes back to `~T[00:00:00]`, which is before the
argument.

The function could raise an error only for such a value. But then a correct
call could fail at some times of the day only, and a test at another time
would not find the problem. Thus the function does not accept a `Time` at
all. `Shoddy.DateTimes.floor/2` accepts a `Time`, because its result is
always in the same day.

`ceil/2` returns its argument with no change if the argument is at the start
of a unit. It does not return the end of the unit that contains the
argument. This rule makes it the counterpart of `floor/2`: each function
returns the nearest start of a unit in one direction.

`Shoddy.DateTimes.next_start/2` is the function for the other need. It
returns the start of the next unit, also for a value at the start of a
unit. Its result is always after the value. Thus a job that runs each hour
never gets its own start time as the next run.

## What is_non_empty_string accepts

`Shoddy.Strings.is_non_empty_string/1` is a guard, not a function. A guard
can select a function clause, so the code needs no `if` expression in the
body. But a guard can use only a small set of operations. These limits
decide what the guard accepts.

Whitespace is a character such as a space, a tab or a newline. A guard can
examine only a fixed number of bytes. It cannot examine each byte of a
string of any length. Thus the guard cannot tell `" "`, which contains only
whitespace, from `" a"`, which has content after the whitespace. A guard
that rejects each string that starts with a space would reject `" a"` also.
Thus the guard accepts each string that is not empty. If whitespace must
count as empty, the caller trims the string first.

UTF-8 is the encoding that Elixir uses for the characters of a string. A
guard cannot call `String.valid?/1`. Thus the guard accepts each binary that
is not empty, also a binary that is not valid UTF-8. This is the same rule
as `is_binary/1`, which Elixir uses for strings.

The name does not end in `_present`. In Shoddy, `_present` means "not
`nil`", and `""` is not `nil`. The name `is_non_empty_string` tells the two
conditions: the value is a string, and it is not empty. The form follows
`is_non_struct_map/1` of `Kernel`.

`Shoddy.Strings.blank?/1` is the function for the other rule. It calls
`String.trim/1`, so it treats whitespace as empty, and it knows the Unicode
whitespace. A function can do this, but a guard cannot. The function accepts
only `nil` and a string. A number or a list is not text, so `blank?` has no
clear answer for it, and the function raises `FunctionClauseError`.

## Why presence changes only the empty string

`Shoddy.Strings.presence/1` changes `""` to `nil`, and it returns each other
value with no change. Thus its result goes to the functions that ignore
`nil`, such as `Shoddy.Maps.put_present/3` and `Shoddy.then_present/3`.
Shoddy has no second set of functions that also ignore `""`.

The function does not change `false`, a number or a list. A form field
that a program converts to a boolean or to a number keeps its value. The
guard is different: it rejects each value that is not a binary. Thus
`is_non_empty_string(value) && value` would lose such a value, and
`presence/1` does not.

The function does not trim the string, for the same reason as the guard.
The two tools then agree: `presence/1` returns `nil` for a binary only if
`is_non_empty_string/1` rejects it.

## Why Parse examines the full text

`Integer.parse/1` returns the start of the text as an integer, and it also
returns the remaining text. The caller must check that the remaining text is
empty. Code often omits this check, and then `"25 items"` becomes `25`.
`Shoddy.Parse.integer/2` does the check, so an incorrect value never becomes
a correct one.

The functions do not trim the text. A trim is a decision about the input,
and different inputs need different rules. The caller makes this decision
with `String.trim/1`.

The functions return a result and do not raise an exception. Incorrect user
input is not a defect in the program. The caller can show a message, or use
a default with `Shoddy.Result.unwrap/2`. The options are different. An
unknown option or a `:min` that is higher than `:max` is a defect in the
program, so it raises `ArgumentError`.

`Shoddy.Parse.one_of/2` returns an atom, but it never makes one. The runtime
never removes an atom, and the number of atoms has a limit. If
`String.to_atom/1` receives user input, a user can fill the table of atoms
and stop the system. `String.to_existing_atom/1` is safe from this problem,
but it accepts the name of each atom in the system, not only the atoms that
the code expects. The list of allowed atoms is thus also a list of the
correct values.

`Shoddy.Parse.boolean/2` accepts only `"true"` and `"false"` by default.
Other programs use many other texts, such as `"1"`, `"on"`, `"yes"` and
`"Y"`. A long default list would accept a text that the caller did not
expect. A text that is not in the list is often a mistake, for example a
variable that a person set to `"ture"`. Thus the caller gives the other
texts with the options `:true_values` and `:false_values`.

## Why index_by raises for a key that is not unique

`Shoddy.Lists.index_by/2` makes a map, and a map has one value for each key.
If two elements have the same key, one of them must go. `Map.new/2` keeps the
last element, and the program continues with less data than it read. No
error tells the reader about the loss.

The caller of `Shoddy.Lists.index_by/2` expects unique keys. A second element
with the same key thus shows that this expectation is wrong, in the code or
in the data. The function raises `ArgumentError`, so the problem is visible
at the place where it occurs. The message tells each such key, so the reader
can find the records.

For data where a key can occur more than one time, the caller must select a
rule. `Enum.group_by/2` keeps each element. `Shoddy.Lists.duplicates_by/2`
finds the keys that are not unique.

## How truncate counts the length

`Shoddy.Strings.truncate/3` counts graphemes. A grapheme is a character that
a reader sees. One grapheme can contain more than one code point, such as a
letter and an accent, or the parts of an emoji. A count of bytes or of code
points could cut such a character in half. The result would then show a
wrong character, or it would not be a valid string.

The omission is part of the maximum length. A caller gives the maximum
because the space has a limit, such as the width of a column. A result that
is longer than the maximum would not fit in that space.

The function raises `ArgumentError` for an omission that is longer than the
maximum. It raises this error also for a string that is short enough. A
check that depends only on the arguments finds the mistake at the first
call, and not only for a long string.

`Shoddy.Strings.truncate_bytes/2` has a different purpose: storage. A
database column or a protocol counts bytes. The function stops at the end
of a grapheme, not at the end of a code point. A cut after a letter and
before its accent would give a valid string, but it would show a different
character. The function adds no omission, because the stored value is data,
not text for a reader.

## Why between? excludes the last value

`Shoddy.DateTimes.between?/3` uses a period that includes its first value
and excludes its last value. Two periods that follow each other then share
no value. For example, midnight belongs to the new day, and not to the day
before it. A period that included its last value would put midnight into
two days, so a count by day would count an event two times.

This rule also makes the last value easy to calculate. The end of a day is
the start of the next day. A period that included its last value would need
the last microsecond of the day, and that value depends on the precision.

The function compares the values with the function `compare/2` of their
module. The operators `<` and `>` compare the fields of a struct in an order
that is not the order of time. For example, `~D[2024-02-01] < ~D[2024-01-31]`
returns `true`.

The function returns `false` for a period in the wrong order, and it does
not raise an exception. A name that ends in `?` tells that the function
returns a boolean. Such a period contains no value, so `false` is correct.

Unlike `Shoddy.DateTimes.floor/2`, this function accepts a `DateTime` in each
time zone. A comparison of two points in time needs no time zone database.

`Shoddy.DateTimes.overlap?/2` uses the same rule for two periods. Two
periods overlap only if a value is in the two periods. Thus a booking that
ends on 4 July and a booking that starts on 4 July do not overlap. A rule
that included the last value would refuse the second booking.

## When nil counts as absent

Some functions of `Shoddy.Maps` treat a key with the value `nil` as an
absent key. Others treat it as a present key. The rule follows the purpose
of each function.

`Shoddy.Maps.get_present/3` reads a value. For a reader, an absent value and
`nil` usually have the same meaning: no value. Thus the function returns the
default for the two cases.

`Shoddy.Maps.put_path/3` goes into a map at each key of the path. A value of
`nil` contains nothing that the function can lose, so the function replaces
it with a map. Each other value that is not a map, such as `false`, is
data. The function does not replace data, so it raises `ArgumentError`.

`Shoddy.Maps.fetch_keys/2` checks that the keys exist, as `Map.fetch/2`
does. A key with the value `nil` exists. A form or an API can send `nil` on
purpose, for example to clear a field. The caller can remove such entries
first if `nil` must count as absent.

## The order of a list of records

A list of records often goes to a person, for example as a table or as a
list with headings. The order of that list is part of its meaning. Three
functions of `Shoddy.Lists` keep or make an order where the standard
functions lose it.

`Shoddy.Lists.group_by_in_order/2` returns a list, not a map. A map with
more than 32 keys has no order that a program can use, so the groups of
`Enum.group_by/2` can change their order. A list of `{key, elements}`
tuples keeps the order of the first element of each key. Thus a sorted
list stays sorted after the grouping.

`Shoddy.Lists.sort_by_keys/2` compares a date or a time with `compare/2` of
its module. The operators `<` and `>` compare the fields of a struct in an
order that is not the order of time. The function also gives each key its
own direction. A single key with a tuple of values cannot do this, because
the direction applies to the full tuple. Equal elements stay in the order
of the input, so a second sort does not move them.

`Shoddy.Lists.upsert_by/4` puts a changed record at the position of the old
record. A person who reads the list then sees the change at the same place.
If more than one record has the key, the function replaces only the first.
The key should be unique, and a replacement of each such record would make
copies of the new record.

## Why Env raises an exception

The functions of `Shoddy.Parse` return a result, because incorrect user
input is not a defect. The functions of `Shoddy.Env` raise an exception
instead. They run when the application starts, in `config/runtime.exs`. A
wrong value there is a mistake in the deployment. If the application
started with a default in place of the wrong value, nobody would see the
mistake until the setting had an effect. An exception stops the start, and
its message tells the name of the variable.

An empty value counts as an absent variable. A tool that starts a container
often sets each variable of a template, also the variables with no value.
Thus `""` usually means "not set". For an absent variable without a
default, the functions raise `System.EnvError`, as `System.fetch_env!/1`
does.

The functions do not examine the default. A default of `nil` can then mark
an optional setting. A default outside the range of `:min` and `:max` can
mark a special case, such as "no limit".

## Integers in Numbers

`Shoddy.Numbers.ceil_div/2` uses only integer operations. The expression
`ceil(a / b)` gives the same result for small numbers, but the operator `/`
returns a float. A float stores about 16 decimal digits, so a larger integer
loses its last digits. For example, `ceil((10 ** 17 + 1) / 1)` returns
`10 ** 17`. A count of items or bytes can be that large, and an error of one
gives a page or a block too few.

`Shoddy.Numbers.clamp/3` raises `ArgumentError` if the minimum is higher
than the maximum. Such a range contains no number. A result in that case
would be wrong for each rule, so an error at the call is the safer choice.

## No entry is lost in a change of keys

`Shoddy.Maps.rename_key/3`, `Shoddy.Maps.invert/1` and
`Shoddy.Maps.stringify_keys/1` change the keys of a map. A map has one value
for each key. If two entries get the same key, one value goes, and nothing
tells the reader about it. Thus each of these functions raises
`ArgumentError` for such a case, as `Shoddy.Maps.take_as/2` and
`Shoddy.Maps.map_keys/2` do.

`Shoddy.Maps.increment/3` puts the amount itself for an absent key. The
expression `Map.update(map, key, 1, &(&1 + by))` puts `1`, which is
correct only for an amount of `1`. The function makes the two values the
same, so the mistake cannot occur.

`Shoddy.Maps.diff/2` compares with `===/2` and only at the top level. A
change from `1` to `1.0` is a change. A deep comparison would need a rule
for lists, structs and keyword lists, and each rule is correct for some
data only.

## Lists that a user changes

`Shoddy.Lists.toggle/2` removes each occurrence of an element that the list
contains. A selection usually contains an element one time. If it contains
the element more than one time, a user who turns the element off expects
it to go completely. A new element goes to the end, so the selection keeps
the order in which the user made it.

`Shoddy.Lists.move/3` and `Shoddy.Lists.cycle_next/2` raise `ArgumentError`
for an index or an element that is not in the list. The caller gets that
value from the list, so a wrong value is a defect. A quiet result, such as
the list with no change, would hide the defect.

`Shoddy.Lists.join_by/4` keeps each element of the first list, also an
element with no partner. A report about orders must show each order, also
an order whose user is gone. The keys of the second list must be unique.
Otherwise one order would have more than one partner, and the function
would have to select one of them.

## What mask shows

`Shoddy.Strings.mask/2` shows some characters of a secret, so that a person
can tell two secrets apart in a log. The function never shows the full
string. If the visible parts are as long as the string, it hides each
character. A rule that showed a short secret completely would put that
secret into the log.

The result has the same length as the input, so a reader can see where a
value is shorter than expected. Thus the result also tells the length of
the secret. For a secret whose length must stay hidden, such as a password,
do not log the value at all.

## A result for an empty list in mean

`Shoddy.Numbers.mean/1` returns `{:error, :empty}` for an empty list. The
mean of no numbers is not defined, and 0 would be a wrong answer. An
average rating of 0 is a different fact from no ratings. A result makes the
caller decide, for example with `Shoddy.Result.unwrap/2`.
