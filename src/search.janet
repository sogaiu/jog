(def sep
  (let [os (os/which)]
    (if (or (= :windows os) (= :mingw os)) `\` "/")))

(defn find-files
  [dir &opt pred skips]
  (default pred identity)
  (default skips (invert [".git"]))
  (def paths @[])
  (defn helper
    [a-dir]
    (each path (os/dir a-dir)
      (def sub-path (string a-dir sep path))
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

  (find-files "." |(string/has-suffix? ".janet" $))

  )

(defn clean-end-of-path
  [path a-sep]
  (when (= 1 (length path))
    (break path))
  #
  (if (string/has-suffix? a-sep path)
    (string/slice path 0 -2)
    path))

(comment

  (clean-end-of-path "hello/" "/")
  # =>
  "hello"

  (clean-end-of-path "/" "/")
  # =>
  "/"

  )

(defn collect-paths
  [includes &opt pred]
  (default pred identity)
  (def filepaths @[])
  # collect file and directory paths
  (each thing includes
    (def apath (clean-end-of-path thing sep))
    (def mode (os/stat apath :mode))
    # XXX: should :link be supported?
    (cond
      (= :file mode)
      (array/push filepaths apath)
      #
      (= :directory mode)
      (array/concat filepaths (find-files apath pred))
      #
      (errorf "Expected file or dir but found %n for: %s" mode apath)))
  #
  filepaths)

# query-fn should return a dictionary
(defn search-paths
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

