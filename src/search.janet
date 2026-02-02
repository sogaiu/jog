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

