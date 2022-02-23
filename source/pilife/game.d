/**
Life game module.
*/
module pilife.game;

import std.typecons : Nullable;
import core.memory : pureMalloc, pureFree;

/**
Size mixture.
*/
mixin template Sized()
{
    const @nogc nothrow pure @safe scope
    {
        @property size_t width()
        {
            return width_;
        }

        @property size_t height()
        {
            return height_;
        }
    }

private:
    size_t width_;
    size_t height_;
}

struct Life
{
}

struct Cell
{
    size_t x;
    size_t y;
    Nullable!Life life;
}

struct LifeGame
{
    mixin Sized;

    @disable this();
    @disable this(ref return scope LifeGame rhs);

    this(size_t width, size_t height) @nogc nothrow pure @safe scope
    {
        this.width_ = width;
        this.height_ = height;
        this.plane1_ = Plane(width, height);
        this.plane2_ = Plane(width, height);
    }

    /**
    life game world translate to next state.
    */
    void next() @nogc nothrow pure @safe
    {
    }

    /**
    For each over world cells.
    */
    int opApply(Dg)(scope Dg dg) const
    {
        return 0;
    }

private:
    Plane plane1_;
    Plane plane2_;
}

///
@nogc nothrow pure @safe unittest
{
    auto game = LifeGame(100, 200);
    assert(game.width == 100);
    assert(game.height == 200);
}

private:

struct Plane
{
    mixin Sized;

    @disable this();
    @disable this(ref return scope Plane rhs);

    this(size_t width, size_t height) @nogc nothrow pure @trusted scope
    {
        this.width_ = width;
        this.height_ = height;
        immutable byteLength = width * height * bool.sizeof;
        this.cells_ = cast(bool[]) pureMalloc(byteLength)[0 .. byteLength];
    }

    ~this() @nogc nothrow pure @trusted scope
    {
        if (this.cells_.length > 0)
        {
            pureFree(&this.cells_[0]);
        }
    }

    bool opIndex(ptrdiff_t x, ptrdiff_t y) const @nogc nothrow pure @safe scope
    {
        immutable position = wrapPosition(x, y, width_, height_);
        return cells_[position.y * width_ + position.x];
    }

    void next(ref const(Plane) before) @nogc nothrow pure @safe scope
        in (before.width == width)
        in (before.height == height)
        in (before !is this)
    {
        foreach (ptrdiff_t y; 0 .. height)
        {
            foreach (ptrdiff_t x; 0 .. width)
            {
                size_t count = 0;
                static foreach (offsetY; -1 .. 2)
                {
                    static foreach (offsetX; -1 .. 2)
                    {
                        if (offsetX != 0 && offsetY != 0 && before[x + offsetX, y + offsetY])
                        {
                            ++count;
                        }
                    }
                }

                if (this[x, y])
                {
                    this[x, y] = (1 < count && count < 4);
                }
                else
                {
                    this[x, y] = (count == 3);
                }
            }
        }
    }

private:

    bool opIndexAssign(bool value, ptrdiff_t x, ptrdiff_t y) @nogc nothrow pure @safe
    {
        immutable position = wrapPosition(x, y, width_, height_);
        return (cells_[position.y * width_ + position.x] = value);
    }

    bool[] cells_;
}

///
@nogc nothrow pure @safe unittest
{
    auto plane = Plane(100, 200);
    assert(plane.width == 100);
    assert(plane.height == 200);
    assert(!plane[0, 0]);
    assert(!plane[-1, -10]);
    assert(!plane[100000, 100000]);

    plane[0, 0] = true;
    assert(plane[0, 0]);
    assert(plane[100, 200]);
    assert(plane[-100, -200]);
    assert(plane[100, 0]);
    assert(plane[0, 200]);

    assert(!plane[99, 200]);
    assert(!plane[100, 199]);
    assert(!plane[-99, -200]);
    assert(!plane[-100, -199]);
}

///
@nogc nothrow pure @safe unittest
{
    auto plane1 = Plane(5, 5);
    auto plane2 = Plane(5, 5);

    plane1[0, 0] = true;
    plane1[0, 2] = true;
    plane1[2, 2] = true;

    plane2.next(plane1);

    assert(plane2[1, 1]);

    assert(!plane2[0, 0]);
    assert(!plane2[0, 1]);
    assert(!plane2[1, 0]);
    assert(!plane2[2, 0]);
    assert(!plane2[2, 1]);
    assert(!plane2[2, 2]);
    assert(!plane2[0, 2]);
    assert(!plane2[1, 2]);
    assert(!plane2[2, 2]);
}

struct Position
{
    size_t x;
    size_t y;
}

Position wrapPosition(ptrdiff_t x, ptrdiff_t y, size_t width, size_t height) @nogc nothrow pure @safe
{
    immutable xOffset = x % cast(ptrdiff_t) width;
    immutable yOffset = y % cast(ptrdiff_t) height;
    return Position(
        (xOffset >= 0) ? xOffset : xOffset + width,
        (yOffset >= 0) ? yOffset : yOffset + height);
}

///
@nogc nothrow pure @safe unittest
{
    assert(wrapPosition(0, 0, 10, 10) == Position(0, 0));
    assert(wrapPosition(9, 19, 10, 20) == Position(9, 19));
    assert(wrapPosition(10, 20, 10, 20) == Position(0, 0));
    assert(wrapPosition(-1, 0, 10, 10) == Position(9, 0));
    assert(wrapPosition(0, -1, 10, 10) == Position(0, 9));
    assert(wrapPosition(-11, -21, 10, 20) == Position(9, 19));
}

