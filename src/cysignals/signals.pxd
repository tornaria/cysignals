# cython: preliminary_late_includes_cy28=True
#*****************************************************************************
#  cysignals is free software: you can redistribute it and/or modify it
#  under the terms of the GNU Lesser General Public License as published
#  by the Free Software Foundation, either version 3 of the License, or
#  (at your option) any later version.
#
#  cysignals is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU Lesser General Public License for more details.
#
#  You should have received a copy of the GNU Lesser General Public License
#  along with cysignals.  If not, see <http://www.gnu.org/licenses/>.
#
#*****************************************************************************

from cpython.object cimport PyObject

cdef extern from *:
    int unlikely(int) nogil  # Defined by Cython


cdef extern from "struct_signals.h":
    ctypedef int cy_atomic_int

    ctypedef struct cysigs_t:
        cy_atomic_int sig_on_count
        cy_atomic_int block_sigint
        const char* s
        PyObject* exc_value


cdef extern from "macros.h" nogil:
    int sig_on() except 0
    int sig_str(const char*) except 0
    int sig_check() except 0
    void sig_off()
    void sig_retry()  # Does not return
    void sig_error()  # Does not return
    void sig_block()
    void sig_unblock()

    # Macros behaving exactly like sig_on, sig_str and sig_check but
    # which are *not* declared "except 0".  This is useful if some
    # low-level Cython code wants to do its own exception handling.
    int sig_on_no_except "sig_on"()
    int sig_str_no_except "sig_str"(const char*)
    int sig_check_no_except "sig_check"()

# This function adds custom block/unblock/pending.
cdef int add_custom_signals(int (*custom_signal_is_blocked)() noexcept,
                            void (*custom_signal_unblock)() noexcept,
                            void (*custom_set_pending_signal)(int) noexcept) except -1

cdef int sig_raise_exception "sig_raise_exception"(int sig, const char* msg) except 0 with gil

# This function does nothing, but it is declared cdef except *, so it
# can be used to make Cython check whether there is a pending exception
# (PyErr_Occurred() is non-NULL). To Cython, it will look like
# cython_check_exception() actually raised the exception.
cdef inline void cython_check_exception() except * nogil:
    pass


cdef void verify_exc_value() noexcept

cdef inline PyObject* sig_occurred() noexcept:
    """
    Borrowed reference to the exception which is currently being
    propagated from cysignals. If there is no exception or if we
    are done handling the exception, return ``NULL``.

    This is meant for Cython code to check whether objects may be in
    an invalid state. Typically, this would be used in an ``except``
    or ``finally`` block or in ``__dealloc__``.

    The implementation is based on reference counting: it checks whether
    the exception has been deleted. This means that it will break if the
    exception is stored somewhere.
    """
    if unlikely(cysigs.exc_value is not NULL):
        verify_exc_value()
    return cysigs.exc_value


# Variables and functions which are implemented in implementation.c
# and used by macros.h. We use the Cython cimport mechanism to make
# these available to every Cython module cimporting this file.
cdef nogil:
    cysigs_t cysigs "cysigs"
    void _sig_on_interrupt_received "_sig_on_interrupt_received"() noexcept
    void _sig_on_recover "_sig_on_recover"() noexcept
    void _sig_off_warning "_sig_off_warning"(const char*, int) noexcept
    void print_backtrace "print_backtrace"() noexcept


cdef inline void __generate_declarations() noexcept:
    cysigs
    _sig_on_interrupt_received
    _sig_on_recover
    _sig_off_warning
    print_backtrace
