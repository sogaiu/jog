(import ./args :prefix "")
(import ./commands :prefix "")

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

    Show docstring(s) of `zip` in `src/jipper.janet`:

    $ jog zip src/jipper.janet

    Show docstring(s) of `zipper` under `./`:

    $ jog zipper .

    Show all docstring(s) under `data/`:

    $ jog data
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
    (let [results (c/do-all-docs opts)]
      (when (and (not results) (not (get opts :dump)))
        (print "Nothing found")))
    # base results on files and/or directories searching
    (get opts :paths-search)
    (let [results (c/do-doc-of opts)]
      (when (and (not results) (not (get opts :dump)))
        (print "Nothing found")))
    # XXX: don't expect to get here
    (errorf "bug somewhere: args: %n opts: %n" args opts)))

