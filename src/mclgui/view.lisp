;;;; -*- mode:lisp;coding:utf-8 -*-
;;;;**************************************************************************
;;;;FILE:               view.lisp
;;;;LANGUAGE:           Common-Lisp
;;;;SYSTEM:             Common-Lisp
;;;;USER-INTERFACE:     NONE
;;;;DESCRIPTION
;;;;    
;;;;    The view class.
;;;;    
;;;;AUTHORS
;;;;    <PJB> Pascal J. Bourguignon <pjb@informatimago.com>
;;;;MODIFICATIONS
;;;;    2012-05-13 <PJB> Created.
;;;;BUGS
;;;;LEGAL
;;;;    GPL3
;;;;    
;;;;    Copyright Pascal J. Bourguignon 2012 - 2012
;;;;    
;;;;    This program is free software: you can redistribute it and/or modify
;;;;    it under the terms of the GNU General Public License as published by
;;;;    the Free Software Foundation, either version 3 of the License, or
;;;;    (at your option) any later version.
;;;;    
;;;;    This program is distributed in the hope that it will be useful,
;;;;    but WITHOUT ANY WARRANTY; without even the implied warranty of
;;;;    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;;;;    GNU General Public License for more details.
;;;;    
;;;;    You should have received a copy of the GNU General Public License
;;;;    along with this program.  If not, see <http://www.gnu.org/licenses/>.
;;;;**************************************************************************

(in-package "MCLGUI")
(enable-sharp-at-reader-macro)
(objcl:enable-objcl-reader-macros)





;; (defun nsview-to-view-position (frame-nsrect size-point)
;;   "
;; RETURN: The view-position POINT.
;; "
;;   #-(and)
;;   (let ((screen-pos (main-screen-frame)))
;;     (make-point (- (round (ns:ns-rect-x frame-nsrect)) (point-h screen-pos))
;;                 (- (point-v screen-pos) (round (ns:ns-rect-y frame-nsrect))
;;                    (point-v size-point)))))
;; 
;; 
;; (defun view-to-nsview-origin (position size)
;;   "
;; RETURN: A NSPoint containing the origin of the nsview.
;; "
;;   #-(and)
;;   (multiple-value-bind (screen-pos screen-siz) (main-screen-frame)
;;     (ns:make-ns-point (+ (point-h screen-pos) (point-h position))
;;                       (- (+ (point-v screen-pos) (point-v screen-siz))
;;                          (point-v position) (point-v size)))))
;; 
;; 
;; (defun view-to-nsview-frame (position size)
;;   "
;; RETURN: A NSRect containing the frame of the view.
;; "
;;   #-(and)
;;   (multiple-value-bind (screen-pos screen-siz) (main-screen-frame)
;;     (ns:make-ns-rect (+ (point-h screen-pos) (point-h position))
;;                      (- (+ (point-v screen-pos) (point-v screen-siz))
;;                         (point-v position) (point-v size))
;;                      (point-h size)
;;                      (point-v size))))






(defmethod initialize-instance :after ((view simple-view) &key &allow-other-keys)
  (when (and (slot-value view 'view-font) (not (typep view 'window)))
    (set-initial-view-font view (slot-value view 'view-font)))
  (setf (slot-value view 'view-size)     (or (slot-value view 'view-size)     (view-default-size     view))
        (slot-value view 'view-position) (or (slot-value view 'view-position) (view-default-position view)))
  (unless (typep view 'window)
    (setf (handle view) [[MclguiView alloc]
                         initWithFrame:(ns:make-ns-rect (point-h (slot-value view 'view-position))
                                                        (point-v (slot-value view 'view-position))
                                                        (point-h (slot-value view 'view-size))
                                                        (point-v (slot-value view 'view-size)))]
          (slot-value (handle view) 'view) view))
  (set-view-container view (slot-value view 'view-container))
  (values))



(defmethod initialize-instance :after ((view view) &key &allow-other-keys)
  (let ((subviews (slot-value view 'view-subviews)))
    (format-trace "initialize-instance" view subviews)
    (setf (slot-value view 'view-subviews) (make-array (length subviews) :adjustable t :fill-pointer 0))
    (apply (function add-subviews) view (coerce subviews 'list)))
  (values))


(defgeneric wptr (simple-view)
  (:documentation "
The wptr generic function holds the pointer to a window record on the
Macintosh heap. 
This generic function returns a window pointer if the view is contained in a
window, or nil if the view is not contained in a window.
All views contained in a given window have the same wptr.
")
  (:method ((view simple-view))
    (let ((window (view-window view)))
      (when (and window (handle window))
        (window-ptr window)))))



(defmethod view-allocate-clip-region ((view view))
  (let ((rgn (view-clip-region view)))
    (or rgn
        (setf (view-clip-region-slot view) (new-rgn)))))

(defmethod view-clip-region ((view view))
  (let ((rgn (view-clip-region-slot view)))
    (unless (or (null rgn) (view-valid-p view))
      (let ((container (view-container view)))
        (compute-view-origin view container)
        (make-view-valid view)
        (compute-view-region view rgn container)))
    rgn))

#-(and)
(defmethod compute-view-region ((view window) rgn container)
  (declare (ignore container))
  (when rgn
    (let* ((topleft (view-origin view))
           (botright (add-points topleft (view-size view))))
      (#_SetRectRgn rgn (point-h topleft) (point-v topleft) (point-h botright) (point-v botright))))
  rgn)


(defgeneric call-with-focused-view (view function &optional font-view)
  (:method ((view simple-view) function &optional font-view)
    (let* ((handle   (handle view))
           (handle   (when handle
                       (if (typep view 'window)
                           [handle contentView]
                           handle)))
           (unlock   nil)
           ff ms
           old-fonts
           old-fonts-view)
      (when handle
        (if (and (eq view *current-view*)
                 #-(and) (or (null font-view) (eq font-view old-font-view)))
            (funcall function view)
            (unwind-protect
                 (let ((*current-view* view)
                       (*current-font-view* (or font-view *current-font-view*)))
                   (if (setf unlock [handle lockFocusIfCanDraw])
                       (progn
                         (format-trace "did lockFocusIfCanDraw" view)
                         (focus-view *current-view* *current-font-view*)
                         #-(and)
                         (when (and view (null old-font-view) font-view
                                    (setf wptr (wptr view)))
                           (multiple-value-setq (ff ms) (wptr-font-codes wptr))
                           (setf old-fonts t))
                         (funcall function view)
                         [[NSGraphicsContext currentContext] flushGraphics])
                       (format-trace "could not lockFocusIfCanDraw" view)))
              (when unlock
                [handle unlockFocus]
                (format-trace "did unlockFocusIfCanDraw" view))
              (focus-view *current-view* *current-font-view*)))))))



(defgeneric focus-view (view &optional font-view)
  (:documentation "
DO:             The FOCUS-VIEW function installs the GrafPort of view
                as the current GrafPort and sets the clip region and
                origin so that drawing will occur in the coordinate
                system of view.  The FOCUS-VIEW function is not
                normally called directly. In general,
                WITH-FOCUSED-VIEW should be used when drawing to
                views.

VIEW:           A view installed in a window, or NIL.  If NIL, the
                current GrafPort is set to an invisible GrafPort.

FONT-VIEW:      A view or NIL. If NIL, the font is unchanged.  If
                non-NIL, the view-font-codes of font-view are
                installed after the rest of the focusing is completed.
                The default is NIL.
")
  (:method ((null null) &optional font-view)
    (setf *current-font-view* font-view
          *current-view* nil))
  (:method ((view simple-view) &optional font-view)
    (if  (handle view)
         (setf *current-font-view* font-view
               *current-view* view)
         (focus-view nil font-view))))



(defmacro with-focused-view (view &body body &environment env)
  "
DO:             The WITH-FOCUSED-VIEW macro executes BODY with the
                current GrafPort set for drawing into view.  This
                involves setting the current GrafPort and setting the
                origin and clip region so that drawing occurs in VIEW.
                When the BODY exits (normally or abnormally), the old
                view is restored.

VIEW:           A view installed in a window, or NIL.  If NIL, the
                current GrafPort is set to an invisible GrafPort.
"
  (let ((sym (if (and view (symbolp view) (eq view (macroexpand view env)))
                 view
                 (gensym))))
    `(call-with-focused-view ,view (lambda (,sym)
                                     (declare (ignorable ,sym))
                                     ,@body))))



(defmacro with-font-focused-view (view &body body &environment env)
  "
DO:             The macro with-font-focused-view focuses on the font
                of view, then calls with-focused-view.

VIEW:           A view installed in a window, or NIL.  If NIL, the
                current GrafPort is set to an invisible GrafPort.
"
  `(let ((*current-font-view* view))
     (with-focused-view ,view ,@body)))


(defun refocus-view (view)
  (when (eq view *current-view*)
    (setq *current-view* nil)
    (focus-view view *current-font-view*)))




(defgeneric install-view-in-window (view window)
  (:documentation "
DO:             Installs VIEW in the WINDOW window.

                This function performs initialization tasks that
                require the containing window.  It should never be
                called directly by user code.  However, it may be
                shadowed.  Specialized versions of
                INSTALL-VIEW-IN-WINDOW should always perform
                CALL-NEXT-METHOD.

VIEW:           A view or subview, but not a window. Instances of
                window cannot have containers.

WINDOW:         A window.
")
  (:method ((view simple-view) window)
    (dovector (subview (view-subviews view))
              (install-view-in-window subview window))))


(defgeneric remove-view-from-window (view)
  (:documentation "
DO:             Remove view from its container.  It should never be
                called directly by user code.  However, it may be
                shadowed.  Specialized versions of
                REMOVE-VIEW-FROM-WINDOW should dispose of any
                Macintosh data the item uses (that is, data not
                subject to garbage collection) and should always
                perform a CALL-NEXT-METHOD.

VIEW:           A view or subview, but not a window.  Instances of
                window cannot have containers.
")
  (:method ((view simple-view))
    (dovector (subview (view-subviews view))
              (remove-view-from-window subview))))


(defgeneric add-view-to-container (view container)
  (:documentation "
DO:             Add the VIEW to container, and its NSView as subview
                of the NSView of the CONTAINER.

POST:           (eq (view-container view) container)

RETURN:         VIEW.
")
  (:method ((view simple-view) (container view))
    (let ((viewh         (handle view))
          (superh        (handle container)))
      (let ((siblings (view-subviews container)))
        (vector-push-extend view siblings))
      (setf (slot-value view 'view-container) container)
      (when (and viewh superh)
        (on-main-thread [superh addSubview:viewh]))
      view))
  (:method ((view simple-view) (container window))
    (let ((viewh         (handle view))
          (winh          (handle container)))
      (let ((siblings (view-subviews container)))
        (vector-push-extend view siblings))
      (setf (slot-value view 'view-container) container)
      (when (and viewh winh)
        (on-main-thread [[winh contentView] addSubview:viewh]))
      view)))


(defgeneric remove-view-from-superview (view)
  (:documentation "
DO:             Remove the VIEW and its NSView from its superview.
NOTE:           the view-container is not changed.
RETURN:         VIEW.
")
  ;; Note: when view-container is a window, it still works, since view
  ;; is a subview of the contentView of its NSWindow, so  [viewh
  ;; removeFromSuperview] works correctly.
  (:method ((view simple-view))
    (with-handle (viewh view)
      (let ((old-container (view-container view)))
        (deletef (slot-value old-container 'view-subviews) view)
        (when viewh
          (on-main-thread [viewh removeFromSuperview])))
      view)))


(defgeneric set-view-container (view new-container)
  (:documentation "
DO:             Set the view that contains to NEW-CONTAINER.  If the
                window of the view is changed by giving it a new
                container, REMOVE-VIEW-FROM-WINDOW is called on view
                and the old window, and INSTALL-VIEW-IN-WINDOW is
                called on view and the new window.

VIEW:           A view or subview, but not a window. Instances of
                window cannot have containers. If SET-VIEW-CONTAINER
                is called on a window, it signals an error.

NEW-CONTAINER:  The new container of the view.
")
  (:method ((view simple-view) new-container)
    ;; If container is nil, removes view from container
    ;; Note: The dialog code depends on the fact that the view-container slot is
    ;; changed AFTER the WPTR is changed.
    (let ((old-container (view-container view)))
      (unless (eq new-container old-container)    
        (when new-container
          (check-type new-container view)
          (when (or (eq new-container view)
                    (view-contains-p view new-container))
            (error 'view-error :view view
                   :format-control "Attempt to make ~S contain itself."
                   :format-arguments (list view))))
        (let* ((new-window (and new-container (view-window new-container)))
               (old-window (and old-container (view-window old-container)))
               (current-view *current-view*)
               (current-font-view *current-font-view*))
          (when old-container
            (invalidate-view view t)
            (when (eq view current-view)
              (focus-view nil))
            ;; Note: remove-view-from-superview doesn't modify the
            ;;       view-container.  This is important because
            ;;       remove-view-from-window methods use
            ;;       view-container (eg. to focus-view).
            (remove-view-from-superview view)
            (unless (eq new-window old-window)
              (remove-view-from-window view))
            (setf (slot-value view 'view-container) nil))
          ;; -
          (when (and (null new-container) (eq *mouse-view* view))
            (setf *mouse-view* nil))
          (when new-container
            (add-view-to-container view new-container)
            (unless (eq new-window old-window)
              (install-view-in-window view new-window))
            (invalidate-view view)
            (when (eq view current-view)
              (focus-view view current-font-view))
            (if (and new-window (window-active-p new-window))
                (view-activate-event-handler view)
                (view-deactivate-event-handler view)))))))
  
  (:method ((w window) new-container)
    (unless (null new-container)
      (error "Container must always be ~S for windows." nil))
    new-container))


(defmethod view-activate-event-handler ((view view))
  (dovector (v (view-subviews view))
    (view-activate-event-handler v))
  (call-next-method))


(defmethod view-deactivate-event-handler ((view view))
  (dovector (v (view-subviews view))
    (view-deactivate-event-handler v))
  (call-next-method))


(defgeneric add-subviews (view &rest subviews)
  (:documentation "
DO:             Set the container of each of subviews to view.  If any
                of the subviews are already owned by view,
                add-subviews does nothing.

VIEW:           A view.

SUBVIEWS:       A list of view or simple view, but not a window;
                SUBVIEWS must be able to be contained within view.
")
  (:method ((view view) &rest subviews)
    (unless (find view subviews :test (function view-contains-p))
      (dolist (subview subviews)
        (set-view-container subview view)))))


(defgeneric remove-subviews (view &rest subviews)
  (:documentation  "
DO:             Remove each of SUBVIEWS from view.  If a subview is
                not in view, an error is signaled.

VIEW:           A view.

SUBVIEWS:       A list of view or simple view, but not a window;
                SUBVIEWS must be able to be contained within view.
")
  (:method ((view view) &rest subviews)
    (unless (find view subviews :test (complement (function view-contains-p)))
     (dolist (subview subviews)
       (set-view-container subview nil)))))



(defgeneric view-contains-p (view contained-view)
  (:documentation "Whether CONTAINED-VIEW is a sub+view of VIEW.")
  (:method ((view simple-view) contained-view)
    (loop
      :for container = (view-container contained-view)
      :then (view-container container)
      :while container 
      :thereis (eq container view)))
  (:method ((view null) contained-view)
    (declare (ignore contained-view))
    nil))


(defmacro do-subviews ((subview-var view &optional (subview-type t))
                       &body body)
  "
DO:             For each subview of VIEW of the given SUBVIEW-TYPE,
                the macro DO-SUBVIEWS executes BODY with SUBVIEW-VAR
                bound to the subview.

SUBVIEW-VAR:    A variable.

VIEW:           A view.

SUBVIEW-TYPE:   A Common Lisp type specifier.
"
  (let ((vview         (gensym "view"))
        (vsubview-type (gensym "subview-type"))
        (vsubviews     (gensym "subviews")))
    `(let ((,vview         ,view)
           (,vsubview-type ,subview-type)
           (,vsubviews     (copy-seq (view-subviews ,vview))))
       (dovector (,subview-var ,vsubviews (values))
                 (when (typep ,subview-var ,vsubview-type)
                   ,@body)))))


(defgeneric map-subviews (view function &optional subview-type)
  (:documentation "
DO:             For each subview of view of the given SUBVIEW-TYPE,
                call FUNCTION with the subview as its single argument.

VIEW:           A view.

FUNCTION:       A function.

SUBVIEW-TYPE:   A Common Lisp type specifier.
")
  (:method ((view simple-view) function &optional (subview-type t))
    (do-subviews (subview view subview-type)
      (funcall function subview))))


(defgeneric subviews (view &optional subview-type)
  (:documentation "
RETURN:         A list of the subviews of view.  If subview-type is
                present, only subviews matching that type are
                returned.

VIEW:           A view.

SUBVIEW-TYPE:   A Common Lisp type specifier.
")
  (:method ((view simple-view) &optional (subview-type t))
    (declare (ignore subview-type))
    '())
  (:method ((view view) &optional (subview-type t))
    (let ((result nil))
      (dovector (subview (view-subviews view) (nreverse result))
                (when (typep subview subview-type)
                  (push subview result))))))

(defgeneric view-named (name view)
  (:documentation "
RETURN:         The first subview of view whose nickname is name. The
                subviews are searched in the order in which they were
                added to view.

NAME:           Any object, but usually a symbol.  Nicknames are
                compared using EQ.

VIEW:           A view.
")
  (:method (name (view simple-view))
    (dovector (subview (view-subviews view))
              (if (eq name (view-nick-name subview))
                  (return subview)))))


(defgeneric find-named-sibling (view name)
  (:documentation "

DO:             Performs a search in view’s container and returns the
                first item in the container whose nickname is name.
                For example, given a dialog item view, it performs a
                search in the view that is view’s container to find
                another item with the nickname name.  The items are
                searched in the order in which they were added to
                view’s container.

VIEW:           A simple view.

NAME:           Any object, but usually a symbol.  Nicknames are
                compared using EQ.
")
  (:method ((view simple-view) name)
    (let ((container (view-container view)))
      (and container (view-named name container)))))



(defgeneric find-clicked-subview (view where)
  (:documentation "
RETURN:         The subview of view that contains the point where in
                its click region.  The method for null searches all
                windows for a subview containing where in its click
                region.  This function is similar to
                find-view-containing-point, but FIND-CLICKED-SUBVIEW
                calls POINT-IN-CLICK-REGION-P, and
                FIND-VIEW-CONTAINING-POINT calls
                VIEW-CONTAINS-POINT-P.  The default method of
                POINT-IN-CLICK-REGION-P for views or simple views
                simply calls VIEW-CONTAINS-POINT-P, but users can
                write methods to make views invisible to mouse clicks.

VIEW:           A view or subview.

WHERE:          A point in the local coordinate system of the view’s container.
")
  (:method ((view simple-view) where)
    (declare (ignore where))
    view)
  (:method ((view view) where)
    (loop
      :for subview :across (view-subviews view)
      :when (point-in-click-region-p subview where)
      :do (return (find-clicked-subview subview (convert-coordinates where view subview)))
      :finally (return nil)))
  (:method ((view null) where)
    (map-windows (lambda (w)
                   (when (point-in-click-region-p w where)
                     (return-from find-clicked-subview
                       (find-clicked-subview w (subtract-points where (view-position w))))))
                 :include-windoids t)
    nil))



(defgeneric view-corners (view)
  (:documentation "
RETURN:         Two points, the upper-left and lower-right corners of
                view, in the coordinate system of the container.
                The method for window returns the #(0 0) and the view size.

VIEW:           A simple view or subclass of simple-view.

WINDOW:         A window.
")
  (:method ((view simple-view))
    (let ((pos  (or (view-position view) #@(0 0)))
          (size (if (view-position view)
                    (or (view-size view)  #@(0 0))
                    #@(0 0))))
      (values pos (add-points pos size))))
  (:method ((wind window))
    (values #@(0 0) (view-size wind))))




;; (defun box (min value max)
;;   (min max (max min value)))
;; (declaim (inline box))



(defgeneric invalidate-region (view region &optional erase-p)
  (:documentation "
DO:             The INVALIDATE-REGION generic function focuses on the
                view and calls #_InvalRgn.  If the value of ERASE-P is
                true, the function adds this region to the erase
                region of the window of the view; the next time
                WINDOW-UPDATE-EVENTHANDLER runs, it will be erased.
                If ERASE-P is NIL and the window was created with the
                :ERASE-ANONYMOUS-INVALIDATIONS initarg set to true
                (the default), the function adds this region to the
                window’s explicit invalidation region;
                WINDOW-UPDATE-EVENT-HANDLER will not erase it.  The
                function INVALIDATE-REGION is called by
                INVALIDATE-VIEW and INVALIDATE-CORNERS, and indirectly
                by SET-VIEW-POSITION, SET-VIEW-SIZE, and
                SET-VIEW-CONTAINER.

VIEW:           A simple view.

REGION:         The region to invalidate.

ERASE-P:        A value indicating whether or not to add the
                invalidated view to the erase region of the window of
                the view. The default is NIL.
")
  (:method ((view simple-view) region &optional erase-p)
    (declare (ignore region erase-p)) ; TODO: for now we invalidate everything.
    (format-trace "invalidate-region" view)
    (with-handle (viewh view)
      [viewh setNeedsDisplay:yes])
    #-(and)
    (let* ((wptr (wptr view)))
      (when wptr
        (let* ((window (view-window view))
               (view-clip-region (and window (view-clip-region view))))    
          (when (and window view-clip-region)
            (with-focused-view view         
              (let* ((rgn *temp-rgn*)
                     (update-rgn *temp-rgn-2*)
                     ;; (window (view-window view)) ;; redundant - but why did it cause a problem????
                     (invalid-rgn (window-invalid-region window))
                     (org (view-origin view))
                     (offset (unless (eql #@(0 0) org) (subtract-points (view-origin window) org))))
                (#_SectRgn region view-clip-region rgn)
                (let ((erase-rgn (window-erase-region window)))
                  (when erase-rgn
                    (when offset (#_offsetrgn rgn (point-h offset)(point-v offset))) ; to window coords
                    (when erase-p
                      (#_UnionRgn rgn erase-rgn erase-rgn))                   
                    (get-window-updatergn wptr update-rgn)
                    (let ((offset (subtract-points #@(0 0) (view-position window))))
                      (#_OffsetRgn update-rgn (point-h offset)(point-v offset)))
                    (when invalid-rgn
                      (#_DiffRgn update-rgn invalid-rgn update-rgn))
                    (#_UnionRgn update-rgn erase-rgn erase-rgn))
                  (when offset
                    (let ((now-offset (subtract-points #@(0 0) offset)))
                      (#_offsetrgn rgn (point-h now-offset)(point-v now-offset)))))
                (#_invalwindowrgn wptr rgn)
                (when invalid-rgn                 
                  (let ((rgn3 *temp-rgn-3*))
                    (get-window-visrgn wptr rgn3)
                    (#_sectrgn rgn3 rgn rgn))
                                        ; view coordinates
                  (when offset (#_offsetrgn  rgn (point-h offset)(point-v offset))) ; to window coords
                  (#_UnionRgn rgn invalid-rgn invalid-rgn)))))))))
  
  (:method ((window window) region &optional erase-p)
    (declare (ignore region erase-p))
    (format-trace "invalidate-region" window)
    (with-handle (winh window)
      [winh setViewsNeedDisplay:yes])))


(defgeneric invalidate-corners (view topleft bottomright &optional erase-p)
  (:documentation "
DO:             Invalidate the rectangle formed by topleft and bottomright in VIEW.

VIEW:           A simple view.

TOPLEFT:        The upper-left corner of the rectangle to invalidate.

BOTTOMRIGHT:    The lower-right corner of the rectangle to invalidate.

ERASE-P:        A value indicating whether or not to add the
                invalidated rectangle to the erase region of the
                window of the view.  The default is NIL.
")
  (:method ((view simple-view) topleft bottomright &optional erase-p)
    (declare (ignore erase-p))
    (format-trace "invalidate-corners" view)
    (with-handle (viewh view)
      [viewh setNeedsDisplayInRect:(ns:make-ns-rect (point-h topleft) (point-v topleft)
                                                    (- (point-h bottomright) (point-h topleft))
                                                    (- (point-v bottomright) (point-v topleft)))])
    nil)
  (:method ((window window) topleft bottomright &optional erase-p)
    (declare (ignore topleft bottomright erase-p))
    (format-trace "invalidate-corners" window)
    (with-handle (winh window)
      [winh setViewsNeedDisplay:yes])))


(defgeneric invalidate-view (view &optional erase-p)
  (:documentation "
DO:             Invalidate VIEW by running INVALIDATE-CORNERS on the
                region bounded by its view-corners.

VIEW:           A view or simple view.

ERASE-P:        A value indicating whether or not to add the
                invalidated region to the erase region of view’s
                window.  The default is NIL.
")
  (:method ((view simple-view) &optional erase-p)
    (declare (ignore erase-p))
    (format-trace "invalidate-view" view)
    (with-handle (viewh view)
      [viewh setNeedsDisplay:yes]))

  (:method ((window window) &optional erase-p)
    (declare (ignore erase-p))
    (format-trace "invalidate-view" window)
    (with-handle (winh window)
      [winh setViewsNeedDisplay:yes])))

    


(defgeneric validate-region (view region)
  (:documentation "
DO:             Focus on the view and calls #_ValidRgn, removing the
                region from view’s window erase region and explicit
                invalidation region.

VIEW:           A simple view.

REGION:         A region. The region must be a Macintosh region handle,
                that is, the result of (#_NewRgn).
")
  (:method ((view simple-view) region)
    (declare (ignore region))
    #| Nothing to do. |#
    (values)))


(defgeneric validate-corners (view topleft bottomright)
  (:documentation "
DO:             Erase the previous contents of the rectangle formed by
                topleft and bottomright and calls #_ValidRgn on the
                rectangle.  It also removes the rectangle from the
                erase region of the view of the view.

VIEW:           A view or simple view.

TOPLEFT:        The upper-left corner of the view to invalidate.

BOTTOMRIGHT:    The lower-right corner of the view to invalidate.
")
  (:method ((view simple-view) topleft bottomright)
    (let ((rgn *temp-rgn*))
      (set-rect-region rgn
                       (point-h topleft) (point-v topleft)
                       (point-h bottomright) (point-v bottomright))
      (validate-region view rgn))))


(defgeneric validate-view (view)
  (:documentation "
DO:             Validates view by running validate-corners on the
                region bounded by its view-corners.

VIEW:           A view or simple view.
")
  (:method ((view simple-view))
    (multiple-value-bind (topleft bottomright) (view-corners view)
      (let ((container (view-container view)))
        (unless container
          (setf container view)
          (unless (typep view 'window)
            (let ((pos (view-position view)))
              (setq topleft     (subtract-points topleft     pos)
                    bottomright (subtract-points bottomright pos)))))
        (validate-corners container topleft bottomright)))))




(defgeneric set-view-position (view h &optional v)
  (:documentation "
DO:             Set the position of the view in its container.  The
                positions are given in the container’s coordinate
                system.

VIEW:           A view or simple view.

H:              The horizontal coordinate of the new position, or the
                complete position (encoded as a point) if V is NIL or
                not supplied.

V:              The vertical coordinate of the new position, or NIL if
                the complete position is given by H.

RETURN:         (make-point h v)
")
  (:method ((view simple-view) h &optional v)
    (let ((pos (make-point h v)))
      (unless (eql pos (view-position view))
        (com.informatimago.common-lisp.cesarum.utility:tracing
         (invalidate-view view t)         
         (setf (slot-value view 'view-position) pos)
         (invalidate-view view t)
         (with-handle (viewh view)
           [viewh setFrameOrigin: (nspoint pos)]
           #-(and)
           (com.informatimago.common-lisp.cesarum.utility:tracing
            view viewh pos
            (on-main-thread [viewh setFrameOrigin: (nspoint pos)])))))
      (refocus-view view)
      pos)))


(defgeneric set-view-size (view h &optional v)
  (:documentation "
DO:             Set the size of the view.

VIEW:           A simple view or subclass of simple-view.

H:              The width of the new size, or the complete size
                (encoded as an integer) if V is NIL or not supplied.

V:              The height of the new size, or NIL if the complete
                size is given by H.
")
  (:method ((view simple-view) h &optional v)
    (let ((siz (make-point h v)))
      (unless (eql siz (view-size view))
        (invalidate-view view t)
        (setf (slot-value view 'view-size) siz)
        (invalidate-view view t)
        (with-handle (viewh view)
          [viewh setFrameSize: (nssize siz)]
          [viewh setBounds: (nssize siz)]
          #-(and)
          (progn
            (on-main-thread [viewh setFrameSize: (nssize siz)])
            (on-main-thread [viewh setBounds: (nssize siz)]))))
      (refocus-view view)
      siz)))


(defgeneric view-default-position (view)
  (:documentation "
DECRIPTION:     When a window is created, the VIEW-DEFAULT-POSITION
                generic function is called if no position is
                explicitly specified either as the :VIEW-POSITION
                initialization argument to MAKE-INSTANCE or as a
                default initialization argument in the class
                definition.  The value returned is used as the initial
                position of the window.  It must be a valid position
                specifier, either a point or a centering specifier as
                documented under SET-VIEW-POSITION.

RETURN:         The system-supplied method specialized on WINDOW
                returns the value of *WINDOW-DEFAULT-POSITION*.

RETURN:         The method of VIEW-DEFAULT-POSITION for simple-view
                returns #@(0 0). This function is called to determine
                the default value of the :view-position initarg of
                view.

VIEW:           A simple-view or subclass of simple-view.
")
  (:method ((view simple-view))
    #@(0 0)))


(defgeneric view-default-size (view)
  (:documentation "
DESCRIPTION:    When a window is created, the VIEW-DEFAULT-SIZE
                generic function is called if no size is explicitly
                specified either as the :VIEW-SIZE initialization
                argument to make-instance or as a default
                initialization argument in the class definition.  The
                value returned is used as the initial size of the
                window.  It must be a point.

RETURN:         The method of view-default-size for simple-view
                returns #@(100 100). This function is called to
                determine the default value of the :viewsize initarg
                of view.

RETURN:         The system-supplied method specialized on WINDOW
                returns the value of *WINDOW-DEFAULT-SIZE*.

VIEW:  A simple view or subclass of simple-view.
")
  (:method ((view simple-view))
    #@(100 100)))


(defgeneric set-view-scroll-position (view h &optional v scroll-visibly)
  (:documentation "
DO:             Set the position of the view’s scroll position. It is
                usually called in response to a mouse click in a
                scroll bar. The function returns NIL.

VIEW:           A simple view or subclass of simple-view.

H:              The horizontal coordinate of the new scroll position,
                or the complete scroll position (encoded as a point)
                if V is NIL or not supplied.

V:              The vertical coordinate of the new scroll position, or NIL
                if the complete scroll position is given by H.

SCROLL-VISIBLY: An argument specifying whether the scrolling is done
                immediately. If true, the function calls #_ScrollRect to
                do the scrolling immediately.  Otherwise, the function
                invalidates the view so that it is redrawn the next time
                WINDOW-UPDATE-EVENT-HANDLER is called.

NOTE:           H and V are in VIEW's coordinates.

RETURN:         (make-point h v)
")
  (:method ((view view) h &optional v (scroll-visibly t))
    (let* ((pt         (make-point h v))
           ;; (container  (view-container view))
           (old-sc-pos (view-scroll-position view))
           (delta      (subtract-points old-sc-pos pt)))
      (with-focused-view view
        (unless (eql delta #@(0 0))
          (if scroll-visibly
              (let* (;; (rgn         *temp-rgn*)
                     (window      (view-window view))
                     (erase-rgn   (window-erase-region window))
                     (invalid-rgn (window-invalid-region window))
                     ;; (view-rgn    (and (or erase-rgn invalid-rgn) (view-clip-region view)))
                     ;; (size        (view-size view))
                     )
                (niy set-view-scroll-position view h v scroll-visibly)
                #-(and)
                (if container
                    (rlet ((r :rect
                              :topleft old-sc-pos
                              :bottomright (add-points old-sc-pos size)))
                          (#_ScrollRect  r (point-h delta)(point-v delta)  rgn)                 
                          (#_invalWindowRgn wptr rgn)
                          (when view-rgn
                            (let ((offset (subtract-points #@(0 0) (view-origin view))))
                              (#_OffsetRgn view-rgn (point-h offset)(point-v offset)))))
                    (progn                
                      (rlet ((arect :rect))
                            (#_getwindowportbounds wptr  arect)
                            (#_scrollrect arect (point-h delta)(point-v delta)  rgn))                 
                      (#_invalWindowRgn wptr rgn)))
                #-(and)
                (when view-rgn
                  (when (and erase-rgn (not (#_EmptyRgn erase-rgn)))
                    (#_CopyRgn erase-rgn rgn)
                    (#_SectRgn rgn view-rgn rgn)
                    (#_DiffRgn erase-rgn rgn erase-rgn)
                    (#_OffsetRgn rgn (point-h delta)(point-v delta))
                    (#_SectRgn rgn view-rgn rgn)
                    (#_UnionRgn rgn erase-rgn erase-rgn))
                  (when (and invalid-rgn (not (#_EmptyRgn invalid-rgn)))
                    (#_CopyRgn invalid-rgn rgn)
                    (#_SectRgn rgn view-rgn rgn)
                    (#_DiffRgn erase-rgn rgn invalid-rgn)
                    (#_OffsetRgn rgn (point-h delta)(point-v delta))
                    (#_SectRgn rgn view-rgn rgn)
                    (#_UnionRgn rgn invalid-rgn invalid-rgn))))
              (invalidate-view view t))))
      (make-view-invalid view)
      (setf (view-scroll-position view) pt)
      (refocus-view view)
      pt)))


 
(defgeneric set-view-nick-name (view new-name)
  (:documentation "
DO:             Set the nickname of VIEW to NEW-NAME.

VIEW:           A view or simple-view.

NEW-NAME:       A name, usually a symbol or string.
")
  (:method ((view simple-view) new-name)
    (setf (slot-value view 'view-nick-name) new-name)))




(defgeneric view-contains-point-p (view point)
  (:documentation "
RETURN:         Whether VIEW contains POINT.  The method for
                simple-view takes POINT in the coordinates of the
                container view; the method for window uses its own
                coordinates.
")
  (:method ((view simple-view) point)
    (let* ((position (view-position view))
           (ph       (point-h position))
           (h        (point-h point)))
      (and (<= ph h)
           (let ((pv    (point-v position))
                 (v     (point-v point)))
             (and (<= pv v)
                  (let ((size  (view-size view)))
                    (and (< h  (+ ph (point-h size)))
                         (< v  (+ pv (point-v size))))))))))
  (:method ((window window) point)
    (and (point<= 0 point) (point<= point (view-size window)))))



(defun convert-coordinates (point source-view destination-view)
  "
The CONVERT-COORDINATES function converts point from the coordinate
system of SOURCE-VIEW to the coordinate system of DESTINATION-VIEW.
The source view and destination view should be in the same view
hierarchy (that is, they should have a common container, or one should
be contained in the other).

POINT:          A point, encoded as an integer.

SOURCE-VIEW:    A view in whose coordinate system point is given.
"
  (add-points point (subtract-points (view-origin destination-view)
                                     (view-origin source-view))))


(defgeneric find-view-containing-point (view h &optional v direct-subviews-only)
  (:documentation "
RETURN:         The view containing the point specified by H and
                V.  This may be the VIEW or one of its subviews.  The
                NULL method searches all windows for a view that
                contains the point.

VIEW:           A view.

H:              The horizontal coordinate of the point, or the complete
                point if V is not supplied.

V:              The vertical coordinate of the point.

DIRECT-SUBVIEWS-ONLY:
                If DIRECT-SUBVIEWS-ONLY is NIL (the default), the most
                specific view is returned; subviews are searched for
                subviews, and so on.  If true, then only the view or
                one of its direct subviews is returned.
")

  (:method ((view simple-view) h &optional v
            (direct-subviews-only nil))
    (declare (ignore h v))
    (unless direct-subviews-only
      view))

  (:method ((view view) h &optional v (direct-subviews-only nil))
    (let* ((point (make-point h v))
           (subviews (view-subviews view)))
      (loop
        :for subview :across subviews
        :when (view-contains-point-p subview point)
        :do (return-from find-view-containing-point
              (if direct-subviews-only
                  subview
                  (find-view-containing-point
                   subview
                   (convert-coordinates point view subview)
                   nil
                   nil)))))
    (unless direct-subviews-only
      view))

  (:method ((view null) h &optional v (direct-subviews-only nil))
    (let ((point (make-point h v)))
      (map-windows (lambda (w)
                     (when (view-contains-point-p w point)
                       (return-from find-view-containing-point
                         (if direct-subviews-only
                             w
                             (find-view-containing-point 
                              w
                              (subtract-points point (view-position w)))))))
                   :include-windoids t)
      nil)))


(defgeneric point-in-click-region-p (view where)
  (:documentation "
The generic function point-in-click-region-p is called by
VIEW-CLICK-EVENT-HANDLER to determine whether where is in view. The
default method calls VIEW-CONTAINS-POINT-P.

VIEW:           A simple view or view.

WHERE:          For a view, the cursor position of the view in the
                local coordinate system when the mouse is clicked. For
                a simple view, the cursor position of the simple view
                in the local coordinate system of the view’s container
                when the mouse is clicked.
")
  (:method ((view simple-view) where)
    (view-contains-point-p view where)))



(defgeneric view-convert-coordinates-and-click (view where container)
  (:documentation "
DO:             Run VIEW-CLICK-EVENT-HANDLER on the cursor position
                within the view’s container.

VIEW:           A simple view or view.

WHERE:          For a view, the mouse click position (the position
                when the mouse is clicked) of the view in the local
                coordinate system.  For a simple view, the mouse click
                position of the simple view in the local coordinate
                system of the view’s container.

CONTAINER:      The container of the view.
")
  (:method ((view simple-view) where container)
    (declare (ignore container))
    (view-click-event-handler view where))

  (:method ((view view) where container)
    (view-click-event-handler view (convert-coordinates where container view))))



(defmacro with-view-frame ((x y w h) view &body body)
  (let ((vpos (gensym))
        (vsiz (gensym))
        (vview (gensym)))
    `(let* ((,vview ,view)
            (,vpos (view-position ,vview))
            (,vsiz (view-size ,vview))
            (,x (point-h ,vpos))
            (,y (point-v ,vpos))
            (,w (point-h ,vsiz))
            (,h (point-v ,vsiz)))
       ,@body)))


(defgeneric view-draw-contents (view)
  (:documentation "
The generic function VIEW-DRAW-CONTENTS is called by the event
system whenever a view needs to redraw any portion of its contents.
The default simple-view method does nothing. It should be shadowed by
views that need to redraw their contents. The default view method calls
VIEW-FOCUS-AND-DRAW-CONTENTS on each of the view’s subviews.

When VIEW-DRAW-CONTENTS is called by the event system, the view’s clip
region is set so that drawing occurs only in the portions that need to be
updated. This normally includes areas that have been covered by other
windows and then uncovered.

VIEW:           A simple view or view.
")
  (:method ((view simple-view))
    ;; DEBUG:
    #-(and)
    (with-view-frame (x y w h) view
      (#_NSFrameRect (ns:make-ns-rect (1+ x) (1+ y) (min 2 (- w 2)) (min 2 (- h 2)))))
    (values))
  (:method ((view view))
    (com.informatimago.common-lisp.cesarum.utility:tracing
     (call-next-method)
     (dovector (subview (view-subviews view))
               (view-focus-and-draw-contents subview)))))



(defgeneric view-focus-and-draw-contents (view &optional visrgn cliprgn)
  (:documentation "
The generic function VIEW-FOCUS-AND-DRAW-CONTENTS is used whenever a
view needs to be focused on before any portion of its contents is
redrawn. The method for VIEW focuses on the view, then calls
VIEW-DRAW-CONTENTS if the VISRGN and CLIPRGN region records
overlap. The method for SIMPLE-VIEW focuses on the view’s container,
then calls VIEW-DRAW-CONTENTS.

VIEW:           A simple view or view.
VISRGN, CLIPRGN Region records from the view’s wptr.
")
  (:method ((view simple-view) &optional visrgn cliprgn)
    (with-focused-view (view-container view)
      (with-temp-rgns (visrgn cliprgn)
        (niy view-focus-and-draw-contents view visrgn cliprgn)
        ;; (get-window-visrgn wptr visrgn)
        ;; (get-window-cliprgn wptr cliprgn)
        (view-draw-contents view)
        #-(and)
        (when (view-is-invalid-p view visrgn cliprgn)
          (view-draw-contents view)))))

  (:method ((view view) &optional visrgn cliprgn)
    (with-focused-view view
      (with-temp-rgns (visrgn cliprgn)
        (niy view-focus-and-draw-contents view visrgn cliprgn)
        ;; (get-window-visrgn wptr visrgn)
        ;; (get-window-cliprgn wptr cliprgn)
        (view-draw-contents view)
        #-(and)
        (when (regions-overlap-p visrgn cliprgn)
          (view-draw-contents view))))))






(defgeneric view-valid-p (view)
  (:method ((view simple-view))
    t)
  (:method ((view view))
    (not (member nil (view-valid view)))))


(defgeneric make-view-invalid (view)
  (:method ((view simple-view))
    view)
  (:method ((view view))
    (let ((valid (view-valid view)))
      (when (and valid (car valid))
        (setf (car valid) nil)))
    view))


(defgeneric make-view-valid (view &optional dont-inval-subviews)
  (:method ((view simple-view) &optional dont-inval-subviews)
    (declare (ignore dont-inval-subviews))
    view)
  (:method ((view view) &optional dont-inval-subviews)
    (let ((valid (view-valid view)))
      (unless (or (null valid) (car valid))
        (setf (car valid) t)
        (unless dont-inval-subviews
          (loop
            :for subview :across (view-subviews view)
            :do (make-view-invalid subview)))))
    view))


(defmethod view-font-codes ((view simple-view))
  (let ((codes (view-get view 'view-font-codes)))
    (if codes
        (values (car codes) (cdr codes))
        (let ((container (view-container view)))
          (and container (view-font-codes container))))))

(defmethod set-view-font-codes ((view simple-view) ff ms &optional ff-mask ms-mask)
  (let ((codes (view-get view 'view-font-codes)))
    (if codes
        (let* ((old-ff (car codes))
               (old-ms (cdr codes))
               (ff (if ff-mask
                       (logior (logand ff ff-mask) 
                               (logandc2 old-ff  ff-mask))
                       ff))
               (ms (if ms-mask
                       (logior (logand ms ms-mask) 
                               (logandc2 old-ms ms-mask))
                       ms)))
          (rplacd (rplaca codes ff) ms))
      (view-put view 'view-font-codes (cons ff ms)))
    (values ff ms)))



(defmethod view-font ((view simple-view))
  (multiple-value-bind (ff ms) (view-font-codes view)
    (font-spec ff ms)))

(defmethod set-view-font ((view simple-view) font-spec)
  (multiple-value-bind (ff ms) (view-font-codes view)
    (multiple-value-bind (ff ms) (font-codes font-spec ff ms)
      (set-view-font-codes view ff ms)))
  font-spec)


(defgeneric view-default-font (view)
  (:documentation "
DESCRIPTION:    If a :VIEW-FONT initialization argument is not
                specified when a view is created, the generic function
                VIEW-DEFAULT-FONT is called to determine its font.
                Every window has a font spec associated with it, even
                if the window never uses fonts.

RETURN:         The WINDOW method on VIEW-DEFAULT-FONT returns the
                value of *DEFAULT-FONT-SPEC*.

RETURN:         The SIMPLE-VIEW method returns NIL, meaning
                that the view inherits its font from its container.

WINDOW:         A window.

VIEW:           A simple view.
")
  (:method ((view simple-view))
    nil))



(defmethod view-font-codes-info ((view simple-view))
  (multiple-value-call (function font-codes-info) (view-font-codes view)))

(defgeneric set-initial-view-font (view font-spec)
  (:method ((view simple-view) font-spec)
    (set-view-font view font-spec)))



(defgeneric view-cursor (view point)
  (:documentation "

The VIEW-CURSOR generic function determines the cursor shape whenever
the window containing the view is active and the cursor is over it.
The VIEW-CURSOR function is called by WINDOW-UPDATE-CURSOR.

VIEW:           A view or simple view.

POINT:          The position of the cursor, expressed as a point.

RETURN:         The cursor shape to display when the mouse is at
                point, a point in view. It is called by
                WINDOW-UPDATE-CURSOR as part of the default
                WINDOW-NULL-EVENT-HANDLER.  Specialize the view-cursor
                generic function to change your view’s cursor to one
                of the following predefined cursors or to a
                user-defined cursor.

                *ARROW-CURSOR* The standard north-northwest arrow
                cursor.

                *I-BEAM-CURSOR* The I-beam shape used when the cursor
                is over an area of editable text.

                *WATCH-CURSOR* The watch-face shape shown during
                time-consuming operations, when event processing is
                disabled.

")
  (:method ((view simple-view) point)
    (let ((container (view-container view)))
      (if container
          (view-cursor container (convert-coordinates point view container))
          *arrow-cursor*))))



(defun inset-corners (inset topleft bottomright)
  (values (add-points inset topleft) (subtract-points bottomright inset)))


;;;---------------------------------------------------------------------
;;; Internal functions.

(defun view-is-invalid-p (view visrgn cliprgn)
  (or (null visrgn)
      (null cliprgn)
      (multiple-value-bind (tl br) (view-corners view)
        (without-interrupts
            (niy view-is-invalid-p view visrgn cliprgn tl br)
            ;; (let ((rgn *temp-rgn*)) ; so *temp-rgn* belongs to us
            ;;   (#_SetRectRgn rgn (point-h tl)(point-v tl) (point-h br)(point-v br))
            ;;   (#_SectRgn rgn visrgn rgn)
            ;;   (#_SectRgn rgn cliprgn rgn)                   
            ;;   (not (#_EmptyRgn rgn)))
          ))))


(defgeneric frame-key-handler (view)
  (:method ((view simple-view))
    view))


(defun initialize/view ()
  (niy initialize/view))




;;;; THE END ;;;;
