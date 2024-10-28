/*
Double Dabble algorithm for Attiny10 written in assembly by: _cazmaTronik

Created: 28.10.2024.
Author : _cazmaTronik
Microcontroller: Attiny10
IDE: Microchip Studio 7.0

This function uses Double Dabble algorithm to convert binary value from ADCL register into
binary coded decimal (BCD) notation. The main purpose of this conversion is for displaying
read out values from ADC to OLED display like SSD1306 or 7 Segment display.
The whole function is written in avr assembler and takes only 46 bytes of program memory.
Function takes around 15 µs to complete with 8MHz clock on Attiny10.

;-------------------------------------------------------------
!---CONVERTED DIGITS ARE RETURNED IN REGISTERS R18 and R19---!
;-------------------------------------------------------------
Register R18 will have "ones" digit in its low nibble and "tens" digit in its high nibble.
Register R19 will have "hundreds" digit in its low nibble.
Decimal number example:
	BIN = 0111 1011
	HEX = 7B
	DEC = 123 = "1" is stored in R19, "2" is stored in R18 high nibble "3" is stored in R18 low nibble

;---------------------------------------------------------------------------------------------------------------------------------------
Example of extracting individual digits from R18:
	mov		Rn, R18				; Load data from R18 into Rn
	andi	R18, 0b0000 1111	; Make all bits in high nibble of R18 0 by AND-ing them with 0
	andi	Rn, 0b1111 0000		; Make all bits in low nibble of Rn 0 by AND-ing them with 0
	swap	Rn					; Swap Rn high and low nibble places to have all individual digits in lower nibble or R19, Rn and R18
;---------------------------------------------------------------------------------------------------------------------------------------

Source: https://en.wikipedia.org/wiki/Double_dabble.
*/

;-----Register definitions-----;
.def	byte = r16
.def	counter = r17
.def	dig_0_1 = r18
.def	dig_2 = r19
.def	add_low = r20
.def	add_high = r21
.def	compare_low = r22
.def	compare_high = r23

;-----DDB function-----;
ddb:
	in		byte, ADCL			; Load ADC value for conversion
	;ldi	byte, 0xFF			; For testing purpose, byte for conversion to decimal
	ldi		counter, 0x08		; Set counter to 8 (8 bits)
	ldi		dig_0_1, 0x00		; Low nibble of dig_0_1 will be digit 0, high nibble will be digit 1
	ldi		dig_2, 0x00			; Low nibble of dig_2 will be digit 2
	ldi		add_low, 0b00000011		; Value of 3 for low nibble addition
	ldi		add_high, 0b00110000		; Value of 3 for high nibble addition
shift_data:
	lsl		byte		; Shift bits to the left and set Carry Flag if bit shifted out is 1
	rol		dig_0_1		; Roll bits to the left, add Carry Flag (0 or 1) to LSB and also set Carry Flag if bit shifted out is 1
	rol		dig_2		; Roll bits to the left and add Carry Flag (0 or 1) to LSB
	dec		counter		; Decrease counter
	breq	end_ddb		; If counter is 0, return from function
	mov		compare_low, dig_0_1	; Move digits value to compare register for low nibble
	mov		compare_high, dig_0_1	; Move digits value to compare register for high nibble
lo_nibble:
	andi	compare_low, 0x0F		; Isolate only low nibble
	cpi		compare_low, 0x05		; Compare low nibble with 5
	brlo	hi_nibble			; If low nibble is lower than 5 skip addition and check high nibble
	add		dig_0_1, add_low		; Add 3 to low nibble if it is equal or bigger than 5
hi_nibble:
	andi	compare_high, 0xF0		; Isolate high nibble
	cpi		compare_high, 0x50		; Compare high nibble with 5
	brlo	shift_data			; If high nibble is lower than 5 skipp addition and start next bit shift
	add		dig_0_1, add_high		; Add 3 to high nibble if it is equal or bigger than 5
	rjmp	shift_data			; Start next bit shift
end_ddb:
ret		; Return from function
