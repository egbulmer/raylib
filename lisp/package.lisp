;; NOTE: 2025-07-05 Happy Birthday!
;;
;; Remember, if you're having issues loading this under ECL, load it via the
;; form found in `repl.lisp', not via automated system loading through Sly! The
;; linker flags need to be set properly before this can be loaded, even when
;; doing REPL developement.

(defpackage raylib
  (:use :cl #+sbcl :sb-alien)
  (:local-nicknames (#:tg #:trivial-garbage))
  ;; --- Types --- ;;
  (:export #:vector2 #:make-vector2 #:vector2-x #:vector2-y
           #:rectangle #:make-rectangle #:rectangle-x #:rectangle-y #:rectangle-width #:rectangle-height
           #:color #:make-color #:color-alpha
           #:texture #:texture-width #:texture-height
           #:font
           #:audio-stream #:sound
           #:music #:music-looping
           #:camera-2d #:make-camera-2d #:camera-2d-offset #:camera-2d-target #:get-world-to-screen-2d
           #:camera-2d-rotation #:camera-2d-zoom
           #:keyboard-key #:gamepad-button)
  ;; --- Functions --- ;;
  (:export #:init-window #:close-window
           #:init-audio-device #:close-audio-device
           #:set-target-fps #:window-should-close
           #:begin-drawing #:end-drawing
           #:begin-mode-2d #:end-mode-2d
           #:clear-background #:draw-fps #:draw-text #:draw-text-ex #:draw-rectangle #:draw-line #:draw-pixel
           #:load-texture #:unload-texture #:is-texture-valid #:draw-texture #:draw-texture-v #:draw-texture-rec
           #:load-sound #:unload-sound #:play-sound
           #:load-music-stream #:unload-music-stream #:is-music-stream-playing #:play-music-stream #:update-music-stream
           #:load-font #:load-font-ex #:unload-font #:is-font-valid #:get-font-default
           #:is-key-pressed #:is-key-down
           #:is-gamepad-button-pressed #:is-gamepad-button-down #:get-gamepad-name #:is-gamepad-available #:get-gamepad-button-pressed
           #:get-mouse-wheel-move
           #:is-mouse-button-pressed #:is-mouse-button-released
           #:is-mouse-button-down #:is-mouse-button-down
           #:get-gamepad-axis-count #:get-gamepad-axis-movement
           #:check-collision-recs #:check-collision-point-rec
           #:get-frame-time)
  ;; --- Library Loading --- ;;
  #+sbcl
  (:export #:load-shared-objects)
  (:documentation "A light wrapping of necessary Raylib types and functions."))

(in-package :raylib)

#+sbcl
(defun load-shared-objects (&key (target nil))
  "Dynamically load the necessary `.so' files. This is wrapped as a function so that
downstream callers can call it again as necessary when the Lisp Image is being
restarted. Note the use of `:dont-save' below. This is to allow the package to
be compiled with `.so' files found in one location, but run with ones from another."
  (let ((dir (case target
               (:linux "/usr/lib/")
               (:darwin #+arm64 "/opt/homebrew/lib/"
                        #-arm64 "/usr/local/lib/")
               (t "lib/"))))
    #+linux
    (progn
      (load-shared-object (merge-pathnames "liblisp-raylib.so" dir) :dont-save t)
      (load-shared-object (merge-pathnames "liblisp-raylib-shim.so" dir) :dont-save t))
    #+win32
    (progn
      (load-shared-object (merge-pathnames "lisp-raylib.dll" dir) :dont-save t)
      (load-shared-object (merge-pathnames "lisp-raylib-shim.dll" dir) :dont-save t))
    #+darwin
    (progn
      (load-shared-object (merge-pathnames "liblisp-raylib.dylib" dir) :dont-save t)
      (load-shared-object (merge-pathnames "liblisp-raylib-shim.dylib" dir) :dont-save t))))

#+sbcl
(load-shared-objects)

;; NOTE: 2025-01-03 We preload the shared libraries here to ensure that all
;; functions are already visible when we start to reference them in other files.
#+(and ecl linux)
(progn
  (ffi:load-foreign-library #p"lib/liblisp-raylib.so")
  (ffi:load-foreign-library #p"lib/liblisp-raylib-shim.so"))

#+(and ecl darwin)
(progn
  (ffi:load-foreign-library #p"lib/liblisp-raylib.dylib")
  (ffi:load-foreign-library #p"lib/liblisp-raylib-shim.dylib"))

;; --- Keyboard and Gamepad --- ;;

;; HACK: 2024-12-29 Hacked manually as I couldn't figure out a first-class way
;; to reference enum values.
(defun keyboard-key (kw)
  (case kw
    (:null 0)            ;; Key: NULL used for no key pressed
    ;; Alphanumeric keys
    (:apostrophe 39)     ;; Key: '
    (:comma 44)          ;; Key: 
    (:minus 45)          ;; Key: -
    (:period 46)         ;; Key: .
    (:slash 47)          ;; Key: /
    (:zero 48)           ;; Key: 0
    (:one 49)            ;; Key: 1
    (:two 50)            ;; Key: 2
    (:three 51)          ;; Key: 3
    (:four 52)           ;; Key: 4
    (:five 53)           ;; Key: 5
    (:six 54)            ;; Key: 6
    (:seven 55)          ;; Key: 7
    (:eight 56)          ;; Key: 8
    (:nine 57)           ;; Key: 9
    (:semicolon 59)      ;; Key: ;
    (:equal 61)          ;; Key: =
    (:a 65)              ;; Key: A | a
    (:b 66)              ;; Key: B | b
    (:c 67)              ;; Key: C | c
    (:d 68)              ;; Key: D | d
    (:e 69)              ;; Key: E | e
    (:f 70)              ;; Key: F | f
    (:g 71)              ;; Key: G | g
    (:h 72)              ;; Key: H | h
    (:i 73)              ;; Key: I | i
    (:j 74)              ;; Key: J | j
    (:k 75)              ;; Key: K | k
    (:l 76)              ;; Key: L | l
    (:m 77)              ;; Key: M | m
    (:n 78)              ;; Key: N | n
    (:o 79)              ;; Key: O | o
    (:p 80)              ;; Key: P | p
    (:q 81)              ;; Key: Q | q
    (:r 82)              ;; Key: R | r
    (:s 83)              ;; Key: S | s
    (:t 84)              ;; Key: T | t
    (:u 85)              ;; Key: U | u
    (:v 86)              ;; Key: V | v
    (:w 87)              ;; Key: W | w
    (:x 88)              ;; Key: X | x
    (:y 89)              ;; Key: Y | y
    (:z 90)              ;; Key: Z | z
    (:left-bracket 91)   ;; Key: [
    (:backslash 92)      ;; Key: '\'
    (:right-bracket 93)  ;; Key: ]
    (:grave 96)          ;; Key: `
    ;; Function keys
    (:space 32)          ;; Key: Space
    (:escape 256)        ;; Key: Esc
    (:enter 257)         ;; Key: Enter
    (:tab 258)           ;; Key: Tab
    (:backspace 259)     ;; Key: Backspace
    (:insert 260)        ;; Key: Ins
    (:delete 261)        ;; Key: Del
    (:right 262)         ;; Key: Cursor right
    (:left 263)          ;; Key: Cursor left
    (:down 264)          ;; Key: Cursor down
    (:up 265)            ;; Key: Cursor up
    (:page-up 266)       ;; Key: Page up
    (:page-down 267)     ;; Key: Page down
    (:home 268)          ;; Key: Home
    (:end 269)           ;; Key: End
    (:caps-lock 280)     ;; Key: Caps lock
    (:scroll-lock 281)   ;; Key: Scroll down
    (:num-lock 282)      ;; Key: Num lock
    (:print-screen 283)  ;; Key: Print screen
    (:pause 284)         ;; Key: Pause
    (:f1 290)            ;; Key: F1
    (:f2 291)            ;; Key: F2
    (:f3 292)            ;; Key: F3
    (:f4 293)            ;; Key: F4
    (:f5 294)            ;; Key: F5
    (:f6 295)            ;; Key: F6
    (:f7 296)            ;; Key: F7
    (:f8 297)            ;; Key: F8
    (:f9 298)            ;; Key: F9
    (:f10 299)           ;; Key: F10
    (:f11 300)           ;; Key: F11
    (:f12 301)           ;; Key: F12
    (:left-shift 340)    ;; Key: Shift left
    (:left-control 341)  ;; Key: Control left
    (:left-alt 342)      ;; Key: Alt left
    (:left-super 343)    ;; Key: Super left
    (:right-shift 344)   ;; Key: Shift right
    (:right-control 345) ;; Key: Control right
    (:right-alt 346)     ;; Key: Alt right
    (:right-super 347)   ;; Key: Super right
    (:kb-menu 348)       ;; Key: KB menu
    ;; Keypad keys
    (:kp-0 320)          ;; Key: Keypad 0
    (:kp-1 321)          ;; Key: Keypad 1
    (:kp-2 322)          ;; Key: Keypad 2
    (:kp-3 323)          ;; Key: Keypad 3
    (:kp-4 324)          ;; Key: Keypad 4
    (:kp-5 325)          ;; Key: Keypad 5
    (:kp-6 326)          ;; Key: Keypad 6
    (:kp-7 327)          ;; Key: Keypad 7
    (:kp-8 328)          ;; Key: Keypad 8
    (:kp-9 329)          ;; Key: Keypad 9
    (:kp-decimal 330)    ;; Key: Keypad .
    (:kp-divide 331)     ;; Key: Keypad /
    (:kp-multiply 332)   ;; Key: Keypad *
    (:kp-subtract 333)   ;; Key: Keypad -
    (:kp-add 334)        ;; Key: Keypad +
    (:kp-enter 335)      ;; Key: Keypad Enter
    (:kp-equal 336)      ;; Key: Keypad =
    ;; Android key buttons
    (:back 4)            ;; Key: Android back button
    (:menu 5)            ;; Key: Android menu button
    (:volume-up 24)      ;; Key: Android volume up button
    (:volume-down 25)    ;; Key: Android volume down button
    (t (error "Unknown keyboard key: ~a" kw))))

#++
(keyboard-key :kim)

(defun gamepad-button (kw)
  (case kw
    (:unknown 0)
    (:left-face-up 1)
    (:left-face-right 2)
    (:left-face-down 3)
    (:left-face-left 4)
    (:right-face-up 5)
    (:right-face-right 6)
    (:right-face-down 7)
    (:right-face-left 8)
    (:left-trigger-1 9)
    (:left-trigger-2 10)
    (:right-trigger-1 11)
    (:right-trigger-2 12)
    (:middle-left 13)
    (:middle 14)
    (:middle-right 15)
    (:left-thumb 16)
    (:right-thumb 17)
    (t (error "Unknown gamepad button: ~a" kw))))

;; Sanity test: This should work as-is under either compiler.
#+nil
(progn
  (init-window 300 300 "hello!")
  (let* ((white (make-color :r 255 :g 255 :b 255 :a 255))
         (black (make-color :r 0 :g 0 :b 0 :a 255))
         (text  "Café 日本語!")
         (points (concatenate 'vector (mapcar #'char-code (concatenate 'list text))))
         (font  (load-font-ex #p"/usr/share/fonts/OTF/ipag.ttf" 20 points))
         (pos   (make-vector2 :x 100 :y 100)))
    (unless (is-font-valid font)
      (error "Invalid font!"))
    (set-target-fps 100)
    (loop :while (not (window-should-close))
          :do (progn (begin-drawing)
                     (clear-background white)
                     (draw-text "Café" 50 50 20 black)
                     (draw-text-ex font "日本語 Café" pos 20 5 black)
                     (draw-fps 0 0)
                     (end-drawing)))
    (unload-font font)
    (close-window)))
