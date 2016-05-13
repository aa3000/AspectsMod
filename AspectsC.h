#ifndef ASPECTS_C_H
#define ASPECTS_C_H

#include <objc/objc.h>

#if __cplusplus
extern "C" {
#endif

Class getRealClass(id _self, Class _cls, SEL _cmd);
    
#if __cplusplus
}
#endif

#endif
