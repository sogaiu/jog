(defn v/path-join
  [& parts]
  (def sep
    (if-let [sep (dyn :path-fs-sep)]
      sep
      (if (let [osw (os/which)]
            (or (= :windows osw) (= :mingw osw)))
        `\`
        "/")))
  #
  (string/join parts sep))

(comment

  (let [sep (dyn :path-fs-sep)]
    (defer (setdyn :path-fs-sep sep)
      (setdyn :path-fs-sep "/")
      (v/path-join "/tmp" "test.txt")))
  # =>
  "/tmp/test.txt"

  (let [sep (dyn :path-fs-sep)]
    (defer (setdyn :path-fs-sep sep)
      (setdyn :path-fs-sep "/")
      (v/path-join "/tmp" "foo" "test.txt")))
  # =>
  "/tmp/foo/test.txt"

  (let [sep (dyn :path-fs-sep)]
    (defer (setdyn :path-fs-sep sep)
      (setdyn :path-fs-sep `\`)
      (v/path-join "C:" "windows" "system32")))
  # =>
  `C:\windows\system32`

  )

(defn v/make-visitor
  [& paths]
  (def todo-paths (reverse paths)) # pop used to process from end
  (def seen? @{})
  #
  (coro
    (while (def p (array/pop todo-paths))
      (def [ok? value] (protect (os/realpath p)))
      (when (and ok? (not (get seen? value)))
        (put seen? value true)
        (yield p)
        (when (= :directory (os/stat p :mode))
          (each subp (reverse (os/dir p))
            (array/push todo-paths (v/path-join p subp))))))))

(comment

  (def v (v/make-visitor (dyn :syspath) "/etc/fonts"))

  (each p v (pp p))

  )

(defn v/visit
  [& paths]
  (def v (v/make-visitor ;paths))
  #
  (seq [p :in v] p))

(comment

  (v/visit (v/path-join (os/getenv "HOME") ".config"))

  )

