# -----------------------------------------------------------------------------
# Examples of use:
#
#  make           -- run all the tests in the current directory
#  make verbose   -- as make test, but up the verbosity
#  make accept    -- run the tests, accepting the current output
#
# The following variables may be set on the make command line:
#
#  TEST      -- specific test to run
#  TESTS     -- specific tests to run (same as $TEST really)
#  EXTRA_HC_OPTS      -- extra flags to send to the Haskell compiler
#  EXTRA_RUNTEST_OPTS -- extra flags to give the test driver
#  CONFIG    -- use a different configuration file
#  COMPILER  -- select a configuration file from config/
#  THREADS   -- run n tests at once
#  PLATFORM  -- if accepting a result, accept it for the current platform.
#  OS        -- if accepting a result, accept it for all wordsizes of the
#               current os.
#  PERF_BASELINE_COMMIT - the baseline commit to use for performance tests.
#
# -----------------------------------------------------------------------------

# export the value of $MAKE for invocation in tests/driver/
export MAKE

RUNTESTS     = $(TOP)/driver/runtests.py
COMPILER     = ghc
CONFIG       = $(TOP)/config/$(COMPILER)

ifeq "$(GhcUnregisterised)" "YES"
    # Otherwise C backend generates many warnings about
    # imcompatible proto casts for GCC's buitins:
    #    memcpy, printf, strlen.
    EXTRA_HC_OPTS += -optc-fno-builtin
endif

# TEST_HC_OPTS is passed to every invocation of TEST_HC
# in nested Makefiles
TEST_HC_OPTS = -dcore-lint -dstg-lint -dcmm-lint -fno-dump-with-ways \
			   -no-user-package-db -rtsopts $(EXTRA_HC_OPTS)

# Don't warn about missing specialisations. They can only occur with `-O`, but
# we want tests to produce the same output for all test ways.
TEST_HC_OPTS += -fno-warn-missed-specialisations
TEST_HC_OPTS += -fshow-warning-groups

# Turn off any VT800 codes in the output or they wreak havoc on the
# testsuite output.
TEST_HC_OPTS += -fdiagnostics-color=never
TEST_HC_OPTS += -fno-diagnostics-show-caret

# don't generate error index links for the GHC testsuite
TEST_HC_OPTS += -fprint-error-index-links=never

# See #15278.
TEST_HC_OPTS += -Werror=compat

# Add the no-debug-output last as it is often convenient to copy the test invocation
# removing this line.
TEST_HC_OPTS += -dno-debug-output

TEST_HC_OPTS_INTERACTIVE = $(TEST_HC_OPTS) --interactive -v0 -ignore-dot-ghci -fno-ghci-history


RUNTEST_OPTS =

ifeq "$(filter $(TargetOS_CPP), cygwin32 mingw32)" ""
exeext =
else
exeext = .exe
endif

ifneq "$(filter $(TargetOS_CPP),cygwin32 mingw32)" ""
dllext = .dll
else ifeq "$(TargetOS_CPP)" "darwin"
dllext = .dylib
else
dllext = .so
endif

RUNTEST_OPTS += -e "ghc_compiler_always_flags='$(TEST_HC_OPTS)'"

ifeq "$(GhcDebugAssertions)" "YES"
RUNTEST_OPTS += -e "config.compiler_debugged=True"
else
RUNTEST_OPTS += -e "config.compiler_debugged=False"
endif

ifeq "$(GhcWithNativeCodeGen)" "YES"
RUNTEST_OPTS += -e ghc_with_native_codegen=True
else
RUNTEST_OPTS += -e ghc_with_native_codegen=False
endif

ifeq "$(GhcLeadingUnderscore)" "YES"
RUNTEST_OPTS += -e "config.leading_underscore=True"
else
RUNTEST_OPTS += -e "config.leading_underscore=False"
endif

ifeq "$(GhcTablesNextToCode)" "YES"
RUNTEST_OPTS += -e "config.tables_next_to_code=True"
else
RUNTEST_OPTS += -e "config.tables_next_to_code=False"
endif

HAVE_GDB := $(shell if gdb --version > /dev/null 2> /dev/null; then echo YES; else echo NO; fi)
HAVE_READELF := $(shell if readelf --version > /dev/null 2> /dev/null; then echo YES; else echo NO; fi)

# we need a better way to find which backend is selected and if --check flag is
# used
BIGNUM_GMP := $(shell "$(GHC_PKG)" field ghc-bignum exposed-modules | grep GMP)

ifeq "$(filter thr, $(GhcRTSWays))" "thr"
RUNTEST_OPTS += -e config.ghc_with_threaded_rts=True
else
RUNTEST_OPTS += -e config.ghc_with_threaded_rts=False
endif

ifeq "$(filter dyn, $(GhcRTSWays))" "dyn"
RUNTEST_OPTS += -e ghc_with_dynamic_rts=True
else
RUNTEST_OPTS += -e ghc_with_dynamic_rts=False
endif

ifeq "$(GhcWithInterpreter)" "NO"
RUNTEST_OPTS += -e config.have_interp=False
else ifeq "$(GhcStage)" "1"
RUNTEST_OPTS += -e config.have_interp=False
else
RUNTEST_OPTS += -e config.have_interp=True
endif

ifeq "$(GhcUnregisterised)" "YES"
RUNTEST_OPTS += -e config.unregisterised=True
else
RUNTEST_OPTS += -e config.unregisterised=False
endif

ifeq "$(HAVE_GDB)" "YES"
RUNTEST_OPTS += -e config.have_gdb=True
else
RUNTEST_OPTS += -e config.have_gdb=False
endif

ifeq "$(HAVE_READELF)" "YES"
RUNTEST_OPTS += -e config.have_readelf=True
else
RUNTEST_OPTS += -e config.have_readelf=False
endif

ifeq "$(BIGNUM_GMP)" ""
RUNTEST_OPTS += -e config.have_fast_bignum=False
else
RUNTEST_OPTS += -e config.have_fast_bignum=True
endif

CABAL_MINIMAL_BUILD = --enable-library-vanilla --disable-shared

ifeq "$(GhcDynamic)" "YES"
RUNTEST_OPTS += -e config.ghc_dynamic=True
CABAL_PLUGIN_BUILD = --enable-shared --disable-library-vanilla
else
RUNTEST_OPTS += -e config.ghc_dynamic=False
CABAL_PLUGIN_BUILD = --enable-library-vanilla --disable-shared
endif

ifeq "$(GhcWithSMP)" "YES"
RUNTEST_OPTS += -e target_with_smp=True
else
RUNTEST_OPTS += -e target_with_smp=False
endif

ifeq "$(GhcWithRtsLinker)" "YES"
RUNTEST_OPTS += -e config.have_RTS_linker=True
else
RUNTEST_OPTS += -e config.have_RTS_linker=False
endif

RUNTEST_OPTS += -e config.libdir="r\"$(GhcLibdir)\""

ifeq "$(WINDOWS)" "YES"
RUNTEST_OPTS += -e windows=True
else
RUNTEST_OPTS += -e windows=False
endif

ifeq "$(DARWIN)" "YES"
RUNTEST_OPTS += -e darwin=True
else
RUNTEST_OPTS += -e darwin=False
endif

ifeq "$(IN_TREE_COMPILER)" "YES"
RUNTEST_OPTS += -e config.in_tree_compiler=True
else
RUNTEST_OPTS += -e config.in_tree_compiler=False
endif

ifneq "$(THREADS)" ""
RUNTEST_OPTS += --threads=$(THREADS)
endif

ifneq "$(VERBOSE)" ""
RUNTEST_OPTS += --verbose=$(VERBOSE)
endif

ifneq "$(PERF_TEST_BASELINE_COMMIT)" ""
RUNTEST_OPTS += --perf-baseline=$(PERF_TEST_BASELINE_COMMIT)
endif

ifeq "$(SKIP_PERF_TESTS)" "YES"
RUNTEST_OPTS += --skip-perf-tests
endif

ifeq "$(ONLY_PERF_TESTS)" "YES"
RUNTEST_OPTS += --only-perf-tests
endif

ifneq "$(TEST_ENV)" ""
RUNTEST_OPTS += --test-env="$(TEST_ENV)"
endif

ifeq "$(CLEANUP)" "0"
RUNTEST_OPTS += -e config.cleanup=False
else ifeq "$(CLEANUP)" "NO"
RUNTEST_OPTS += -e config.cleanup=False
else
RUNTEST_OPTS += -e config.cleanup=True
endif

ifeq "$(LOCAL)" "0"
# See Note [Running tests in /tmp].
RUNTEST_OPTS += -e config.local=False
else ifeq "$(LOCAL)" "NO"
RUNTEST_OPTS += -e config.local=False
else
RUNTEST_OPTS += -e config.local=True
endif

RUNTEST_OPTS +=  \
	--rootdir=. \
	--config-file=$(CONFIG) \
	--top="$(TOP_ABS)" \
	-e 'config.platform="$(TARGETPLATFORM)"' \
	-e 'config.os="$(TargetOS_CPP)"' \
	-e 'config.arch="$(TargetARCH_CPP)"' \
	-e 'config.wordsize="$(WORDSIZE)"' \
	-e 'config.timeout=int($(TIMEOUT)) or config.timeout' \
	-e 'config.exeext="$(exeext)"'

# Wrap non-empty program paths in quotes, because they may contain spaces. Do
# it here, so we don't have to (and don't forget to do it) in the .T test
# scripts (search for '{compiler}' or '{hpc}'). This may or may not be a good
# idea.
# Use `--config` instead of `-e`, because `-e` (which calls Python's `eval`
# function) would require another pair of (escaped) quotes, which interfers
# with MinGW's magic path handling (see #10449, and
# http://www.mingw.org/wiki/Posix_path_conversion).
# We use double instead of single quotes, which may or may not be important
# when using msys2 (#9626, #10441).
quote_path = $(if $1,"$1")
RUNTEST_OPTS +=  \
	--config 'compiler=$(call quote_path,$(TEST_HC))' \
	--config 'ghc_pkg=$(call quote_path,$(GHC_PKG))' \
	--config 'haddock=$(call quote_path,$(HADDOCK))' \
	--config 'hp2ps=$(call quote_path,$(HP2PS_ABS))' \
	--config 'hpc=$(call quote_path,$(HPC))' \
	--config 'gs=$(call quote_path,$(GS))' \
	--config 'timeout_prog=$(call quote_path,$(TIMEOUT_PROGRAM))'

RUNTEST_OPTS += --config 'stats_files_dir=$(TOP)/tests/perf/haddock'

RUNTEST_OPTS += -e "config.stage=$(GhcStage)"

ifneq "$(METRICS_FILE)" ""
RUNTEST_OPTS +=  \
	--metrics-file "$(METRICS_FILE)"
endif
ifneq "$(JUNIT_FILE)" ""
RUNTEST_OPTS +=  \
  --junit "$(JUNIT_FILE)"
endif
ifneq "$(SUMMARY_FILE)" ""
RUNTEST_OPTS +=  \
	--summary-file "$(SUMMARY_FILE)"
endif

ifneq "$(PERF_BASELINE_COMMIT)" ""
RUNTEST_OPTS +=  \
	--perf-baseline "$(PERF_BASELINE_COMMIT)"
endif

RUNTEST_OPTS +=  \
	$(EXTRA_RUNTEST_OPTS)

ifeq "$(list_broken)" "YES"
set_list_broken = -e config.list_broken=True
else
set_list_broken =
endif

# See Note [validate and testsuite speed] in `validate`
ifneq "$(SPEED)" ""
setspeed = -e config.speed="$(SPEED)"
else ifeq "$(fast)" "YES"
# Backward compatibility. Maybe some people are running 'make accept fast=YES'?
setspeed = -e config.speed=2
else
setspeed =
endif

ifeq "$(accept)" "YES"
setaccept = -e config.accept=True

ifeq "$(PLATFORM)" "YES"
setaccept += -e config.accept_platform=True
endif

ifeq "$(OS)" "YES"
setaccept += -e config.accept_os=True
endif

else
setaccept =
endif

.PHONY: all boot test verbose accept fast slow list_broken

all: test

TIMEOUT_PROGRAM = $(TOP)/timeout/install-inplace/bin/timeout$(exeext)

boot: $(TIMEOUT_PROGRAM)

$(TIMEOUT_PROGRAM) :
	@echo "Looks like you don't have timeout, building it first..."
	$(MAKE) -C $(TOP)/timeout all

# Use a '+' to make sure that any sub-MAKEs that python spawns can
# communicate with the topmake.
# See Note [Communicating options and variables to a submake]
test: $(TIMEOUT_PROGRAM)
	+PYTHON="$(PYTHON)" "$(PYTHON)" $(RUNTESTS) $(RUNTEST_OPTS) \
		$(patsubst %, --only=%, $(TEST)) \
		$(patsubst %, --only=%, $(TESTS)) \
		$(patsubst %, --way=%, $(WAY)) \
		$(patsubst %, --skipway=%, $(SKIPWAY)) \
		$(set_list_broken) \
		$(setspeed) \
		$(setaccept)

verbose: test

accept:
	$(MAKE) accept=YES

fast fasttest:
	# See Note [validate and testsuite speed] in `validate`
	$(MAKE) SPEED=2

slow slowtest:
	$(MAKE) SPEED=0

list_broken:
	$(MAKE) list_broken=YES

# Note [Communicating options and variables to a submake]
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Consider the following scenario:
#   * A test foo is defined as
#     test('foo', [], run_command, ['$MAKE footarget'])
#   * A user calls 'make -j24 TEST=foo'
#
# What happens is something like this:
#   * make (topmake) reads all options and variables given on the commandline
#     and adds them to the variable MAKEFLAGS [1]. This variable is exported by
#     default [1], so submakes can use them.
#   * The 'test' target calls 'python ..'
#   * Python calls 'make footarget' (submake)
#
# **First question**: what happens to the '-j24' option when calling make
# recursively?
#
# From
# https://www.gnu.org/software/make/manual/html_node/Variables_002fRecursion.html:
#
#     "The '-j' option is a special case (see Parallel Execution). If you set
#     it to some numeric value 'N' and your operating system supports it (most
#     any UNIX system will; others typically won't), the parent make and all the
#     sub-makes will communicate to ensure that there are only 'N' jobs running
#     at the same time between them all."
#
# In our scenario, the user will actually see the following warning [2]:
#
#     'warning: jobserver unavailable: using -j1. Add '+' to parent make rule.'
#
# The problem is that topmake and submake don't know about eachother, since
# python is in between. To let them communicate, we have to use the '+'
# option, by calling '+python' instead of 'python' [2]. This works,
# magically, and fixes #11569.
#
# **Second question**: can't we just unexport MAKEFLAGS, instead of using
# that '+' trick? The testsuite driver (python) mangages parallelism by
# itself already, so '-j24' doesn't do the right thing anyway. You have to
# use 'make test THREADS=24'. Unexporting MAKEFLAGS would mean ignoring
# any '-j' flags passed to make (either from the user calling 'make -j'
# explicitly or from having MAKEFLAGS=-j set in the shell, see #11569).
#
# This almost works, except when calling 'make fast/slow/accept TEST_HC=ghc'
# instead of just 'make test'. These targets call 'make test FAST=YES'
# recursively (and 'make test' calls python, as before).
#
# The problem is that in boilerplate.mk we try to override the variable
# TEST_HC (See Note [The TEST_HC variable]). Somewhere somehow this
# information (of us wanting to update TEST_HC) gets lost in the process,
# resulting in the final TEST_HC always getting set to the inplace compiler.
# It seems possible to remedy this yet again by exporting TEST_HC explicitly,
# but I didn't understand nor test it thoroughly (what about the other
# variables we override, see calls to canonicalise), and the '+' trick seems
# to work at least equally well (just don't run something like
# 'make test fast slow accept').
#
# Tests:
# * `make TEST=T3307 -j2` should not show a warning.
# * `make TEST=tc001 TEST_HC=ghc fast` should not use the inplace compiler.
#
# [1] https://www.gnu.org/software/make/manual/html_node/Variables_002fRecursion.html
# [2] https://www.gnu.org/software/make/manual/html_node/Error-Messages.html
