; *******************************************************************
; *** This software is copyright 2004 by Michael H Riley          ***
; *** You have permission to use, modify, copy, and distribute    ***
; *** this software so long as this copyright notice is retained. ***
; *** This software may not be used in commercial applications    ***
; *** without express written permission from the author.         ***
; *******************************************************************

include    bios.inc
include    kernel.inc

           org     8000h
           lbr     0ff00h
           db      'patch',0
           dw      9000h
           dw      endrom+7000h
           dw      2000h
           dw      endrom-2000h
           dw      2000h
           db      0

           org     2000h
           br      start

include    date.inc
include    build.inc
           db      'Written by Michael H. Riley',0

start:     ghi     ra                  ; copy argument address to rf
           phi     rf
           glo     ra
           plo     rf
loop1:     lda     rf                  ; look for first less <= space
           smi     33
           lbdf    loop1
           dec     rf                  ; backup to char
           ldi     0                   ; need proper termination
           str     rf
           ghi     ra                  ; back to beginning of name
           phi     rf
           glo     ra
           plo     rf
           ldi     high fildes         ; get file descriptor
           phi     rd
           ldi     low fildes
           plo     rd
           ldi     0                   ; flags for open
           plo     r7
           sep     scall               ; attempt to open file
           dw      o_open
           lbnf    opened              ; jump if file was opened
           ldi     high errmsg         ; get error message
           phi     rf
           ldi     low errmsg
           plo     rf
           sep     scall               ; display it
           dw      o_msg
           lbr     o_wrmboot           ; and return to os
opened:    sep     scall               ; setup buffer
           dw      setbuffer
           sep     scall               ; read first line of patch file
           dw      readln
           lbdf    readerr             ; jump on read error
           glo     rc                  ; get read count
           lbz     opened              ; loop back if nothing read
           sep     scall               ; return to beginning of buffer
           dw      setbuffer
loop2:     lda     rf                  ; seek space or less
           smi     33
           lbdf    loop2               ; loop until end of name found
           dec     rf                  ; backup one char
           ldi     0                   ; and place a terminator
           str     rf
           ghi     rd                  ; make copy of first descriptor
           phi     ra
           glo     rd
           plo     ra
           sep     scall               ; point to next filename
           dw      setbuffer
           ldi     high fildes2        ; get file descriptor
           phi     rd
           ldi     low fildes2
           plo     rd
           ldi     0                   ; flags for open
           plo     r7
           sep     scall               ; attempt to open file
           dw      o_open
           lbdf    openerr             ; jump if could not open file
           ghi     rd                  ; copy descriptor
           phi     rb
           glo     rd
           plo     rb
loop3:     sep     scall               ; read line from patch file
           dw      read1
           lbdf    filedone            ; jump if at end of file
           glo     rc                  ; see how many bytes were read
           lbz     loop3               ; loop back if none
           sep     scall               ; point to beginning of buffer
           dw      setbuffer
           ldn     rf                  ; get byte from buffer
           smi     'R'                 ; check for relative mode
           lbz     relative
           ldn     rf                  ; check lowercase as well
           smi     'r'
           lbz     relative
mainlp:    sep     scall               ; convert address to binary
           dw      f_hexin
           ldi     high offset         ; point to offset value
           phi     r9
           ldi     low offset
           plo     r9
           inc     r9                  ; point to low byte
           ldn     r9                  ; get low byte of offset
           str     r2                  ; need to subtract from address
           glo     rd
           sm
           plo     r7                  ; and place into r7 for seek
           dec     r9                  ; now high byte
           ldn     r9
           str     r2
           ghi     rd
           smb
           phi     r7
           ldi     0                   ; high word is zeroes
           phi     r8
           plo     r8
           plo     rc                  ; seek from beginning
           ghi     rb                  ; recover descripter
           phi     rd
           glo     rb
           plo     rd
           sep     scall               ; perform file seek
           dw      o_seek
mainlp2:   lda     rf                  ; get byte from buffer
           lbz     doneline            ; jump if terminator
           smi     33                  ; ignore all other whitespace
           dec     rf                  ; point back to non-whitespace char
           lbnf    mainlp2
           sep     scall               ; convert next byte
           dw      f_hexin
           glo     rf                  ; save buffer position
           stxd
           ghi     rf                  ; save buffer position
           stxd
           ldi     high outchar        ; point to output character
           phi     rf
           ldi     low outchar
           plo     rf
           glo     rd                  ; get converted byte
           str     rf                  ; and prepare for output
           ldi     0                   ; 1 byte to write
           phi     rc
           ldi     1
           plo     rc
           ghi     rb                  ; recover descritper
           phi     rd
           glo     rb
           plo     rd
           sep     scall               ; write the byte
           dw      o_write
           irx                         ; recover buffer position
           ldxa
           phi     rf
           ldx
           plo     rf
           lbr     mainlp2             ; loop back for remaining bytes
doneline:  sep     scall               ; read line from patch file
           dw      read1
           lbdf    filedone            ; jump if at end of file
           glo     rc                  ; see how many bytes were read
           lbz     doneline            ; loop back if none
           sep     scall               ; point to beginning of buffer
           dw      setbuffer
           lbr     mainlp              ; process line

filedone:  sep     scall               ; close the files
           dw      o_close
           ghi     ra
           phi     rd
           glo     ra
           plo     rd
           sep     scall
           dw      o_close
           sep     sret                ; return to os

relative:  ldi     high offset         ; point to offset
           phi     rf
           ldi     low offset
           plo     rf
           ldi     0                   ; need to load 2 bytes
           phi     rc
           ldi     2
           plo     rc
           sep     scall               ; read file offset bytes
           dw      o_read
           ldi     high offset         ; point to offset
           phi     rf
           ldi     low offset
           plo     rf
           inc     rf                  ; point to low byte
           ldn     rf                  ; retreive it
           smi     6                   ; 6 bytes in file header
           str     rf                  ; and put it back
           dec     rf                  ; point to high byte
           ldn     rf                  ; propagate the carry
           smbi    0
           str     rf
           lbr     doneline            ; no go and process the file

read1:     ghi     ra                  ; get first descriptor
           phi     rd
           glo     ra
           plo     rd
           sep     scall               ; point to buffer
           dw      setbuffer
           sep     scall               ; read 1 line
           dw      readln
           ghi     rb                  ; reset descriptor 2
           phi     rd
           glo     rb
           plo     rd
           sep     sret                ; and return to caller

readerr:   ldi     high readermsg      ; point to error
           phi     rf
           ldi     low readermsg
           plo     rf
           sep     scall               ; display it
           dw      o_msg
           sep     scall               ; close patch file
           dw      o_close
           sep     sret                ; and return to os

openerr:   ldi     high openermsg      ; point to error
           phi     rf
           ldi     low openermsg
           plo     rf
           sep     scall               ; display it
           dw      o_msg
           sep     scall               ; close patch file
           ghi     ra                  ; recover first descriptor
           phi     rd
           glo     ra
           plo     rd
           dw      o_close
           sep     sret                ; and return to os

setbuffer: ldi     high buffer         ; get address of buffer
           phi     rf
           ldi     low buffer
           plo     rf
           sep     sret                ; return to caller

; *****************************************
; *** Read one line                     ***
; *** RF - where to put read line       ***
; *** Returns: RC - count of characters ***
; ***          DF=0 - good read         ***
; ***          DF=1 - Error             ***
; *****************************************
readln:    ldi     0                   ; set byte count
           phi     rc
           plo     rc
readln1:   sep     scall               ; read a byte
           dw      readbyte
           lbdf    readlneof           ; jump on eof
           plo     re                  ; keep a copy
           smi     32                  ; look for anything below a space
           lbnf    readln1
readln2:   glo     re                  ; recover byte
           str     rf                  ; store into buffer
           inc     rf                  ; point to next position
           inc     rc                  ; increment character count
           sep     scall               ; read next byte
           dw      readbyte
           lbdf    readlneof           ; jump if end of file
           plo     re                  ; keep a copy of read byte
           smi     32                  ; make sure it is positive
           lbdf    readln2             ; loop back on valid characters
           ldi     0                   ; signal valid read
readlncnt: shr                         ; shift into DF
           ldi     0
           str     rf
           sep     sret                ; and return to caller
readlneof: ldi     1                   ; signal eof
           lbr     readlncnt

readbyte:  glo     rf
           stxd
           ghi     rf
           stxd
           glo     rc
           stxd
           ghi     rc
           stxd
           ldi     high char
           phi     rf
           ldi     low char
           plo     rf
           ldi     0
           phi     rc
           ldi     1
           plo     rc
           sep     scall
           dw      o_read
           glo     rc
           lbz     readbno
           ldi     0
readbcnt:  shr
           ldi     high char
           phi     rf
           ldi     low char
           plo     rf
           ldn     rf
           plo     re
           irx
           ldxa
           phi     rc
           ldxa
           plo     rc
           ldxa
           phi     rf
           ldx
           plo     rf
           glo     re
           sep     sret
readbno:   ldi     1
           lbr     readbcnt
char:      db      0
outchar:   db      0
offset:    dw      0
errmsg:    db      'Patch File not found',10,13,0
readermsg: db      'Patch file format error',10,13,0
openermsg: db      'Could not open file to be patched',10,13,0

fildes:    db      0,0,0,0
           dw      dta
           db      0,0
           db      0
           db      0,0,0,0
           dw      0,0
           db      0,0,0,0
fildes2:   db      0,0,0,0
           dw      dta2
           db      0,0
           db      0
           db      0,0,0,0
           dw      0,0
           db      0,0,0,0

endrom:    equ     $

dta:       ds      512
dta2:      ds      512
buffer:    ds      256

