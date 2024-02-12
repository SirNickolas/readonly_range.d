import ro_slice;

nothrow pure @safe @nogc:

unittest {
    static assert(hasReadonlyElements!(const(int)[ ]));
    static assert(hasReadonlyElements!(const(char)[ ]));
    static assert(!hasReadonlyElements!(int[ ]));
    static assert(!hasReadonlyElements!(char[ ]));
}

unittest {
    static assert(is(RoRange!string == string));
    static assert(is(RoRange!(char[ ]) == struct));
    static assert(!__traits(compiles, RoRange!char));
}

unittest {
    int[3] data = [1, 2, 3];
    auto a = data[ ].readonly;
    assert(!a.empty);
    assert(a.length == 3);
    assert(a.front == 1);
    assert(a.back == 3);
    assert(a[$ - 2] == 2);
    assert(a[ ] == data[ ]);
    assert(a <= a);

    static assert(is(typeof(a[ ]) == RoRange!(int[ ])));
    static assert(is(typeof(a[0 .. 0]) == RoRange!(int[ ])));

    static assert(!__traits(compiles, a.front = 0));
    static assert(!__traits(compiles, a.back = 0));
    static assert(!__traits(compiles, { a[1] = 0; }));
    static assert(!__traits(compiles, ++a[1]));
    static assert(!__traits(compiles, a[1]++));
    static assert(!__traits(compiles, { a[ ] = 0; }));
    static assert(!__traits(compiles, ++a[ ]));
    static assert(!__traits(compiles, a[ ]++));
    static assert(!__traits(compiles, { a[ ][ ] = 0; }));
    static assert(!__traits(compiles, ++a[ ][ ]));
    static assert(!__traits(compiles, a[ ][ ]++));
    static assert(!__traits(compiles, { a[0 .. 0] = 0; }));
    static assert(!__traits(compiles, ++a[0 .. 0]));
    static assert(!__traits(compiles, a[0 .. 0]++));
    static assert(!__traits(compiles, { a[0 .. 0][ ] = 0; }));
    static assert(!__traits(compiles, ++a[0 .. 0][ ]));
    static assert(!__traits(compiles, a[0 .. 0][ ]++));
}

unittest {
    struct Point {
        int x, y;
    }

    Point[1] data = [
        { x: 1, y: 2 },
    ];
    auto p = data[ ].readonly;
    static assert(hasReadonlyElements!(typeof(p)));
}

unittest {
    import std.algorithm.iteration: filter;
    import std.range: iota;
    import std.range.primitives: isRandomAccessRange;

    auto a = iota(10).filter!q{a & 0x1};
    static assert(!isRandomAccessRange!(typeof(a)));
    static assert(is(typeof(a.readonly) == typeof(a)));
}

unittest {
    import std.range.primitives;

    static struct Forever {
        struct Dollar { }
        struct InfiniteSlice { }

        int* p;

        enum empty = false;
        @property ref inout(int) front() inout { return *p; }
        void popFront() const { }
        @property inout(Forever) save() inout { return this; }

        enum opDollar = Dollar.init;
        size_t[2] opSlice(size_t dim: 0)(size_t i, size_t j) const { return [i, j]; }
        InfiniteSlice opSlice(size_t dim: 0)(size_t, Dollar) const { return InfiniteSlice.init; }

        ref inout(int) opIndex(size_t) inout { return *p; }
        inout(Forever) opIndex() inout { return this; }
        inout(Forever) opIndex(InfiniteSlice) inout { return this; }

        auto opIndex(size_t[2] indices) {
            import std.range: takeExactly;

            return this.takeExactly(indices[1] - indices[0]);
        }
    }

    static assert(isRandomAccessRange!Forever);
    static assert(!hasReadonlyElements!Forever);

    int x = 5;
    auto a = Forever((() @trusted => &x)()).readonly;
    alias R = typeof(a);
    static assert(isForwardRange!R);
    static assert(isRandomAccessRange!R);
    static assert(isInfinite!R);
    static assert(hasSlicing!R);
    static assert(hasReadonlyElements!R);
    static assert(!hasLength!R);
    a = a[1 .. $];
    assert(a.front == 5);
    x++;
    assert(a.front == 6);
}

unittest {
    char[5] msg = "hello";
    auto a = msg[ ].readonly;
    static assert(!__traits(compiles, { a[4] = '!'; }));
}
