#! /usr/bin/env janet

(use ./sh-dsl)

########################################################################

(prin "* running jell...") (flush)
(def jell-exit ($ janet ./bin/jell))
(assertf (zero? jell-exit)
         "jell exited: %d" jell-exit)
(print "done")

########################################################################

(print "* running niche...")
(def niche-exit ($ janet ./bin/niche.janet))
(assertf (zero? niche-exit)
         "niche exited: %d" niche-exit)
(print "done")

########################################################################

(print "* updating README...")
(def readme-update-ext ($ janet jog -h > README))
(assertf (zero? readme-update-ext)
         "updating README exited: %d" readme-update-ext)
(print "done")

########################################################################

(print "* trying some invocations...")

# sourced from jog -h output
(def invocations
  ['[./jog zipper .]
   '[./jog data]
   '[./jog zip src/jipper.janet]])

(each cmd invocations
  (def exit-code ($ ;cmd))
  (if (= 0 exit-code)
    (printf "%n exited: %d" cmd exit-code)
    (do
      (eprintf "%n returned non-zero exit code: %d" cmd exit-code)
      (os/exit 1))))

(print "done")

