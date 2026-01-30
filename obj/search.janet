(def s/sep
  (let [os (os/which)]
    (if (or (= :windows os) (= :mingw os)) `\` "/")))

(defn s/find-files
  [dir &opt pred skips]
  (default pred identity)
  (default skips (invert [".git"]))
  (def paths @[])
  (defn helper
    [a-dir]
    (each path (os/dir a-dir)
      (def sub-path (string a-dir s/sep path))
      (case (os/stat sub-path :mode)
        :directory
        (when (not (get skips path))
          (helper sub-path))
        #
        :file
        (when (pred sub-path)
          (array/push paths sub-path)))))
  #
  (helper dir)
  #
  paths)

(comment

  (s/find-files "." |(string/has-suffix? ".janet" $))

  )

(defn s/clean-end-of-path
  [path a-sep]
  (when (= 1 (length path))
    (break path))
  #
  (if (string/has-suffix? a-sep path)
    (string/slice path 0 -2)
    path))

(comment

  (s/clean-end-of-path "hello/" "/")
  # =>
  "hello"

  (s/clean-end-of-path "/" "/")
  # =>
  "/"

  )

(defn s/collect-paths
  [includes &opt pred]
  (default pred identity)
  (def filepaths @[])
  # collect file and directory paths
  (each thing includes
    (def apath (s/clean-end-of-path thing s/sep))
    (def mode (os/stat apath :mode))
    # XXX: should :link be supported?
    (cond
      (= :file mode)
      (array/push filepaths apath)
      #
      (= :directory mode)
      (array/concat filepaths (s/find-files apath pred))
      #
      (errorf "Expected file or dir but found %n for: %s" mode apath)))
  #
  filepaths)

# query-fn should return a dictionary
(defn s/search-paths
  [paths query-fn opts &opt pattern]
  #
  (def all-results @[])
  (def hit-paths @[])
  (each p paths
    (def src (slurp p))
    (when (< 0 (length src))
      (when (or (not pattern) (string/find pattern src))
        (array/push hit-paths p)
        (def results
          (try (query-fn src opts)
            ([e] (eprintf "search failed for: %s" p))))
        (when (and results (not (empty? results)))
          (each item results
            (array/push all-results (merge item {:path p})))))))
  #
  [all-results hit-paths])

