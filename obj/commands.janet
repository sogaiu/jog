(import ./empathy :prefix "")
(import ./find :prefix "")
(import ./report :prefix "")
(import ./search :prefix "")
(import ./utils :prefix "")

########################################################################

(defn c/search-and-dump
  [opts]
  (def {:paths paths :query-fn query-fn :pattern pattern} opts)
  #
  (def [all-results _]
    (s/search-paths paths query-fn opts pattern))
  # output could be done via (printf "%j" all-results), but the
  # resulting output is harder to read and manipulate
  (print "[")
  (when (not (empty? all-results))
    (each r all-results
      (printf "[%n %n %n %n %n %n %n]"
              (get r :path) (get r :bl) (get r :bc)
              (get r :def-type) (get r :name) (get r :params-str)
              (get r :text))))
  (print "]\n"))

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
            (em/itemize ;includes)))
  #
  (when (get opts :dump)
    (c/search-and-dump {:query-fn f/find-docs
                      :paths src-filepaths})
    (break))
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
            (em/itemize ;includes)))
  #
  (when (get opts :dump)
    (c/search-and-dump {:query-fn f/find-doc-of
                      :paths src-filepaths
                      :pattern name})
    (break))
  #
  (c/search-and-report {:query-fn f/find-doc-of :paths src-filepaths
                      :pattern name}))

