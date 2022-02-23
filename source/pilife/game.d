/**
Life game module.
*/
module pilife.game;

import std.typecons : Nullable;

struct Life
{
}

struct Cell
{
    size_t x;
    size_tsize_t  y;
    Nullable!Life life;
}

struct LifeGame
{
    @disable this();
    @disable this(ref return scope LifeGame rhs);

    this(size_t width, size_t height) @nogc nothrow pure @safe scope
    {
        this.width_ = width;
        this.height_ = height;
    }

    ~this() @nogc nothrow pure @safe scope
    {
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
}

