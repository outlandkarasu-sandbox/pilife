/**
Main module.
*/

import std.exception :
    enforce;
import std.random :
    choice, uniform;
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
    SDL_KEYDOWN,
    SDL_WINDOWPOS_UNDEFINED,
    SDL_WINDOW_HIDDEN,
    SDL_RENDERER_ACCELERATED,
    SDL_RENDERER_PRESENTVSYNC;

import pilife.game :
    LifeGame, Cell;
import pilife.sdl :
    enforceSDL,
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

    enforceSDL(SDL_Init(SDL_INIT_VIDEO) == 0);

    auto window = enforceSDL(SDL_CreateWindow(
        "pilife",
        SDL_WINDOWPOS_UNDEFINED,
        SDL_WINDOWPOS_UNDEFINED,
        640, 480,
        SDL_WINDOW_HIDDEN));
    scope(exit) SDL_DestroyWindow(window);

    auto renderer = enforceSDL(SDL_CreateRenderer(
        window,
        -1,
        SDL_RENDERER_ACCELERATED | SDL_RENDERER_PRESENTVSYNC));
    scope(exit) SDL_DestroyRenderer(renderer);

    auto lifeGame = LifeGame(640, 480);
    foreach (y; 0 .. 480)
    {
        foreach (x; 0 .. 640)
        {
            if ([true, false].choice)
            {
                lifeGame[x, y] = Cell.fromHue(cast(ubyte) uniform(0, ubyte.max));
            }
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
    bool running = false;
    for (SDL_Event event; ;)
    {
        if (running)
        {
            lifeGame.next();
        }

        while (SDL_PollEvent(&event))
        {
            switch (event.type)
            {
                case SDL_KEYDOWN:
                    running = !running;
                    break;
                case SDL_QUIT:
                    return;
                default:
                    break;
            }
        }

        SDL_SetRenderDrawColor(renderer, 0, 0, 0, 0);
        SDL_RenderClear(renderer);

        foreach (const size_t x, const size_t y, const Cell life; lifeGame)
        {
            if (life.lifespan > 0)
            {
                SDL_SetRenderDrawColor(
                    renderer,
                    life.color.red,
                    life.color.green,
                    life.color.blue,
                    life.lifespan);
                SDL_RenderDrawPoint(renderer, cast(int) x, cast(int) y);
            }
        }
        SDL_RenderPresent(renderer);
    }
}

