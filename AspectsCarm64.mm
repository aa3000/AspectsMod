
//struct PointerAndInt_ {
//  uintptr_t ptr;
//  int i;
//};

// arm64 hooking magic.

// Called in our replacementObjc_msgSend before calling the original objc_msgSend.
// This pushes a CallRecord to our stack, most importantly saving the lr.
// Returns orig_objc_msgSend in x0 and isLoggingEnabled in x1.
/*
struct PointerAndInt_ preObjc_msgSend(id self, uintptr_t lr, SEL _cmd, struct RegState_ *rs) {
  ThreadCallStack *cs = getThreadCallStack();
  if (!cs->isLoggingEnabled) { // Not enabled, just return.
    return (struct PointerAndInt_) {reinterpret_cast<uintptr_t>(orig_objc_msgSend), 0};
  }
  pushCallRecord(self, lr, _cmd, cs);
  pa_list args = (pa_list){ rs, ((unsigned char *)rs) + 208, 2, 0 }; // 208 is the offset of rs from the top of the stack.

  preObjc_msgSend_common(self, lr, _cmd, cs, args);

  return (struct PointerAndInt_) {reinterpret_cast<uintptr_t>(orig_objc_msgSend), 1};
}
 */

#define call(b, value) \
    __asm volatile ("stp x8, x9, [sp, #-16]!\n"); \
    __asm volatile ("mov x12, %0\n" :: "r"(value)); \
    __asm volatile ("ldp x8, x9, [sp], #16\n"); \
    __asm volatile (#b " x12\n");

// push {q0-q7}
// push {x0-x8, lr}
#define save() \
    __asm volatile ( \
        /*"stp q6, q7, [sp, #-32]!\n" \
        "stp q4, q5, [sp, #-32]!\n" \
        "stp q2, q3, [sp, #-32]!\n" \
        "stp q0, q1, [sp, #-32]!\n"*/ \
        "stp x8, x9, [sp, #-16]!\n" \
        "stp x6, x7, [sp, #-16]!\n" \
        "stp x4, x5, [sp, #-16]!\n" \
        "stp x2, x3, [sp, #-16]!\n" \
        "stp x0, x1, [sp, #-16]!\n");

// pop {x0-x8, lr}
// pop {q0-q7}
#define load() \
    __asm volatile ( \
        "ldp x0, x1, [sp], #16\n" \
        "ldp x2, x3, [sp], #16\n" \
        "ldp x4, x5, [sp], #16\n" \
        "ldp x6, x7, [sp], #16\n" \
        "ldp x8, x9, [sp], #16\n" \
        /*"ldp q0, q1, [sp], #32\n" \
        "ldp q2, q3, [sp], #32\n" \
        "ldp q4, q5, [sp], #32\n" \
        "ldp q6, q7, [sp], #32\n"*/);

#define link(b, value) \
    __asm volatile ("stp x8, lr, [sp, #-16]!\n"); \
    __asm volatile ("sub sp, sp, #16\n"); \
    call(b, value); \
    __asm volatile ("add sp, sp, #16\n"); \
    __asm volatile ("ldp x8, lr, [sp], #16\n");

#define ret() __asm volatile ("ret\n");

__attribute__((__naked__))
static void replacementObjc_msgSend()
{
    // Save parameters.
    save()
    
    __asm volatile ("mov x2, lr\n");
    __asm volatile ("mov x3, x4\n");
    
    // Call our preObjc_msgSend.
    call(blr, &preObjc_msgSend)
    
    // Load parameters.
    load()
    
    // Call through to the original objc_msgSend.
    call(blr, orig_objc_msgSend)
    
    // Save original objc_msgSend return value.
    save()
    
    // Call our postObjc_msgSend.
    call(blr, &postObjc_msgSend)
    
    // restore lr
    __asm volatile ("mov lr, x0\n");
    
    // Load original objc_msgSend return value.
    load()
    
    // return
    ret()
}

//__attribute__((__naked__))
//static void replacementObjc_msgSend_stret()
//{
//    save()
//    __asm volatile ("mov x0, x1\n");
//    __asm volatile ("mov x1, x2\n");
//    __asm volatile ("mov x2, lr\n");
//    call(blr, &preObjc_msgSend)
//    load()
//    call(blr, orig_objc_msgSend_stret)
//    save()
//    call(blr, &postObjc_msgSend)
//    __asm volatile ("mov lr, x0\n");
//    load()
//    ret()
//}
static void replacementObjc_msgSend_stret()
{
    printf("Misses implement objc_msgSend_stret\n");
    assert(0);
}

//__attribute__((__naked__))
//static void replacementObjc_msgSendSuper()
//{
//    save()
//    __asm volatile ("mov x2, lr\n");
//    call(blr, &preObjc_msgSendSuper)
//    load()
//    call(blr, orig_objc_msgSendSuper)
//    save()
//    call(blr, &postObjc_msgSend)
//    __asm volatile ("mov lr, x0\n");
//    load()
//    ret()
//}
static void replacementObjc_msgSendSuper()
{
    printf("Misses implement objc_msgSendSuper\n");
    assert(0);
}


//__attribute__((__naked__))
//static void replacementObjc_msgSendSuper_stret()
//{
//    save()
//    __asm volatile ("mov x0, x1\n");
//    __asm volatile ("mov x1, x2\n");
//    __asm volatile ("mov x2, lr\n");
//    call(blr, &preObjc_msgSendSuper)
//    load()
//    call(blr, orig_objc_msgSendSuper_stret)
//    save()
//    call(blr, &postObjc_msgSend)
//    __asm volatile ("mov lr, x0\n");
//    load()
//    ret()
//}
static void replacementObjc_msgSendSuper_stret()
{
    printf("Misses implement objc_msgSendSuper_stret\n");
    assert(0);
}

__attribute__((__naked__))
static void replacementObjc_msgSendSuper2()
{
    save()
    __asm volatile ("mov x2, lr\n");
    call(blr, &preObjc_msgSendSuper2)
    load()
    call(blr, orig_objc_msgSendSuper2)
    save()
    call(blr, &postObjc_msgSend)
    __asm volatile ("mov lr, x0\n");
    load()
    ret()
}


//__attribute__((__naked__))
//static void replacementObjc_msgSendSuper2_stret()
//{
//    save()
//    __asm volatile ("mov x0, x1\n");
//    __asm volatile ("mov x1, x2\n");
//    __asm volatile ("mov x2, lr\n");
//    call(blr, &preObjc_msgSendSuper2)
//    load()
//    call(blr, orig_objc_msgSendSuper2_stret)
//    save()
//    call(blr, &postObjc_msgSend)
//    __asm volatile ("mov lr, x0\n");
//    load()
//    ret()
//}

static void replacementObjc_msgSendSuper2_stret()
{
    printf("Misses implement objc_msgSendSuper2_stret\n");
    assert(0);
}

//// Our replacement objc_msgSend (arm64).
////
//// See:
//// https://blog.nelhage.com/2010/10/amd64-and-pa_arg/
//// http://infocenter.arm.com/help/topic/com.arm.doc.ihi0055b/IHI0055B_aapcs64.pdf
//// https://developer.apple.com/library/ios/documentation/Xcode/Conceptual/iPhoneOSABIReference/Articles/ARM64FunctionCallingConventions.html
//__attribute__((__naked__))
//static volatile void replacementObjc_msgSend1() {
//  __asm__ volatile (
//    // push {q0-q7}
//      "stp q6, q7, [sp, #-32]!\n"
//      "stp q4, q5, [sp, #-32]!\n"
//      "stp q2, q3, [sp, #-32]!\n"
//      "stp q0, q1, [sp, #-32]!\n"
//    // push {x0-x8, lr}
//      "stp x8, lr, [sp, #-16]!\n"
//      "stp x6, x7, [sp, #-16]!\n"
//      "stp x4, x5, [sp, #-16]!\n"
//      "stp x2, x3, [sp, #-16]!\n"
//      "stp x0, x1, [sp, #-16]!\n"
//    // Swap args around for call.
//      "mov x2, x1\n"
//      "mov x1, lr\n"
//      "mov x3, sp\n"
//    // Call preObjc_msgSend which puts orig_objc_msgSend into x0 and isLoggingEnabled into x1.
//      "bl __Z15preObjc_msgSendP11objc_objectmP13objc_selectorP9RegState_\n"
//      "mov x9, x0\n"
//      "mov x10, x1\n"
//      "tst x10, x10\n" // Set condition code for later branch.
//    // pop {x0-x8, lr}
//      "ldp x0, x1, [sp], #16\n"
//      "ldp x2, x3, [sp], #16\n"
//      "ldp x4, x5, [sp], #16\n"
//      "ldp x6, x7, [sp], #16\n"
//      "ldp x8, lr, [sp], #16\n"
//    // pop {q0-q7}
//      "ldp q0, q1, [sp], #32\n"
//      "ldp q2, q3, [sp], #32\n"
//      "ldp q4, q5, [sp], #32\n"
//      "ldp q6, q7, [sp], #32\n"
//    // Make sure it's enabled.
//      "b.eq Lpassthrough\n"
//    // Call through to the original objc_msgSend.
//      "blr x9\n"
//    // push {x0-x9}
//      "stp x0, x1, [sp, #-16]!\n"
//      "stp x2, x3, [sp, #-16]!\n"
//      "stp x4, x5, [sp, #-16]!\n"
//      "stp x6, x7, [sp, #-16]!\n"
//      "stp x8, x9, [sp, #-16]!\n" // Not sure if needed - push for alignment.
//    // push {q0-q7}
//      "stp q0, q1, [sp, #-32]!\n"
//      "stp q2, q3, [sp, #-32]!\n"
//      "stp q4, q5, [sp, #-32]!\n"
//      "stp q6, q7, [sp, #-32]!\n"
//    // Call our postObjc_msgSend hook.
//      "bl __Z16postObjc_msgSendv\n"
//      "mov lr, x0\n"
//    // pop {q0-q7}
//      "ldp q6, q7, [sp], #32\n"
//      "ldp q4, q5, [sp], #32\n"
//      "ldp q2, q3, [sp], #32\n"
//      "ldp q0, q1, [sp], #32\n"
//    // pop {x0-x9}
//      "ldp x8, x9, [sp], #16\n"
//      "ldp x6, x7, [sp], #16\n"
//      "ldp x4, x5, [sp], #16\n"
//      "ldp x2, x3, [sp], #16\n"
//      "ldp x0, x1, [sp], #16\n"
//      "ret\n"
//
//    // Pass through to original objc_msgSend.
//      "Lpassthrough:\n"
//      "br x9"
//    );
//}
