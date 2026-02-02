(import ./find :prefix "")
(import ./itemize :prefix "")
(import ./report :prefix "")
(import ./search :prefix "")
(import ./utils :prefix "")

(defn c/search-and-report
  [opts]
  (def {:paths paths :query-fn query-fn :pattern pattern} opts)
  #
  (def [all-results _] (s/search-paths paths query-fn opts pattern))
  (when (zero? (length all-results))
    (break false))
  #
  (r/report all-results))

########################################################################

(defn c/do-all-docs
  [opts]
  (def {:rest the-args} opts)
  #
  (def includes the-args)
  # find .janet files
  (def src-filepaths
    (filter |(and (= :file (os/stat $ :mode))
                  (u/looks-like-janet? $))
            (i/itemize ;includes)))
  #
  (c/search-and-report {:query-fn f/find-docs :paths src-filepaths}))

(defn c/do-doc-of
  [opts]
  (def {:rest the-args} opts)
  #
  (def name (get the-args 0))
  (array/remove the-args 0)
  #
  (def includes the-args)
  # find .janet files
  (def src-filepaths
    (filter |(and (= :file (os/stat $ :mode))
                  (u/looks-like-janet? $))
            (i/itemize ;includes)))
  #
  (c/search-and-report {:query-fn f/find-doc-of :paths src-filepaths
                      :pattern name}))

