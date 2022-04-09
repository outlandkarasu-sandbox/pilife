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
    SDLK_a,
    SDLK_b,
    SDLK_c,
    SDLK_RETURN,
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
    SDL_GL_CreateContext,
    SDL_GL_DeleteContext,
    SDL_GL_SetAttribute,
    SDL_GL_CONTEXT_MAJOR_VERSION,
    SDL_GL_CONTEXT_MINOR_VERSION,
    SDL_GL_CONTEXT_PROFILE_MASK,
    SDL_GL_CONTEXT_PROFILE_CORE,
    SDL_GL_DOUBLEBUFFER,
    SDL_GL_SwapWindow,
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
    SDL_WINDOW_OPENGL,
    SDL_RENDERER_ACCELERATED,
    SDL_RENDERER_PRESENTVSYNC,
    SDL_GetPerformanceCounter,
    SDL_GetPerformanceFrequency,
    SDL_SetRenderDrawBlendMode,
    SDL_BLENDMODE_BLEND;

import bindbc.opengl :
    loadOpenGL,
    unloadOpenGL,
    glSupport,
    GLSupport,
    GLuint,
    GLushort,
    GLfloat,
    GLvoid,
    GLenum,
    glGenTextures,
    glDeleteTextures,
    glGenBuffers,
    glDeleteBuffers,
    glBindBuffer,
    glPixelStorei,
    glBindTexture,
    glBufferData,
    GL_ARRAY_BUFFER,
    GL_ELEMENT_ARRAY_BUFFER,
    GL_STATIC_DRAW,
    GL_TEXTURE_2D,
    GL_TEXTURE_WRAP_S,
    GL_TEXTURE_WRAP_T,
    GL_REPEAT,
    GL_NEAREST,
    GL_RGB,
    GL_UNSIGNED_BYTE,
    GL_UNPACK_ALIGNMENT,
    GL_FLOAT,
    GL_FALSE,
    GL_TRUE,
    glTexParameteri,
    glTexImage2D,
    GL_TEXTURE_MIN_FILTER,
    GL_TEXTURE_MAG_FILTER,
    glGenVertexArrays,
    glDeleteVertexArrays,
    glBindVertexArray,
    glVertexAttribPointer,
    glEnableVertexAttribArray,
    glDisableVertexAttribArray,
    glClearColor,
    glClear,
    GL_COLOR_BUFFER_BIT,
    GL_DEPTH_BUFFER_BIT,
    glUseProgram,
    glDeleteProgram,
    glActiveTexture,
    glDrawElements,
    glFlush,
    glGetUniformLocation,
    glUniform1i,
    GL_TEXTURE0,
    GL_TRIANGLES,
    GLsizei,
    GL_UNSIGNED_SHORT,
    glViewport,
    glEnable,
    GL_DEPTH_TEST,
    glDeleteFramebuffers,
    glGenFramebuffers,
    glBindFramebuffer,
    GL_FRAMEBUFFER,
    glFramebufferTexture,
    glDrawBuffers,
    GL_COLOR_ATTACHMENT0,
    GL_BACK_LEFT,
    GL_FRONT_LEFT,
    glBlitFramebuffer,
    GL_READ_FRAMEBUFFER,
    GL_DRAW_FRAMEBUFFER;

import pilife.game :
    LifeGame,
    Cell,
    Plane,
    GLIDER;
import pilife.sdl :
    getDisplays,
    enforceSDL,
    sdlError;
import pilife.opengl :
    createShaderProgram,
    enforceGL;

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
    scope(exit) SDL_Quit();

    //lifeGameOpenGL();
    lifeGame2D();
}

void lifeGame2D()
{
    writefln("displays: %s", getDisplays());

    auto window = enforceSDL(SDL_CreateWindow(
        "pilife",
        SDL_WINDOWPOS_UNDEFINED,
        SDL_WINDOWPOS_UNDEFINED,
        720, 450,
        0)); //SDL_WINDOW_FULLSCREEN));
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

    SDL_UpdateWindowSurface(window);
    SDL_ShowWindow(window);

    mainLoop(lifeGame, lifeGameSurface, windowSurface, window);
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
    bool pushedA;
    bool pushedB;
    bool pushedC;
    bool pushedSpace;

    void processInput()
    {
        if (pushedA)
        {
             lifeGame.addLife(360, 200, GLIDER, randomHue());
             pushedA = false;
        }

        if (pushedB)
        {
             lifeGame.addLife(0, 200, GLIDER, randomHue());
             pushedB = false;
        }

        if (pushedC)
        {
             lifeGame.addLife(700, 200, GLIDER, randomHue());
             pushedC = false;
        }

        if (pushedSpace)
        {
            foreach (y; 0 .. lifeGame.height)
            {
                foreach (x; 0 .. lifeGame.width)
                {
                    if ([true, false].choice)
                    {
                        lifeGame[x, y] = Cell.fromHue(randomHue());
                    }
                }
            }
            pushedSpace = false;
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
        processInput();
        auto nextStateTask = scopedTask(&lifeGame.next);
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
                    switch (event.key.keysym.sym)
                    {
                        case SDLK_RETURN:
                            running = !running;
                            break;
                        case SDLK_SPACE:
                            pushedSpace = true;
                            break;
                        case SDLK_ESCAPE:
                            return;
                        case SDLK_a:
                            pushedA = true;
                            break;
                        case SDLK_b:
                            pushedB = true;
                            break;
                        case SDLK_c:
                            pushedC = true;
                            break;
                        default:
                            break;
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

struct Vertex
{
    GLfloat x;
    GLfloat y;
    GLfloat z;
    GLfloat u;
    GLfloat v;
}

immutable vertices = [
    Vertex(-1.0f,  1.0f, 0.0f, 0.0f, 0.0f),
    Vertex( 1.0f,  1.0f, 0.0f, 1.0f, 0.0f),
    Vertex(-1.0f, -1.0f, 0.0f, 0.0f, 1.0f),
    Vertex( 1.0f, -1.0f, 0.0f, 1.0f, 1.0f),
];

immutable GLushort[] indices = [0, 1, 2, 2, 1, 3];

immutable vertexShader = `
#version 330 core
layout(location = 0) in vec3 position;
layout(location = 1) in vec2 uv;

out vec2 vertexUv;

void main() {
    gl_Position = vec4(position, 1.0f);
    vertexUv = uv;
}
`;

immutable fragmentShader = `
#version 330 core

in vec2 vertexUv;
layout(location = 0) out vec3 color;

uniform sampler2D textureSampler;

void main() {
    color = texture(textureSampler, vertexUv).rgb;
}
`;

immutable GLenum[] drawBuffers = [GL_COLOR_ATTACHMENT0];
immutable GLenum[] screenBuffers = [GL_BACK_LEFT];

void lifeGameOpenGL()
{
    SDL_GL_SetAttribute(SDL_GL_CONTEXT_MAJOR_VERSION, 3);
    SDL_GL_SetAttribute(SDL_GL_CONTEXT_MINOR_VERSION, 3);
    SDL_GL_SetAttribute(SDL_GL_CONTEXT_PROFILE_MASK, SDL_GL_CONTEXT_PROFILE_CORE);
    SDL_GL_SetAttribute(SDL_GL_DOUBLEBUFFER, 1);

    auto window = enforceSDL(SDL_CreateWindow(
        "pilife",
        SDL_WINDOWPOS_UNDEFINED,
        SDL_WINDOWPOS_UNDEFINED,
        512, 512,
        SDL_WINDOW_OPENGL));
    scope(exit) SDL_DestroyWindow(window);

    auto openGlContext = enforceSDL(SDL_GL_CreateContext(window));
    scope(exit) SDL_GL_DeleteContext(openGlContext);

    immutable loadedOpenGLVersion = loadOpenGL();
    enforce(loadedOpenGLVersion >= glSupport, format("loadOpenGL error: %s", loadedOpenGLVersion));
    scope(exit) unloadOpenGL();

    writefln("loaded OpenGL: %s", loadedOpenGLVersion);

    enforceGL(glPixelStorei(GL_UNPACK_ALIGNMENT, 1));
    enforceGL(glEnable(GL_DEPTH_TEST));

    // setup frame buffers
    GLuint frameBuffer;
    enforceGL(glGenFramebuffers(1, &frameBuffer));
    scope(exit) glDeleteFramebuffers(1, &frameBuffer);

    GLuint frameTexture;
    glGenTextures(1, &frameTexture);
    scope(exit) glDeleteTextures(1, &frameTexture);

    glBindTexture(GL_TEXTURE_2D, frameTexture);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGB, 512, 512, 0, GL_RGB, GL_UNSIGNED_BYTE, null);
    glBindTexture(GL_TEXTURE_2D, 0);

    enforceGL(glBindFramebuffer(GL_FRAMEBUFFER, frameBuffer));
    enforceGL(glFramebufferTexture(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, frameTexture, 0));
    enforceGL(glDrawBuffers(1, drawBuffers.ptr));
    enforceGL(glBindFramebuffer(GL_FRAMEBUFFER, 0));

    // create VBO
    GLuint verticesBuffer;
    glGenBuffers(1, &verticesBuffer);
    scope(exit) glDeleteBuffers(1, &verticesBuffer);

    glBindBuffer(GL_ARRAY_BUFFER, verticesBuffer);
    glBufferData(GL_ARRAY_BUFFER, vertices.length * Vertex.sizeof, vertices.ptr, GL_STATIC_DRAW);
    glBindBuffer(GL_ARRAY_BUFFER, 0);

    // create IBO
    GLuint elementBuffer;
    glGenBuffers(1, &elementBuffer);
    scope(exit) glDeleteBuffers(1, &elementBuffer);

    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, elementBuffer);
    glBufferData(GL_ELEMENT_ARRAY_BUFFER, indices.length * GLushort.sizeof, indices.ptr, GL_STATIC_DRAW);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, 0);

    // generate texture
    GLuint texture;
    glGenTextures(1, &texture);
    scope(exit) glDeleteTextures(1, &texture);

    immutable ubyte[] texturePixels = [
        255,   0,   0,
          0, 255,   0,
          0,   0, 255,
          0,   0,   0
    ];

    glBindTexture(GL_TEXTURE_2D, texture);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_REPEAT);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_REPEAT);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGB, 2, 2, 0, GL_RGB, GL_UNSIGNED_BYTE, texturePixels.ptr);
    glBindTexture(GL_TEXTURE_2D, 0);

    // create VAO
    GLuint vao;
    glGenVertexArrays(1, &vao);
    scope(exit) glDeleteVertexArrays(1, &vao);

    enforceGL(glBindVertexArray(vao));
    enforceGL(glBindBuffer(GL_ARRAY_BUFFER, verticesBuffer));
    enforceGL(glVertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE, Vertex.sizeof, cast(const(GLvoid)*) Vertex.x.offsetof));
    enforceGL(glEnableVertexAttribArray(0));
    enforceGL(glVertexAttribPointer(1, 2, GL_FLOAT, GL_FALSE, Vertex.sizeof, cast(const(GLvoid)*) Vertex.u.offsetof));
    enforceGL(glEnableVertexAttribArray(1));
    enforceGL(glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, elementBuffer));
    enforceGL(glBindVertexArray(0));

    // build shader program.
    immutable programId = createShaderProgram(vertexShader, fragmentShader);
    scope(exit) glDeleteProgram(programId);
    auto textureLocation = glGetUniformLocation(programId, "textureSampler");

    immutable frequency = SDL_GetPerformanceFrequency();
    immutable frameFrequency = frequency / 60;
    size_t frameCount;
    size_t lastTick;
    size_t lastFrameTick;
    bool running = false;
    for (SDL_Event event; ; ++frameCount, lastFrameTick = SDL_GetPerformanceCounter())
    {
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

        // wait next frame.
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

        // clear window
        glViewport(0, 0, 512, 512);
        glClearColor(0.0f, 0.0f, 0.0f, 1.0f);
        glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);

        // setup elements
        glUseProgram(programId);
        glBindVertexArray(vao);
        glActiveTexture(GL_TEXTURE0);
        glBindTexture(GL_TEXTURE_2D, texture);
        glUniform1i(textureLocation, 0);

        glBindFramebuffer(GL_DRAW_FRAMEBUFFER, frameBuffer);
        glDrawElements(GL_TRIANGLES, cast(GLsizei) indices.length, GL_UNSIGNED_SHORT, cast(const(GLvoid)*) 0);

        glBindVertexArray(0);
        glUseProgram(0);

        enforceGL(glBindFramebuffer(GL_READ_FRAMEBUFFER, frameBuffer));
        enforceGL(glBindFramebuffer(GL_DRAW_FRAMEBUFFER, 0));
        enforceGL(glBlitFramebuffer(0, 0, 512, 512, 0, 0, 512, 512, GL_COLOR_BUFFER_BIT, GL_NEAREST));

        glFlush();

        SDL_GL_SwapWindow(window);
    }
}

private:

ubyte randomHue() @safe
{
    return cast(ubyte) uniform(0, ubyte.max);
}
