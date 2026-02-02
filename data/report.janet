(import ./find :as f)

(defn massage-param-str
  [in-str]
  (peg/replace-all ~(some (choice " " "\r" "\n"))
                   " " in-str))

(comment

  (massage-param-str
    (string "root &keys {:branch? branch?\n"
            "    :children children\n"
            "        :make-node make-node}"))
  # =>
  (buffer "root &keys {:branch? branch? "
          ":children children "
          ":make-node make-node}")

  )

(def janet-indent
  "Default indentation that the built-in `doc-format` uses."
  4)

# XXX: this only works for no indentation
(def indent-ws "")

(defn dedent
  [region &opt amount]
  (default amount janet-indent)
  (def d-lines
    (->> (string/split "\n" region)
         (map |(if (<= amount (length $))
                 (string/slice $ amount)
                 $))))
  (string/join d-lines "\n"))

(comment

  (dedent (string "    line one\n"
                  "    line two\n"
                  "    line three")
          4)
  # =>
  (string "line one\n"
          "line two\n"
          "line three")

  )

(defn make-line-1
  [def-type]
  (def key (symbol def-type))
  (cond
    (get f/special-definers key)
    (string/format "%svalue (%s)" indent-ws def-type)
    #
    (get f/func-definers key)
    (string/format "%sfunction (%s)" indent-ws def-type)
    #
    (get f/macro-definers key)
    (string/format "%smacro (%s)" indent-ws def-type)
    #
    (= "defdyn" def-type)
    (string/format "%sdynamic variable" indent-ws)
    #
    (errorf "unknown def-type: %n" def-type)))

(defn report
  [all-results]
  (print)
  (each r all-results
    (def {:path path :bl line-no :bc col-no
          :def-type def-type :text pre-str
          :params-str params-str} r)
    (def line-1 (make-line-1 def-type))
    (def line-2 (string/format "%s%s on line %d, column %d"
                               indent-ws path line-no col-no))
    (def name (cond
                (def found-name (get r :found-name))
                found-name
                #
                (def name (get r :name))
                name
                #
                name))
    (def usage
      (if-not (get r :params-str)
        name
        (let [# ensure string is one line
              line-str (massage-param-str params-str)
              # drop surrounding delimiters
              inner-str (string/slice line-str 1 -2)]
          (string/format "(%s %s)" name inner-str))))
    (def leading-ws (string/repeat " " (dec col-no)))
    (def doc-str
      (string/format "%s\n\n%s" usage
                     # sometimes long-string dedenting is needed, so
                     # prepend proper amount of whitespace
                     (parse (string leading-ws pre-str))))
    (def bottom
      (string/format "%s%s"
                     indent-ws
                     (-> (doc-format doc-str)
                         (string/trim "\n")
                         dedent
                         # leading newline removal
                         (string/trim "\n"))))
    (def fmt (string "%s\n"
                     "%s\n"
                     "\n"
                     "%s\n"))
    (printf fmt line-1 line-2 bottom)
    # XXX: 72 = 80 - 8 (from janet's `boot.janet`)
    (def width (- (- (dyn :doc-width 80) 8)
                  janet-indent))
    (printf (string/repeat "-" width))
    (print))
  #
  all-results)

(def not-found-message "Nothing found")

