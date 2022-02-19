/**
SDL utilities module.
*/
module pilife.sdl;

import std.string :
    fromStringz;

import bindbc.sdl :
    SDL_GetError;

/**
SDL error.
*/
string sdlError() nothrow
{
    return SDL_GetError().fromStringz.idup;
}

