#include "macaw_framework_ext.h"

VALUE rb_mMacawFramework;

void
Init_macaw_framework_ext(void) {
    rb_mMacawFramework = rb_define_module("MacawFramework");
}
