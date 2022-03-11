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
    SDLK_SPACE,
    SDLK_ESCAPE,
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
    SDL_WINDOW_FULLSCREEN,
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
    LifeGame,
    Cell,
    Plane;
import pilife.sdl :
    getDisplays,
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

    writefln("displays: %s", getDisplays());

    auto window = enforceSDL(SDL_CreateWindow(
        "pilife",
        SDL_WINDOWPOS_UNDEFINED,
        SDL_WINDOWPOS_UNDEFINED,
        720, 450,
        SDL_WINDOW_FULLSCREEN));
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
    bool running = false;
    uint[] pixels;
    const(Plane)* currentPlane;

    void nextState()
    {
        if (running)
        {
            lifeGame.next();
        }
    }

    void renderCells()
    {
        pixels = cast(uint[]) surface.pixels[0 .. surface.w * surface.h * uint.sizeof];
        foreach (const size_t x, const size_t y, scope ref const(Cell) cell; *currentPlane)
        {
            if (cell.live)
            {
                pixels[y * surface.w + x] =
                    (cell.color.red << RED_SHIFT) |
                    (cell.color.green << GREEN_SHIFT) |
                    (cell.color.blue << BLUE_SHIFT) |
                    (cell.lifespan << ALPHA_SHIFT);
            }
            else
            {
                pixels[y * surface.w + x] = 0x8 << ALPHA_SHIFT;
            }
        }
    }

    immutable frequency = SDL_GetPerformanceFrequency();
    immutable frameFrequency = frequency / 60;
    size_t frameCount;
    size_t lastTick;
    size_t lastFrameTick;
    for (SDL_Event event; ; ++frameCount, lastFrameTick = SDL_GetPerformanceCounter())
    {
        currentPlane = &lifeGame.currentPlane();
        auto nextStateTask = scopedTask(&nextState);
        taskPool.put(nextStateTask);
        scope(success) nextStateTask.yieldForce();

        enforceSDL(SDL_LockSurface(surface) == 0);
        auto renderCellsTask = scopedTask(&renderCells);
        taskPool.put(renderCellsTask);

        while (SDL_PollEvent(&event))
        {
            switch (event.type)
            {
                case SDL_KEYDOWN:
                    if (event.key.keysym.sym == SDLK_SPACE)
                    {
                        running = !running;
                    }
                    else if (event.key.keysym.sym == SDLK_ESCAPE)
                    {
                        return;
                    }
                    break;
                case SDL_QUIT:
                    return;
                default:
                    break;
            }
        }

        renderCellsTask.yieldForce();
        SDL_UnlockSurface(surface);
        SDL_BlitSurface(surface, null, windowSurface, null);

        for (;;)
        {
            immutable currentTick = SDL_GetPerformanceCounter();
            if (currentTick - lastTick > frequency)
            {
                writefln("FPS: %d", frameCount);
                lastTick = currentTick;
                frameCount = 0;
            }

            if (currentTick - lastFrameTick > frameFrequency)
            {
                break;
            }

            SDL_Delay(0);
        }

        SDL_UpdateWindowSurface(window);
    }
}

