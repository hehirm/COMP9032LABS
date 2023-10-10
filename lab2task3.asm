; Define statements

.include "m2560def.inc"

; Pattern registers
.def pattern1 = r12   ; Stores the first pattern
.def pattern2 = r13   ; Stores the second pattern
.def pattern3 = r14   ; Stores the third pattern

; Registers used for counting in the delay function
.def dL = r16         ; Stores the low 8 bits of the counter
.def dM = r17         ; Stores the middle 8 bits of the counter
.def dH = r18         ; Stores the high 8 bits of the counter
.def incer = r19      ; Stores the increment value for the counter (either 0 or 1)

; mode stores one of four states the program can be in
; - displaying static pattern 1 (mode = 0)
; - displaying static pattern 2 (mode = 1)
; - displaying static pattern 3 (mode = 2)
; - displaying all 3 patterns in a loop (mode = 4)
.def mode = r21

; Registers used for outputing the patterns
.def outreg1 = r22
.def outreg2 = r23
.def outreg3 = r24

; Macro used for two purposes
; - Intoduces a delay between the display of the three patterns
; - Polls for interaction from both buttons
; Specifying the argument @0 to be 19 results in the delay being exactly one second
.macro delay
	clr dL            ; 1 cycle
	clr dM            ; 1 cycle
	clr dH            ; 1 cycle
loop:
	sbis PIND, 0      ; 2 cycles on failure
	rjmp pressbt0
	sbis PIND, 1      ; 2 cycles on failure
	rjmp pressbt1
	ldi incer, 1      ; 1 cycle
	add dL, incer     ; 1 cycle
	clr incer         ; 1 cycle
	adc dM, incer     ; 1 cycle
	adc dH, incer     ; 1 cycle
	cpi dH, @0        ; 1 cycle
	breq end          ; 1 if false, 2 if true
	rjmp loop         ; 2 cycles
end:
	nop
	nop
.endmacro

; Perfrom relevant initialisations for the program
setup:
	; Setting up I/O
	ser mode
	out DDRC, mode      ; Setting port C direction for output
	cbi DDRD, 0
	sbi PORTD, 0
	sbi PIND, 0
	cbi DDRD, 1
	sbi PORTD, 1
	sbi PIND, 1

	; Set the pattern registers to contain the relevant patterns
	ldi mode, 1
	mov pattern1, mode
	ldi mode, 2
	mov pattern2, mode
	ldi mode, 4
	mov pattern3, mode

	; Set the output registers to contain the first pattern
	mov outreg1, pattern1
	mov outreg2, pattern1
	mov outreg3, pattern1

	; Set the mode to 0 
	clr mode

; Main loop writes the contents of the output registers to the LED bar
; A delay exists in between these writes which gives the program the opportunity
; to poll for a button press (inside the delay macro). The parameter is 19 to ensure
; that the delay is precisely 1 second.	
main:
	out PORTC, outreg1
	delay 19
	out PORTC, outreg2
	delay 19
	out PORTC, outreg3
	delay 19
	rjmp main

; Program execution jumps here when push button 1 is pressed. In this case we reset
; the program to mode 0 (displaying pattern 1)
pressbt1:
	delay 1                  ; Delay to debounce
	clr mode                 ; set mode to 0
	rjmp setpattern1         ; Set the output registers to contain pattern 1

; Program execution jumps here when push button 0 is pressed. In this case we move to the
; next mode (cycling back after the last mode has been reached).
pressbt0:
	delay 1                  ; Delay to debounce
	inc mode                 ; Increment the mode
	cpi mode, 1              ; Series of logical checks to determine what the mode is
	breq setpattern2         ; and set the correct pattern values to the output registers
	cpi mode, 2
	breq setpattern3
	cpi mode, 3
	breq setloopingpattern
	clr mode                 ; If the mode has exceeded all valid values we cycle back to 0

; Sets all of the output registers to pattern 1		 
setpattern1:
	mov outreg1, pattern1
	mov outreg2, pattern1
	mov outreg3, pattern1
	rjmp main

; Sets all of the output registers to pattern 2
setpattern2:
	mov outreg1, pattern2
	mov outreg2, pattern2
	mov outreg3, pattern2
	rjmp main

; Sets all of the output registers to pattern 3
setpattern3:
	mov outreg1, pattern3
	mov outreg2, pattern3
	mov outreg3, pattern3
	rjmp main

; Sets the output registers to loop through all three patterns
setloopingpattern:
	mov outreg1, pattern1
	mov outreg2, pattern2
	mov outreg3, pattern3
	rjmp main

	
	
