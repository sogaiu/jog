#! /usr/bin/env janet

(import ./args :prefix "")
(import ./report :prefix "")

(def usage
  ``
  Usage: jog [<patt>] <file-or-dir>...
         jog [-h|--help]

  View Janet project docstrings from the command line.

  Parameters:

    <patt>                 string to query with
    <file-or-dir>          path to file or directory

  Options:

    -h, --help                   show this output

  Examples:

    Show docstring(s) of `zip` in `jeat/zipper.janet`:

    $ jog zip jeat/zipper.janet

    Show docstring(s) of `zipper` under `./`:

    $ jog zipper .

    Show all docstring(s) under `./`:

    $ jog .
  ``)

(defn main
  [_ & args]
  (def opts (a/parse-args args))
  #
  (def {:rest the-args} opts)
  #
  (def arg (get the-args 0))
  #
  (def root-bindings (all-bindings root-env))
  #
  (cond
    (get opts :help)
    (print usage)
    # enumerate docs for files and/or directories
    (get opts :enum-docs)
    (let [results (r/do-all-docs opts)]
      (when (not results)
        (print r/not-found-message)))
    # base results on files and/or directories searching
    (get opts :paths-search)
    (let [results (r/do-doc-of opts)]
      (when (not results)
        (print r/not-found-message)))
    # XXX: don't expect to get here
    (errorf "bug somewhere: args: %n opts: %n" args opts)))

