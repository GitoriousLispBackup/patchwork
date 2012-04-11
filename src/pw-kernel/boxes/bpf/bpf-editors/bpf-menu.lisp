;;;;=========================================================;;;;;;;;  PATCH-WORK;;;;  By Mikael Laurson, Jacques Duthen, Camilo Rueda.;;;;  � 1986-1992 IRCAM ;;;;;;;;=========================================================(in-package :pw)(provide 'BPF-menu);=========================================(defvar *active-BPF-window* ())(defvar *pw-BPF-library* ());=========================================; file(defvar *BPF-menu-file* (new-menu "File"))(add-menu-items *BPF-menu-file*  (new-leafmenu "Save BPF lib..."     #'(lambda () (save-BPF-lib *pw-BPF-library*))))(add-menu-items *BPF-menu-file*  (new-leafmenu "Load BPF lib..."     #'(lambda () (load-BPF-lib))));;;============================;;Hardcopy printing(defvar *BPF-print-setUp*  (new-leafmenu "Page Setup�" #'(lambda () (ccl::win-print-setUp *active-BPF-window*))))(defvar *print-BPF-menu*   (new-leafmenu "Print�" #'(lambda () (ccl::window-hardcopy *active-BPF-window*))))(add-menu-items *BPF-menu-file* *BPF-print-setUp* *print-BPF-menu*);=========================================; edit(defvar *BPF-menu-edit* (new-menu "Edit"))(let ((menu-now))  (add-menu-items  *BPF-menu-edit*      (setq menu-now (new-leafmenu "Cut"        #'(lambda () (cut-bpf (editor-view-object *active-BPF-window*))))))   (set-command-key menu-now #\X)   (add-menu-items  *BPF-menu-edit*       (setq menu-now (new-leafmenu "Copy"        #'(lambda () (copy-bpf (editor-view-object *active-BPF-window*))))))   (set-command-key menu-now #\C)   (add-menu-items  *BPF-menu-edit*       (setq menu-now (new-leafmenu "Paste"        #'(lambda () (paste-bpf (editor-view-object *active-BPF-window*))))))   (set-command-key menu-now #\V)   (add-menu-items  *BPF-menu-edit*       (setq menu-now (new-leafmenu "Select All"      #'(lambda () (select-all-bpf (editor-view-object *active-BPF-window*) )))))   (set-command-key menu-now #\A));============================================; BPF(defvar *BPF-menu* (new-menu "BPF"))(add-menu-items *BPF-menu*  (new-leafmenu "Add BPF to lib"       #'(lambda () (add-BPF-to-lib *active-BPF-window* *pw-BPF-library*))))(let ((menu-now))  (add-menu-items *BPF-menu*    (setq menu-now (new-leafmenu "Next BPF from lib"      #'(lambda () (next-from-BPF-lib *active-BPF-window* *pw-BPF-library*)))))   (set-command-key menu-now #\N)   (add-menu-items *BPF-menu*   (setq menu-now (new-leafmenu "Prev BPF from lib"      #'(lambda () (next-from-BPF-lib *active-BPF-window* *pw-BPF-library* -1)))))   (set-command-key menu-now #\P))(add-menu-items *BPF-menu*   (new-leafmenu "Reset BPF lib"        #'(lambda () (reset-BPF-lib *pw-BPF-library*))));============================================; menubar for BPF(defvar *BPF-menu-root*  (list      *pw-menu-apps*     *BPF-menu-file*      *BPF-menu-edit*     (fifth (menubar))     (sixth (menubar))     *BPF-menu*  ));============================================; application (defvar *apps-BPF-menu-item* ())(setf *apps-BPF-menu-item*    (add-apps-item-to-apps-menu  "BPF"     #'(lambda ()         (if *active-BPF-window*           (if (wptr *active-BPF-window*)            (progn               (window-select *active-BPF-window*)              (enable-all-apps-menu-items)              (menu-item-disable *apps-BPF-menu-item*))            (ed-beep))          (ed-beep)))))