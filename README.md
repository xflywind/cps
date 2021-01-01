# Continuation-Passing Style

[![Test Matrix](https://github.com/disruptek/cps/workflows/CI/badge.svg)](https://github.com/disruptek/cps/actions?query=workflow%3ACI)
[![GitHub release (latest by date)](https://img.shields.io/github/v/release/disruptek/cps?style=flat)](https://github.com/disruptek/cps/releases/latest)
![Minimum supported Nim version](https://img.shields.io/badge/nim-1.5.1%2B-informational?style=flat&logo=nim)
[![License](https://img.shields.io/github/license/disruptek/cps?style=flat)](#license)

This project provides a macro `cps` which you can apply to a procedure to
rewrite it to use continuations for control flow.

All runtime functionality is implemented in a dispatcher which you can replace
to completely change the type and behavior of your continuations.

For a description of the origins of this concept, see the included papers
and https://github.com/zevv/nimcsp.

## Why

These continuations...

- compose efficient and idiomatic asynchronous code
- are over a thousand times lighter than threads
- are leak-free under Nim's ARC memory management
- may be based upon your own custom `ref object`
- may be dispatched using your own custom dispatcher
- may be moved between threads to parallelize execution
- require no `{.gcsafe.}` for global/local accesses
- are only 10-15% slower than Nim's native iterators
- are faster and lighter than async/await futures

## Work In Progress

The macro itself should be considered alpha quality. It is expected to
fail frequently, but it is in a state where we can begin to add tests and
refinement.

The included dispatcher is based upon
[selectors](https://nim-lang.org/docs/selectors.html), so you can see how the
features of that module will map quite easily to the following list.

Windows is not supported by the included dispatcher yet due to the lack of
native timer support in `selectors`, but [an ioselectors package that supports
Windows](https://github.com/xflywind/ioselectors) is in an advanced stage of
development.

## Usage

The provided `selectors`-based event queue is imported as `cps/eventqueue`. The
`cps` macro will use whatever return value you specify to determine the type of
your continuations.

```nim
# all cps programs need the cps macro to perform the transformation
import cps

# but each usage of the .cps. macro can have its own dispatcher
# implementation and continuation type, allowing you to implement
# custom forms of async or using an existing library implementation
from cps/eventqueue import sleep, run, spawn, trampoline, Cont

# a procedure that starts off synchronous and becomes asynchronous
proc tock(name: string; ms: int) {.cps: Cont.} =
  ## echo the `name` at `ms` millisecond intervals, ten times

  # a recent change to cps allows us to use type inference
  var count = 10
  # `for` loops are not supported yet
  while count > 0:
    dec count
    # the dispatcher supplied this primitive which receives the
    # continuation and returns control to the caller immediately
    sleep ms
    # subsequent control-flow is continues from the dispatcher
    # when it elects to resume the continuation
    echo name, " ", count

# NOTE: all the subsequent code is supplied by the chosen dispatcher

# the trampoline repeatedly invokes continuations until they
# complete or are queued in the dispatcher; this call does not block
trampoline tock("tick", ms = 300)

# you can also send a continuation directly to the dispatcher;
# this call does not block
spawn tock("tock", ms = 700)

# run the dispatcher to invoke its pending continuations from the queue;
# this is a blocking call that completes when the queue is empty
run()
```
...is rewritten during compilation to something like...

```nim
import cps
from cps/eventqueue import sleep, run, spawn, trampoline, Cont

type
  env_33554698 = ref object of Cont
    name_33554715: string
    ms_33554724: int
    count_33555007: int

proc loop_33555024(continuation: Cont): Cont
proc after_33555046(continuation: Cont): Cont

proc loop_33555024(continuation: Cont): Cont =
  if 0 < env_33554698(continuation).count_33555007:
    dec env_33554698(continuation).count_33555007
    continuation.fn = after_33555046
    return sleep continuation, env_33554698(continuation).ms_33554724

proc after_33555046(continuation: Cont): Cont =
  echo env_33554698(continuation).name_33554715, " ",
       env_33554698(continuation).count_33555007
  continuation.fn = loop_33555024
  return continuation

proc tock(continuation: Cont): Cont =
  env_33554698(continuation).count_33555007 = 10
  continuation.fn = loop_33555024
  return continuation

proc tock(name: string; ms: int): Cont =
  result = env_33554698(fn: tock, ms_33554724: ms, name_33554715: name)

trampoline tock("tick", ms = 300)

spawn tock("tock", ms = 700)

run()
```
...and when built with `--define:cpsDebug`, outputs something like...

![tick-tock demonstration](docs/demo.svg "tick-tock demonstration")

## Hacking

- use `--define:cpsDebug` to get extra debugging output
- use `--define:cpsTrace` to get continuation tracing from the trampoline
- use `--define:cpsCast` to `cast` continuations (versus type conversion)
- use `--define:cpsTree` to dump AST via `treeRepr` in `cpsDebug` mode
- use `--define:cpsExcept` catch exceptions and stash them in the continuation
- use `--define:cpsMutant` toggle mutating continuations (default: _off_)

## Documentation

See [the documentation for the cps module](https://disruptek.github.io/cps/cps.html) as generated directly from the source.
You can also jump to [the documentation for the included dispatcher](https://disruptek.github.io/cps/cps/eventqueue.html).

## Tests

The tests provide the best examples of usage and are a great starting point for
your experiments.

Here are some tests that Zevv prepared:

![zevv tests](docs/tzevv.svg "zevv tests")

Here are the simpler tests of AST rewrites:

![taste tests](docs/taste.svg "taste tests")

## License
MIT
