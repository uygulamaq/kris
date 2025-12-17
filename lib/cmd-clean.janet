(import ./compile :as c)
(import ./util)

(def config
  ```
  The configuration for the clean subcommand
  ```
  {:rules []
   :short "c"
   :info {:about "Deletes the kris cache directory."}
   :help "Delete the kris cache directory."})

(defn run
  [args]
  (def cache-dir (c/get-cache-dir))
  (if (= :directory (os/stat cache-dir :mode))
    (do
      (print "removing cache directory: " cache-dir)
      (util/rmrf cache-dir)
      (print "Cache cleaned."))
    (print "cache directory does not exist: " cache-dir)))
