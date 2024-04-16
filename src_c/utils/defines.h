#ifdef _MSC_VER
#define INLINE static __forceinline
#define DEBUG_BREAK() __debugbreak()
#else
#define INLINE static inline
#define DEBUG_BREAK() __builtin_trap()
#endif

#ifdef BUILD_DEBUG
#define ASSERT(expr)\
if (!(expr))\
{\
fprintf(stderr, "%s(%i): assertion failure '%s'\n", __FILE__, __LINE__, #expr);\
DEBUG_BREAK();\
}

#define ASSERT_MSG(expr, msg)\
if (!(expr))\
{\
fprintf(stderr, "%s(%i): assertion failure '%s': '%s'\n", __FILE__, __LINE__, #expr, msg);\
DEBUG_BREAK();\
}

#else
#define ASSERT(expr)
#define ASSERT_MSG(expr, msg)
#endif

#define BYTES(n)      (n)
#define KILOBYTES(n)  (BYTES(n)*1024)
#define MEGABYTES(n)  (KILOBYTES(n)*1024)