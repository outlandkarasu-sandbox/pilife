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

RGB hueToRGB()(real hue) @nogc nothrow pure @safe
{
    immutable h2 = (hue % 360.0) / 60.0;
    immutable x = cast(ubyte)((1.0 - abs(h2 % 2.0 - 1.0)) * 255.0);

    if (0.0 <= h2 && h2 < 1.0) {
        return RGB(255, x, 0);
    }

    if (1.0 <= h2 && h2 < 2.0) {
        return RGB(x, 255, 0);
    }

    if (2.0 <= h2 && h2 < 3.0) {
        return RGB(0, 255, x);
    }

    if (3.0 <= h2 && h2 < 4.0) {
        return RGB(0, x, 255);
    }

    if (4.0 <= h2 && h2 < 5.0) {
        return RGB(x, 0, 255);
    }

    if (5.0 <= h2 && h2 < 6.0) {
        return RGB(255, 0, x);
    }

    return RGB(0, 0, 0);
}

///
@safe unittest
{
    assert(hueToRGB(180.0) == RGB(0, 255, 255));
}

