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
    uint x;
    uint y;
    Nullable!Life life;
}

struct LifeGame
{
    @disable this();
    @disable this(ref return scope LifeGame rhs);

    this(uint width, uint height) @nogc nothrow pure @safe scope
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
        @property uint width()
        {
            return width_;
        }

        @property uint height()
        {
            return height_;
        }
    }

private:
    uint width_;
    uint height_;
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

