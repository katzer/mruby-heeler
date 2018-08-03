/* MIT License
 *
 * Copyright (c) 2018 Sebastian Katzer
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 */

#include "mruby.h"
#include "mruby/error.h"

#include <sys/types.h>
#include <sys/wait.h>
#include <string.h>
#include <unistd.h>
#include <errno.h>
#include <pthread.h>

static pthread_t clean_thread;

static mrb_value
mrb_f_fork (mrb_state *mrb, mrb_value self)
{
    mrb_value b;
    pid_t pid = 0;

    mrb_get_args(mrb, "&", &b);

#ifndef _WIN32
    pid = fork();
#endif

    switch (pid)
    {
        case 0:
        {
            mrb_yield(mrb, b, mrb_nil_value());
            _exit(0);

            return mrb_nil_value();
        }
        case -1:
        {
            mrb_sys_fail(mrb, "fork failed");
            return mrb_nil_value();
        }
        default:
        {
            return mrb_fixnum_value(pid);
        }
    }
}

#ifndef _WIN32
static void *mrb_do_cleaning (void *data)
{
    int inval = (int)data;

    while (1)
    {
        while (waitpid((pid_t)(-1), 0, WNOHANG) > 0);
        sleep(inval);
    }
}
#endif

static inline mrb_value
mrb_f_stop_cleanup (mrb_state *mrb, mrb_value self)
{
#ifndef _WIN32
    if (clean_thread) pthread_cancel(clean_thread);
#endif
    return mrb_nil_value();
}

static mrb_value
mrb_f_keep_clean (mrb_state *mrb, mrb_value self)
{
#ifndef _WIN32
    mrb_int inval = 5;
    int res;

    mrb_get_args(mrb, "|i", &inval);

    mrb_f_stop_cleanup(mrb, self);

    if ((res = pthread_create(&clean_thread, NULL, &mrb_do_cleaning, (void *)inval)))
    {
        mrb_sys_fail(mrb, strerror(res));
    }
#endif
    return mrb_nil_value();
}

void
mrb_mruby_heeler_gem_init(mrb_state *mrb)
{
    struct RClass *mod, *cls;

    mod = mrb_define_module(mrb, "Heeler");
    cls = mrb_define_class_under(mrb, mod, "Server", mrb->object_class);

    mrb_define_method(mrb, cls, "fork",         mrb_f_fork,         MRB_ARGS_BLOCK());
    mrb_define_method(mrb, cls, "keep_clean",   mrb_f_keep_clean,   MRB_ARGS_OPT(1));
    mrb_define_method(mrb, cls, "stop_cleanup", mrb_f_stop_cleanup, MRB_ARGS_NONE());
}

void
mrb_mruby_heeler_gem_final(mrb_state *mrb)
{

}