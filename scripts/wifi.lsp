#!/usr/bin/env newlisp

(module "getopts.lsp")

(load "src/argparse.lsp")

;;;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
;;; Constants
;;;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>

(setq prog-name "Wifi wrapper")
(setq version "1.2.0")
(setq release-year "2016")
(setq version-string
  (format "%s, version %s (%s)" prog-name version release-year))

;;;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
;;; Error functions
;;;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>

(define (display-unknown-cmd cmd script)
  (println (format "\nERROR: Unknown command '%s'." cmd))
  (usage script))

(define (display-missing-subcmd cmd subcmd script)
  (println (format "\nERROR: Command '%s' is missing required subcommand."
                   cmd)))

(define (display-unknown-subcmd cmd subcmd script)
  (println (format "\nERROR: Unknown subcommand '%s' for command '%s'."
                   subcmd cmd)))

;;;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
;;; Supporting functions
;;;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>

(define (display-access-points)
  (! "nmcli device wifi list"))

(define (join-access-point cmd-args)
  (if (= cmd-args '())
    (begin
      (display-missing-subcmd "join")
      (usage script)))
  (let ((ssid (first cmd-args))
        (cmd-args (rest cmd-args)))
    (println (format "Connecting to SSID %s ..." ssid))
    (if (= cmd-args '())
      (! (string "nmcli device wifi connect " ssid))
      (! (format "nmcli device wifi connect \"%s\" password %s"
                 ssid
                 (first cmd-args))))))

;;;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
;;; Set up and parse options
;;;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>

(define (usage script)
  (letn ((base-template "%s %-20s\t%s")
         (short-opt-template (append "\t -" base-template))
         (long-opt-template (append "\t--" base-template))
         (cmd-template (append "\t  " base-template)))
    (println)
    (println version-string)
    (println)
    (println
      (format "Usage: %s [options|command] [command options]" script))
    (println)
    (println "Options:")
    (dolist
      (o getopts:short)
      (println (format short-opt-template (o 0) "" (o 1 2))))
    (dolist
      (o getopts:long)
      (println (format long-opt-template (o 0) "" (o 1 2))))
    (println)
    (println "Commands:")
    (println
      (format cmd-template
              "scan"
              ""
              "Display a list of nearby access points"))
    (println
      (format cmd-template
              "join"
              "<SSID> <password>"
              "Join the access point with given password"))
    (exit)))

(shortopt "v" (getopts:die version-string) nil "Print version string")
(shortopt "h" (usage (argparse:get-script)) nil "Print this help message")
(longopt "help" (usage (argparse:get-script)) nil "Print this help message")

(new Tree 'parsed)
(parsed (argparse))

;;;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
;;; Entry point
;;;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>

(define (main script opts)
  (cond
    ((empty? opts)
      (println)
      (println "ERROR: either an option or a command must be provided.")
      (usage script)))
  (let ((cmd (first opts))
        (cmd-args (rest opts)))
    (case cmd
      ("scan" (display-access-points))
      ("join" (join-access-point cmd-args))
      (true (display-unknown-cmd cmd script))))
  (exit))

;;;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
;;; Run the program
;;;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>

(main (parsed "script")
      (parsed "opts"))
