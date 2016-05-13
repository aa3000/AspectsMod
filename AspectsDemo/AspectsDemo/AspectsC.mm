//#include <substrate.h>
#include <Foundation/Foundation.h>

#include <cstdarg>
#include <cstdio>

#include <sys/types.h>
#include <sys/stat.h>

#include <pthread.h>

#import <objc/runtime.h>
#import "fishhook.h"
#include "AspectsC.h"

#ifndef OBJC_ARC_ENABLED
    #ifdef __has_feature
        #define OBJC_ARC_ENABLED __has_feature(objc_arc)
    #else
        #define OBJC_ARC_ENABLED 0
    #endif
#endif

#if (OBJC_ARC_ENABLED)
    #error "AspectsC does no support arc, please specify compiler flags '-fno-objc-arc' for AspectsC.mm"
#else

#if __arm64__
#define arg_list pa_list
#else
#define arg_list va_list
#endif

static pthread_key_t threadKey;

// The original objc_msgSend.
__unused static id (*orig_objc_msgSend)(id, SEL, ...);
__unused static id (*orig_objc_msgSend_stret)(void *, id, SEL, ...);
__unused static id (*orig_objc_msgSendSuper)(void *, SEL, ...);
__unused static id (*orig_objc_msgSendSuper_stret)(void *, void *, SEL, ...);
__unused static id (*orig_objc_msgSendSuper2)(void *, SEL, ...);
__unused static id (*orig_objc_msgSendSuper2_stret)(void *, void *, SEL, ...);

// Shared structures.
typedef struct CallRecord_ {
    __unsafe_unretained id _self;
    Class _cls;
    SEL _cmd;
    uintptr_t _lr;
} CallRecord;

typedef struct ThreadCallStack_ {
    CallRecord* stack;
    int allocatedLength;
    int index;
} ThreadCallStack;

#define DEFAULT_CALLSTACK_DEPTH 128
#define CALLSTACK_DEPTH_INCREMENT 64


static inline ThreadCallStack * getThreadCallStack();

static inline ThreadCallStack * getThreadCallStack() {
  ThreadCallStack *cs = (ThreadCallStack *)pthread_getspecific(threadKey);
  if (cs == NULL) {
      cs = (ThreadCallStack *)malloc(sizeof(ThreadCallStack));
      cs->stack = (CallRecord *)calloc(DEFAULT_CALLSTACK_DEPTH, sizeof(CallRecord));
      cs->allocatedLength = DEFAULT_CALLSTACK_DEPTH;
      cs->index = -1;
    pthread_setspecific(threadKey, cs);
  }
  return cs;
}

static void destroyThreadCallStack(void *ptr) {
    ThreadCallStack *cs = (ThreadCallStack *)ptr;

    free(cs->stack);

    free(cs);
}

static void pushCallRecord(id _self, Class _cls, SEL _cmd, uintptr_t lr)
{
    ThreadCallStack *cs = getThreadCallStack();
    if (cs)
    {
        int nextIndex = (++cs->index);
        if (nextIndex >= cs->allocatedLength) {
            cs->allocatedLength += CALLSTACK_DEPTH_INCREMENT;
            cs->stack = (CallRecord *)realloc(cs->stack, cs->allocatedLength * sizeof(CallRecord));
        }
        CallRecord *newRecord = &cs->stack[nextIndex];
        newRecord->_self = _self;
        newRecord->_cls = _cls;
        newRecord->_cmd = _cmd;
        newRecord->_lr = lr;
        //printf("pushCallRecord index %d\n", cs->index);
    }
}

static uintptr_t popCallRecord()
{
    ThreadCallStack *cs = getThreadCallStack();
    int nextIndex = cs->index--;
    //printf("popCallRecord index %d\n", cs->index);
    CallRecord *pRecord = &cs->stack[nextIndex];
    return pRecord->_lr;
}

static CallRecord * currentCallRecord(id _self, SEL _cmd)
{
    ThreadCallStack *cs = getThreadCallStack();
    
    CallRecord * pCallRecord = NULL;
    
    if (cs->index >= 0)
    {
    #ifdef __arm64__
        pCallRecord = &cs->stack[cs->index];
    #else
        int index = cs->index;
        do
        {
            pCallRecord = &cs->stack[index];
            if (_self == pCallRecord->_self && _cmd == pCallRecord->_cmd)
            {
                break;
            }
            pCallRecord = NULL;
        } while (index-- > 0);
    }
    #endif
    return pCallRecord;

}

Class getRealClass(id _self, Class _cls, SEL _cmd)
{
    Class cls = _cls;

    CallRecord * pCallRecord = currentCallRecord(_self, _cmd);

    if (pCallRecord)
    {
        if (_self != pCallRecord->_self)
        {
            printf("Aspects: %s\n", "Not the same object");
        }
        else if (_cmd != pCallRecord->_cmd)
        {
            printf("Aspects: %s obj:<%s: %p> _cmd:%s\n", "Not the same command", class_getName(object_getClass(_self)), _self, sel_getName(_cmd));
        }
        else
        {
            cls = pCallRecord->_cls;
        }
    }
    
    return cls;
}

void preObjc_msgSend(id self, SEL _cmd, uintptr_t lr)
{
    pushCallRecord(self, object_getClass(self), _cmd, lr);
}

struct objc_super {
    /// Specifies an instance of a class.
    __unsafe_unretained id receiver;
    
    /// Specifies the particular superclass of the instance to message.
#if !defined(__cplusplus)  &&  !__OBJC2__
    /* For compatibility with old objc-runtime.h header */
    __unsafe_unretained Class class;
#else
    __unsafe_unretained Class super_class;
#endif
    /* super_class is the first class to search */
};

void preObjc_msgSendSuper(struct objc_super *_super, SEL _cmd, uintptr_t lr)
{
    pushCallRecord(_super->receiver, _super->super_class, _cmd, lr);
}

void preObjc_msgSendSuper2(struct objc_super *_super, SEL _cmd, uintptr_t lr)
{
    pushCallRecord(_super->receiver, class_getSuperclass(_super->super_class), _cmd, lr);
}

uintptr_t postObjc_msgSend()
{
    return popCallRecord();
}

// 32-bit vs 64-bit stuff.
#if TARGET_IPHONE_SIMULATOR
    //#include "InspectiveCarm32.mm"
#else
    #ifdef __arm64__
        #include "AspectsCarm64.mm"
    #else
        #include "AspectsCarm32.mm"
    #endif
#endif
    
#define _finline inline __attribute__((__always_inline__))
    
#ifdef __cplusplus
    #define AspectsCInitialize \
    static void _AspectsCInitialize(void); \
    namespace { static class $AspectsCInitialize { public: _finline $AspectsCInitialize() { \
    _AspectsCInitialize(); \
    } } $AspectsCInitialize; } \
    static void _AspectsCInitialize()
#else
    #define AspectsCInitialize \
    __attribute__((__constructor__)) static void _AspectsCInitialize(void)
#endif

AspectsCInitialize {
    pthread_key_create(&threadKey, &destroyThreadCallStack);

#if TARGET_IPHONE_SIMULATOR
#else
    rebind_symbols((struct rebinding[6]){
        //{"objc_msgSend", (void *)replacementObjc_msgSend, (void **)&orig_objc_msgSend},
        //{"objc_msgSend_stret", (void *)replacementObjc_msgSend_stret, (void **)&orig_objc_msgSend_stret},
        {"objc_msgSendSuper", (void *)replacementObjc_msgSendSuper, (void **)&orig_objc_msgSendSuper},
        {"objc_msgSendSuper_stret", (void *)replacementObjc_msgSendSuper_stret, (void **)&orig_objc_msgSendSuper_stret},
        {"objc_msgSendSuper2", (void *)replacementObjc_msgSendSuper2, (void **)&orig_objc_msgSendSuper2},
        {"objc_msgSendSuper2_stret", (void *)replacementObjc_msgSendSuper2_stret, (void **)&orig_objc_msgSendSuper2_stret}
    }, 4);
#endif

}
    
#endif
