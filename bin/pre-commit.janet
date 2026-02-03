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

(print `* trying some "raw" invocations...`)

# sourced from jakl -h output
(def expectations
  ['[5 [./jog zipper .]]
   '[1 [./jog data]]
   '[2 [./jog zip src/jipper.janet]]])

(each [n cmd] expectations
  (def new-cmd
    [(first cmd) "{:dump true}" ;(drop 1 cmd)])
  (def output ($< ;new-cmd))
  (def results (parse output))
  (def len (length results))
  (if (= n len)
    (printf "got all %d expected result(s) for: %n" n new-cmd)
    (do
      (eprintf "expected %d result(s) but got %d for: %n"
               n len new-cmd)
      (os/exit 1))))

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

