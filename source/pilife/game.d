/**
Life game module.
*/
module pilife.game;

import std.algorithm : min, max;
import std.typecons : Nullable;
import core.memory : pureMalloc, pureFree;

import pilife.color : RGB, hueToRGB;

struct Cell
{
    static Cell fromHue(ubyte hue, ubyte lifespan = ubyte.max) @nogc nothrow pure @safe
    {
        return Cell(hue, lifespan, (hue * 360.0 / ubyte.max).hueToRGB);
    }

    ///
    @nogc nothrow pure @safe unittest
    {
        assert(Cell.fromHue(128) == Cell(128, ubyte.max, RGB(0, 251, 255)));
        assert(Cell.fromHue(128, 100) == Cell(128, 100, RGB(0, 251, 255)));
    }

    ubyte hue;
    ubyte lifespan;
    RGB color;
}

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
        this.currentIs2_ = false;
    }

    Cell opIndexAssign()(auto ref const(Cell) value, ptrdiff_t x, ptrdiff_t y) @nogc nothrow pure @safe scope
    {
        if (currentIs2_)
        {
            plane2_[x, y] = value;
        }
        else
        {
            plane1_[x, y] = value;
        }
        return value;
    }

    /**
    life game world translate to next state.
    */
    void next() @nogc nothrow pure @safe
    {
        auto currentPlane = (currentIs2_ ? &plane2_ : &plane1_);
        auto nextPlane = (currentIs2_ ? &plane1_ : &plane2_);
        nextPlane.next(*currentPlane);
        currentIs2_ = !currentIs2_;
    }

    /**
    For each over world cells.
    */
    int opApply(Dg)(scope Dg dg) const
    {
        auto plane = (currentIs2_ ? &plane2_ : &plane1_);
        foreach (immutable y; 0 .. height_)
        {
            foreach (immutable x; 0 .. width_)
            {
                immutable life = (*plane)[x, y];
                auto result = dg(x, y, life);
                if (result)
                {
                    return result;
                }
            }
        }
        return 0;
    }

private:
    Plane plane1_;
    Plane plane2_;
    bool currentIs2_;
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
        immutable byteLength = width * height * Cell.sizeof;
        this.cells_ = cast(Cell[]) pureMalloc(byteLength)[0 .. byteLength];
        this.cells_[] = Cell.init;
    }

    ~this() @nogc nothrow pure @trusted scope
    {
        if (this.cells_.length > 0)
        {
            pureFree(&this.cells_[0]);
        }
    }

    ref inout(Cell) opIndex(ptrdiff_t x, ptrdiff_t y) inout @nogc nothrow pure @safe return scope
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
                uint maxLifespan = 0;
                uint sumHue = 0;
                static foreach (yOffset; -1 .. 2)
                {
                    static foreach (xOffset; -1 .. 2)
                    {
                        if (xOffset != 0 || yOffset != 0)
                        {
                            immutable cell = before[x + xOffset, y + yOffset];
                            if (cell.lifespan > 0)
                            {
                                sumHue += cell.hue;
                                maxLifespan = max(maxLifespan, cell.lifespan);
                                ++count;
                            }
                        }
                    }
                }

                immutable beforeCell = before[x, y];
                maxLifespan = max(maxLifespan, beforeCell.lifespan);
                if (beforeCell.lifespan > 0)
                {
                    this[x, y] = Cell(
                        beforeCell.hue,
                        cast(ubyte)((1 < count && count < 4) ? beforeCell.lifespan - 1 : 0),
                        beforeCell.color);
                }
                else if (count == 3)
                {
                    this[x, y] = Cell.fromHue(cast(ubyte) sumHue, cast(ubyte) maxLifespan);
                }
                else
                {
                    this[x, y] = Cell.fromHue(0, 0);
                }
            }
        }
    }

private:

    Cell opIndexAssign()(auto ref const(Cell) value, ptrdiff_t x, ptrdiff_t y) @nogc nothrow pure @safe
    {
        immutable position = wrapPosition(x, y, width_, height_);
        cells_[position.y * width_ + position.x] = value;
        return value;
    }

    Cell[] cells_;
}

///
@nogc nothrow pure @safe unittest
{
    auto plane = Plane(100, 200);
    assert(plane.width == 100);
    assert(plane.height == 200);
    assert(plane[0, 0].lifespan == 0);
    assert(plane[-1, -10].lifespan == 0);
    assert(plane[100000, 100000].lifespan == 0);

    plane[0, 0] = Cell(0, ubyte.max);
    assert(plane[0, 0].lifespan == ubyte.max);
    assert(plane[100, 200].lifespan == ubyte.max);
    assert(plane[-100, -200].lifespan == ubyte.max);
    assert(plane[100, 0].lifespan == ubyte.max);
    assert(plane[0, 200].lifespan == ubyte.max);

    assert(plane[99, 200].lifespan == 0);
    assert(plane[100, 199].lifespan == 0);
    assert(plane[-99, -200].lifespan == 0);
    assert(plane[-100, -199].lifespan == 0);
}

///
@nogc nothrow pure @safe unittest
{
    import std.math : isClose;

    auto plane1 = Plane(100, 100);
    auto plane2 = Plane(100, 100);

    plane1[0, 0] = Cell(1, ubyte.max);
    plane1[0, 2] = Cell(0, ubyte.max);
    plane1[2, 2] = Cell(1, ubyte.max);

    plane2.next(plane1);

    assert(plane2[1, 1].lifespan == ubyte.max);
    assert(plane2[1, 1].hue == 2);

    assert(plane2[0, 0].lifespan == 0);
    assert(plane2[0, 1].lifespan == 0);
    assert(plane2[0, 2].lifespan == 0);
    assert(plane2[1, 0].lifespan == 0);
    assert(plane2[1, 2].lifespan == 0);
    assert(plane2[2, 0].lifespan == 0);
    assert(plane2[2, 1].lifespan == 0);
    assert(plane2[2, 2].lifespan == 0);
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

