module readonly_range;

///
public import std.range.primitives: back, empty, front, popBack, popFront, save;

import std.range.primitives: isInputRange;

/++
    `true` if `R` is an input range with read-only elements. This is *not* simply the inverse of
    [hasAssignableElements](https://dlang.org/phobos/std_range_primitives.html#hasAssignableElements):
    when autodecoding is enabled, the latter returns `false` for narrow strings (`char[ ]`,
    `wchar[ ]`), although they can be mutated by index (`s[i] = c`). This trait, on the other hand,
    checks `front`, `back`, and `opIndex` independently.
+/
enum bool hasReadonlyElements(R) =
    isInputRange!R &&
    !is(typeof((R r) { r.front = typeof(r.front).init; })) &&
    !is(typeof((R r) { r.back = typeof(r.back).init; })) &&
    !is(typeof((R r) { r[0] = typeof(r[0]).init; }));

private struct _Indices(A, B) {
    A a;
    B b;
}

/++
    A thin wrapper that makes the range `R` head-const (aka read-only, aka final):
    [hasReadonlyElements]`!(ReadonlyRange!R)` is `true` for any `R`. If `R` is already head-const,
    `ReadonlyRange` aliases itself to it.
+/
struct ReadonlyRange(R) if (isInputRange!R && !hasReadonlyElements!R) {
pragma(inline, true):
    import std.range.primitives: ElementType, hasLength, isBidirectionalRange, isForwardRange;

    private R _r;

    /++
        Range interface. `front`, `back`, and `opIndex` return a **copy** of the element, therefore,
        they are not lvalues.
    +/
    static if (!is(typeof({ enum e = R.empty; })))
        @property bool empty() { return _r.empty; }
    else
        enum empty = R.empty;

    /// ditto
    @property ElementType!R front() { return _r.front; }

    /// ditto
    void popFront() { _r.popFront(); }

    static if (isBidirectionalRange!R) {
        /// ditto
        @property ElementType!R back() { return _r.back; }

        /// ditto
        void popBack() { _r.popBack(); }
    }

    static if (isForwardRange!R) {
        /// ditto
        @property ReadonlyRange!R save() { return ReadonlyRange!R(_r.save); }
    }

    static if (hasLength!R) {
        /// ditto
        @property size_t length() { return _r.length; }
    }

    /// ditto
    template opDollar(size_t i) {
        // https://dlang.org/spec/operatoroverloading.html#dollar
        static if (is(typeof(_r.opDollar!i)))
            auto ref opDollar() { return _r.opDollar!i; }
        else {
            static assert(!i, '`' ~ R.stringof ~ "` does not support multidimensional indexing");
            static if (is(typeof(_r.opDollar)))
                auto ref opDollar() { return _r.opDollar; }
            else
                alias opDollar = length;
        }
    }

    /// ditto
    auto ref opSlice(size_t i, A, B)(auto ref A lower, auto ref B upper) {
        /+
            Normally, `a[ ]` is rewritten to `a.opIndex()`, and `a[i .. j]` is rewritten to either
            `a.opIndex(a.opSlice!0(i, j))` or `a.opIndex(a.opSlice(i, j))` if the former does not
            compile. However, if they still fail to compile, DMD tries legacy rewrites:
            `a[ ] -> a.opSlice()` and `a[i .. j] -> a.opSlice(i, j)`. In these cases, `opSlice` has
            a completely different meaning. Therefore, we never invoke `_r.opSlice` manually for 0-
            and 1-dimensional slicing since we cannot know what semantics it will have.

            https://dlang.org/spec/operatoroverloading.html#slice
        +/
        static if (i)
            return _r.opSlice!i(lower, upper);
        else
            return _Indices!(A, B)(lower, upper);
    }

    /// ditto
    auto opIndex(Args...)(auto ref Args indices) {
        // See the comment for `opSlice` above.
        static if (!Args.length)
            return ReadonlyRange!R(_r[ ]);
        else static if (is(Args[0] == _Indices!(A, B), A, B))
            static if (Args.length == 1) // Unfortunately, this check is required.
                return readonlyRange(_r[indices[0].a .. indices[0].b]);
            else
                return readonlyRange(_r[indices[0].a .. indices[0].b, indices[1 .. $]]);
        else
            return _r[indices];
    }

    /// `ReadonlyRange!R` is implicitly convertible to `const R` (i.e., head-const to deep-const).
    T opCast(T)() const if (is(T == const R)) { return _r; }

    /// ditto
    alias toConst = opCast!(const R);
    alias toConst this;
}

/// ditto
template ReadonlyRange(R) if (hasReadonlyElements!R) {
    alias ReadonlyRange = R;
}

/// ditto
pragma(inline, true)
ReadonlyRange!R readonlyRange(R)(R r) if (isInputRange!R) {
    static if (hasReadonlyElements!R)
        return r;
    else
        return ReadonlyRange!R(r);
}
