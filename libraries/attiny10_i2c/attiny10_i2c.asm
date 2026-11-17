/*
 * attiny10_i2c.asm
 *
 * Created: 13.10.2024. 19:05:57
 * Author: mARTi_null
 */

/***********************************************************************************************************************
CONSTANTS AND REGISTERS
***********************************************************************************************************************/
.ifndef SDA
	.equ	SDA = PB0
.endif

.ifndef SCL
	.equ	SCL = PB1
.endif

.ifndef i2c_data
	.def	i2c_data = r17
.endif

.ifndef i2c_counter
	.def	i2c_counter = r18
.endif

/***********************************************************************************************************************
I2C START
***********************************************************************************************************************/
i2c_start:
	cbi		PORTB, SDA		; Set SDA LOW
	cbi		PORTB, SCL		; Set SCL LOW
ret

/***********************************************************************************************************************
I2C STOP
***********************************************************************************************************************/
i2c_stop:
	cbi		PORTB, SDA		; Set SDA LOW
	sbi		PORTB, SCL		; Set SCL HIGH
	sbi		PORTB, SDA		; Set SDA HIGH
ret

/***********************************************************************************************************************
I2C SEND BYTE
***********************************************************************************************************************/
i2c_send:
	ldi		i2c_counter, 0x08	; We are sending 8 bits of data
get_bit:
	lsl		i2c_data			; Shifting data bits to the left. If the bit shifted out is 1 it will set the carry flag
	brcs	high_bit			; Check if carry flag is set and branch if true
	cbi		PORTB, SDA			; If carry flag is not set then set SDA LOW
	rjmp	clock_it			; Jump to clocking the data bit
high_bit:
	sbi		PORTB, SDA			; If carry flag is set then set SDA HIGH
	nop							; Sync delay
clock_it:
	sbi		PORTB, SCL			; Clock the data bit to the I2C bus
	nop							; Sync delay
	cbi		PORTB, SCL			; Clock release
	dec		i2c_counter			; Decrease bit counter
	brne	get_bit				; If bit counter is not 0 then jump back and shift the next bit
	sbi		PORTB, SDA			; ACK
	sbi		PORTB, SCL			; ACK Clock
	nop							; Sync delay
	cbi		PORTB, SCL			; Clock release
ret
