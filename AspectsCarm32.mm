
// arm32 hooking magic.

//// Called in our replacementObjc_msgSend before calling the original objc_msgSend.
//// This pushes a CallRecord to our stack, most importantly saving the lr.
//// Returns orig_objc_msgSend.
//uintptr_t preObjc_msgSend(id self, uintptr_t lr, SEL _cmd, va_list args) {
//    ThreadCallStack *cs = getThreadCallStack();
//    pushCallRecord(self, lr, _cmd, cs);
//    
//    preObjc_msgSend_common(self, lr, _cmd, cs, (arg_list &)args);
//    
//    return reinterpret_cast<uintptr_t>(orig_objc_msgSend);
//}

#define call(b, value) \
    __asm volatile ("push {r0}\n"); \
    __asm volatile ("mov r12, %0\n" :: "r"(value)); \
    __asm volatile ("pop {r0}\n"); \
    __asm volatile (#b " r12\n");

#define save() \
    __asm volatile ("push {r0, r1, r2, r3}\n");

#define load() \
    __asm volatile ("pop {r0, r1, r2, r3}\n");

#define link(b, value) \
    __asm volatile ("push {lr}\n"); \
    __asm volatile ("sub sp, #4\n"); \
    call(b, value) \
    __asm volatile ("add sp, #4\n"); \
    __asm volatile ("pop {lr}\n");

#define ret() __asm volatile ("bx lr\n");

#define checkandjump(b, value, tag)\
    __asm volatile ("push {lr}\n"); \
    __asm volatile ("sub sp, #4\n"); \
    save() \
    call(b, value) \
    __asm volatile ("mov r12, r0\n"); \
    load() \
    __asm volatile ("add sp, #4\n"); \
    __asm volatile ("pop {lr}\n"); \
    __asm volatile ("sxtb   r12, r12\n"); \
    __asm volatile ("cmp    r12, #0x0\n"); \
    __asm volatile ("beq L" #tag "\n");

#define tag(tag) \
    __asm volatile ("L" #tag ":\n");

__attribute__((__naked__))
static void replacementObjc_msgSend()
{
    // Save parameters.
    save()

    __asm volatile ("mov r2, lr\n");
    //__asm volatile ("add r3, sp, #8\n");

    // Call our preObjc_msgSend.
    call(blx, &preObjc_msgSend)

    // Load parameters.
    load()
    
    // Call through to the original objc_msgSend.
    call(blx, orig_objc_msgSend)
    
    // Save original objc_msgSend return value.
    save()
    
    // Call our postObjc_msgSend.
    call(blx, &postObjc_msgSend)
    
    // restore lr
    __asm volatile ("mov lr, r0\n");

    // Load original objc_msgSend return value.
    load()
    
    // return
    ret()
    
    //call(bx, orig_objc_msgSend)
}

__attribute__((__naked__))
static void replacementObjc_msgSend_stret()
{
    save()
    __asm volatile ("mov r0, r1\n");
    __asm volatile ("mov r1, r2\n");
    __asm volatile ("mov r2, lr\n");
    //__asm volatile ("add r3, sp, #12\n");
    call(blx, &preObjc_msgSend)
    load()
    call(blx, orig_objc_msgSend_stret)
    save()
    call(blx, &postObjc_msgSend)
    __asm volatile ("mov lr, r0\n");
    load()
    ret()
    
    //call(bx, orig_objc_msgSend_stret);
}

__attribute__((__naked__))
static void replacementObjc_msgSendSuper()
{
    save()
    __asm volatile ("mov r2, lr\n");
    //__asm volatile ("add r3, sp, #8\n");
    call(blx, &preObjc_msgSendSuper)
    load()
    call(blx, orig_objc_msgSendSuper)
    save()
    call(blx, &postObjc_msgSend)
    __asm volatile ("mov lr, r0\n");
    load()
    ret()
}

__attribute__((__naked__))
static void replacementObjc_msgSendSuper_stret()
{
    save()
    __asm volatile ("mov r0, r1\n");
    __asm volatile ("mov r1, r2\n");
    __asm volatile ("mov r2, lr\n");
    //__asm volatile ("add r3, sp, #12\n");
    call(blx, &preObjc_msgSendSuper)
    load()
    call(blx, orig_objc_msgSendSuper_stret)
    save()
    call(blx, &postObjc_msgSend)
    __asm volatile ("mov lr, r0\n");
    load()
    ret()
}

__attribute__((__naked__))
static void replacementObjc_msgSendSuper2()
{
    save()
    __asm volatile ("mov r2, lr\n");
    //__asm volatile ("add r3, sp, #8\n");
    call(blx, &preObjc_msgSendSuper2)
    load()
    call(blx, orig_objc_msgSendSuper2)
    save()
    call(blx, &postObjc_msgSend)
    __asm volatile ("mov lr, r0\n");
    load()
    ret()
    
//    call(bx, orig_objc_msgSendSuper2)
}

__attribute__((__naked__))
static void replacementObjc_msgSendSuper2_stret()
{
    save()
    __asm volatile ("mov r0, r1\n");
    __asm volatile ("mov r1, r2\n");
    __asm volatile ("mov r2, lr\n");
    //__asm volatile ("add r3, sp, #12\n");
    call(blx, &preObjc_msgSendSuper2)
    load()
    call(blx, orig_objc_msgSendSuper2_stret)
    save()
    call(blx, &postObjc_msgSend)
    __asm volatile ("mov lr, r0\n");
    load()
    ret()
    
//    call(bx, orig_objc_msgSendSuper2_stret)
}

//// Our replacement objc_msgSeng for arm32.
//__attribute__((__naked__))
//static void replacementObjc_msgSend1() {
//    __asm__ volatile (
//      // Make sure it's enabled.
//      "push {r0-r3, lr}\n"
//      "blx _InspectiveC_isLoggingEnabled\n"
//      "mov r12, r0\n"
//      "pop {r0-r3, lr}\n"
//      "ands r12, r12\n"
//      "beq Lpassthrough\n"
//      // Call our preObjc_msgSend hook - returns orig_objc_msgSend.
//      // Swap the args around for our call to preObjc_msgSend.
//      "push {r0, r1, r2, r3}\n"
//      "mov r2, r1\n"
//      "mov r1, lr\n"
//      "add r3, sp, #8\n"
//      "blx __Z15preObjc_msgSendP11objc_objectmP13objc_selectorPv\n"
//      "mov r12, r0\n"
//      "pop {r0, r1, r2, r3}\n"
//      // Call through to the original objc_msgSend.
//      "blx r12\n"
//      // Call our postObjc_msgSend hook.
//      "push {r0-r3}\n"
//      "blx __Z16postObjc_msgSendv\n"
//      "mov lr, r0\n"
//      "pop {r0-r3}\n"
//      "bx lr\n"
//      // Pass through to original objc_msgSend.
//      "Lpassthrough:\n"
//      "push {r0, lr}\n"
//      "blx __Z19getOrigObjc_msgSendv\n"
//      "mov r12, r0\n"
//      "pop {r0, lr}\n"
//      "bx r12"
//      );
//}
