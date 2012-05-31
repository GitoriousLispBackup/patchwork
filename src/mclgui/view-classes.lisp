;;;; -*- mode:lisp;coding:utf-8 -*-
;;;;**************************************************************************
;;;;FILE:               view-classes.lisp
;;;;LANGUAGE:           Common-Lisp
;;;;SYSTEM:             Common-Lisp
;;;;USER-INTERFACE:     NONE
;;;;DESCRIPTION
;;;;    
;;;;    XXX
;;;;    
;;;;AUTHORS
;;;;    <PJB> Pascal J. Bourguignon <pjb@informatimago.com>
;;;;MODIFICATIONS
;;;;    2012-05-15 <PJB> 
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

;;;---------------------------------------------------------------------

(defclass simple-view (colored stream) ; output-stream TODO: We may want a gray-stream here.
  ((help-spec            :initform nil         :initarg  :help-spec            :accessor help-spec)
   (view-container       :initform nil                                         :reader view-container
                         :documentation "The view that contains this view.")
   (view-position        :initform #@(0 0)     :initarg  :view-position        :reader view-position
                         :documentation "The position of the view in its container.")
   (view-size            :initform #@(100 100) :initarg  :view-size            :reader view-size
                         :documentation "The size of the view.")
   (view-scroll-position :initform #@(0 0)
                         :initarg :view-scroll-position
                         :accessor view-scroll-position
                         :documentation "The current scroll position of the view, which is the
coordinate of the upper-left corner of the view.")
   (view-nick-name       :initform nil         :initarg  :view-nick-name       :reader view-nick-name
                         :documentation "The nickname of the view.")
   (view-font            :initform nil         :initarg  :view-font            :reader view-font)
   (view-alist           :initform nil                                         :accessor view-alist)))




(defmethod initialize-instance :after ((view simple-view) &key &allow-other-keys)
  (when (and (slot-value view 'view-font) (not (typep view 'window)))
    (set-initial-view-font view (slot-value view 'view-font)))
  (setf (slot-value view 'view-size)     (or (slot-value view 'view-size)     (view-default-size     view))
        (slot-value view 'view-position) (or (slot-value view 'view-position) (view-default-position view)))
  (set-view-container view (slot-value view 'view-container))
  (values))


(defgeneric view-subviews (view)
  (:documentation "
RETURN:         A vector containing all of the view’s subviews.  This
                vector should never be changed directly.  It is
                updated automatically by calls to
                SET-VIEW-CONTAINER.
")
  (:method ((view simple-view))
    #()))


(defgeneric view-get (view key &optional default)
  (:documentation "
RETURN:         The property KEY of the VIEW.  If it is not present then return DEFAULT.
")
  (:method ((view simple-view) key &optional default)
    (let ((cell (assoc key (view-alist view))))
      (if cell
          (cdr cell)
          default))))


(defgeneric view-put (view key value)
  (:documentation "
DO:             Set the property KEY of the VIEW to VALUE.
RETURN:         VALUE.
")
  (:method ((view simple-view) key value)
    (let ((cell (assoc key (view-alist view))))
      (if cell
          (setf (cdr cell) value)
          (push (cons key value) (view-alist view)))
      value)))


(defgeneric (setf view-get) (value view key &optional default)
  (:documentation "
DO:             Set the property KEY of the VIEW to VALUE.
RETURN:         VALUE.
")
  (:method (value (view simple-view) key &optional default)
    (declare (ignore default))
    (view-put view key value)))


(defgeneric view-remprop (view key)
  (:documentation "
DO:             Remove the property KEY from the VIEW.
")
  (:method ((view simple-view) key)
    (setf (view-alist view)
          (delete key (view-alist view) :key (function car)))
    view))


;;;---------------------------------------------------------------------

(defclass view (simple-view)
  ((view-origin          :initform #@(0 0)
                         :accessor view-origin-slot)
   (view-subviews        :initform nil
                         :reader   view-subviews
                         ;; Note: the vector is initialized in initialize-instance.
                         :documentation "A vector of subviews.")
   (view-valid           :initform nil
                         :accessor view-valid) ; for lazy clip-region updating.
   (view-clip-region     :initform nil
                         :accessor view-clip-region-slot)))


(defmethod initialize-instance :after ((view view) &key &allow-other-keys)
  (let ((subviews (slot-value view 'view-subviews)))
    (setf (slot-value view 'view-subviews) (make-array (length subviews) :adjustable t :fill-pointer 0))
    (apply (function add-subviews) views subviews))
  ;; (dolist (subview view-subviews)
  ;;   (set-view-container subview view))
  (values))


;;;---------------------------------------------------------------------

(defclass window (view)
  ((window-cursor                    :initform  *arrow-cursor*
                                     :reader    window-cursor)
   (window-grow-rect                 :initform  nil
                                     :reader    window-grow-rect)
   (window-drag-rect                 :initform  nil
                                     :reader    window-drag-rect)
   (color-list                       :initform  nil                          
                                     :reader    window-color-list)
   (back-color                       :initform  nil)
   (my-item                          :initform  nil)
   (window-do-first-click            :initform  nil                          
                                     :accessor  window-do-first-click
                                     :initarg   :window-do-first-click)
   (window-other-attributes          :initform  0                            
                                     :accessor  window-other-attributes
                                     :initarg   :window-other-attributes) 
   (window-active-p                  :initform  nil                          
                                     :accessor  window-active-p)
   ;; The window-active-p generic function returns t if window is the active
   ;; window, nil otherwise.
   ;; Except when Macintosh Common Lisp is not the active application, it returns
   ;; t for all floating windows and for the frontmost non-floating visible window.
   
   (window-erase-region              :initform  (new-rgn)
                                     :accessor  window-erase-region)
   (window-invalid-region            :initform  nil                          
                                     :accessor  window-invalid-region)
   (process                          :initform  nil                          
                                     :initarg  :process                        
                                     :accessor  window-process)
   (queue                            :initform  (make-process-queue "Window")
                                     :reader    window-process-queue)
   (auto-position                    :initarg   :auto-position               
                                     :initform  :noAutoCenter
                                     :type      (member nil :noAutoCenter
                                                       :alertPositionParentWindow
                                                       :centerMainScreen
                                                       :staggerParentWindow
                                                       :alertPositionMainScreen
                                                       :centerParentWindowScreen
                                                       :staggerMainScreen
                                                       :alertPositionParentWindowScreen
                                                       :centerParentWindow
                                                       :staggerParentWindowScreen))
   (window-title                     :initform   "Untitled"
                                     :initarg    :window-title
                                     :reader     window-title)
   (visiblep                         :initform   t
                                     :initarg    :window-show
                                     :initarg    :visiblep
                                     :reader     window-visiblep
                                     :reader     window-shown-p)
   (colorp                           :initform   nil
                                     :initarg    :color-p
                                     :initarg    :colorp
                                     :reader     window-colorp)
   (close-box-p                      :initform   t
                                     :initarg   :close-box-p
                                     :reader     window-close-box-p)
   (grow-icon-p                      :initform   nil
                                     :initarg   :grow-icon-p
                                     :reader     window-grow-icon-p)
   (window-layer                     :initform   0
                                     :initarg   :window-layer
                                     :type       integer)
   (window-theme-background          :initform   nil                          
                                     :initarg    :theme-background 
                                     :accessor   window-theme-background 
                                     :accessor   theme-background)
   (window-prior-theme-drawing-state :initform   nil                          
                                     :accessor   window-prior-theme-drawing-state)
   (window-type                      :initform   :document-with-zoom
                                     :type       (member :document
                                                         :document-with-grow
                                                         :document-with-zoom
                                                         :double-edge-box
                                                         :single-edge-box
                                                         :shadow-edge-box
                                                         :tool)
                                     :accessor   window-type)
   (erase-anonymous-invalidations    :initform   t
                                     :initarg   :erase-anonymous-invalidations)))



(defmethod initialize-instance ((window window) &key (view-font (view-default-font window)) &allow-other-keys)
  (call-next-method)
  (setf (view-valid window) (list nil))
  (view-allocate-clip-region window)
  (when (and (slot-value window 'erase-anonymous-invalidations)
             (not (slot-value window 'theme-background)))
    ;; only needed for non-theme color background
    (setf (window-invalid-region window) (new-rgn)))
  (niy initialize-instance 'window window)
  (window-size-parts window)
  (when window-show
    (window-show window))
  window)


(defmethod print-object ((window window) stream)
  (print-unreadable-object (window stream :identity t :type t)
    (format stream "~S" (ignore-errors (window-title w))))
  window)


;;;---------------------------------------------------------------------


(defclass windoid (window)
  ((show-on-resume-p :initform nil))
  (:default-initargs :window-title "" :window-do-first-click t :window-type :windoid))


;;;---------------------------------------------------------------------


(define-condition view-error (simple-error)
  ((view :initarg :view :reader view-error-view))
  (:report (lambda (err stream)
             (format stream "~?"
                     (simple-condition-format-control err)
                     (simple-condition-format-arguments err)))))


(define-condition view-size-error (view-error)
  ((size :initarg :size :reader view-error-size)))


;;;; THE END ;;;;