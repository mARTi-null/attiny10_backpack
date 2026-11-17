/***********************************************************************************************************************
Double Dabble algorithm for Attiny10 written in assembly

Created: 28.10.2024.
Author : mARTi_null
Microcontroller: Attiny10
IDE: Microchip Studio 7.0

This function uses Double Dabble algorithm to convert binary value from ADCL register into
binary coded decimal (BCD) notation. The main purpose of this conversion is for displaying
read out values from ADC to OLED display like SSD1306 or 7 Segment display.

/***********************************************************************************************************************
CONVERTED DIGITS ARE STORED IN SRAM
***********************************************************************************************************************
Decimal number example:
	BIN = 0111 1011
	HEX = 7B
	DEC = 123 = "1" is stored in "digit_2", "2" is stored in "digit_1" and "3" is stored in "digit_0" SRAM locations

Source: https://en.wikipedia.org/wiki/Double_dabble.


/***********************************************************************************************************************
VARIABLE DECLARATION
***********************************************************************************************************************/
 .dseg
	digit_2: .byte 1
	digit_1: .byte 1
	digit_0: .byte 1
.cseg

/***********************************************************************************************************************
DOUBLE DABBLE ALGORITHM
***********************************************************************************************************************/
 ddb:
	in		R16, ADCL			; Load ADC value for conversion
	ldi		R18, 0x08			; Set counter to 8 (8 bits)
	ldi		R19, 0x00			; Low nibble of dig_0_1 will be digit 0, high nibble will be digit 1
	ldi		R20, 0x00			; Low nibble of dig_2 will be digit 2
	ldi		R21, 0b00000011		; Value of 3 for low nibble addition
	ldi		R22, 0b00110000		; Value of 3 for high nibble addition
shift_data:
	lsl		R16				; Shift bits to the left and set Carry Flag if bit shifted out is 1
	rol		R19				; Roll bits to the left, add Carry Flag (0 or 1) to LSB and also set Carry Flag if bit shifted out is 1
	rol		R20				; Roll bits to the left and add Carry Flag (0 or 1) to LSB
	dec		R18				; Decrease counter
	breq	end_ddb			; If counter is 0, return
	mov		R23, R19		; Move digits value to compare register for low nibble
	mov		R24, R19		; Move digits value to compare register for high nibble
lo_nibble:
	andi	R23, 0x0F		; Isolate only low nibble
	cpi		R23, 0x05		; Compare low nibble with 5
	brlo	hi_nibble		; If low nibble is lower than 5 skip addition and check high nibble
	add		R19, R21		; Add 3 to low nibble if it is equal or bigger than 5
hi_nibble:
	andi	R24, 0xF0		; Isolate high nibble
	cpi		R24, 0x50		; Compare high nibble with 5
	brlo	shift_data		; If high nibble is lower than 5 skipp addition and start next bit shift
	add		R19, R22		; Add 3 to high nibble if it is equal or bigger than 5
	rjmp	shift_data		; Start next bit shift
end_ddb:
	sts		digit_2, R20	; Store Hundreds digit (digit 2) into SRAM
	mov		R23, R19		; Move data for digit 0 and 1 into R23
	andi	R23, 0xF0		; Make low nibble all 0s in R23
	swap	R23				; Swap nibbles in R23
	sts		digit_1, R23	; Store data for tens digit (digit 1) into SRAM
	andi	R19, 0x0F		; Make high nibble 0s in R19
	sts		digit_0, R19	; Store data for ones digit (digit 0) into SRAM
ret							; Return from function