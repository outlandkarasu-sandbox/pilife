/**
OpenGL module.
*/
module pilife.opengl;

import std.exception : assumeUnique;

import bindbc.opengl :
    GLenum,
    GLint,
    GLuint,
    glDeleteShader,
    glCreateProgram,
    glAttachShader,
    glDetachShader,
    glGetProgramiv,
    glGetProgramInfoLog,
    glLinkProgram,
    glDeleteProgram,
    GL_LINK_STATUS,
    GL_FALSE,
    GLchar,
    GL_COMPILE_STATUS,
    GL_INFO_LOG_LENGTH,
    GL_VERTEX_SHADER,
    GL_FRAGMENT_SHADER,
    glCreateShader,
    glShaderSource,
    glCompileShader,
    glGetShaderiv,
    glGetShaderInfoLog;

/**
Compile shaders and create program.
*/
GLuint createShaderProgram(
    scope const(char)[] vertexShaderSource,
    scope const(char)[] fragmentShaderSource)
{
    immutable vertexShaderId = compileShader(vertexShaderSource, GL_VERTEX_SHADER);
    scope(exit) glDeleteShader(vertexShaderId);

    immutable fragmentShaderId = compileShader(fragmentShaderSource, GL_FRAGMENT_SHADER);
    scope(exit) glDeleteShader(fragmentShaderId);

    immutable programId = glCreateProgram();
    scope(failure) glDeleteProgram(programId);
    glAttachShader(programId, vertexShaderId);
    scope(exit) glDetachShader(programId, vertexShaderId);
    glAttachShader(programId, fragmentShaderId);
    scope(exit) glDetachShader(programId, fragmentShaderId);

    glLinkProgram(programId);

    GLint status;
    glGetProgramiv(programId, GL_LINK_STATUS, &status);
    if(status == GL_FALSE) {
        GLint logLength;
        glGetProgramiv(programId, GL_INFO_LOG_LENGTH, &logLength);
        auto log = new GLchar[logLength];
        glGetProgramInfoLog(programId, logLength, null, log.ptr);
        throw new Exception(assumeUnique(log));
    }

    return programId;
}

private:

GLuint compileShader(scope const(char)[] source, GLenum shaderType)
{
    immutable shaderId = glCreateShader(shaderType);
    scope(failure) glDeleteShader(shaderId);

    immutable length = cast(GLint) source.length;
    const sourcePointer = source.ptr;
    glShaderSource(shaderId, 1, &sourcePointer, &length);
    glCompileShader(shaderId);

    GLint status;
    glGetShaderiv(shaderId, GL_COMPILE_STATUS, &status);
    if(status == GL_FALSE) {
        GLint logLength;
        glGetShaderiv(shaderId, GL_INFO_LOG_LENGTH, &logLength);
        auto log = new GLchar[logLength];
        glGetShaderInfoLog(shaderId, logLength, null, log.ptr);
        throw new Exception(assumeUnique(log));
    }

    return shaderId;
}

