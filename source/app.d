/**
Main module.
*/

import std.exception :
    enforce;
import std.random :
    choice;
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
    unloadSDL,
    SDL_CreateRenderer,
    SDL_CreateWindow,
    SDL_Delay,
    SDL_DestroyRenderer,
    SDL_DestroyWindow,
    SDL_RenderDrawPoint,
    SDL_SetRenderDrawColor,
    SDL_RenderClear,
    SDL_RenderPresent,
    SDL_Event,
    SDL_PollEvent,
    SDL_QUIT,
    SDL_Renderer,
    SDL_ShowWindow,
    SDL_WINDOWPOS_UNDEFINED,
    SDL_WINDOW_HIDDEN,
    SDL_RENDERER_ACCELERATED,
    SDL_RENDERER_PRESENTVSYNC;

import pilife.game :
    LifeGame;
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

    auto window = enforce(SDL_CreateWindow(
        "pilife",
        SDL_WINDOWPOS_UNDEFINED,
        SDL_WINDOWPOS_UNDEFINED,
        640, 480,
        SDL_WINDOW_HIDDEN));
    scope(exit) SDL_DestroyWindow(window);

    auto renderer = enforce(SDL_CreateRenderer(
        window,
        -1,
        SDL_RENDERER_ACCELERATED | SDL_RENDERER_PRESENTVSYNC),
        sdlError);
    scope(exit) SDL_DestroyRenderer(renderer);

    auto lifeGame = LifeGame(640, 480);
    foreach (y; 0 .. 480)
    {
        foreach (x; 0 .. 640)
        {
            lifeGame[x, y] = choice([true, false]);
        }
    }

    SDL_SetRenderDrawColor(renderer, 0, 0, 0, 0);
    SDL_RenderClear(renderer);
    SDL_RenderPresent(renderer);

    SDL_ShowWindow(window);

    mainLoop(lifeGame, renderer);

    scope(exit) SDL_Quit();
}

void mainLoop(ref LifeGame lifeGame, SDL_Renderer* renderer)
{
    for (SDL_Event event; ;)
    {
        lifeGame.next();

        while (SDL_PollEvent(&event))
        {
            switch (event.type)
            {
                case SDL_QUIT:
                    return;
                default:
                    break;
            }
        }

        SDL_SetRenderDrawColor(renderer, 0, 0, 0, 0);
        SDL_RenderClear(renderer);
        SDL_SetRenderDrawColor(renderer, 255, 0, 0, 255);

        foreach (const size_t x, const size_t y, const bool life; lifeGame)
        {
            if (life)
            {
                SDL_RenderDrawPoint(renderer, cast(int) x, cast(int) y);
            }
        }
        SDL_RenderPresent(renderer);
    }
}

