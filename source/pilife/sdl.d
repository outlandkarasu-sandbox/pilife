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
    SDL_GetNumDisplayModes,
    SDL_DisplayMode;

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

