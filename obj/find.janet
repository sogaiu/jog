(import ./jipper :prefix "")

# XXX: doesn't handle atypical code that uses ordinary tuples for
#      parameter lists
(defn f/find-caller-docstring
  [zloc]
  (var cur-zloc zloc)
  (var ret nil)
  (set cur-zloc (j/right-until cur-zloc |(match (j/node $)
                                           [:bracket-tuple]
                                           $)))
  (when cur-zloc
    (def params-node (j/node cur-zloc))
    (while (def left-zloc (j/left cur-zloc))
      (set cur-zloc left-zloc)
      (when-let [[node-type {:bl bl :bc bc} node-value]
                 (j/node left-zloc)]
        (when (get {:string 1 :long-string 1} node-type)
          (set ret @{:bl bl :bc bc :text node-value
                     :params-str (j/gen params-node)})
          (break))))
    #
    ret))

# XXX: only called when parsed parent has length = 3
(defn f/find-defdyn-docstring
  [zloc]
  (var cur-zloc zloc)
  (var ret nil)
  # start at the rightmost end
  (set cur-zloc (j/rightmost cur-zloc))
  (when cur-zloc
    (while cur-zloc
      (when-let [[node-type {:bl bl :bc bc} node-value]
                 (j/node cur-zloc)]
        (when (get {:string 1 :long-string 1} node-type)
          (set ret @{:bl bl :bc bc :text node-value})
          (break)))
      #
      (set cur-zloc (j/left cur-zloc)))
    #
    ret))

# XXX: only called when parsed parent has length >= 4
(defn f/find-special-docstring
  [zloc]
  (var cur-zloc zloc)
  (var ret nil)
  # start at the rightmost end
  (set cur-zloc (j/rightmost cur-zloc))
  (when cur-zloc
    # cannot be the rightmost node
    (while (def left-zloc (j/left cur-zloc))
      (when-let [[node-type {:bl bl :bc bc} node-value]
                 (j/node left-zloc)]
        (when (get {:string 1 :long-string 1} node-type)
          (set ret @{:bl bl :bc bc :text node-value})
          (break)))
      #
      (set cur-zloc left-zloc))
    #
    ret))

# XXX: if the keys were strings then other code would need to
#      change...
(def f/func-definers
  {'defn 1 'defn- 1})

(def f/macro-definers
  {'defmacro 1 'defmacro- 1})

(def f/call-definers
  (merge f/func-definers f/macro-definers))

(def f/special-definers
  {'def 1 'def- 1
   'var 1 'var- 1})

(defn f/find-doc-of
  [src opts]
  (def {:pattern name} opts)
  #
  (def tree (j/par src))
  (var cur-zloc (j/zip-down tree))
  (def results @[])
  #
  (while (def next-zloc
           (j/search-from cur-zloc
                          |(match (j/node $)
                             [:symbol _ sym]
                             (when (string/has-suffix? name sym)
                               $))))
    (def parent-zloc (j/up next-zloc))
    (when (= :tuple (get (j/node parent-zloc) 0))
      (def node (j/node parent-zloc))
      (def raw-code-str (j/gen node))
      (def parsed
        (try
          (parse raw-code-str)
          ([e]
            (eprintf "failed to parse: %s" raw-code-str))))
      (when parsed
        (def found-name (string (get parsed 1)))
        (when (string/has-suffix? name found-name)
          (def head (first parsed))
          (cond
            (and (get f/special-definers head)
                 (<= 4 (length parsed))) # metadata possible
            (when-let [ds-tbl (f/find-special-docstring (j/down parent-zloc))]
              (array/push results
                          (merge ds-tbl {:def-type (string head)
                                         :found-name found-name})))
            #
            (get f/call-definers head)
            (when-let [ds-tbl (f/find-caller-docstring (j/down parent-zloc))]
              (array/push results
                          (merge ds-tbl {:def-type (string head)
                                         :found-name found-name})))
            #
            (and (= 'defdyn head) (= 3 (length parsed)))
            (when-let [ds-tbl (f/find-defdyn-docstring (j/down parent-zloc))]
              (array/push results
                          (merge ds-tbl {:def-type (string head)
                                         :found-name found-name})))
            # XXX: other cases?
            nil))))
    #
    (set cur-zloc (j/df-next next-zloc)))
  #
  results)

(comment

  (f/find-doc-of
    ``
    (defn smile
      "I am a defn docstring."
      [y]
      (pp y))

    (defn- smile
      "I am a defn- docstring."
      [z]
      (pp [:z z]))
    ``
    {:pattern "smile"})
  # =>
  @[@{:bc 3 :bl 2
      :def-type "defn"
      :found-name "smile"
      :text `"I am a defn docstring."`
      :params-str "[y]"}
    @{:bc 3 :bl 7
      :def-type "defn-"
      :found-name "smile"
      :text `"I am a defn- docstring."`
      :params-str "[z]"}]

  (f/find-doc-of
    ``
    (var smile "a docstring" {:a 2})

    (var- smile "woohoo" "hello")
    ``
    {:pattern "smile"})
  # =>
  @[@{:bc 12 :bl 1
      :def-type "var"
      :found-name "smile"
      :text `"a docstring"`}
    @{:bc 13 :bl 3
      :def-type "var-"
      :found-name "smile"
      :text `"woohoo"`}]

  (f/find-doc-of
    ``
    (defdyn *smile*)

    (defdyn *smile* "smiling docstring")
    ``
    {:pattern "*smile*"})
  # =>
  @[@{:bc 17 :bl 3
      :def-type "defdyn"
      :found-name "*smile*"
      :text `"smiling docstring"`}]

  (f/find-doc-of
    ```
    (defmacro as-macro
      ``Use a function or macro literal `f` as a macro. This lets
      any function be used as a macro. Inside a quasiquote, the
      idiom `(as-macro ,my-custom-macro arg1 arg2...)` can be used
      to avoid unwanted variable capture of `my-custom-macro`.``
      [f & args]
      (f ;args))
    ```
    {:pattern "as-macro"})

  # =>
  @[@{:bc 3 :bl 2
      :def-type "defmacro"
      :found-name "as-macro"
      :text
      (string
        "``Use a function or macro literal `f` as a macro. This lets\n"
        "  any function be used as a macro. Inside a quasiquote, the\n"
        "  idiom `(as-macro ,my-custom-macro arg1 arg2...)` can be used\n"
        "  to avoid unwanted variable capture of `my-custom-macro`.``")
      :params-str "[f & args]"}]

  (f/find-doc-of
    ``
    (def smile "a docstring" 1)

    (defn smile
      "I am a docstring."
      [y]
      (pp y))
    ``
    {:pattern "smile"})
  # =>
  @[@{:bc 12 :bl 1
      :def-type "def"
      :found-name "smile"
      :text `"a docstring"`}
    @{:bc 3 :bl 4
      :def-type "defn"
      :found-name "smile"
      :text `"I am a docstring."`
      :params-str "[y]"}]

  )

(defn f/find-docs
  [src &opt opts]
  (default opts {})
  (def {:pred pred} opts)
  #
  (def tree (j/par src))
  (var cur-zloc (j/zip-down tree))
  (def results @[])
  #
  (while (def next-zloc
           (j/search-from cur-zloc
                          |(match (j/node $)
                             [:tuple]
                             $)))
    (def node (j/node next-zloc))
    (def raw-code-str (j/gen node))
    (def parsed
      (try
        (parse raw-code-str)
        ([e]
          (eprintf "failed to parse: %s" raw-code-str))))
    (when (and parsed
               (if-not pred true (pred parsed)))
      (when-let [head (first parsed)]
        (when (symbol? head)
          (def name (string (get parsed 1)))
          (cond
            (and (get f/special-definers head)
                 (<= 4 (length parsed))) # metadata possible
            (when-let [ds-tbl (f/find-special-docstring (j/down next-zloc))]
              (array/push results
                          (merge ds-tbl {:def-type (string head)
                                         :name name})))
            #
            (get f/call-definers head)
            (when-let [ds-tbl (f/find-caller-docstring (j/down next-zloc))]
              (array/push results
                          (merge ds-tbl {:def-type (string head)
                                         :name name})))
            #
            (and (= 'defdyn head) (= 3 (length parsed)))
            (when-let [ds-tbl (f/find-defdyn-docstring (j/down next-zloc))]
              (array/push results
                          (merge ds-tbl {:def-type (string head)
                                         :name name})))
            # XXX: other cases?
            nil))))
    #
    (set cur-zloc (j/df-next next-zloc)))
  #
  results)

(comment

  (f/find-docs
    ``
    (defn smile
      "I am a defn docstring."
      [y]
      (pp y))

    (defn- smile
      "I am a defn- docstring."
      [z]
      (pp [:z z]))
    ``)
  # =>
  @[@{:bc 3 :bl 2
      :def-type "defn"
      :name "smile"
      :text `"I am a defn docstring."`
      :params-str "[y]"}
    @{:bc 3 :bl 7
      :def-type "defn-"
      :name "smile"
      :text `"I am a defn- docstring."`
      :params-str "[z]"}]

  (f/find-docs
    ``
    (var smile "a docstring" {:a 2})

    (var- smile "woohoo" "hello")
    ``)
  # =>
  @[@{:bc 12 :bl 1
      :def-type "var"
      :name "smile"
      :text `"a docstring"`}
    @{:bc 13 :bl 3
      :def-type "var-"
      :name "smile"
      :text `"woohoo"`}]

  (f/find-docs
    ``
    (defdyn *smile*)

    (defdyn *smile* "smiling docstring")
    ``)
  # =>
  @[@{:bc 17 :bl 3
      :def-type "defdyn"
      :name "*smile*"
      :text `"smiling docstring"`}]

  (f/find-docs
    ```
    (defmacro as-macro
      ``Use a function or macro literal `f` as a macro. This lets
      any function be used as a macro. Inside a quasiquote, the
      idiom `(as-macro ,my-custom-macro arg1 arg2...)` can be used
      to avoid unwanted variable capture of `my-custom-macro`.``
      [f & args]
      (f ;args))
    ```)
  # =>
  @[@{:bc 3 :bl 2
      :def-type "defmacro"
      :name "as-macro"
      :text
      (string
        "``Use a function or macro literal `f` as a macro. This lets\n"
        "  any function be used as a macro. Inside a quasiquote, the\n"
        "  idiom `(as-macro ,my-custom-macro arg1 arg2...)` can be used\n"
        "  to avoid unwanted variable capture of `my-custom-macro`.``")
      :params-str "[f & args]"}]

  (f/find-docs
    ``
    (def smile "a docstring" 1)

    (defn smile
      "I am a docstring."
      [y]
      (pp y))
    ``)
  # =>
  @[@{:bc 12 :bl 1
      :def-type "def"
      :name "smile"
      :text `"a docstring"`}
    @{:bc 3 :bl 4
      :def-type "defn"
      :name "smile"
      :text `"I am a docstring."`
      :params-str "[y]"}]

  )

