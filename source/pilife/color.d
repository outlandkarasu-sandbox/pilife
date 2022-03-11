/**
Color functions.
*/
module pilife.color;

import std.math : isClose, abs;

struct RGB
{
    ubyte red;
    ubyte green;
    ubyte blue;
}

RGB hueToRGB()(ubyte hue) @nogc nothrow pure @safe
{
    immutable h2 = (hue << 16) / 43;
    immutable x = cast(ubyte)(((0x10000 - abs((h2 & 0x1ffff) - 0x10000)) * 255) >>> 16);

    if (hue < 43)
    {
        return RGB(255, x, 0);
    }

    if (hue < 86)
    {
        return RGB(x, 255, 0);
    }

    if (hue < 129)
    {
        return RGB(0, 255, x);
    }

    if (hue < 172)
    {
        return RGB(0, x, 255);
    }

    if (hue < 215)
    {
        return RGB(x, 0, 255);
    }

    return RGB(255, 0, x);
}

///
@safe unittest
{
    assert(hueToRGB(129) == RGB(0, 255, 255));
}

