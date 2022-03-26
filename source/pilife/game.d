/**
Life game module.
*/
module pilife.game;

import std.algorithm : min, max, reverse, map;
import std.array : array;
import std.exception : assumeUnique;
import std.parallelism : parallel;
import std.range : iota;
import std.typecons : Nullable;
import core.memory : pureMalloc, pureFree;

import pilife.color : RGB, hueToRGB;

/**
Life game cell.
*/
struct Cell
{
    static Cell fromHue(ubyte hue, ubyte lifespan = ubyte.max) @nogc nothrow pure @safe
    {
        return Cell(hue, lifespan, hue.hueToRGB);
    }

    ///
    @nogc nothrow pure @safe unittest
    {
        assert(Cell.fromHue(129) == Cell(129, ubyte.max, RGB(0, 255, 255)));
        assert(Cell.fromHue(129, 100) == Cell(129, 100, RGB(0, 255, 255)));
    }

    /**
    Empty cell value.
    */
    static immutable empty = Cell.init;

    /**
    is live.
    */
    @property bool live() const @nogc nothrow pure @safe scope
    {
        return lifespan > 0;
    }

    ///
    @nogc nothrow pure @safe unittest
    {
        assert(!Cell.empty.live);
        assert(Cell.fromHue(0).live);
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

    void addLife(ptrdiff_t x, ptrdiff_t y, scope const bool[][] life, ubyte hue) @nogc nothrow pure @safe scope
    {
        foreach (lr, row; life)
        {
            foreach (lc, b; row)
            {
                if (b)
                {
                    this[x + lc, y + lr] = Cell.fromHue(hue);
                }
                else
                {
                    this[x + lc, y + lr] = Cell.init;
                }
            }
        }
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
    void next() @safe
    {
        auto nextPlane = (currentIs2_ ? &plane1_ : &plane2_);
        nextPlane.next(currentPlane);
        currentIs2_ = !currentIs2_;
    }

    @property ref const(Plane) currentPlane() const @nogc nothrow pure @safe return scope
    {
        return (currentIs2_ ? plane2_ : plane1_);
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

/**
Life game plane.
*/
struct Plane
{
    mixin Sized;

    @disable this();
    @disable this(ref return scope Plane rhs);

    /**
    For each over world cells.
    */
    int opApply(Dg)(scope Dg dg) const
    {
        foreach (immutable y; 0 .. height)
        {
            immutable rowIndex = y * width;
            foreach (immutable x; 0 .. width)
            {
                auto result = dg(x, y, cells_[rowIndex + x]);
                if (result)
                {
                    return result;
                }
            }
        }
        return 0;
    }

private:

    this(size_t width, size_t height) @nogc nothrow pure @trusted scope
    {
        this.width_ = width;
        this.height_ = height;
        immutable byteLength = width * height * Cell.sizeof;
        this.cells_ = cast(Cell[]) pureMalloc(byteLength)[0 .. byteLength];
        this.cells_[] = Cell.empty;
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

    void next(ref const(Plane) before) @trusted scope
        in (before.width == width)
        in (before.height == height)
        in (before !is this)
    {
        foreach (ptrdiff_t y; parallel(iota(cast(ptrdiff_t) height)))
        {
            immutable rowIndex = y * width;

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

                immutable cellIndex = rowIndex + x;
                immutable beforeCell = before.cells_[cellIndex];
                maxLifespan = max(maxLifespan, beforeCell.lifespan);
                if (beforeCell.live && 1 < count && count < 4)
                {
                    cells_[cellIndex] = Cell(
                        beforeCell.hue,
                        cast(ubyte)(beforeCell.lifespan - 1),
                        beforeCell.color);
                }
                else if (!beforeCell.live && count == 3 && maxLifespan > 1)
                {
                    cells_[cellIndex] = Cell.fromHue(cast(ubyte) sumHue, cast(ubyte) maxLifespan);
                }
                else
                {
                    cells_[cellIndex] = Cell.empty;
                }
            }
        }
    }

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
@safe unittest
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

immutable bool[][] GLIDER = [
    [false, true, false],
    [false, false, true],
    [true, true, true],
]; 

immutable bool[][] SPACE_SHIP = [
    [true, false, false, true, false],
    [false, false, false, false, true],
    [true, false, false, false, true],
    [false, true, true, true, true],
]; 

immutable(bool[][]) flipH(return scope const bool[][] life) nothrow pure @trusted
{
    return life.map!((a) => assumeUnique(a.dup.reverse)).array;
}

immutable(bool[][]) flipV(return scope const bool[][] life) nothrow pure @trusted
{
    return assumeUnique(life.dup.reverse);
}

private:

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

