(defn has-janet-shebang?
  [path]
  (with [f (file/open path)]
    (def first-line (file/read f :line))
    (when first-line
      # some .js files has very long first lines and can contain
      # a lot of strings...
      (and (string/find "bin/env" first-line)
           (string/find "janet" first-line)))))

(defn looks-like-janet?
  [path]
  (or (string/has-suffix? ".janet" path)
      (has-janet-shebang? path)))

