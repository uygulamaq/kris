(import ./util)
(import ./compile :as c)

(def target-list
  (do
    (def targets (sort (keys c/target-map)))
    (def last-t (array/pop targets))
    (string (string/join targets ", ") " and " last-t)))

(def config
  ```
  The configuration for the quickbin subcommand
  ```
  {:rules [:script {:help "The Janet script with a main function."
                    :req? true}
          :exe {:help "The name of the executable to create."
                :req? true}
          "--target"  {:kind    :single
                       :short   "t"
                       :default "native"
                       :help    (string "The target platform. Valid targets are "
                                        target-list ".")}
          "--version" {:kind    :single
                       :short   "v"
                       :default "latest"
                       :help    "The Janet version to use for the runtime."}
          "--small"   {:kind    :flag
                       :short   "s"
                       :help    "Optimise for smallest binary size."}
          "-------------------------------------------"]
   :short "q"
   :info {:about "Cross-compiles a standalone executable from a Janet script."}
   :help "Cross-compile a standalone executable."})

(defn run
  [args]
  (def params (args :params))
  (def opts (args :opts))
  (def script (params :script))
  (def exe (params :exe))
  (def target (opts "target"))
  (def version (opts "version"))
  (def small? (opts "small"))
  (def zig-target (get c/target-map target))
  (unless zig-target
    (eprintf (string "kris: invalid target %s\n"
                     "Try 'kris --help' for more information.")
             target target-list)
    (os/exit 1))
  (unless (= :file (os/stat script :mode))
    (eprintf (string "kris: script %s not found\n"
                     "Try 'kris --help' for more information.")
             script)
    (os/exit 1))
  (print "creating executable '" exe "' from '" script "' for " zig-target "...")
  (def source-dir (c/download-janet version))
  (def bootstrap (c/build-bootstrap source-dir))
  (def build-c-dir (c/generate-amalgamation source-dir bootstrap))
  (def libjanet-path (c/build-libjanet source-dir build-c-dir target small?))
  (def bytecode (c/marshal-script script))
  (def embedding-c (c/create-embedding-c bytecode))
  (c/compile-quickbin source-dir libjanet-path embedding-c target exe small?)
  (print "Compilation completed."))
