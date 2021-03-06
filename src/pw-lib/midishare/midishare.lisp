;;;; -*- mode:lisp; coding:utf-8 -*-
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;  MidiShare-interface.lisp
;;
;;  Copyright (c) 1990, GRAME.  All rights reserved.
;;
;;  This file contains definitions for records and Pascal style routines, used
;;  for interfacing ACL with MidiShare 1.31, real-time multitasking Midi operating system.
;;  It is in conformity with MPW Pascal MidiShareUnit.p .
;;
;;  History :
;;  
;;   11-Nov-90, First version. -Yo-
;;   25-Nov-90, Ajoute def de TMidiSeq + FirstEv & LastEv -Yo-
;;   25-Nov-90, Continue changé en Cont -Yo-
;;   26-Nov-90, Modification de firstEv, lastEv, link,
;;              on ne pouvais pas ecrire par ex: (firstEv seq nil) qui était 
;;              confondu avec (firstEv seq)
;;   01-Dec-90, Ajout d'une macro DOEVENTS, analogue à DOLIST, pour parcourir
;;              une chaine d'événements.-Yo-
;;              Ajout des fonctions : Clock, typeName, name, fieldslist,
;;              printEv, printSeq. -Yo-
;;              Ajout des fonctions ou macro : pushevent, dupevents, delevents,
;;              mergeevents. -Yo-
;;   07-Dec-90, Correction de ProgChange. -Yo-
;;   12-Dec-90  Ajout de linkSE,linkST
;;-------------------------------------------------------------------------
;;   15-Dec-90  Nouvelle version de l'interface, restreinte aux seules
;;              fonctions de MidiShare et utilisant des macros. -Yo- 
;;   09-Jan-91  Ajout d'une variante info dans la description d'un événement et des
;;              fonctions d'accès associées.
;;   09-Jan-91  Ajout fonctions d'acces aux filtres
;;   14-Mai-91  Adaptation MCL 2.0b1
;;   19-Mai-91  Pb des ff-call. Enrobage par (Block nil ..)
;;   22-Mai-91  Changement de nom des macro d'accès aux filtres
;;   31-Mai-91  Ajout des "s", (eval-when () ...)
;;   18-Jul-91  Ajout de la fonction bend (de l'ancienne version de msh-interface)
;;   04-Aou-91  Toutes les macros d'acces transferées dans le fichier extension
;;   31-Oct-91  Modification de MidiForgetTask
;;-------------------------------------------------------------------------
;;   04-Dec-94  Suppression du package MidiShare !!!
;;		Suppression des (block nil ..)
;;-------------------------------------------------------------------------
;;   22-07-96   Adaptation pour MCL PPC 3.9 : Le fonctionnement de ff-call a change
;;		pour les fonctions Pascal, il ne faut plus pusher dans la pile la place
;;		pour le resultat !!!
;;   23-07-96   Integration du fichiers "0 - quit-actions.lisp" et d'une partie du 
;;		fichier "2 - MidiShare-Extension.lisp"

(defpackage "MIDISHARE" 
  (:use "COMMON-LISP")
  (:import-from "UI" "NIY")
  (:export "TYPENOTE" "TYPEKEYON" "TYPEKEYOFF" "TYPEKEYPRESS"
           "TYPECTRLCHANGE" "TYPEPROGCHANGE"  "TYPECHANPRESS"
           "TYPEPITCHWHEEL" "TYPESONGPOS" "TYPESONGSEL" "TYPECLOCK"
           "TYPESTART" "TYPECONTINUE" "TYPESTOP" "TYPETUNE"
           "TYPEACTIVESENS" "TYPERESET" "TYPESYSEX" "TYPESTREAM"
           "TYPEPRIVATE" "TYPEPROCESS" "TYPEDPROCESS" "TYPEQFRAME"
           "TYPERESERVED" "TYPEDEAD" "TYPECTRL14B" "TYPENONREGPARAM"
           "TYPEREGPARAM" "TYPESEQNUM" "TYPETEXT" "TYPECOPYRIGHT"
           "TYPESEQNAME" "TYPEINSTRNAME" "TYPELYRIC" "TYPEMARKER"
           "TYPECUEPOINT" "TYPECHANPREFIX"  "TYPEENDTRACK" "TYPETEMPO"
           "TYPESMPTEOFFSET" "TYPETIMESIGN" "TYPEKEYSIGN"
           "TYPESPECIFIC"
           
           "MIDIERRSPACE" "MIDIERRREFNUM" "MIDIERRBADTYPE"
           "MIDIERRINDEX"
           
           "MODEMPORT" "PRINTERPORT"
           
           "MIDIEXTERNALSYNC" "MIDISYNCANYPORT"  "SMPTE24FR"
           "SMPTE25FR" "SMPTE30DF" "SMPTE30FR"
           
           "MIDIOPENAPPL" "MIDICLOSEAPPL" "MIDICHGNAME"
           "MIDICHGCONNECT" "MIDIOPENMODEM" "MIDICLOSEMODEM"
           "MIDIOPENPRINTER" "MIDICLOSEPRINTER" "MIDISYNCSTART"
           "MIDISYNCSTOP" "MIDICHANGESYNC"
           
           "MIDIGETVERSION" "MIDICOUNTAPPLS" "MIDIGETINDAPPL"
           "MIDIGETNAMEDAPPL" "MIDIOPEN" "MIDICLOSE" "MIDIGETNAME"
           "MIDISETNAME" "MIDIGETINFO" "MIDISETINFO" "MIDIGETFILTER"
           "MIDISETFILTER" "MIDIGETRCVALARM" "MIDISETRCVALARM"
           "MIDIGETAPPLALARM" "MIDISETAPPLALARM" "MIDICONNECT"
           "MIDIISCONNECTED" "MIDIGETPORTSTATE" "MIDISETPORTSTATE"
           "MIDIFREESPACE" "MIDINEWEV" "MIDICOPYEV" "MIDIFREEEV"
           "MIDISETFIELD" "MIDIGETFIELD" "MIDIADDFIELD"
           "MIDICOUNTFIELDS" "MIDINEWSEQ" "MIDIADDSEQ" "MIDIFREESEQ"
           "MIDICLEARSEQ" "MIDIAPPLYSEQ" "MIDIGETTIME" "MIDISENDIM"
           "MIDISEND" "MIDISENDAT" "MIDICOUNTEVS" "MIDIGETEV"
           "MIDIAVAILEV" "MIDIFLUSHEVS" "MIDIREADSYNC" "MIDIWRITESYNC"
           "MIDICALL" "MIDITASK" "MIDIDTASK" "MIDIFORGETTASK"
           "MIDICOUNTDTASKS" "MIDIFLUSHDTASKS" "MIDIEXEC1DTASK"
           "MIDINEWCELL" "MIDIFREECELL" "MIDITOTALSPACE"
           "MIDIGROWSPACE" "MIDISHARE"

           "NULL-EVENT-P"
           "LINK" "DATE" "TYPE" "REF" "PORT" "CHAN" "XFIELD" "PITCH"
           "VEL" "DUR" "XFIELDS" "TEXT"  "FIRSTEV" "LASTEV"
           "FILTERBIT"  "ACCEPTPORT" "ACCEPTTYPE" "ACCEPTCHAN"))
(in-package :midishare)


(defmacro defrecord (name &rest slots)
  `(defstruct ,name ,@(mapcar (function first) slots)))



;;---------------------------------------------------------------------------------
;;---------------------------------------------------------------------------------
;;
;; 				MidiShare Data Structures
;;
;;---------------------------------------------------------------------------------
;;---------------------------------------------------------------------------------


;; Extension record for typeSysEx events

(defrecord TMidiSEX  
  (link (:pointer TMidiSEX))
  (data (:array :byte 12)))


;; Extension record for typePrivate, typeProcess and typeDProcess events

(defrecord TMidiST
    (ptr1 :pointer)
  (ptr2 :pointer)
  (ptr3 :pointer)
  (ptr4 :pointer))


;;---------------------------------------------------------------------------------
;; Common Record for all MidiShare events
;;---------------------------------------------------------------------------------

(defrecord TMidiEv
    (link (:pointer TMidiEv))
  (date :longint)
  (evtype :byte)
  (ref :byte)
  (port :byte)
  (chan :byte)
  (variant ((pitch :byte)
            (vel :byte)
            (dur :integer))
           ((data0 :byte)
            (data1 :byte)
            (data2 :byte)
            (data3 :byte))
           ((info :longint))
           ((linkSE (:pointer TMidiSEX)))
           ((linkST (:pointer TMidiST)))))


(defun null-event-p (ev)
  (null ev))

;;---------------------------------------------------------------------------------
;; Record for a MidiShare Sequence
;;---------------------------------------------------------------------------------

(defrecord TMidiSeq
    (first (:pointer TMidiEv))    ; first event
  (last (:pointer TMidiEv))     ; last event
  (undef1 :pointer)   
  (undef2 :pointer) )  


;;---------------------------------------------------------------------------------
;; Record for a MidiShare input filter
;;---------------------------------------------------------------------------------

(defrecord TFilter
    (port (string 63))     ; 256-bits
  (evType (string 63))   ; 256-bits
  (channel (string 1))   ;  16-bits
  (unused (string 1)))   ;  16-bits


;;---------------------------------------------------------------------------------
;; Record for MidiShare SMPTE synchronisation informations
;;---------------------------------------------------------------------------------

(defrecord TSyncInfo
    (time :longint)
  (reenter :longint)
  (syncMode :unsigned-short)
  (syncLocked :byte)
  (syncPort :byte)
  (syncStart :longint)
  (syncStop :longint)
  (syncOffset :longint)
  (syncSpeed :longint)
  (syncBreaks :longint)
  (syncFormat :short))


;;---------------------------------------------------------------------------------
;; Record for MidiShare SMPTE locations
;;---------------------------------------------------------------------------------

(defrecord TSmpteLocation
    (format :short)
  (hours :short)
  (minutes :short)
  (seconds :short)
  (frames :short)
  (fracs :short))


;;---------------------------------------------------------------------------------
;;---------------------------------------------------------------------------------
;;
;; 		Macros for accessing MidiShare Events data structures
;;
;;---------------------------------------------------------------------------------
;;---------------------------------------------------------------------------------

;;---------------------------------------------------------------------------------
;;                      Macros common to every type of event
;;---------------------------------------------------------------------------------


;;................................................................................: link
(defun link (e &optional (d nil d?))
  "read or set the link of an event"
  (niy link e d d?) #-(and)
  (if d?
      `(rset ,e :TMidiEv.link ,d)
      `(rref ,e :TMidiEv.link)))

;;................................................................................: date
(defun date (e &optional d)
  "read or set the date of an event"
  (niy date e d) #-(and)
  (if d
      `(rset ,e :TMidiEv.date ,d)
      `(rref ,e :TMidiEv.date)))

;;................................................................................: type
(defun type (e &optional v)
  "read or set the type of an event. Be careful in 
 modifying the type of an event"
  (niy type e v) #-(and)
  (if v
      `(rset ,e :TMidiEv.evType ,v)
      `(rref ,e :TMidiEv.evType)))

;;................................................................................: ref
(defun ref (e &optional v)
  "read or set the reference number of an event"
  (niy ref e v) #-(and)
  (if v
      `(rset ,e :TMidiEv.ref ,v)
      `(rref ,e :TMidiEv.ref)))

;;................................................................................: port
(defun port (e &optional v)
  "read or set the port number of an event"
  (niy port e v) #-(and)
  (if v
      `(rset ,e :TMidiEv.port ,v)
      `(rref ,e :TMidiEv.port)))

;;................................................................................: chan
(defun chan (e &optional v)
  "read or set the chan number of an event"
  (niy chan e v) #-(and)
  (if v
      `(rset ,e :TMidiEv.chan ,v)
      `(rref ,e :TMidiEv.chan)))

;;................................................................................: field
(defun field (e &optional f v)
  "give the number of fields or read or set a particular field of an event"
  (niy field e f v) #-(and)
  (if f
      (if v
          `(midiSetField ,e ,f ,v)
          `(midiGetField ,e ,f))
      `(midiCountFields ,e)))

;;................................................................................: fieldsList
(defun fieldsList (e &optional (n 4))
  "collect all the fields of an event into a list"
  (niy fieldlist e n) #-(and)
  (let (l)
    (dotimes (i (min n (midicountfields e)))
      (push (midigetfield e i) l))
    (nreverse l)))


;;---------------------------------------------------------------------------------
;;                         Specific to typeNote events
;;---------------------------------------------------------------------------------

;;................................................................................: pitch
(defun pitch (e &optional v)
  "read or set the pitch of an event"
  (niy pitch e v) #-(and)
  (if v
      `(rset ,e :TMidiEv.pitch ,v)
      `(rref ,e :TMidiEv.pitch)))

;;................................................................................: vel
(defun vel (e &optional v)
  "read or set the velocity of an event"
  (niy vel e v) #-(and)
  (if v
      `(rset ,e :TMidiEv.vel ,v)
      `(rref ,e :TMidiEv.vel)))

;;................................................................................: dur
(defun dur (e &optional v)
  "read or set the duration of an event"
  (niy dur e v) #-(and)
  (if v
      `(rset ,e :TMidiEv.dur ,v)
      `(rref ,e :TMidiEv.dur)))


;;---------------------------------------------------------------------------------
;;                        Specific to other types of events
;;---------------------------------------------------------------------------------

;;................................................................................: linkSE
(defun linkSE (e &optional (d nil d?))
  "read or set the link of an SEXevent "
  (niy linkse e d d?) #-(and)
  (if d?
      `(rset ,e :TMidiEv.linkSE ,d)
      `(rref ,e :TMidiEv.linkSE)))

;;................................................................................: linkST
(defun linkST (e &optional (d nil d?))
  "read or set the link of an STevent "
  (niy linkst e d d?) #-(and)
  (if d?
      `(rset ,e :TMidiEv.linkST ,d)
      `(rref ,e :TMidiEv.linkST)))


;;................................................................................: kpress
(defun kpress (e &optional v)
  (niy kpress e v) #-(and)
  (if v
      `(rset ,e :TMidiEv.vel ,v)
      `(rref ,e :TMidiEv.vel)))


;;................................................................................: ctrl
(defun ctrl (e &optional v)
  (niy ctrl e v) #-(and)
  (if v
      `(midisetfield ,e 0 ,v)
      `(midigetfield ,e 0)))


;;................................................................................: param
(defun param (e &optional v)
  (niy param e v) #-(and)
  (if v
      `(midisetfield ,e 0 ,v)
      `(midigetfield ,e 0)))


;;................................................................................: num
(defun num (e &optional v)
  (niy num e v) #-(and)
  (if v
      `(midisetfield ,e 0 ,v)
      `(midigetfield ,e 0)))


;;................................................................................: prefix
(defun prefix (e &optional v)
  (niy prefix e v) #-(and)
  (if v
      `(midisetfield ,e 0 ,v)
      `(midigetfield ,e 0)))


;;................................................................................: tempo
(defun tempo (e &optional v)
  (niy tempo e v) #-(and)
  (if v
      `(midisetfield ,e 0 ,v)
      `(midigetfield ,e 0)))


;;................................................................................: seconds
(defun seconds (e &optional v)
  (niy seconds e v) #-(and)
  (if v
      `(midisetfield ,e 0 ,v)
      `(midigetfield ,e 0)))


;;................................................................................: subframes
(defun subframes (e &optional v)
  (niy subframes e v) #-(and)
  (if v
      `(midisetfield ,e 1 ,v)
      `(midigetfield ,e 1)))


;;................................................................................: val
(defun val (e &optional v)
  (niy val e v) #-(and)
  (if v
      `(midisetfield ,e 1 ,v)
      `(midigetfield ,e 1)))


;;................................................................................: pgm
(defun pgm (e &optional v)
  (niy pgm e v) #-(and)
  (if v
      `(rset ,e :TMidiEv.pitch ,v)
      `(rref ,e :TMidiEv.pitch)))


;;................................................................................: bend
(defun bend (e &optional v)
  "read or set the bend value of an event"
  (niy bend e v) #-(and)
  (if v
      `(multiple-value-bind (ms7b ls7b) (floor (+ ,v 8192) 128)
         (rset ,e :TMidiEv.pitch ls7b)
         (rset ,e :TMidiEv.vel ms7b))
      `(- (+ (rref ,e :TMidiEv.pitch) (* 128 (rref ,e :TMidiEv.vel))) 8192)))


;;................................................................................: clk
(defun clk (e &optional v)
  (niy clk e v) #-(and)
  (if v
      `(multiple-value-bind (ms7b ls7b) (floor (round (/ ,v 6)) 128)
         (rset ,e :TMidiEv.pitch ls7b)
         (rset ,e :TMidiEv.vel ms7b))
      `(* 6 (+ (pitch ,e) (* 128 (vel ,e)))) ))


;;................................................................................: song
(defun song (e &optional v)
  (niy song e v) #-(and)
  (if v
      `(rset ,e :TMidiEv.pitch ,v)
      `(rref ,e :TMidiEv.pitch)))


;;................................................................................: fields
(defun fields (e &optional v)
  (niy fields e v) #-(and)
  (if v
      `(let ((e ,e)) (mapc (lambda (f) (midiaddfield e f)) ,v))
      `(let (l (e ,e))  (dotimes (i (midicountfields e)) (push (midigetfield e i) l)) (nreverse l)) ))


;;................................................................................: text
(defun text (e &optional s)
  (niy text e s) #-(and)
  (if s
      `(fields ,e (map 'list #'char-code ,s))
      `(map 'string #'character (fields ,e)) ))


;;................................................................................: fmsg
(defun fmsg (e &optional v)
  (niy fmsg e v) #-(and)
  (if v
      `(rset ,e :TMidiEv.pitch ,v)
      `(rref ,e :TMidiEv.pitch)))

;;................................................................................: fcount
(defun fcount (e &optional v)
  (niy fcount e v) #-(and)
  (if v
      `(rset ,e :TMidiEv.vel ,v)
      `(rref ,e :TMidiEv.vel)))

;;................................................................................: tsnum
(defun tsnum (e &optional v)
  (niy tsnum e v) #-(and)
  (if v
      `(midisetfield ,e 0 ,v)
      `(midigetfield ,e 0)))


;;................................................................................: tsdenom
(defun tsdenom (e &optional v)
  (niy tsdenom e v) #-(and)
  (if v
      `(midisetfield ,e 1 ,v)
      `(midigetfield ,e 1)))


;;................................................................................: tsclick
(defun tsclick (e &optional v)
  (niy tsclick e v) #-(and)
  (if v
      `(midisetfield ,e 2 ,v)
      `(midigetfield ,e 2)))


;;................................................................................: tsquarter
(defun tsquarter (e &optional v)
  (niy tsquarter e v) #-(and)
  (if v
      `(midisetfield ,e 3 ,v)
      `(midigetfield ,e 3)))

;;................................................................................: alteration
(defun alteration (e &optional v)
  (niy alteratio e v) #-(and)
  (if v
      `(midisetfield ,e 0 ,v)
      `(midigetfield ,e 0)))

;;................................................................................: minor-scale
(defun minor-scale (e &optional v)
  (niy minor-scale e v) #-(and)
  (if v
      `(midisetfield ,e 1 (if ,v 1 0))
      `(= 1 (midigetfield ,e 1))))

;;................................................................................: info
(defun info (e &optional d)
  "read or set the info of an event"
  (niy info e d) #-(and)
  (if d
      `(rset ,e :TMidiEv.info ,d)
      `(rref ,e :TMidiEv.info)))



;;---------------------------------------------------------------------------------
;;---------------------------------------------------------------------------------
;;
;; 		Macros for accessing MidiShare Sequences data structures
;;
;;---------------------------------------------------------------------------------
;;---------------------------------------------------------------------------------

;;................................................................................: firstEv
(defun firstEv (s &optional (e nil e?))
  "read or set the first event of a sequence"
  (niy firstev s e e?) #-(and)
  (if e?
      `(rset ,s :TMidiSeq.first ,e)
      `(rref ,s :TMidiSeq.first)))

;;................................................................................: lastEv
(defun lastEv (s &optional (e nil e?))
  "read or set the last event of a sequence"
  (niy lastev s e e?) #-(and)
  (if e?
      `(rset ,s :TMidiSeq.last ,e)
      `(rref ,s :TMidiSeq.last)))


;;---------------------------------------------------------------------------------
;;---------------------------------------------------------------------------------
;;
;; 		Macros for accessing MidiShare Filters
;;
;;---------------------------------------------------------------------------------
;;---------------------------------------------------------------------------------

;;................................................................................: FilterBit
(defun FilterBit (p n &optional (val nil val?))
  (niy filterbit p n val val?) #-(and)
  (if val?
      (%put-byte p (if val 
                       (logior (%get-byte p (ash n -3)) (ash 1 (logand n 7)))
                       (logandc2 (%get-byte p (ash n -3)) (ash 1 (logand n 7))) )
                 (ash n -3))
      (logbitp (logand n 7) (%get-byte p (ash n -3)))))

;;................................................................................: AcceptPort
(defun AcceptPort (f p &rest s)
  (niy acceptport f p s) #-(and)
  `(filterBit ,f ,p ,@s))

;;................................................................................: AcceptType
(defun AcceptType (f p &rest s)
  (niy accepttype f p s) #-(and)
  `(filterBit (%inc-ptr ,f 32) ,p ,@s))

;;................................................................................: AcceptChan
(defun AcceptChan (f p &rest s)
  (niy acceptchan f p s) #-(and)
  `(filterBit (%inc-ptr ,f 64) ,p ,@s))




;;---------------------------------------------------------------------------------
;;---------------------------------------------------------------------------------
;;
;; 				MidiShare Constant Definitions
;;
;;---------------------------------------------------------------------------------
;;---------------------------------------------------------------------------------


;; Constant definition for every type of MidiShare events

(defconstant typeNote 0          "a note with pitch, velocity and duration")
(defconstant typeKeyOn 1         "a key on with pitch and velocity")
(defconstant typeKeyOff 2        "a key off with pitch and velocity")
(defconstant typeKeyPress 3      "a key pressure with pitch and pressure value")
(defconstant typeCtrlChange 4    "a control change with control number and control value")
(defconstant typeProgChange 5    "a program change with program number")
(defconstant typeChanPress 6     "a channel pressure with pressure value")
(defconstant typePitchWheel 7    "a pitch bender with lsb and msb of the 14-bit value")
(defconstant typePitchBend 7     "a pitch bender with lsb and msb of the 14-bit value")
(defconstant typeSongPos 8       "a song position with lsb and msb of the 14-bit position")
(defconstant typeSongSel 9       "a song selection with a song number")
(defconstant typeClock 10        "a clock request (no argument)")
(defconstant typeStart 11        "a start request (no argument)")
(defconstant typeContinue 12     "a continue request (no argument)")
(defconstant typeStop 13         "a stop request (no argument)")
(defconstant typeTune 14         "a tune request (no argument)")
(defconstant typeActiveSens 15   "an active sensing code (no argument)")
(defconstant typeReset 16        "a reset request (no argument)")
(defconstant typeSysEx 17        "a system exclusive with any number of data bytes. Leading $F0 and tailing $F7 are automatically supplied by MidiShare and MUST NOT be included by the user")
(defconstant typeStream 18       "a special event with any number of data and status bytes sended without any processing")
(defconstant typePrivate 19      "a private event for internal use with 4 32-bits arguments")
(defconstant typeProcess 128     "an interrupt level task with a function adress and 3 32-bits arguments")
(defconstant typeDProcess 129    "a foreground level task with a function adress and 3 32-bits arguments")
(defconstant typeQFrame 130      "a quarter frame message with a type from 0 to 7 and a value")


(defconstant typeCtrl14b	131)
(defconstant typeNonRegParam	132)
(defconstant typeRegParam	133)

(defconstant typeSeqNum		134)
(defconstant typeText		135)
(defconstant typeCopyright	136)
(defconstant typeSeqName	137)
(defconstant typeInstrName	138)
(defconstant typeLyric		139)
(defconstant typeMarker		140)
(defconstant typeCuePoint	141)
(defconstant typeChanPrefix	142)
(defconstant typeEndTrack	143)
(defconstant typeTempo		144)
(defconstant typeSMPTEOffset	145)

(defconstant typeTimeSign	146)
(defconstant typeKeySign	147)
(defconstant typeSpecific	148)

(defconstant typeReserved 149    "events reserved for futur use")
(defconstant typedead 255        "a dead task. Used by MidiShare to forget and inactivate typeProcess and typeDProcess tasks")


;; Constant definition for every MidiShare error code

(defconstant MIDIerrSpace -1	 "too many applications")
(defconstant MIDIerrRefNum -2	 "bad reference number")
(defconstant MIDIerrBadType -3   "bad event type")
(defconstant MIDIerrIndex -4	 "bad index")


;; Constant definition for the Macintosh serial ports

(defconstant ModemPort 0	 "Macintosh modem port")
(defconstant PrinterPort 1	 "Macintosh printer port")


;; Constant definition for the synchronisation modes

(defconstant MidiExternalSync #x8000	 "Bit-15 set for external synchronisation")
(defconstant MidiSyncAnyPort #x4000	 "Bit-14 set for synchronisation on any port")


;; Constant definition for SMPTE frame format

(defconstant smpte24fr 0	 	"24 frame/sec")
(defconstant smpte25fr 1	 	"25 frame/sec")
(defconstant smpte29fr 2	 	"29 frame/sec (30 drop frame)")
(defconstant smpte30fr 3	 	"30 frame/sec")


;; Constant definition for MidiShare world changes

(defconstant MIDIOpenAppl 1      "an application was opened")
(defconstant MIDICloseAppl 2     "an application was closed")
(defconstant MIDIChgName 3       "an application name was changed")
(defconstant MIDIChgConnect 4    "a connection was changed")
(defconstant MIDIOpenModem 5     "Modem port was opened")
(defconstant MIDICloseModem 6    "Modem port was closed")
(defconstant MIDIOpenPrinter 7   "Printer port was opened")
(defconstant MIDIClosePrinter 8  "Printer port was closed")
(defconstant MIDISyncStart 9     "SMPTE synchronisation just start")
(defconstant MIDISyncStop 10     "SMPTE synchronisation just stop")





;;---------------------------------------------------------------------------------
;;---------------------------------------------------------------------------------
;;
;; 				MidiShare Entry Points
;;
;;---------------------------------------------------------------------------------
;;---------------------------------------------------------------------------------

;; Interface description for a MidiShare PROCEDURE 
;; with a word and a pointer parameter
;;  (ff-call *midiShare* :word <arg1> :ptr <arg2> :d0 <MidiShare routine #>)
;;
;; Interface description for a MidiShare FUNCTION (previous to MCL PPC 3.9)
;; with a word and a pointer parameter and a pointer result
;;  (ff-call *midiShare*  :ptr (%null-ptr) :word <arg1> :ptr <arg2> :d0 <MidiShare routine #> :ptr)
;;
;; Interface description for a MidiShare FUNCTION (with MCL PPC 3.9) 
;; with a word and a pointer parameter and a pointer result
;;  (ff-call *midiShare* :word <arg1> :ptr <arg2> :d0 <MidiShare routine #> :ptr)
;;


;; Entry point of MidiShare (setup at boot time by the "MidiShare" init)

(defvar *midiShare* nil)

;;---------------------------------------------------------------------------------
;;			To Know about MidiShare and Active Sessions
;;---------------------------------------------------------------------------------

;;................................................................................: MidiShare
(defun MidiShare ()
  "returns true if MidiShare is installed"
  (niy MidiShare)
  nil)

;;................................................................................: MidiGetVersion
(defun MidiGetVersion ()
  "Give MidiShare version as a fixnum. For example 131 as result, means : version 1.31"
  (niy MidiGetVersion)
  0)

;;................................................................................: MidiCountAppls
(defun MidiCountAppls ()
  "Give the number of MidiShare applications currently opened"
  (niy MidiCountAppls)
  0)

;;................................................................................: MidiGetIndAppl
(defun MidiGetIndAppl (index)
  "Give the reference number of a MidiShare application from its index, a fixnum
 between 1 and (MidiCountAppls)"
  (niy MidiGetIndAppl index)
  1)

;;................................................................................: MidiGetNamedAppl
(defun MidiGetNamedAppl (name)
  "Give the reference number of a MidiShare application from its name"
  (niy MidiGetNamedAppl name)
  0)

;;---------------------------------------------------------------------------------
;;			To Open and Close a MidiShare session
;;---------------------------------------------------------------------------------

;;................................................................................: MidiOpen
(defun MidiOpen (name)
  "Open a new MidiShare application, with name name. Give a unique reference number."
  (niy MidiOpen name)
  0)

;;................................................................................: MidiClose
(defun MidiClose (refNum)
  "Close an opened MidiShare application from its reference number"
  (niy MidiClose refNum)
  (values))


;;---------------------------------------------------------------------------------
;;			To Configure a MidiShare session
;;---------------------------------------------------------------------------------

;;................................................................................: MidiGetName
(defun MidiGetName (refNum)
  "Give the name of a MidiShare application from its reference number"
  (niy MidiGetName refNum)
  "Untitled")

;;................................................................................: MidiSetName
(defun MidiSetName (refNum name)
  "Change the name of a MidiShare application"
  (niy MidiSetName refNum name)
  (values))

;;................................................................................: MidiGetInfo
(defun MidiGetInfo (refNum)
  "Give the 32-bits user defined content of the info field of a MidiShare application. 
 Analogous to window's refcon."
  (niy MidiGetInfo refNum)
  0)

;;................................................................................: MidiSetInfo
(defun MidiSetInfo (refNum p)
  "Set the 32-bits user defined content of the info field of a MidiShare application. 
 Analogous to window's refcon."
  (niy MidiSetInfo refNum p)
  (values))

;;................................................................................: MidiGetFilter
(defun MidiGetFilter (refNum)
  "Give a pointer to the input filter record of a MidiShare application. 
 Give NIL if no filter is installed"
  (niy MidiGetFilter refNum)
  nil)

;;................................................................................: MidiSetFilter
(defun MidiSetFilter (refNum p)
  "Install an input filter. The argument p is a pointer to a filter record."
  (niy MidiSetFilter refNum p)
  (values))

;;................................................................................: MidiGetRcvAlarm
(defun MidiGetRcvAlarm (refNum)
  "Get the adress of the receive alarm"
  (niy MidiGetRcvAlarm refNum)
  0)

;;................................................................................: MidiSetRcvAlarm
(defun MidiSetRcvAlarm (refNum alarm)
  "Install a receive alarm"
  (niy MidiSetRcvAlarm refNum alarm)
  (values))

;;................................................................................: MidiGetApplAlarm
(defun MidiGetApplAlarm (refNum)
  "Get the adress of the context alarm"
  (niy MidiGetApplAlarm refNum)
  0)

;;................................................................................: MidiSetApplAlarm
(defun MidiSetApplAlarm (refNum alarm)
  "Install a context alarm"
  (niy MidiSetApplAlarm refNum alarm)
  (values))

;;---------------------------------------------------------------------------------
;;			To Manage MidiShare IAC and Midi Ports
;;---------------------------------------------------------------------------------

;;................................................................................: MidiConnect
(defun MidiConnect (src dst state)
  "Connect or disconnect two MidiShare applications"
  (niy MidiConnect src dst state)
  (values))

;;................................................................................: MidiIsConnected
(defun MidiIsConnected (src dst)
  "Test if two MidiShare applications are connected"
  (niy MidiIsConnected src dst)
  nil)

;;................................................................................: MidiGetPortState
(defun MidiGetPortState (port)
  "Give the state : open or closed, of a MidiPort"
  (niy MidiGetPortState port)
  nil)

;;................................................................................: MidiSetPortState
(defun MidiSetPortState (port state)
  "Open or close a MidiPort"
  (niy MidiSetPortState port state)
  (values))

;;---------------------------------------------------------------------------------
;;			To Manage MidiShare events
;;---------------------------------------------------------------------------------

;;................................................................................: MidiFreeSpace
(defun MidiFreeSpace ()
  "Amount of free MidiShare cells"
  (niy MidiFreeSpace)
  0)

;;................................................................................: MidiNewEv
(defun MidiNewEv (typeNum)
  "Allocate a new MidiEvent"
  (niy MidiNewEv typenum)
  nil)

;;................................................................................: MidiCopyEv
(defun MidiCopyEv (ev)
  "Duplicate a MidiEvent"
  (niy MidiCopyEv ev)
  nil)

;;................................................................................: MidiFreeEv
(defun MidiFreeEv (ev)
  "Free a MidiEvent"
  (niy MidiFreeEv ev)
  (values))


;;................................................................................: MidiSetField
(defun MidiSetField (ev field val)
  "Set a field of a MidiEvent"
  (niy MidiSetField ev field val)
  (values))

;;................................................................................: MidiGetField
(defun MidiGetField (ev field)
  "Get a field of a MidiEvent"
  (niy MidiGetField ev field)
  nil)

;;................................................................................: MidiAddField
(defun MidiAddField (ev val)
  "Append a field to a MidiEvent (only for sysex and stream)"
  (niy MidiAddField ev val)
  (values))

;;................................................................................: MidiCountFields
(defun MidiCountFields (ev)
  "The number of fields of a MidiEvent"
  (niy MidiCountFields ev)
  0)

;;---------------------------------------------------------------------------------
;;			To Manage MidiShare Sequences
;;---------------------------------------------------------------------------------

;;................................................................................: MidiNewSeq
(defun MidiNewSeq ()
  "Allocate an empty sequence"
  (niy MidiNewSeq)
  nil)

;;................................................................................: MidiAddSeq
(defun MidiAddSeq (seq ev)
  "Add an event to a sequence"
  (niy MidiAddSeq seq ev)
  nil)

;;................................................................................: MidiFreeSeq
(defun MidiFreeSeq (seq)
  "Free a sequence and its content"
  (niy MidiFreeSeq seq)
  (values))

;;................................................................................: MidiClearSeq
(defun MidiClearSeq (seq)
  "Free only the content of a sequence. The sequence become empty"
  (niy MidiClearSeq seq)
  (values))

;;................................................................................: MidiApplySeq
(defun MidiApplySeq (seq proc)
  "Call a function for every events of a sequence"
  (niy MidiApplySeq seq proc)
  (values))

;;---------------------------------------------------------------------------------
;;				   MidiShare Time
;;---------------------------------------------------------------------------------

;;................................................................................: MidiGetTime
(defconstant tick (/ internal-time-units-per-second 60))

(defun MidiGetTime ()
  "give the current time"
  (niy MidiGetTime)
  `(/ (get-internal-run-time) tick))

;;---------------------------------------------------------------------------------
;;				To Send MidiShare events
;;---------------------------------------------------------------------------------

;;................................................................................: MidiSendIm
(defun MidiSendIm (refNum ev)
  "send an event now"
  (niy MidiSendIm refnum ev)
  (values))

;;................................................................................: MidiSend
(defun MidiSend (refNum ev)
  "send an event using its own date"
  (niy MidiSend refnum ev)
  (values))

;;................................................................................: MidiSendAt
(defun MidiSendAt (refNum ev date)
  "send an event at date <date>"
  (niy MidiSendAt refnum ev date)
  (values))

;;---------------------------------------------------------------------------------
;;                            To Receive MidiShare Events
;;---------------------------------------------------------------------------------

;;................................................................................: MidiCountEvs
(defun MidiCountEvs (refNum)
  "Give the number of events waiting in the reception fifo"
  (niy MidiCountEvs refnum)
  0)

;;................................................................................: MidiGetEv
(defun MidiGetEv (refNum)
  "Read an event from the reception fifo"
  (niy MidiGetEv refnum)
  nil)

;;................................................................................: MidiAvailEv
(defun MidiAvailEv (refNum)
  "Get a pointer to the first event in the reception fifo without removing it"
  (niy MidiAvailEv refnum)
  nil)

;;................................................................................: MidiFlushEvs
(defun MidiFlushEvs (refNum)
  "Delete all the events waiting in the reception fifo"
  (niy MidiFlushEvs refnum)
  (values))

;;---------------------------------------------------------------------------------
;;                             To access shared data
;;---------------------------------------------------------------------------------

;;................................................................................: MidiReadSync
(defun MidiReadSync (adrMem)
  "Read and clear a memory address (not-interruptible)"
  (niy MidiReadSync adrmem)
  0)

;;................................................................................: MidiWriteSync
(defun MidiWriteSync (adrMem val)
  "write if nil into a memory address (not-interruptible)"
  (niy MidiWriteSync adrmem val)
  (values))

;;---------------------------------------------------------------------------------
;;                               Realtime Tasks
;;---------------------------------------------------------------------------------

;;................................................................................: MidiCall
(defun MidiCall (proc date refNum arg1 arg2 arg3)
  "Call the routine <proc> at date <date> with arguments <arg1> <arg2> <arg3>"
  (niy MidiCall proc date refNum arg1 arg2 arg3)
  (values))

;;................................................................................: MidiTask
(defun MidiTask (proc date refNum arg1 arg2 arg3)
  "Call the routine <proc> at date <date> with arguments <arg1> <arg2> <arg3>. 
 Return a pointer to the corresponding typeProcess event"
  (niy MidiTask proc date refNum arg1 arg2 arg3)
  nil)

;;................................................................................: MidiDTask
(defun MidiDTask (proc date refNum arg1 arg2 arg3)
  "Call the routine <proc> at date <date> with arguments <arg1> <arg2> <arg3>. 
 Return a pointer to the corresponding typeDProcess event"
  (niy MidiDTask proc date refNum arg1 arg2 arg3)
  nil)

;;................................................................................: MidiForgetTaskHdl
(defun MidiForgetTaskHdl (thdl)
  "Forget a previously scheduled typeProcess or typeDProcess event created by MidiTask or MidiDTask"
  (niy MidiForgetTaskHdl thdl)
  (values))

;;................................................................................: MidiForgetTask
(defun MidiForgetTask (ev)
  "Forget a previously scheduled typeProcess or typeDProcess event created by MidiTask or MidiDTask"
  (niy MidiForgetTask ev)
  (values))

;;................................................................................: MidiCountDTasks
(defun MidiCountDTasks (refNum)
  "Give the number of typeDProcess events waiting"
  (niy MidiCountDTasks refnum)
  0)

;;................................................................................: MidiFlushDTasks
(defun MidiFlushDTasks (refNum)
  "Remove all the typeDProcess events waiting"
  (niy MidiFlushDTasks refnum)
  (values))

;;................................................................................: MidiExec1DTask
(defun MidiExec1DTask (refNum)
  "Call the next typeDProcess waiting"
  (niy MidiExec1DTask refnum)
  (values))

;;---------------------------------------------------------------------------------
;;                        Low Level MidiShare Memory Management
;;---------------------------------------------------------------------------------

;;................................................................................: MidiNewCell
(defun MidiNewCell ()
  "Allocate a basic Cell"
  nil)

;;................................................................................: MidiFreeCell
(defun MidiFreeCell (cell)
  "Delete a basic Cell"
  (niy MidiNewCell cell)
  (values))

;;................................................................................: MidiTotalSpace
(defun MidiTotalSpace ()
  "Total amount of Cells"
  0)

;;................................................................................: MidiGrowSpace
(defun MidiGrowSpace ()
  "Total amount of Cells"
  0)


;;---------------------------------------------------------------------------------
;;                        SMPTE Synchronisation functions
;;---------------------------------------------------------------------------------

;;................................................................................: MidiGetSyncInfo
(defun MidiGetSyncInfo (syncInfo)
  "Fill syncInfo with current synchronisation informations"
  (niy MidiTotalSpace syncInfo)
  (values))

;;................................................................................: MidiSetSyncMode
(defun MidiSetSyncMode (mode)
  "set the MidiShare synchroniation mode"
  (niy MidiSetSyncMode mode)
  (values))

;;................................................................................: MidiGetExtTime
(defun MidiGetExtTime ()
  "give the current external time"
  `(/ (get-internal-run-time) tick))

;;................................................................................: MidiInt2ExtTime
(defun MidiInt2ExtTime (time)
  "convert internal time to external time"
  (niy MidiInt2ExtTime time)
  time)

;;................................................................................: MidiExt2IntTime
(defun MidiExt2IntTime (time)
  "convert internal time to external time"
  (niy MidiExt2IntTime time)
  time)

;;................................................................................: MidiTime2Smpte
(defun MidiTime2Smpte (time format smpteLocation)
  "convert time to Smpte location"
  (niy MidiGetExtTime format smpteLocation)
  time)

;;................................................................................: MidiSmpte2Time
(defun MidiSmpte2Time (smpteLocation)
  "convert time to Smpte location"
  (niy MidiSmpte2Time smpteLocation)
  smpteLocation)






;; (eval-when (:compile-toplevel :load-toplevel :execute)
;;   (let (#+ccl(ccl:*warn-if-redefine* nil))
;;     (require :ff)))
;; 
;; (defmacro defrecord (&rest args) (declare (ignorable args)) (ui:uiwarn "ff defrecord stub"))
;; 
;; 
;; 
;; ;;---------------------------------------------------------------------------------
;; ;;
;; ;; 				Utilities
;; ;;
;; ;;---------------------------------------------------------------------------------
;; 
;; (defun %%get-string (ps) 
;;   "Same as %get-string but work with mac non-zone pointers"
;;   (let (name count)
;;     (setq count (%get-byte ps))
;;     (setq name (make-string count))  
;;     (dotimes (i count)
;;       (setq ps (%inc-ptr ps 1))
;;       (setf (aref name i) (coerce (%get-byte ps) 'character)))
;;     name))
;; 
;; ;; For bug (?) in MCL PPC 3.9 when returning signed word
;; 
;; (defun %%unsigned-to-signed-word (w)
;;   "convert an unsigned word to a signed word"
;;   (if (< w 32768) w (- w 65536)))
;; 
;; (defun %%word-high-byte (w)
;;   "most significant byte of a word"
;;   (ash w -8))
;; 
;; 
;; ;;---------------------------------------------------------------------------------
;; ;;---------------------------------------------------------------------------------
;; ;;
;; ;; 				MidiShare Data Structures
;; ;;
;; ;;---------------------------------------------------------------------------------
;; ;;---------------------------------------------------------------------------------
;; 
;; 
;; ;; Extension record for typeSysEx events
;; 
;; (defrecord TMidiSEX  
;;     (link (:pointer TMidiSEX))
;;   (data (:array :byte 12)))
;; 
;; 
;; ;; Extension record for typePrivate, typeProcess and typeDProcess events
;; 
;; (defrecord TMidiST
;;     (ptr1 :pointer)
;;   (ptr2 :pointer)
;;   (ptr3 :pointer)
;;   (ptr4 :pointer))
;; 
;; 
;; ;;---------------------------------------------------------------------------------
;; ;; Common Record for all MidiShare events
;; ;;---------------------------------------------------------------------------------
;; 
;; (defrecord TMidiEv
;;     (link (:pointer TMidiEv))
;;   (date :longint)
;;   (evtype :byte)
;;   (ref :byte)
;;   (port :byte)
;;   (chan :byte)
;;   (variant ((pitch :byte)
;;             (vel :byte)
;;             (dur :integer))
;;            ((data0 :byte)
;;             (data1 :byte)
;;             (data2 :byte)
;;             (data3 :byte))
;;            ((info :longint))
;;            ((linkSE (:pointer TMidiSEX)))
;;            ((linkST (:pointer TMidiST)))))
;; 
;; 
;; ;;---------------------------------------------------------------------------------
;; ;; Record for a MidiShare Sequence
;; ;;---------------------------------------------------------------------------------
;; 
;; (defrecord TMidiSeq
;;     (first (:pointer TMidiEv))    ; first event
;;   (last (:pointer TMidiEv))     ; last event
;;   (undef1 :pointer)   
;;   (undef2 :pointer) )  
;; 
;; 
;; ;;---------------------------------------------------------------------------------
;; ;; Record for a MidiShare input filter
;; ;;---------------------------------------------------------------------------------
;; 
;; (defrecord TFilter
;;     (port (string 63))     ; 256-bits
;;   (evType (string 63))   ; 256-bits
;;   (channel (string 1))   ;  16-bits
;;   (unused (string 1)))   ;  16-bits
;; 
;; 
;; ;;---------------------------------------------------------------------------------
;; ;; Record for MidiShare SMPTE synchronisation informations
;; ;;---------------------------------------------------------------------------------
;; 
;; (defrecord TSyncInfo
;;     (time :longint)
;;   (reenter :longint)
;;   (syncMode :unsigned-short)
;;   (syncLocked :byte)
;;   (syncPort :byte)
;;   (syncStart :longint)
;;   (syncStop :longint)
;;   (syncOffset :longint)
;;   (syncSpeed :longint)
;;   (syncBreaks :longint)
;;   (syncFormat :short))
;; 
;; 
;; ;;---------------------------------------------------------------------------------
;; ;; Record for MidiShare SMPTE locations
;; ;;---------------------------------------------------------------------------------
;; 
;; (defrecord TSmpteLocation
;;     (format :short)
;;   (hours :short)
;;   (minutes :short)
;;   (seconds :short)
;;   (frames :short)
;;   (fracs :short))
;; 
;; 
;; ;;---------------------------------------------------------------------------------
;; ;;---------------------------------------------------------------------------------
;; ;;
;; ;; 		Macros for accessing MidiShare Events data structures
;; ;;
;; ;;---------------------------------------------------------------------------------
;; ;;---------------------------------------------------------------------------------
;; 
;; ;;---------------------------------------------------------------------------------
;; ;;                      Macros common to every type of event
;; ;;---------------------------------------------------------------------------------
;; 
;; ;;................................................................................: link
;; (defmacro link (e &optional (d nil d?))
;;   "read or set the link of an event"
;;   (if d?
;;       `(rset ,e :TMidiEv.link ,d)
;;       `(rref ,e :TMidiEv.link)))
;; 
;; ;;................................................................................: date
;; (defmacro date (e &optional d)
;;   "read or set the date of an event"
;;   (if d
;;       `(rset ,e :TMidiEv.date ,d)
;;       `(rref ,e :TMidiEv.date)))
;; 
;; ;;................................................................................: type
;; (defmacro type (e &optional v)
;;   "read or set the type of an event. Be careful in 
;; modifying the type of an event"
;;   (if v
;;       `(rset ,e :TMidiEv.evType ,v)
;;       `(rref ,e :TMidiEv.evType)))
;; 
;; ;;................................................................................: ref
;; (defmacro ref (e &optional v)
;;   "read or set the reference number of an event"
;;   (if v
;;       `(rset ,e :TMidiEv.ref ,v)
;;       `(rref ,e :TMidiEv.ref)))
;; 
;; ;;................................................................................: port
;; (defmacro port (e &optional v)
;;   "read or set the port number of an event"
;;   (if v
;;       `(rset ,e :TMidiEv.port ,v)
;;       `(rref ,e :TMidiEv.port)))
;; 
;; ;;................................................................................: chan
;; (defmacro chan (e &optional v)
;;   "read or set the chan number of an event"
;;   (if v
;;       `(rset ,e :TMidiEv.chan ,v)
;;       `(rref ,e :TMidiEv.chan)))
;; 
;; ;;................................................................................: field
;; (defmacro field (e &optional f v)
;;   "give the number of fields or read or set a particular field of an event"
;;   (if f
;;       (if v
;;           `(midiSetField ,e ,f ,v)
;;           `(midiGetField ,e ,f))
;;       `(midiCountFields ,e)))
;; 
;; ;;................................................................................: fieldsList
;; (defun fieldsList (e &optional (n 4))
;;   "collect all the fields of an event into a list"
;;   (let (l)
;;     (dotimes (i (min n (midicountfields e)))
;;       (push (midigetfield e i) l))
;;     (nreverse l)))
;; 
;; 
;; ;;---------------------------------------------------------------------------------
;; ;;                         Specific to typeNote events
;; ;;---------------------------------------------------------------------------------
;; 
;; ;;................................................................................: pitch
;; (defmacro pitch (e &optional v)
;;   "read or set the pitch of an event"
;;   (if v
;;       `(rset ,e :TMidiEv.pitch ,v)
;;       `(rref ,e :TMidiEv.pitch)))
;; 
;; ;;................................................................................: vel
;; (defmacro vel (e &optional v)
;;   "read or set the velocity of an event"
;;   (if v
;;       `(rset ,e :TMidiEv.vel ,v)
;;       `(rref ,e :TMidiEv.vel)))
;; 
;; ;;................................................................................: dur
;; (defmacro dur (e &optional v)
;;   "read or set the duration of an event"
;;   (if v
;;       `(rset ,e :TMidiEv.dur ,v)
;;       `(rref ,e :TMidiEv.dur)))
;; 
;; 
;; ;;---------------------------------------------------------------------------------
;; ;;                        Specific to other types of events
;; ;;---------------------------------------------------------------------------------
;; 
;; ;;................................................................................: linkSE
;; (defmacro linkSE (e &optional (d nil d?))
;;   "read or set the link of an SEXevent "
;;   (if d?
;;       `(rset ,e :TMidiEv.linkSE ,d)
;;       `(rref ,e :TMidiEv.linkSE)))
;; 
;; ;;................................................................................: linkST
;; (defmacro linkST (e &optional (d nil d?))
;;   "read or set the link of an STevent "
;;   (if d?
;;       `(rset ,e :TMidiEv.linkST ,d)
;;       `(rref ,e :TMidiEv.linkST)))
;; 
;; 
;; ;;................................................................................: kpress
;; (defmacro kpress (e &optional v)
;;   (if v
;;       `(rset ,e :TMidiEv.vel ,v)
;;       `(rref ,e :TMidiEv.vel)))
;; 
;; 
;; ;;................................................................................: ctrl
;; (defmacro ctrl (e &optional v)
;;   (if v
;;       `(midisetfield ,e 0 ,v)
;;       `(midigetfield ,e 0)))
;; 
;; 
;; ;;................................................................................: param
;; (defmacro param (e &optional v)
;;   (if v
;;       `(midisetfield ,e 0 ,v)
;;       `(midigetfield ,e 0)))
;; 
;; 
;; ;;................................................................................: num
;; (defmacro num (e &optional v)
;;   (if v
;;       `(midisetfield ,e 0 ,v)
;;       `(midigetfield ,e 0)))
;; 
;; 
;; ;;................................................................................: prefix
;; (defmacro prefix (e &optional v)
;;   (if v
;;       `(midisetfield ,e 0 ,v)
;;       `(midigetfield ,e 0)))
;; 
;; 
;; ;;................................................................................: tempo
;; (defmacro tempo (e &optional v)
;;   (if v
;;       `(midisetfield ,e 0 ,v)
;;       `(midigetfield ,e 0)))
;; 
;; 
;; ;;................................................................................: seconds
;; (defmacro seconds (e &optional v)
;;   (if v
;;       `(midisetfield ,e 0 ,v)
;;       `(midigetfield ,e 0)))
;; 
;; 
;; ;;................................................................................: subframes
;; (defmacro subframes (e &optional v)
;;   (if v
;;       `(midisetfield ,e 1 ,v)
;;       `(midigetfield ,e 1)))
;; 
;; 
;; ;;................................................................................: val
;; (defmacro val (e &optional v)
;;   (if v
;;       `(midisetfield ,e 1 ,v)
;;       `(midigetfield ,e 1)))
;; 
;; 
;; ;;................................................................................: pgm
;; (defmacro pgm (e &optional v)
;;   (if v
;;       `(rset ,e :TMidiEv.pitch ,v)
;;       `(rref ,e :TMidiEv.pitch)))
;; 
;; 
;; ;;................................................................................: bend
;; (defmacro bend (e &optional v)
;;   "read or set the bend value of an event"
;;   (if v
;;       `(multiple-value-bind (ms7b ls7b) (floor (+ ,v 8192) 128)
;;          (rset ,e :TMidiEv.pitch ls7b)
;;          (rset ,e :TMidiEv.vel ms7b))
;;       `(- (+ (rref ,e :TMidiEv.pitch) (* 128 (rref ,e :TMidiEv.vel))) 8192)))
;; 
;; 
;; ;;................................................................................: clk
;; (defmacro clk (e &optional v)
;;   (if v
;;       `(multiple-value-bind (ms7b ls7b) (floor (round (/ ,v 6)) 128)
;;          (rset ,e :TMidiEv.pitch ls7b)
;;          (rset ,e :TMidiEv.vel ms7b))
;;       `(* 6 (+ (pitch ,e) (* 128 (vel ,e)))) ))
;; 
;; 
;; ;;................................................................................: song
;; (defmacro song (e &optional v)
;;   (if v
;;       `(rset ,e :TMidiEv.pitch ,v)
;;       `(rref ,e :TMidiEv.pitch)))
;; 
;; 
;; ;;................................................................................: fields
;; (defmacro fields (e &optional v)
;;   (if v
;;       `(let ((e ,e)) (mapc (lambda (f) (midiaddfield e f)) ,v))
;;       `(let (l (e ,e))  (dotimes (i (midicountfields e)) (push (midigetfield e i) l)) (nreverse l)) ))
;; 
;; 
;; ;;................................................................................: text
;; (defmacro text (e &optional s)
;;   (if s
;;       `(fields ,e (map 'list #'char-code ,s))
;;       `(map 'string #'character (fields ,e)) ))
;; 
;; 
;; ;;................................................................................: fmsg
;; (defmacro fmsg (e &optional v)
;;   (if v
;;       `(rset ,e :TMidiEv.pitch ,v)
;;       `(rref ,e :TMidiEv.pitch)))
;; 
;; ;;................................................................................: fcount
;; (defmacro fcount (e &optional v)
;;   (if v
;;       `(rset ,e :TMidiEv.vel ,v)
;;       `(rref ,e :TMidiEv.vel)))
;; 
;; ;;................................................................................: tsnum
;; (defmacro tsnum (e &optional v)
;;   (if v
;;       `(midisetfield ,e 0 ,v)
;;       `(midigetfield ,e 0)))
;; 
;; 
;; ;;................................................................................: tsdenom
;; (defmacro tsdenom (e &optional v)
;;   (if v
;;       `(midisetfield ,e 1 ,v)
;;       `(midigetfield ,e 1)))
;; 
;; 
;; ;;................................................................................: tsclick
;; (defmacro tsclick (e &optional v)
;;   (if v
;;       `(midisetfield ,e 2 ,v)
;;       `(midigetfield ,e 2)))
;; 
;; 
;; ;;................................................................................: tsquarter
;; (defmacro tsquarter (e &optional v)
;;   (if v
;;       `(midisetfield ,e 3 ,v)
;;       `(midigetfield ,e 3)))
;; 
;; ;;................................................................................: alteration
;; (defmacro alteration (e &optional v)
;;   (if v
;;       `(midisetfield ,e 0 ,v)
;;       `(midigetfield ,e 0)))
;; 
;; ;;................................................................................: minor-scale
;; (defmacro minor-scale (e &optional v)
;;   (if v
;;       `(midisetfield ,e 1 (if ,v 1 0))
;;       `(= 1 (midigetfield ,e 1))))
;; 
;; ;;................................................................................: info
;; (defmacro info (e &optional d)
;;   "read or set the info of an event"
;;   (if d
;;       `(rset ,e :TMidiEv.info ,d)
;;       `(rref ,e :TMidiEv.info)))
;; 
;; 
;; 
;; ;;---------------------------------------------------------------------------------
;; ;;---------------------------------------------------------------------------------
;; ;;
;; ;; 		Macros for accessing MidiShare Sequences data structures
;; ;;
;; ;;---------------------------------------------------------------------------------
;; ;;---------------------------------------------------------------------------------
;; 
;; ;;................................................................................: firstEv
;; (defmacro firstEv (s &optional (e nil e?))
;;   "read or set the first event of a sequence"
;;   (if e?
;;       `(rset ,s :TMidiSeq.first ,e)
;;       `(rref ,s :TMidiSeq.first)))
;; 
;; ;;................................................................................: lastEv
;; (defmacro lastEv (s &optional (e nil e?))
;;   "read or set the last event of a sequence"
;;   (if e?
;;       `(rset ,s :TMidiSeq.last ,e)
;;       `(rref ,s :TMidiSeq.last)))
;; 
;; 
;; ;;---------------------------------------------------------------------------------
;; ;;---------------------------------------------------------------------------------
;; ;;
;; ;; 		Macros for accessing MidiShare Filters
;; ;;
;; ;;---------------------------------------------------------------------------------
;; ;;---------------------------------------------------------------------------------
;; 
;; ;;................................................................................: FilterBit
;; (defun FilterBit (p n &optional (val nil val?))
;;   (if val?
;;       (%put-byte p (if val 
;;                        (logior (%get-byte p (ash n -3)) (ash 1 (logand n 7)))
;;                        (logandc2 (%get-byte p (ash n -3)) (ash 1 (logand n 7))) )
;;                  (ash n -3))
;;       (logbitp (logand n 7) (%get-byte p (ash n -3)))))
;; 
;; ;;................................................................................: AcceptPort
;; (defmacro AcceptPort (f p &rest s)
;;   `(filterBit ,f ,p ,@s))
;; 
;; ;;................................................................................: AcceptType
;; (defmacro AcceptType (f p &rest s)
;;   `(filterBit (%inc-ptr ,f 32) ,p ,@s))
;; 
;; ;;................................................................................: AcceptChan
;; (defmacro AcceptChan (f p &rest s)
;;   `(filterBit (%inc-ptr ,f 64) ,p ,@s))
;; 
;; 
;; 
;; ;;---------------------------------------------------------------------------------
;; ;;---------------------------------------------------------------------------------
;; ;;
;; ;; 				MidiShare Constant Definitions
;; ;;
;; ;;---------------------------------------------------------------------------------
;; ;;---------------------------------------------------------------------------------
;; 
;; 
;; ;; Constant definition for every type of MidiShare events
;; 
;; (defconstant typeNote 0          "a note with pitch, velocity and duration")
;; (defconstant typeKeyOn 1         "a key on with pitch and velocity")
;; (defconstant typeKeyOff 2        "a key off with pitch and velocity")
;; (defconstant typeKeyPress 3      "a key pressure with pitch and pressure value")
;; (defconstant typeCtrlChange 4    "a control change with control number and control value")
;; (defconstant typeProgChange 5    "a program change with program number")
;; (defconstant typeChanPress 6     "a channel pressure with pressure value")
;; (defconstant typePitchWheel 7    "a pitch bender with lsb and msb of the 14-bit value")
;; (defconstant typePitchBend 7     "a pitch bender with lsb and msb of the 14-bit value")
;; (defconstant typeSongPos 8       "a song position with lsb and msb of the 14-bit position")
;; (defconstant typeSongSel 9       "a song selection with a song number")
;; (defconstant typeClock 10        "a clock request (no argument)")
;; (defconstant typeStart 11        "a start request (no argument)")
;; (defconstant typeContinue 12     "a continue request (no argument)")
;; (defconstant typeStop 13         "a stop request (no argument)")
;; (defconstant typeTune 14         "a tune request (no argument)")
;; (defconstant typeActiveSens 15   "an active sensing code (no argument)")
;; (defconstant typeReset 16        "a reset request (no argument)")
;; (defconstant typeSysEx 17        "a system exclusive with any number of data bytes. Leading $F0 and tailing $F7 are automatically supplied by MidiShare and MUST NOT be included by the user")
;; (defconstant typeStream 18       "a special event with any number of data and status bytes sended without any processing")
;; (defconstant typePrivate 19      "a private event for internal use with 4 32-bits arguments")
;; (defconstant typeProcess 128     "an interrupt level task with a function adress and 3 32-bits arguments")
;; (defconstant typeDProcess 129    "a foreground level task with a function adress and 3 32-bits arguments")
;; (defconstant typeQFrame 130      "a quarter frame message with a type from 0 to 7 and a value")
;; 
;; 
;; (defconstant typeCtrl14b	131)
;; (defconstant typeNonRegParam	132)
;; (defconstant typeRegParam	133)
;; 
;; (defconstant typeSeqNum		134)
;; (defconstant typeText		135)
;; (defconstant typeCopyright	136)
;; (defconstant typeSeqName	137)
;; (defconstant typeInstrName	138)
;; (defconstant typeLyric		139)
;; (defconstant typeMarker		140)
;; (defconstant typeCuePoint	141)
;; (defconstant typeChanPrefix	142)
;; (defconstant typeEndTrack	143)
;; (defconstant typeTempo		144)
;; (defconstant typeSMPTEOffset	145)
;; 
;; (defconstant typeTimeSign	146)
;; (defconstant typeKeySign	147)
;; (defconstant typeSpecific	148)
;; 
;; (defconstant typeReserved 149    "events reserved for futur use")
;; (defconstant typedead 255        "a dead task. Used by MidiShare to forget and inactivate typeProcess and typeDProcess tasks")
;; 
;; 
;; ;; Constant definition for every MidiShare error code
;; 
;; (defconstant MIDIerrSpace -1	 "too many applications")
;; (defconstant MIDIerrRefNum -2	 "bad reference number")
;; (defconstant MIDIerrBadType -3   "bad event type")
;; (defconstant MIDIerrIndex -4	 "bad index")
;; 
;; 
;; ;; Constant definition for the Macintosh serial ports
;; 
;; (defconstant ModemPort 0	 "Macintosh modem port")
;; (defconstant PrinterPort 1	 "Macintosh printer port")
;; 
;; 
;; ;; Constant definition for the synchronisation modes
;; 
;; (defconstant MidiExternalSync #x8000	 "Bit-15 set for external synchronisation")
;; (defconstant MidiSyncAnyPort #x4000	 "Bit-14 set for synchronisation on any port")
;; 
;; 
;; ;; Constant definition for SMPTE frame format
;; 
;; (defconstant smpte24fr 0	 	"24 frame/sec")
;; (defconstant smpte25fr 1	 	"25 frame/sec")
;; (defconstant smpte29fr 2	 	"29 frame/sec (30 drop frame)")
;; (defconstant smpte30fr 3	 	"30 frame/sec")
;; 
;; 
;; ;; Constant definition for MidiShare world changes
;; 
;; (defconstant MIDIOpenAppl 1      "an application was opened")
;; (defconstant MIDICloseAppl 2     "an application was closed")
;; (defconstant MIDIChgName 3       "an application name was changed")
;; (defconstant MIDIChgConnect 4    "a connection was changed")
;; (defconstant MIDIOpenModem 5     "Modem port was opened")
;; (defconstant MIDICloseModem 6    "Modem port was closed")
;; (defconstant MIDIOpenPrinter 7   "Printer port was opened")
;; (defconstant MIDIClosePrinter 8  "Printer port was closed")
;; (defconstant MIDISyncStart 9     "SMPTE synchronisation just start")
;; (defconstant MIDISyncStop 10     "SMPTE synchronisation just stop")
;; 
;; 
;; 
;; ;;---------------------------------------------------------------------------------
;; ;;---------------------------------------------------------------------------------
;; ;;
;; ;; 				MidiShare Entry Points
;; ;;
;; ;;---------------------------------------------------------------------------------
;; ;;---------------------------------------------------------------------------------
;; 
;; ;; Interface description for a MidiShare PROCEDURE 
;; ;; with a word and a pointer parameter
;; ;;  (ff-call *midiShare* :word <arg1> :ptr <arg2> :d0 <MidiShare routine #>)
;; ;;
;; ;; Interface description for a MidiShare FUNCTION (previous to MCL PPC 3.9)
;; ;; with a word and a pointer parameter and a pointer result
;; ;;  (ff-call *midiShare*  :ptr (%null-ptr) :word <arg1> :ptr <arg2> :d0 <MidiShare routine #> :ptr)
;; ;;
;; ;; Interface description for a MidiShare FUNCTION (with MCL PPC 3.9) 
;; ;; with a word and a pointer parameter and a pointer result
;; ;;  (ff-call *midiShare* :word <arg1> :ptr <arg2> :d0 <MidiShare routine #> :ptr)
;; ;;
;; 
;; 
;; ;; Entry point of MidiShare (setup at boot time by the "MidiShare" init)
;; 
;; (defvar *midiShare*)
;; 
;; ;;---------------------------------------------------------------------------------
;; ;;			To Know about MidiShare and Active Sessions
;; ;;---------------------------------------------------------------------------------
;; 
;; 
;; ;;................................................................................: MidiShare
;; (defun MidiShare ()
;;   "returns true if MidiShare is installed"
;;   (and (= (%get-word *midiShare*) #xD080)
;;        (= (%get-word *midiShare* 2) #xD080)))
;; 
;; ;;................................................................................: MidiGetVersion
;; (defmacro MidiGetVersion ()
;;   "Give MidiShare version as a fixnum. For example 131 as result, means : version 1.31"
;;   `(ff-call *midiShare* :d0 0 :word))
;; 
;; ;;................................................................................: MidiCountAppls
;; (defmacro MidiCountAppls ()
;;   "Give the number of MidiShare applications currently opened"
;;   `(ff-call *midiShare* :d0 1 :word))
;; 
;; ;;................................................................................: MidiGetIndAppl
;; (defmacro MidiGetIndAppl (index)
;;   "Give the reference number of a MidiShare application from its index, a fixnum
;; between 1 and (MidiCountAppls)"
;;   `(%%unsigned-to-signed-word (ff-call *midiShare* :word ,index :d0 2 :word)))
;; 
;; ;;................................................................................: MidiGetNamedAppl
;; (defmacro MidiGetNamedAppl (name)
;;   "Give the reference number of a MidiShare application from its name"
;;   `(with-pstrs ((s ,name))
;;      (%%unsigned-to-signed-word (ff-call *midiShare* :ptr s :d0 3 :word))))
;; 
;; ;;---------------------------------------------------------------------------------
;; ;;			To Open and Close a MidiShare session
;; ;;---------------------------------------------------------------------------------
;; 
;; ;;................................................................................: MidiOpen
;; (defmacro MidiOpen (name)
;;   "Open a new MidiShare application, with name name. Give a unique reference number."
;;   `(with-pstrs ((s ,name))
;;      (%%unsigned-to-signed-word (ff-call *midiShare* :ptr s :d0 4 :word))))
;; 
;; ;;................................................................................: MidiClose
;; (defmacro MidiClose (refNum)
;;   "Close an opened MidiShare application from its reference number"
;;   `(ff-call *midiShare* :word ,refNum :d0 5))
;; 
;; 
;; ;;---------------------------------------------------------------------------------
;; ;;			To Configure a MidiShare session
;; ;;---------------------------------------------------------------------------------
;; 
;; ;;................................................................................: MidiGetName
;; (defmacro MidiGetName (refNum)
;;   "Give the name of a MidiShare application from its reference number"
;;   `(%%get-string (ff-call *midiShare* :word ,refNum :d0 6 :ptr)))
;; 
;; ;;................................................................................: MidiSetName
;; (defmacro MidiSetName (refNum name)
;;   "Change the name of a MidiShare application"
;;   `(with-pstrs ((s ,name))
;;      (ff-call *midiShare* :word ,refNum :ptr s :d0 7 )))
;; 
;; ;;................................................................................: MidiGetInfo
;; (defmacro MidiGetInfo (refNum)
;;   "Give the 32-bits user defined content of the info field of a MidiShare application. 
;; Analogous to window's refcon."
;;   `(ff-call *midiShare* :word ,refNum :d0 8 :ptr))
;; 
;; ;;................................................................................: MidiSetInfo
;; (defmacro MidiSetInfo (refNum p)
;;   "Set the 32-bits user defined content of the info field of a MidiShare application. 
;; Analogous to window's refcon."
;;   `(ff-call *midiShare* :word ,refNum :ptr ,p :d0 9))
;; 
;; ;;................................................................................: MidiGetFilter
;; (defmacro MidiGetFilter (refNum)
;;   "Give a pointer to the input filter record of a MidiShare application. 
;; Give NIL if no filter is installed"
;;   `(ff-call *midiShare* :word ,refNum :d0 10 :ptr))
;; 
;; ;;................................................................................: MidiSetFilter
;; (defmacro MidiSetFilter (refNum p)
;;   "Install an input filter. The argument p is a pointer to a filter record."
;;   `(ff-call *midiShare* :word ,refNum :ptr ,p :d0 11))
;; 
;; ;;................................................................................: MidiGetRcvAlarm
;; (defmacro MidiGetRcvAlarm (refNum)
;;   "Get the adress of the receive alarm"
;;   `(ff-call *midiShare* :word ,refNum :d0 #x0C :ptr))
;; 
;; ;;................................................................................: MidiSetRcvAlarm
;; (defmacro MidiSetRcvAlarm (refNum alarm)
;;   "Install a receive alarm"
;;   `(ff-call *midiShare* :word ,refNum :ptr ,alarm :d0 #x0D))
;; 
;; ;;................................................................................: MidiGetApplAlarm
;; (defmacro MidiGetApplAlarm (refNum)
;;   "Get the adress of the context alarm"
;;   `(ff-call *midiShare* :word ,refNum :d0 #x0E :ptr))
;; 
;; ;;................................................................................: MidiSetApplAlarm
;; (defmacro MidiSetApplAlarm (refNum alarm)
;;   "Install a context alarm"
;;   `(ff-call *midiShare* :word ,refNum :ptr ,alarm :d0 #x0F))
;; 
;; ;;---------------------------------------------------------------------------------
;; ;;			To Manage MidiShare IAC and Midi Ports
;; ;;---------------------------------------------------------------------------------
;; 
;; ;;................................................................................: MidiConnect
;; (defmacro MidiConnect (src dst state)
;;   "Connect or disconnect two MidiShare applications"
;;   `(ff-call *midiShare* :word ,src :word ,dst :word (if ,state -1 0) :d0 #x10))
;; 
;; ;;................................................................................: MidiIsConnected
;; (defmacro MidiIsConnected (src dst)
;;   "Test if two MidiShare applications are connected"
;;   `(not (eq 0 (ff-call *midiShare* :word ,src :word ,dst :d0 #x11 :word))))
;; 
;; ;;................................................................................: MidiGetPortState
;; (defmacro MidiGetPortState (port)
;;   "Give the state : open or closed, of a MidiPort"
;;   `(not (eq 0 (%%word-high-byte (ff-call *midiShare* :word ,port :d0 #x12 :word)))))
;; 
;; ;;................................................................................: MidiSetPortState
;; (defmacro MidiSetPortState (port state)
;;   "Open or close a MidiPort"
;;   `(ff-call *midiShare* :word ,port :word (if ,state -1 0) :d0 #x13))
;; 
;; ;;---------------------------------------------------------------------------------
;; ;;			To Manage MidiShare events
;; ;;---------------------------------------------------------------------------------
;; 
;; ;;................................................................................: MidiFreeSpace
;; (defmacro MidiFreeSpace ()
;;   "Amount of free MidiShare cells"
;;   `(ff-call *midiShare* :d0 #x14 :long))
;; 
;; ;;................................................................................: MidiNewEv
;; (defmacro MidiNewEv (typeNum)
;;   "Allocate a new MidiEvent"
;;   `(ff-call *midiShare* :word ,typeNum :d0 #x15 :ptr))
;; 
;; ;;................................................................................: MidiCopyEv
;; (defmacro MidiCopyEv (ev)
;;   "Duplicate a MidiEvent"
;;   `(ff-call *midiShare* :ptr ,ev :d0 #x16 :ptr))
;; 
;; ;;................................................................................: MidiFreeEv
;; (defmacro MidiFreeEv (ev)
;;   "Free a MidiEvent"
;;   `(ff-call *midiShare* :ptr ,ev :d0 #x17))
;; 
;; 
;; ;;................................................................................: MidiSetField
;; (defmacro MidiSetField (ev field val)
;;   "Set a field of a MidiEvent"
;;   `(ff-call *midiShare* :ptr ,ev :long ,field :long ,val :d0 #x3A))
;; 
;; ;;................................................................................: MidiGetField
;; (defmacro MidiGetField (ev field)
;;   "Get a field of a MidiEvent"
;;   `(ff-call *midiShare* :ptr ,ev :long ,field :d0 #x3B :long))
;; 
;; ;;................................................................................: MidiAddField
;; (defmacro MidiAddField (ev val)
;;   "Append a field to a MidiEvent (only for sysex and stream)"
;;   `(ff-call *midiShare* :ptr ,ev :long ,val :d0 #x1A))
;; 
;; ;;................................................................................: MidiCountFields
;; (defmacro MidiCountFields (ev)
;;   "The number of fields of a MidiEvent"
;;   `(ff-call *midiShare* :ptr ,ev :d0 #x3C :long))
;; 
;; ;;---------------------------------------------------------------------------------
;; ;;			To Manage MidiShare Sequences
;; ;;---------------------------------------------------------------------------------
;; 
;; ;;................................................................................: MidiNewSeq
;; (defmacro MidiNewSeq ()
;;   "Allocate an empty sequence"
;;   `(ff-call *midiShare* :d0 #x1D :ptr))
;; 
;; ;;................................................................................: MidiAddSeq
;; (defmacro MidiAddSeq (seq ev)
;;   "Add an event to a sequence"
;;   `(ff-call *midiShare* :ptr ,seq :ptr ,ev :d0 #x1E))
;; 
;; ;;................................................................................: MidiFreeSeq
;; (defmacro MidiFreeSeq (seq)
;;   "Free a sequence and its content"
;;   `(ff-call *midiShare* :ptr ,seq :d0 #x1F))
;; 
;; ;;................................................................................: MidiClearSeq
;; (defmacro MidiClearSeq (seq)
;;   "Free only the content of a sequence. The sequence become empty"
;;   `(ff-call *midiShare* :ptr ,seq :d0 #x20))
;; 
;; ;;................................................................................: MidiApplySeq
;; (defmacro MidiApplySeq (seq proc)
;;   "Call a function for every events of a sequence"
;;   `(ff-call *midiShare* :ptr ,seq :ptr ,proc :d0 #x21))
;; 
;; ;;---------------------------------------------------------------------------------
;; ;;				   MidiShare Time
;; ;;---------------------------------------------------------------------------------
;; 
;; ;;................................................................................: MidiGetTime
;; (defmacro MidiGetTime ()
;;   "give the current time"
;;   `(ff-call *midiShare* :d0 #x22 :long))
;; 
;; ;;---------------------------------------------------------------------------------
;; ;;				To Send MidiShare events
;; ;;---------------------------------------------------------------------------------
;; 
;; ;;................................................................................: MidiSendIm
;; (defmacro MidiSendIm (refNum ev)
;;   "send an event now"
;;   `(ff-call *midiShare* :word ,refNum :ptr ,ev :d0 #x23))
;; 
;; ;;................................................................................: MidiSend
;; (defmacro MidiSend (refNum ev)
;;   "send an event using its own date"
;;   `(ff-call *midiShare* :word ,refNum :ptr ,ev :d0 #x24))
;; 
;; ;;................................................................................: MidiSendAt
;; (defmacro MidiSendAt (refNum ev date)
;;   "send an event at date <date>"
;;   `(ff-call *midiShare* :word ,refNum :ptr ,ev :long ,date :d0 #x25))
;; 
;; ;;---------------------------------------------------------------------------------
;; ;;                            To Receive MidiShare Events
;; ;;---------------------------------------------------------------------------------
;; 
;; ;;................................................................................: MidiCountEvs
;; (defmacro MidiCountEvs (refNum)
;;   "Give the number of events waiting in the reception fifo"
;;   `(ff-call *midiShare* :word ,refNum :d0 #x26 :long))
;; 
;; ;;................................................................................: MidiGetEv
;; (defmacro MidiGetEv (refNum)
;;   "Read an event from the reception fifo"
;;   `(ff-call *midiShare* :word ,refNum :d0 #x27 :ptr))
;; 
;; ;;................................................................................: MidiAvailEv
;; (defmacro MidiAvailEv (refNum)
;;   "Get a pointer to the first event in the reception fifo without removing it"
;;   `(ff-call *midiShare* :word ,refNum :d0 #x28 :ptr))
;; 
;; ;;................................................................................: MidiFlushEvs
;; (defmacro MidiFlushEvs (refNum)
;;   "Delete all the events waiting in the reception fifo"
;;   `(ff-call *midiShare* :word ,refNum :d0 #x29))
;; 
;; ;;---------------------------------------------------------------------------------
;; ;;                             To access shared data
;; ;;---------------------------------------------------------------------------------
;; 
;; ;;................................................................................: MidiReadSync
;; (defmacro MidiReadSync (adrMem)
;;   "Read and clear a memory address (not-interruptible)"
;;   `(ff-call *midiShare* :ptr ,adrMem :d0 #x2A :ptr))
;; 
;; ;;................................................................................: MidiWriteSync
;; (defmacro MidiWriteSync (adrMem val)
;;   "write if nil into a memory address (not-interruptible)"
;;   `(ff-call *midiShare* :ptr ,adrMem :ptr ,val :d0 #x2B :ptr))
;; 
;; ;;---------------------------------------------------------------------------------
;; ;;                               Realtime Tasks
;; ;;---------------------------------------------------------------------------------
;; 
;; ;;................................................................................: MidiCall
;; (defmacro MidiCall (proc date refNum arg1 arg2 arg3)
;;   "Call the routine <proc> at date <date> with arguments <arg1> <arg2> <arg3>"
;;   `(ff-call *midiShare* :ptr ,proc :long ,date :word ,refNum :long ,arg1 :long ,arg2 :long ,arg3 :d0 #x2C))
;; 
;; ;;................................................................................: MidiTask
;; (defmacro MidiTask (proc date refNum arg1 arg2 arg3)
;;   "Call the routine <proc> at date <date> with arguments <arg1> <arg2> <arg3>. 
;; Return a pointer to the corresponding typeProcess event"
;;   `(ff-call *midiShare* :ptr ,proc :long ,date :word ,refNum :long ,arg1 :long ,arg2 :long ,arg3 :d0 #x2D :ptr))
;; 
;; ;;................................................................................: MidiDTask
;; (defmacro MidiDTask (proc date refNum arg1 arg2 arg3)
;;   "Call the routine <proc> at date <date> with arguments <arg1> <arg2> <arg3>. 
;; Return a pointer to the corresponding typeDProcess event"
;;   `(ff-call *midiShare* :ptr ,proc :long ,date :word ,refNum :long ,arg1 :long ,arg2 :long ,arg3 :d0 #x2E :ptr))
;; 
;; ;;................................................................................: MidiForgetTaskHdl
;; (defmacro MidiForgetTaskHdl (thdl)
;;   "Forget a previously scheduled typeProcess or typeDProcess event created by MidiTask or MidiDTask"
;;   `(ff-call *midiShare* :ptr ,thdl :d0 #x2F))
;; 
;; ;;................................................................................: MidiForgetTask
;; (defmacro MidiForgetTask (ev)
;;   "Forget a previously scheduled typeProcess or typeDProcess event created by MidiTask or MidiDTask"
;;   `(without-interrupts 
;;        (%stack-block ((taskptr 4))
;;                      (%setf-macptr taskptr ,ev) (midiforgetTaskHdl taskptr))))
;; 
;; ;;................................................................................: MidiCountDTasks
;; (defmacro MidiCountDTasks (refNum)
;;   "Give the number of typeDProcess events waiting"
;;   `(ff-call *midiShare* :word ,refNum :d0 #x30 :long))
;; 
;; ;;................................................................................: MidiFlushDTasks
;; (defmacro MidiFlushDTasks (refNum)
;;   "Remove all the typeDProcess events waiting"
;;   `(ff-call *midiShare* :word ,refNum :d0 #x31))
;; 
;; ;;................................................................................: MidiExec1DTask
;; (defmacro MidiExec1DTask (refNum)
;;   "Call the next typeDProcess waiting"
;;   `(ff-call *midiShare* :word ,refNum :d0 #x32))
;; 
;; ;;---------------------------------------------------------------------------------
;; ;;                        Low Level MidiShare Memory Management
;; ;;---------------------------------------------------------------------------------
;; 
;; ;;................................................................................: MidiNewCell
;; (defmacro MidiNewCell ()
;;   "Allocate a basic Cell"
;;   `(ff-call *midiShare* :d0 #x33 :ptr))
;; 
;; ;;................................................................................: MidiFreeCell
;; (defmacro MidiFreeCell (cell)
;;   "Delete a basic Cell"
;;   `(ff-call *midiShare* :ptr ,cell :d0 #x34))
;; 
;; ;;................................................................................: MidiTotalSpace
;; (defmacro MidiTotalSpace ()
;;   "Total amount of Cells"
;;   `(ff-call *midiShare* :d0 #x35 :long))
;; 
;; ;;................................................................................: MidiGrowSpace
;; (defmacro MidiGrowSpace (n)
;;   "Total amount of Cells"
;;   `(ff-call *midiShare* :long ,n :d0 #x36 :long))
;; 
;; 
;; ;;---------------------------------------------------------------------------------
;; ;;                        SMPTE Synchronisation functions
;; ;;---------------------------------------------------------------------------------
;; 
;; ;;................................................................................: MidiGetSyncInfo
;; (defmacro MidiGetSyncInfo (syncInfo)
;;   "Fill syncInfo with current synchronisation informations"
;;   `(ff-call *midiShare* :ptr ,syncInfo :d0 #x38))
;; 
;; ;;................................................................................: MidiSetSyncMode
;; (defmacro MidiSetSyncMode (mode)
;;   "set the MidiShare synchroniation mode"
;;   `(ff-call *midiShare* :word ,mode :d0 #x39))
;; 
;; ;;................................................................................: MidiGetExtTime
;; (defmacro MidiGetExtTime ()
;;   "give the current external time"
;;   `(ff-call *midiShare* :d0 #x3D :long))
;; 
;; ;;................................................................................: MidiInt2ExtTime
;; (defmacro MidiInt2ExtTime (time)
;;   "convert internal time to external time"
;;   `(ff-call *midiShare* :long ,time :d0 #x3E :long))
;; 
;; ;;................................................................................: MidiExt2IntTime
;; (defmacro MidiExt2IntTime (time)
;;   "convert internal time to external time"
;;   `(ff-call *midiShare* :long ,time :d0 #x3F :long))
;; 
;; ;;................................................................................: MidiTime2Smpte
;; (defmacro MidiTime2Smpte (time format smpteLocation)
;;   "convert time to Smpte location"
;;   `(ff-call *midiShare* :long ,time :word ,format :ptr ,smpteLocation :d0 #x40))
;; 
;; ;;................................................................................: MidiSmpte2Time
;; (defmacro MidiSmpte2Time (smpteLocation)
;;   "convert time to Smpte location"
;;   `(ff-call *midiShare* :ptr ,smpteLocation :d0 #x41 :long))
;; 
;; 
;; 
;; ;;---------------------------------------------------------------------------------
;; ;;---------------------------------------------------------------------------------
;; ;;
;; ;; 			To Install and Remove the MidiShare Interface
;; ;;
;; ;;---------------------------------------------------------------------------------
;; ;;---------------------------------------------------------------------------------
;; 
;; 
;; (defun install-midishare-interface ()
;;   (unless (midishare) 
;;     (print "MidiShare not installed. PatchWork cannot play or record Midi.")))
;; 
;; (defun remove-midishare-interface ()
;;   (setq *midiShare* nil))
;; 
;; ;;---------------------------------------------------------------------------------
;; ;; 	 			**Evaluate this**
;; ;;---------------------------------------------------------------------------------
;; 
;; 
;; (eval-when (:load-toplevel :execute)
;;   (on-load-and-now start-midi-share
;;                    (setf *midishare* (%get-ptr (%int-to-ptr #xB8))))
;;   (on-startup install-midishare-interface)
;;   (on-quit    remove-midishare-interface)
;;   (install-midishare-interface))




;;---------------------------------------------------------------------------------
;;---------------------------------------------------------------------------------
;;
;; 			To Install and Remove the MidiShare Interface
;;
;;---------------------------------------------------------------------------------
;;---------------------------------------------------------------------------------


(defun install-midishare-interface ()
  (unless (midishare) 
    (print "MidiShare not installed. PatchWork cannot play or record Midi.")))

(defun remove-midishare-interface ()
  (setq *midiShare* nil))

;;---------------------------------------------------------------------------------
;; 	 			**Evaluate this**
;;---------------------------------------------------------------------------------


;; (eval-when (:load-toplevel :execute)
;;   (on-load-and-now start-midi-share
;;                    (setf *midishare* (%get-ptr (%int-to-ptr #xB8))))
;;   (on-startup install-midishare-interface)
;;   (on-quit    remove-midishare-interface)
;;   (install-midishare-interface))

