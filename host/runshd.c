#define WIN32_LEAN_AND_MEAN
#include <windows.h>
#include <GL/gl.h>
#include <shellapi.h>
#include <stddef.h>

/* A deliberately small, CRT-free Win32/OpenGL shader viewer. */
typedef char GLchar;
typedef ptrdiff_t GLsizeiptr;
int _fltused = 0;

/* Ask hybrid-graphics drivers to prefer the high-performance GPU. */
__declspec(dllexport) DWORD NvOptimusEnablement = 0x00000001;
__declspec(dllexport) DWORD AmdPowerXpressRequestHighPerformance = 0x00000001;

static size_t strlen(const char *s) {
    const char *p = s;
    while (*p)
        p++;
    return (size_t)(p - s);
}
void *memset(void *d, int c, size_t n) {
    volatile unsigned char *p = (volatile unsigned char *)d;
    while (n--)
        *p++ = (unsigned char)c;
    return d;
}
static int strncmp(const char *a, const char *b, size_t n) {
    while (n && *a && *a == *b) {
        a++;
        b++;
        n--;
    }
    return n ? ((unsigned char)*a - (unsigned char)*b) : 0;
}
static char *strstr(const char *s, const char *q) {
    size_t n = strlen(q);
    if (!n)
        return (char *)s;
    for (; *s; s++)
        if (!strncmp(s, q, n))
            return (char *)s;
    return 0;
}
static void *memcpy(void *d, const void *s, size_t n) {
    volatile unsigned char *a = (volatile unsigned char *)d;
    const volatile unsigned char *b = (const volatile unsigned char *)s;
    while (n--)
        *a++ = *b++;
    return d;
}
static void *memmove(void *d, const void *s, size_t n) {
    unsigned char *a = (unsigned char *)d;
    const unsigned char *b = (const unsigned char *)s;
    if (a < b)
        while (n--)
            *a++ = *b++;
    else {
        a += n;
        b += n;
        while (n--)
            *--a = *--b;
    }
    return d;
}
static int wtoi(const wchar_t *s) {
    int n = 0;
    while (*s == L' ' || *s == L'\t')
        s++;
    while (*s >= L'0' && *s <= L'9')
        n = n * 10 + (*s++ - L'0');
    return n;
}
#define GL_VERTEX_SHADER 0x8B31
#define GL_FRAGMENT_SHADER 0x8B30
#define GL_COMPILE_STATUS 0x8B81
#define GL_LINK_STATUS 0x8B82
#define GL_INFO_LOG_LENGTH 0x8B84
#define GL_ARRAY_BUFFER 0x8892
#define GL_STATIC_DRAW 0x88E4
#define GL_FLOAT 0x1406
#define GL_TEXTURE0 0x84C0
#define GL_CLAMP_TO_EDGE 0x812F
#define GL_FRAMEBUFFER_SRGB 0x8DB9

typedef GLuint(APIENTRY *CreateShaderFn)(GLenum);
typedef void(APIENTRY *ShaderSourceFn)(GLuint, GLsizei, const GLchar **, const GLint *);
typedef void(APIENTRY *CompileShaderFn)(GLuint);
typedef void(APIENTRY *GetShaderivFn)(GLuint, GLenum, GLint *);
typedef void(APIENTRY *GetShaderInfoLogFn)(GLuint, GLsizei, GLsizei *, GLchar *);
typedef GLuint(APIENTRY *CreateProgramFn)(void);
typedef void(APIENTRY *AttachShaderFn)(GLuint, GLuint);
typedef void(APIENTRY *LinkProgramFn)(GLuint);
typedef void(APIENTRY *GetProgramivFn)(GLuint, GLenum, GLint *);
typedef void(APIENTRY *GetProgramInfoLogFn)(GLuint, GLsizei, GLsizei *, GLchar *);
typedef void(APIENTRY *UseProgramFn)(GLuint);
typedef GLint(APIENTRY *GetUniformLocationFn)(GLuint, const GLchar *);
typedef void(APIENTRY *Uniform1fFn)(GLint, GLfloat);
typedef void(APIENTRY *Uniform1iFn)(GLint, GLint);
typedef void(APIENTRY *Uniform2fFn)(GLint, GLfloat, GLfloat);
typedef void(APIENTRY *Uniform3fFn)(GLint, GLfloat, GLfloat, GLfloat);
typedef void(APIENTRY *Uniform4fFn)(GLint, GLfloat, GLfloat, GLfloat, GLfloat);
typedef void(APIENTRY *ActiveTextureFn)(GLenum);
typedef void(APIENTRY *GenBuffersFn)(GLsizei, GLuint *);
typedef void(APIENTRY *BindBufferFn)(GLenum, GLuint);
typedef void(APIENTRY *BufferDataFn)(GLenum, GLsizeiptr, const void *, GLenum);
typedef GLint(APIENTRY *GetAttribLocationFn)(GLuint, const GLchar *);
typedef void(APIENTRY *EnableVertexAttribArrayFn)(GLuint);
typedef void(APIENTRY *VertexAttribPointerFn)(GLuint, GLint, GLenum, GLboolean, GLsizei,
                                              const void *);
typedef void(APIENTRY *DrawArraysFn)(GLenum, GLint, GLsizei);

#define LOAD(n, t) static t n
LOAD(pCreateShader, CreateShaderFn);
LOAD(pShaderSource, ShaderSourceFn);
LOAD(pCompileShader, CompileShaderFn);
LOAD(pGetShaderiv, GetShaderivFn);
LOAD(pGetShaderInfoLog, GetShaderInfoLogFn);
LOAD(pCreateProgram, CreateProgramFn);
LOAD(pAttachShader, AttachShaderFn);
LOAD(pLinkProgram, LinkProgramFn);
LOAD(pGetProgramiv, GetProgramivFn);
LOAD(pGetProgramInfoLog, GetProgramInfoLogFn);
LOAD(pUseProgram, UseProgramFn);
LOAD(pGetUniformLocation, GetUniformLocationFn);
LOAD(pUniform1f, Uniform1fFn);
LOAD(pUniform1i, Uniform1iFn);
LOAD(pUniform2f, Uniform2fFn);
LOAD(pUniform3f, Uniform3fFn);
LOAD(pUniform4f, Uniform4fFn);
LOAD(pActiveTexture, ActiveTextureFn);
LOAD(pGenBuffers, GenBuffersFn);
LOAD(pBindBuffer, BindBufferFn);
LOAD(pBufferData, BufferDataFn);
LOAD(pGetAttribLocation, GetAttribLocationFn);
LOAD(pEnableVertexAttribArray, EnableVertexAttribArrayFn);
LOAD(pVertexAttribPointer, VertexAttribPointerFn);
LOAD(pDrawArrays, DrawArraysFn);

static HDC dc;
static HGLRC rc;
static HWND win;
static GLuint prog, tex, vbo;
static GLint uRes, uTime, uMouse, uBack, uIRes, uITime, uIMouse, uFrame, uChannel, uDelta, uRate,
    uEpoch;
static int width = 800, height = 600, frameNo;
static float mx, my;
static LARGE_INTEGER freq, start, previous;

static void *glproc(const char *s) {
    PROC p = wglGetProcAddress(s);
    if (!p || p == (PROC)1 || p == (PROC)2 || p == (PROC)3 || p == (PROC)-1)
        p = GetProcAddress(GetModuleHandleA("opengl32.dll"), s);
    return (void *)p;
}
#define GET(v, n, t)                                                                               \
    v = (t)glproc(n);                                                                              \
    if (!v)                                                                                        \
    return 0
static int loadgl(void) {
    GET(pCreateShader, "glCreateShader", CreateShaderFn);
    GET(pShaderSource, "glShaderSource", ShaderSourceFn);
    GET(pCompileShader, "glCompileShader", CompileShaderFn);
    GET(pGetShaderiv, "glGetShaderiv", GetShaderivFn);
    GET(pGetShaderInfoLog, "glGetShaderInfoLog", GetShaderInfoLogFn);
    GET(pCreateProgram, "glCreateProgram", CreateProgramFn);
    GET(pAttachShader, "glAttachShader", AttachShaderFn);
    GET(pLinkProgram, "glLinkProgram", LinkProgramFn);
    GET(pGetProgramiv, "glGetProgramiv", GetProgramivFn);
    GET(pGetProgramInfoLog, "glGetProgramInfoLog", GetProgramInfoLogFn);
    GET(pUseProgram, "glUseProgram", UseProgramFn);
    GET(pGetUniformLocation, "glGetUniformLocation", GetUniformLocationFn);
    GET(pUniform1f, "glUniform1f", Uniform1fFn);
    GET(pUniform1i, "glUniform1i", Uniform1iFn);
    GET(pUniform2f, "glUniform2f", Uniform2fFn);
    GET(pUniform3f, "glUniform3f", Uniform3fFn);
    GET(pUniform4f, "glUniform4f", Uniform4fFn);
    GET(pActiveTexture, "glActiveTexture", ActiveTextureFn);
    GET(pGenBuffers, "glGenBuffers", GenBuffersFn);
    GET(pBindBuffer, "glBindBuffer", BindBufferFn);
    GET(pBufferData, "glBufferData", BufferDataFn);
    GET(pGetAttribLocation, "glGetAttribLocation", GetAttribLocationFn);
    GET(pEnableVertexAttribArray, "glEnableVertexAttribArray", EnableVertexAttribArrayFn);
    GET(pVertexAttribPointer, "glVertexAttribPointer", VertexAttribPointerFn);
    GET(pDrawArrays, "glDrawArrays", DrawArraysFn);
    return 1;
}
static char *readfile(const wchar_t *path, DWORD *size) {
    HANDLE f = CreateFileW(path, GENERIC_READ, FILE_SHARE_READ, 0, OPEN_EXISTING,
                           FILE_ATTRIBUTE_NORMAL, 0);
    if (f == INVALID_HANDLE_VALUE)
        return 0;
    DWORD n = GetFileSize(f, 0), got;
    char *p = HeapAlloc(GetProcessHeap(), 0, n + 1);
    if (!p || !ReadFile(f, p, n, &got, 0) || got != n) {
        if (p)
            HeapFree(GetProcessHeap(), 0, p);
        CloseHandle(f);
        return 0;
    }
    CloseHandle(f);
    p[n] = 0;
    *size = n;
    return p;
}
static int has(const char *s, const char *q) {
    return strstr(s, q) != 0;
}
static char *prepare(const char *src, DWORD n, DWORD *out) {
    /* Remove desktop-invalid ES precision statements and their conditional wrapper. */
    char *body = HeapAlloc(GetProcessHeap(), HEAP_ZERO_MEMORY, n * 2 + 4096);
    if (!body)
        return 0;
    DWORD i = 0, j = 0;
    while (i < n) {
        if (!strncmp(src + i, "#ifdef GL_FRAGMENT_PRECISION_HIGH", 33)) {
            while (i < n && src[i] != '\n')
                i++;
            if (i < n)
                i++;
            continue;
        }
        if (!strncmp(src + i, "#else", 5)) {
            while (i < n && src[i] != '\n')
                i++;
            if (i < n)
                i++;
            continue;
        }
        if (!strncmp(src + i, "#endif", 6)) {
            while (i < n && src[i] != '\n')
                i++;
            if (i < n)
                i++;
            continue;
        }
        if (!strncmp(src + i, "precision ", 10)) {
            while (i < n && src[i] != '\n')
                i++;
            if (i < n)
                i++;
            continue;
        }
        if (!strncmp(src + i, "#version", 8)) {
            while (i < n && src[i] != '\n')
                i++;
            if (i < n)
                i++;
            continue;
        }
        body[j++] = src[i++];
    }
    body[j] = 0;
    /* Shadertoy shorthand and ES 3.x sampling on the GL 2.x compatibility path. */
    char *x = body;
    while ((x = strstr(x, "texture("))) {
        memmove(x + 9, x + 7, strlen(x + 7) + 1);
        x[7] = '2';
        x[8] = 'D';
        x += 9;
    }
    int toy = has(body, "mainImage(");
    const char *head = "uniform vec3 iResolution; uniform float iTime; uniform float iTimeDelta; "
                       "uniform float iFrameRate; uniform float iTimeEpoch; uniform int iFrame; "
                       "uniform vec4 iMouse; uniform sampler2D iChannel0;\n";
    char *sig = strstr(body, "void mainImage(");
    if (sig) {
        char *p = strstr(sig, "mainImage");
        memmove(p + 13, p + 9, strlen(p + 9) + 1);
        memcpy(p, "userMainImage", 13);
    }
    j = (DWORD)strlen(body);
    const char *tail =
        toy ? "\nvoid main(){vec4 c;userMainImage(c,gl_FragCoord.xy);gl_FragColor=c;}\n" : "\n";
    DWORD hl = (DWORD)strlen(head), tl = (DWORD)strlen(tail);
    char *all = HeapAlloc(GetProcessHeap(), 0, hl + j + tl + 1);
    if (!all) {
        HeapFree(GetProcessHeap(), 0, body);
        return 0;
    }
    memcpy(all, head, hl);
    memcpy(all + hl, body, j);
    memcpy(all + hl + j, tail, tl + 1);
    HeapFree(GetProcessHeap(), 0, body);
    *out = hl + j + tl;
    return all;
}
static GLuint shader(GLenum type, const char *src) {
    GLuint s = pCreateShader(type);
    pShaderSource(s, 1, &src, 0);
    pCompileShader(s);
    GLint ok = 0;
    pGetShaderiv(s, GL_COMPILE_STATUS, &ok);
    if (!ok) {
        char log[4096];
        GLsizei n;
        pGetShaderInfoLog(s, sizeof(log), &n, log);
        OutputDebugStringA(log);
        MessageBoxA(win, log, "Shader compile error", MB_ICONERROR);
        return 0;
    }
    return s;
}
static void loc(void) {
    uRes = pGetUniformLocation(prog, "resolution");
    uTime = pGetUniformLocation(prog, "time");
    uMouse = pGetUniformLocation(prog, "mouse");
    uBack = pGetUniformLocation(prog, "backbuffer");
    uIRes = pGetUniformLocation(prog, "iResolution");
    uITime = pGetUniformLocation(prog, "iTime");
    uIMouse = pGetUniformLocation(prog, "iMouse");
    uFrame = pGetUniformLocation(prog, "iFrame");
    uChannel = pGetUniformLocation(prog, "iChannel0");
    uDelta = pGetUniformLocation(prog, "iTimeDelta");
    uRate = pGetUniformLocation(prog, "iFrameRate");
    uEpoch = pGetUniformLocation(prog, "iTimeEpoch");
}
static void draw(void) {
    RECT r;
    GetClientRect(win, &r);
    int w = r.right, h = r.bottom;
    if (w < 1 || h < 1)
        return;
    if (w != width || h != height) {
        width = w;
        height = h;
        glBindTexture(GL_TEXTURE_2D, tex);
        glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA8, width, height, 0, GL_RGBA, GL_UNSIGNED_BYTE, 0);
    }
    glViewport(0, 0, width, height);
    glClear(GL_COLOR_BUFFER_BIT);
    pUseProgram(prog);
    LARGE_INTEGER now;
    QueryPerformanceCounter(&now);
    float t = (float)(now.QuadPart - start.QuadPart) / (float)freq.QuadPart;
    float dt = (float)(now.QuadPart - previous.QuadPart) / (float)freq.QuadPart;
    if (dt <= 0)
        dt = 1.f / 60.f;
    previous = now;
    if (uRes >= 0)
        pUniform2f(uRes, (float)width, (float)height);
    if (uTime >= 0)
        pUniform1f(uTime, t);
    if (uMouse >= 0)
        pUniform2f(uMouse, mx / width, my / height);
    if (uIRes >= 0)
        pUniform3f(uIRes, (float)width, (float)height, 1.f);
    if (uITime >= 0)
        pUniform1f(uITime, t);
    if (uDelta >= 0)
        pUniform1f(uDelta, dt);
    if (uRate >= 0)
        pUniform1f(uRate, 1.f / dt);
    if (uEpoch >= 0) {
        FILETIME ft;
        ULARGE_INTEGER q;
        GetSystemTimeAsFileTime(&ft);
        q.LowPart = ft.dwLowDateTime;
        q.HighPart = ft.dwHighDateTime;
        pUniform1f(uEpoch, (float)((q.QuadPart - 116444736000000000ULL) / 10000000.0));
    }
    if (uFrame >= 0)
        pUniform1i(uFrame, frameNo);
    if (uBack >= 0)
        pUniform1i(uBack, 0);
    if (uChannel >= 0)
        pUniform1i(uChannel, 0);
    pActiveTexture(GL_TEXTURE0);
    glBindTexture(GL_TEXTURE_2D, tex);
    if (uIMouse >= 0)
        pUniform4f(uIMouse, mx, my, 0, 0);
    pBindBuffer(GL_ARRAY_BUFFER, vbo);
    GLint a = pGetAttribLocation(prog, "position");
    if (a < 0)
        a = pGetAttribLocation(prog, "pos");
    if (a >= 0) {
        pEnableVertexAttribArray(a);
        pVertexAttribPointer(a, 2, GL_FLOAT, GL_FALSE, 0, 0);
    } else {
        glBegin(GL_TRIANGLE_STRIP);
        glVertex2f(-1, -1);
        glVertex2f(1, -1);
        glVertex2f(-1, 1);
        glVertex2f(1, 1);
        glEnd();
    }
    if (a >= 0)
        pDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
    glBindTexture(GL_TEXTURE_2D, tex);
    glCopyTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, 0, 0, width, height, 0);
    SwapBuffers(dc);
    frameNo++;
}
static LRESULT CALLBACK wndproc(HWND h, UINT m, WPARAM w, LPARAM l) {
    switch (m) {
    case WM_SIZE:
        width = 0;
        return 0;
    case WM_MOUSEMOVE:
        mx = (float)LOWORD(l);
        my = (float)(height - HIWORD(l));
        return 0;
    case WM_LBUTTONDOWN:
        mx = (float)LOWORD(l);
        my = (float)(height - HIWORD(l));
        return 0;
    case WM_KEYDOWN:
        if (w == VK_ESCAPE)
            DestroyWindow(h);
        return 0;
    case WM_DESTROY:
        PostQuitMessage(0);
        return 0;
    }
    return DefWindowProcW(h, m, w, l);
}
static void message(const wchar_t *s) {
    MessageBoxW(0, s, L"runshd", MB_ICONERROR);
}
void WINAPI entry(void) {
    int argc = 0;
    wchar_t **argv = CommandLineToArgvW(GetCommandLineW(), &argc);
    if (argc < 2) {
        message(L"Usage: runshd.exe shader.glsl [width height]");
        ExitProcess(2);
    }
    if (argc >= 4) {
        width = wtoi(argv[2]);
        height = wtoi(argv[3]);
        if (width < 1 || height < 1 || width > 16384 || height > 16384) {
            message(L"Invalid window size.");
            ExitProcess(2);
        }
    }
    DWORD len = 0, plen = 0;
    char *raw = readfile(argv[1], &len);
    if (!raw) {
        message(L"Cannot read shader file.");
        ExitProcess(2);
    }
    char *frag = prepare(raw, len, &plen);
    HeapFree(GetProcessHeap(), 0, raw);
    WNDCLASSW c = {0};
    c.style = CS_OWNDC;
    c.lpfnWndProc = wndproc;
    c.hInstance = GetModuleHandleW(0);
    c.hCursor = LoadCursorW(0, MAKEINTRESOURCEW(32512));
    c.lpszClassName = L"runshd";
    RegisterClassW(&c);
    RECT r = {0, 0, width, height};
    AdjustWindowRect(&r, WS_OVERLAPPEDWINDOW, FALSE);
    win = CreateWindowW(c.lpszClassName, L"runshd", WS_OVERLAPPEDWINDOW | WS_VISIBLE, CW_USEDEFAULT,
                        CW_USEDEFAULT, r.right - r.left, r.bottom - r.top, 0, 0, c.hInstance, 0);
    dc = GetDC(win);
    PIXELFORMATDESCRIPTOR p = {sizeof(p),
                               1,
                               PFD_DRAW_TO_WINDOW | PFD_SUPPORT_OPENGL | PFD_DOUBLEBUFFER,
                               PFD_TYPE_RGBA,
                               32,
                               0,
                               0,
                               0,
                               0,
                               0,
                               0,
                               0,
                               0,
                               0,
                               0,
                               0,
                               0,
                               0,
                               24,
                               8,
                               0,
                               PFD_MAIN_PLANE,
                               0,
                               0,
                               0,
                               0};
    int pf = ChoosePixelFormat(dc, &p);
    SetPixelFormat(dc, pf, &p);
    rc = wglCreateContext(dc);
    wglMakeCurrent(dc, rc);
    if (!loadgl()) {
        message(L"OpenGL 2.0 shader functions are unavailable.");
        ExitProcess(3);
    }
    const char *vs =
        "#version 120\nattribute vec2 position;void main(){gl_Position=vec4(position,0.,1.);}";
    GLuint v = shader(GL_VERTEX_SHADER, vs), f = shader(GL_FRAGMENT_SHADER, frag);
    if (!v || !f)
        ExitProcess(4);
    prog = pCreateProgram();
    pAttachShader(prog, v);
    pAttachShader(prog, f);
    pLinkProgram(prog);
    GLint ok = 0;
    pGetProgramiv(prog, GL_LINK_STATUS, &ok);
    if (!ok) {
        char log[4096];
        GLsizei n;
        pGetProgramInfoLog(prog, sizeof(log), &n, log);
        MessageBoxA(win, log, "Shader link error", MB_ICONERROR);
        ExitProcess(4);
    }
    loc();
    float quad[] = {-1, -1, 1, -1, -1, 1, 1, 1};
    pGenBuffers(1, &vbo);
    pBindBuffer(GL_ARRAY_BUFFER, vbo);
    pBufferData(GL_ARRAY_BUFFER, sizeof(quad), quad, GL_STATIC_DRAW);
    glGenTextures(1, &tex);
    glBindTexture(GL_TEXTURE_2D, tex);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA8, width, height, 0, GL_RGBA, GL_UNSIGNED_BYTE, 0);
    QueryPerformanceFrequency(&freq);
    QueryPerformanceCounter(&start);
    previous = start;
    MSG msg;
    while (1) {
        while (PeekMessageW(&msg, 0, 0, 0, PM_REMOVE)) {
            if (msg.message == WM_QUIT)
                ExitProcess(0);
            TranslateMessage(&msg);
            DispatchMessageW(&msg);
        }
        draw();
    }
}
