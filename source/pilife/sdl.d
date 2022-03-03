/**
SDL utilities module.
*/
module pilife.sdl;

import std.exception :
    enforce;
import std.string :
    fromStringz;

import bindbc.sdl :
    SDL_GetDisplayMode,
    SDL_GetError,
    SDL_GetNumVideoDisplays,
    SDL_GetNumDisplayModes,
    SDL_DisplayMode,
    SDL_GetDisplayBounds,
    SDL_Rect;

/**
SDL error.
*/
string sdlError() nothrow
{
    return SDL_GetError().fromStringz.idup;
}

/**
Enforce SDL value.
*/
auto enforceSDL(T)(auto return scope ref T value)
{
    return enforce(value, sdlError);
}

/**
SDL display information.
*/
struct Display
{
    SDL_Rect bounds;
    SDL_DisplayMode[] modes;
}

/**
Get SDL displays.
*/
Display[] getDisplays()
{
    Display[] result;
    foreach (displayIndex; 0 .. SDL_GetNumVideoDisplays())
    {
        Display display;
        enforceSDL(SDL_GetDisplayBounds(displayIndex, &display.bounds) == 0);
        foreach (modeIndex; 0 .. SDL_GetNumDisplayModes(displayIndex))
        {
            SDL_DisplayMode mode;
            enforceSDL(SDL_GetDisplayMode(displayIndex, modeIndex, &mode) == 0);
            display.modes ~= mode;
        }
        result ~= display;
    }
    return result;
}

