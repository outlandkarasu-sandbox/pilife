/**
Color functions.
*/
module pilife.color;

import std.math : isClose, abs;

struct RGB
{
    real red;
    real green;
    real blue;
}

struct HSV
{
    real hue;
    real saturation;
    real value;
}

import std.stdio : writeln;

RGB toRGB()(auto ref const(HSV) hsv) @nogc nothrow pure @safe
{
    if (hsv.saturation.isClose(0.0))
    {
        return RGB(hsv.value, hsv.value, hsv.value);
    }

    immutable c = hsv.saturation * hsv.value;
    immutable h2 = (hsv.hue % 360.0) / 60.0;
    immutable x = c * (1.0 - abs(h2 % 2.0 - 1));
    immutable m = hsv.value - c;

    debug
    {
        writeln("c:", c, " h2:", h2, " x:", x, " m:", m);
    }

    if (0.0 <= h2 && h2 < 1.0) {
        return RGB(c + m, x + m, m);
    }

    if (1.0 <= h2 && h2 < 2.0) {
        return RGB(x + m, c + m, m);
    }

    if (2.0 <= h2 && h2 < 3.0) {
        return RGB(m, c + m, x + m);
    }

    if (3.0 <= h2 && h2 < 4.0) {
        return RGB(m, x + m, c + m);
    }

    if (4.0 <= h2 && h2 < 5.0) {
        return RGB(x + m, m, c + m);
    }

    if (5.0 <= h2 && h2 < 6.0) {
        return RGB(c + m, m, x + m);
    }

    return RGB(m, m, m);
}

///
@safe unittest
{
    import std.conv : to;
    import std.stdio : writeln;
    writeln(HSV(180.0, 0.5, 0.5).toRGB);
}

