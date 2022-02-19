/**
Main module.
*/

import std.exception :
    enforce;
import std.stdio :
    writefln;
import std.string :
    format;

import bindbc.sdl :
    loadSDL,
    SDL_INIT_VIDEO,
    SDL_Init,
    SDL_Quit,
    sdlSupport,
    unloadSDL;

import pilife.sdl :
    sdlError;

/**
Main function.
*/
void main()
{
    immutable loadedSDLVersion = loadSDL();
    enforce(loadedSDLVersion >= sdlSupport, format("loadSDL error: %s", loadedSDLVersion));
    scope(exit) unloadSDL();

    writefln("loaded SDL: %s", loadedSDLVersion);

    enforce(SDL_Init(SDL_INIT_VIDEO) == 0, sdlError);
    scope(exit) SDL_Quit();
}

