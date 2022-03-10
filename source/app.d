/**
Main module.
*/

import std.exception :
    enforce;
import std.parallelism :
    scopedTask, taskPool;
import std.random :
    choice, uniform;
import std.stdio :
    writefln;
import std.string :
    format;

import bindbc.sdl :
    loadSDL,
    SDL_INIT_TIMER,
    SDL_INIT_VIDEO,
    SDL_Init,
    SDL_Quit,
    sdlSupport,
    unloadSDL,
    SDL_BlitSurface,
    SDL_CreateRGBSurface,
    SDL_CreateWindow,
    SDL_Delay,
    SDL_DestroyWindow,
    SDL_FreeSurface,
    SDL_GetWindowSurface,
    SDL_Event,
    SDL_LockSurface,
    SDL_PollEvent,
    SDL_QUIT,
    SDL_Renderer,
    SDL_SetSurfaceRLE,
    SDL_ShowWindow,
    SDL_Surface,
    SDL_UnlockSurface,
    SDL_UpdateWindowSurface,
    SDL_Window,
    SDL_KEYDOWN,
    SDL_WINDOWPOS_UNDEFINED,
    SDL_WINDOW_HIDDEN,
    SDL_RENDERER_ACCELERATED,
    SDL_RENDERER_PRESENTVSYNC,
    SDL_GetPerformanceCounter,
    SDL_GetPerformanceFrequency,
    SDL_SetRenderDrawBlendMode,
    SDL_BLENDMODE_BLEND;

import pilife.game :
    LifeGame, Cell;
import pilife.sdl :
    enforceSDL,
    sdlError;

version (BigEndian)
{
    enum {
        RED_SHIFT = 24,
        GREEN_SHIFT = 16,
        BLUE_SHIFT = 8,
        ALPHA_SHIFT = 0,
    };
}
else
{
    enum {
        RED_SHIFT = 0,
        GREEN_SHIFT = 8,
        BLUE_SHIFT = 16,
        ALPHA_SHIFT = 24,
    };
}

enum {
    RED_MASK   = 0xff << RED_SHIFT,
    GREEN_MASK = 0xff << GREEN_SHIFT,
    BLUE_MASK  = 0xff << BLUE_SHIFT,
    ALPHA_MASK = 0xff << ALPHA_SHIFT,
};

/**
Main function.
*/
void main()
{
    immutable loadedSDLVersion = loadSDL();
    enforce(loadedSDLVersion >= sdlSupport, format("loadSDL error: %s", loadedSDLVersion));
    scope(exit) unloadSDL();

    writefln("loaded SDL: %s", loadedSDLVersion);

    enforceSDL(SDL_Init(SDL_INIT_VIDEO | SDL_INIT_TIMER) == 0);

    auto window = enforceSDL(SDL_CreateWindow(
        "pilife",
        SDL_WINDOWPOS_UNDEFINED,
        SDL_WINDOWPOS_UNDEFINED,
        640, 480,
        SDL_WINDOW_HIDDEN));
    scope(exit) SDL_DestroyWindow(window);
    auto windowSurface = enforceSDL(SDL_GetWindowSurface(window));

    auto lifeGameSurface = enforceSDL(SDL_CreateRGBSurface(
        0,
        windowSurface.w,
        windowSurface.h,
        32,
        RED_MASK,
        GREEN_MASK,
        BLUE_MASK,
        ALPHA_MASK));
    scope(exit) SDL_FreeSurface(lifeGameSurface);
    enforceSDL(SDL_SetSurfaceRLE(lifeGameSurface, 1) == 0);

    auto lifeGame = LifeGame(lifeGameSurface.w, lifeGameSurface.h);
    foreach (y; 0 .. lifeGameSurface.h)
    {
        foreach (x; 0 .. lifeGameSurface.w)
        {
            if ([true, false].choice)
            {
                lifeGame[x, y] = Cell.fromHue(cast(ubyte) uniform(0, ubyte.max));
            }
        }
    }

    SDL_UpdateWindowSurface(window);
    SDL_ShowWindow(window);

    mainLoop(lifeGame, lifeGameSurface, windowSurface, window);

    scope(exit) SDL_Quit();
}

void mainLoop(
    ref LifeGame lifeGame,
    SDL_Surface* surface,
    SDL_Surface* windowSurface,
    SDL_Window* window)
{
    immutable frequency = SDL_GetPerformanceFrequency();
    size_t frameCount;
    size_t lastTick;
    bool running = false;

    void nextState()
    {
        if (running)
        {
            lifeGame.next();
        }
    }

    for (SDL_Event event; ; ++frameCount)
    {
        auto currentPlane = &lifeGame.currentPlane();
        auto task = scopedTask(&nextState);
        taskPool.put(task);
        scope(success) task.yieldForce();

        immutable currentTick = SDL_GetPerformanceCounter();
        if (currentTick - lastTick > frequency)
        {
            writefln("FPS: %d", frameCount);
            lastTick = currentTick;
            frameCount = 0;
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

        {
            enforceSDL(SDL_LockSurface(surface) == 0);
            scope(exit) SDL_UnlockSurface(surface);

            uint[] pixels = cast(uint[]) surface.pixels[0 .. surface.w * surface.h * uint.sizeof];
            foreach (const size_t x, const size_t y, const Cell life; *currentPlane)
            {
                if (life.lifespan > 0)
                {
                    pixels[y * surface.w + x] =
                        (life.color.red << RED_SHIFT) |
                        (life.color.green << GREEN_SHIFT) |
                        (life.color.blue << BLUE_SHIFT) |
                        (life.lifespan << ALPHA_SHIFT);
                }
                else
                {
                    pixels[y * surface.w + x] = 0xff << ALPHA_SHIFT;
                }
            }
        }

        SDL_BlitSurface(surface, null, windowSurface, null);
        SDL_UpdateWindowSurface(window);
    }
}

