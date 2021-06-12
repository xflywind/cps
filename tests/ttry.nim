import balls
import cps

include preamble

suite "try statements":

  var r = 0

  block:
    ## try-except statements may be split across continuations
    r = 0
    proc foo() {.cps: Cont.} =
      inc r
      try:
        noop()
        inc r
      except:
        fail "this branch should not run"
      inc r

    trampoline whelp(foo())
    check r == 3

  block:
    ## try-except statements may split and also raise exceptions
    r = 0
    proc foo() {.cps: Cont.} =
      inc r
      try:
        noop()
        inc r
        raise newException(CatchableError, "test")
        fail "statement run after raise"
      except:
        check getCurrentExceptionMsg() == "test"
        inc r
      inc r

    trampoline whelp(foo())
    check r == 4

  block:
    ## exception clauses may split across continuations
    r = 0
    proc foo() {.cps: Cont.} =
      inc r
      try:
        noop()
        inc r
        raise newException(CatchableError, "test")
        fail "statement run after raise"
      except:
        inc r
        noop()
        check getCurrentExceptionMsg() == "test"
        inc r
      inc r

    trampoline whelp(foo())
    check r == 5

  block:
    ## exceptions raised in the current continuation work
    r = 0
    proc foo() {.cps: Cont.} =
      inc r
      try:
        inc r
        raise newException(CatchableError, "test")
        fail "statement run after raise"
      except:
        inc r
        noop()
        check getCurrentExceptionMsg() == "test"
        inc r
      inc r

    trampoline whelp(foo())
    check r == 5

  block:
    ## try statements with a finally clause
    skip "not working, see #78":
      r = 0
      proc foo() {.cps: Cont.} =
        inc r
        try:
          noop()
          inc r
        finally:
          inc r

      trampoline whelp(foo())
      check r == 3

  block:
    ## try statements with a finally and a return
    skip "not working, see #78":
      r = 0
      proc foo() {.cps: Cont.} =
        inc r
        try:
          noop()
          inc r
          return
        finally:
          inc r

      trampoline whelp(foo())
      check r == 3

  block:
    ## try statements with an exception and a finally
    skip "not working, see #78":
      r = 0
      proc foo() {.cps: Cont.} =
        inc r
        try:
          noop()
          inc r
          raise newException(CatchableError, "")
          fail "statement run after raise"
        except:
          inc r
        finally:
          inc r
        inc r

      trampoline whelp(foo())
      check r == 5

  block:
    ## nested try statements within the except branch
    r = 0
    proc foo() {.cps: Cont.} =
      inc r
      try:
        noop()
        inc r
        raise newException(CatchableError, "test")
        fail "statement run after raise"
      except:
        check getCurrentExceptionMsg() == "test"
        inc r

        try:
          noop()
          inc r
          raise newException(CatchableError, "test 2")
          fail "statement run after raise"
        except:
          check getCurrentExceptionMsg() == "test 2"
          inc r

        check getCurrentExceptionMsg() == "test"
        inc r

      inc r

    trampoline whelp(foo())
    check r == 7
