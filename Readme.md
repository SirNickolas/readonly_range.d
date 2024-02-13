# readonly_range

This library provides a simple wrapper that makes the passed range head-const: it prevents
reassigning the elements but otherwise does not affect their constness. This is essentially
the opposite of [Rebindable][rebindable].

[rebindable]: https://dlang.org/phobos/std_typecons.html#Rebindable

```d
import readonly_range;

struct S {
    int field;
}

auto data = [new S(1), new S(2), new S(3)];
auto view = data.readonlyRange;
// view[0] = null; // Forbidden.
view[0].field = 13; // Allowed.
assert(data[0].field == 13);
const(S*)[ ] constView = view; // Implicit conversion.
```

It works by making `front`, `back`, and `opIndex` return the element **by value**—keep that in mind
and avoid using it for types that are expensive to copy. Note that in the example above, `data` is
`S*[ ]` so `view[0]` copies just the pointer, not the pointed-to object.
