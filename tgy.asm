;**** **** **** **** ****
;
;Die Benutzung der Software ist mit folgenden Bedingungen verbunden:
;
;1. Da ich alles kostenlos zur Verf�gung stelle, gebe ich keinerlei Garantie
;   und �bernehme auch keinerlei Haftung f�r die Folgen der Benutzung.
;
;2. Die Software ist ausschlie�lich zur privaten Nutzung bestimmt. Ich
;   habe nicht gepr�ft, ob bei gewerblicher Nutzung irgendwelche Patentrechte
;   verletzt werden oder sonstige rechtliche Einschr�nkungen vorliegen.
;
;3. Jeder darf �nderungen vornehmen, z.B. um die Funktion seinen Bed�rfnissen
;   anzupassen oder zu erweitern. Ich w�rde mich freuen, wenn ich weiterhin als
;   Co-Autor in den Unterlagen erscheine und mir ein Link zur entprechenden Seite
;   (falls vorhanden) mitgeteilt wird.
;
;4. Auch nach den �nderungen sollen die Software weiterhin frei sein, d.h. kostenlos bleiben.
;
;!! Wer mit den Nutzungbedingungen nicht einverstanden ist, darf die Software nicht nutzen !!
;
; tp-18a
; October 2004
; autor: Bernhard Konze
; email: bernhard.konze@versanet.de
;--
; Based on upon Bernhard's "tp-18a" and others; see
; http://home.versanet.de/~b-konze/blc_18a/blc_18a.htm
; Copyright (C) 2004 Bernhard Konze
; Copyright (C) 2011-2012 Simon Kirby and other contributors
; NO WARRANTY EXPRESSED OR IMPLIED. USE AT YOUR OWN RISK. Always test
; without propellers! Please respect Bernhard Konze's license above.
;--
; WARNING: I have blown FETs on Turnigy Plush 18A ESCs in previous versions
; of this code with my modifications. Some bugs have since been fixed, such
; as leaving PWM enabled while busy-looping forever outside of ISR code.
; However, this does run with higher PWM frequency than most original code,
; so higher FET temperatures may occur! USE AT YOUR OWN RISK, and maybe see
; how it compares and let me know!
;
; WARNING: This does not check temperature or voltage ADC inputs.
;
; NOTE: We do 16-bit PWM on timer2 at full CPU clock rate resolution, using
; tcnt2h to simulate the high byte. An input FULL to STOP range of 800 plus
; a MIN_DUTY of 58 (a POWER_RANGE of 858) gives 800 unique PWM steps at an
; about 18kHz on a 16MHz CPU clock. The output frequency is slightly lower
; than F_CPU / POWER_RANGE due to cycles used in the interrupt as TCNT2 is
; reloaded.
;
; Simon Kirby <sim@simulated.ca>
;
;-- Device ----------------------------------------------------------------
;
.include "m8def.inc"
;
; 8K Bytes of In-System Self-Programmable Flash
; 512 Bytes EEPROM
; 1K Byte Internal SRAM
;
;-- Fuses -----------------------------------------------------------------
;
; Old fuses for internal RC oscillator at 8MHz were lfuse=0xa4 hfuse=0xdf,
; but since we now set OSCCAL to 0xff (about 16MHz), running under 4.5V is
; officially out of spec. We'd better set the brown-out detection to 4.0V.
; The resulting code works with or without external 16MHz oscillators.
; Boards with external oscillators can use lfuse=0x3f.
;
; If the boot loader is enabled, the last nibble of the hfuse should be set
; to 'a' or '2' to also enable EESAVE - save EEPROM on chip erase. This is
; a 512-word boot flash section (0xe00), and enable BOOTRST to jump to it.
; Setting these fuses actually has no harm even without the boot loader,
; since 0xffff is nop, and it will just nop-sled around into normal code.
;
; Suggested fuses with 4.0V brown-out voltage:
; Without external oscillator: avrdude -U lfuse:w:0x24:m -U hfuse:w:0xda:m
;    With external oscillator: avrdude -U lfuse:w:0x3f:m -U hfuse:w:0xca:m
;
; Don't set WDTON if using the boot loader. We will enable it on start.
;
;-- Board -----------------------------------------------------------------
;
; The following only works with avra or avrasm2.
; For avrasm32, just comment out all but the include you need.
#if defined(afro_esc)
#include "afro.inc"		; AfroESC (ICP PWM, I2C, UART)
#elif defined(afro2_esc)
#include "afro2.inc"		; AfroESC 2 (ICP PWM, I2C, UART)
#elif defined(birdie70a_esc)
#include "birdie70a.inc"	; Birdie 70A with all nFETs (INT0 PWM)
#elif defined(bs_esc)
#include "bs.inc"		; HobbyKing BlueSeries / Mystery (INT0 PWM)
#elif defined(bs_nfet_esc)
#include "bs_nfet.inc"		; HobbyKing BlueSeries / Mystery with all nFETs (INT0 PWM)
#elif defined(bs40a_esc)
#include "bs40a.inc"		; HobbyKing BlueSeries / Mystery 40A (INT0 PWM)
#elif defined(bs50_esc)
#include "bs50.inc"		; HobbyKing BlueSeries 50A (INT0 PWM)
#elif defined(dlu40a_esc)
#include "dlu40a.inc"		; Pulso Advance Plus 40A DLU40A inverted-PWM-opto (INT0 PWM)
#elif defined(hk200a_esc)
#include "hk200a.inc"		; HobbyKing SS Series 190-200A with all nFETs (INT0 PWM)
#elif defined(kda_esc)
#include "kda.inc"		; Keda Model 12A - 30A (INT0 PWM)
#elif defined(rb50a_esc)
#include "rb50a.inc"		; Red Brick 50A with all nFETs (INT0 PWM)
#elif defined(rb70a_esc)
#include "rb70a.inc"		; Red Brick 70A with all nFETs (INT0 PWM)
#elif defined(rct50a_esc)
#include "rct50a.inc"		; RCTimer 50A with all nFETs (INT0 PWM)
#elif defined(tp_esc)
#include "tp.inc"		; TowerPro 25A/HobbyKing 18A "type 1" (INT0 PWM)
#elif defined(tp_i2c_esc)
#include "tp_i2c.inc"		; TowerPro 25A/HobbyKing 18A "type 1" (I2C)
#elif defined(tp_nfet_esc)
#include "tp_nfet.inc"		; TowerPro 25A with all nFETs "type 3" (INT0 PWM)
#elif defined(tgy6a_esc)
#include "tgy6a.inc"		; Turnigy Plush 6A (INT0 PWM)
#else
#include "tgy.inc"		; TowerPro/Turnigy Basic/Plush "type 2" (INT0 PWM)
#endif

.equ	BOOT_LOADER	= 1	; Enable or disable boot loader

.equ	I2C_ADDR	= 0x50	; MK-style I2C address
.equ	MOTOR_ID	= 1	; MK-style I2C motor ID, or UART motor number

.equ	COMP_PWM	= 0	; During PWM off, switch high side on (unsafe on some boards!)
.equ	MOTOR_ADVANCE	= 18	; Degrees of timing advance (0 - 30, 30 meaning no delay)
.equ	MOTOR_BRAKE	= 0	; Enable brake
.equ	MOTOR_REVERSE	= 0	; Reverse normal commutation direction
.equ	RC_PULS_REVERSE	= 0	; Enable RC-car style forward/reverse throttle
.equ	SLOW_THROTTLE	= 0	; Limit maximum throttle jump to try to prevent overcurrent
.equ	BEACON		= 1	; Beep periodically when RC signal is lost
.equ	MOTOR_DEBUG	= 0

.equ	RCP_TOT		= 16	; Number of 65536us periods before considering rc pulse lost
.equ	CPU_MHZ		= F_CPU / 1000000

; These are now defaults which can be adjusted via throttle calibration
; (stick high, stick low, (stick neutral) at start).
.if defined(ultrapwm)
.equ	STOP_RC_PULS	= 200	; Support for http://www.xaircraft.com/wiki/UltraPWM/en
.equ	FULL_RC_PULS	= 1200	; which says motors should start at 200us,
.equ	MAX_RC_PULS	= 1400	; but does not define min/max pulse width.
.else
; These might be a bit wide for most radios, but lines up with POWER_RANGE.
.equ	STOP_RC_PULS	= 1060	; Stop motor at or below this pulse length
.equ	FULL_RC_PULS	= 1860	; Full speed at or above this pulse length
.equ	MAX_RC_PULS	= 2400	; Throw away any pulses longer than this
.endif

.if	RC_PULS_REVERSE
.equ	RCP_DEADBAND	= 50	; Do not start until this much above or below neutral
.equ	PROGRAM_RC_PULS	= (STOP_RC_PULS + FULL_RC_PULS * 3) / 4	; Normally 1660
.else
.equ	RCP_DEADBAND	= 0
.equ	PROGRAM_RC_PULS	= (STOP_RC_PULS + FULL_RC_PULS) / 2	; Normally 1460
.endif
.equ	MAX_DRIFT_PULS	= 10	; Maximum jitter/drift microseconds during programming

; Minimum PWM on-time (too low and FETs won't turn on, hard starting)
.equ	MIN_DUTY	= 58 * CPU_MHZ / 16

; Number of PWM steps (too high and PWM frequency drops into audible range)
.equ	POWER_RANGE	= 800 * CPU_MHZ / 16 + MIN_DUTY

.equ	MAX_POWER	= (POWER_RANGE-1)
.equ	PWR_MIN_START	= (POWER_RANGE/6) ; Power limit while starting (to start)
.equ	PWR_MAX_START	= (POWER_RANGE/4) ; Power limit while starting (if still not running)
.equ	PWR_MAX_RPM1	= (POWER_RANGE/4) ; Power limit when running slower than TIMING_RANGE1
.equ	PWR_MAX_RPM2	= (POWER_RANGE/2) ; Power limit when running slower than TIMING_RANGE2

.equ	BRAKE_POWER	= MAX_POWER*2/3	; Brake force is exponential, so start fairly high
.equ	BRAKE_SPEED	= 3		; Speed to reach MAX_POWER, 0 (slowest) - 8 (fastest)

.equ	TIMING_MIN	= 0x8000 ; 8192us per commutation
.equ	TIMING_RUN	= 0x1000 ; 1024us per commutation
.equ	TIMING_RANGE1	= 0x4000 ; 4096us per commutation
.equ	TIMING_RANGE2	= 0x2000 ; 2048us per commutation
.equ	TIMING_MAX	= 0x00e0 ; 20us per commutation

.equ	timeoutSTART	= 48000 ; 48ms per commutation
.equ	timeoutMIN	= 36000	; 36ms per commutation

.equ	ENOUGH_GOODIES	= 12	; This many start cycles without timeout will transition to running mode

.equ	T0CLK		= (1<<CS01)	; clk/8 == 2Mhz
.equ	T1CLK		= (1<<CS10)+(USE_ICP<<ICES1)+(USE_ICP<<ICNC1)	; clk/1 == 16MHz
.equ	T2CLK		= (1<<CS20)	; clk/1 == 16MHz

.equ	EEPROM_SIGN	= 31337		; Random 16-bit value
.equ	EEPROM_OFFSET	= 0x80		; Offset into 512-byte space (why not)

;**** **** **** **** ****
; Register Definitions
.def	temp5		= r0		; aux temporary (L) (limited operations)
.def	temp6		= r1		; aux temporary (H) (limited operations)
.def	duty_l		= r2		; on duty cycle low, one's complement
.def	duty_h		= r3		; on duty cycle high
.def	off_duty_l	= r4		; off duty cycle low, one's complement
.def	off_duty_h	= r5		; off duty cycle high
.def	rx_l		= r6		; received throttle low
.def	rx_h		= r7		; received throttle high
.def	tcnt2h		= r8		; timer2 high byte
.def	i_sreg		= r9		; status register save in interrupts
;.def			= r10
.def	rc_timeout	= r11
.def	sys_control_l	= r12		; duty limit low (word register aligned)
.def	sys_control_h	= r13		; duty limit high
.def	temp7		= r14		; really aux temporary (limited operations)
;.def			= r15

;.def	nfet_on		= r18
;.def	nfet_off	= r19
.def	i_temp1		= r20		; interrupt temporary
.def	i_temp2		= r21		; interrupt temporary
.def	temp3		= r22		; main temporary (L)
.def	temp4		= r23		; main temporary (H)
.def	temp1		= r24		; main temporary (L), adiw-capable
.def	temp2		= r25		; main temporary (H), adiw-capable

.def	flags0	= r16	; state flags
	.equ	OCT1_PENDING	= 0	; if set, output compare interrupt is pending
	.equ	SET_DUTY	= 1	; if set when armed, set duty during evaluate_rc
;	.equ	I_pFET_HIGH	= 2	; set if over-current detect
;	.equ	GET_STATE	= 3	; set if state is to be send
	.equ	I2C_FIRST	= 4	; if set, i2c will receive first byte next
	.equ	I2C_SPACE_LEFT	= 5	; if set, i2c buffer has room
	.equ	UART_SYNC	= 6	; if set, we are waiting for our serial throttle byte
	.equ	NO_CALIBRATION	= 7	; if set, disallow calibration (unsafe reset cause)

.def	flags1	= r17	; state flags
	.equ	POWER_OFF	= 0	; switch fets on disabled
	.equ	FULL_POWER	= 1	; 100% on - don't switch off, but do OFF_CYCLE working
	.equ	I2C_MODE	= 2	; if receiving updates via I2C
	.equ	UART_MODE	= 3	; if receiving updates via UART
	.equ	EVAL_RC		= 4	; if set, evaluate rc command while waiting for OCT1
	.equ	ACO_EDGE_HIGH	= 5	; if set, looking for ACO high - conviently located at the same bit position as ACO
	.equ	STARTUP		= 6	; if set, startup-phase is active
	.equ	REVERSE		= 7	; if set, do reverse commutation

.def	flags2	= r18
	.equ	A_FET		= 0	; if set, A FET is being PWMed
	.equ	B_FET		= 1	; if set, B FET is being PWMed
	.equ	C_FET		= 2	; if set, C FET is being PWMed
	.equ	ALL_FETS	= (1<<A_FET)+(1<<B_FET)+(1<<C_FET)
;.def	flags2	= r25
;	.equ	RPM_RANGE1	= 0	; if set RPM is lower than 1831 RPM
;	.equ	RPM_RANGE2	= 1	; if set RPM is lower than 3662 RPM
;	.equ	RC_INTERVAL_OK	= 2
;	.equ	POFF_CYCLE	= 3	; if set one commutation cycle is performed without power
;	.equ	COMP_SAVE	= 4	; if set ACO was high
;	.equ	COMP_SAVE_READY	= 5	; if acsr_save was set by PWM interrupt
;	.equ	STARTUP		= 6	; if set startup-phase is active
;	.equ	SCAN_TIMEOUT	= 7	; if set a startup timeout occurred

; here the XYZ registers are placed ( r26-r31)

; XL: general temporary
; XH: general temporary
; YL: general temporary
; YH: general temporary
; ZL: Next PWM interrupt vector (low)
; ZH: Next PWM interrupt vector (high, stays at zero) -- used as "zero" register

;**** **** **** **** ****
; RAM Definitions
.dseg				; DATA segment
.org SRAM_START

orig_osccal:	.byte	1	; original OSCCAL value
goodies:	.byte	1	; Number of rounds without timeout
powerskip:	.byte	1	; Skip power through this number of steps
ocr1ax:		.byte	1	; 3rd byte of OCR1A
tcnt1x:		.byte	1	; 3rd byte of TCNT1
last_tcnt1_l:	.byte	1	; last timer1 value
last_tcnt1_h:	.byte	1
last_tcnt1_x:	.byte	1
l2_tcnt1_l:	.byte	1	; last last timer1 value
l2_tcnt1_h:	.byte	1
l2_tcnt1_x:	.byte	1
t_minblank_l:	.byte	1	; time from switch to comparator scan start
t_minblank_h:	.byte	1
t_minblank_x:	.byte	1
t_maxblank_l: 	.byte	1	; expected ZC point - latest possible demagnetization
t_maxblank_h: 	.byte	1
t_maxblank_x: 	.byte	1
t_zc_wait_l:	.byte	1	; time to wait for zero-crossing while running
t_zc_wait_h:	.byte	1
t_zc_wait_x:	.byte	1
wt_OCT1_tot_l:	.byte	1	; time for each startup commutation
wt_OCT1_tot_h:	.byte	1
wt_OCT1_tot_x:	.byte	1
zc_filter_time:	.byte	1	; number of times to check zero-crossing
rc_duty_l:	.byte	1	; desired duty cycle
rc_duty_h:	.byte	1
timing_duty_l:	.byte	1	; duty cycle limit based on timing
timing_duty_h:	.byte	1
fwd_scale_l:	.byte	1	; 16.16 multipliers to scale input RC pulse to POWER_RANGE
fwd_scale_h:	.byte	1
rev_scale_l:	.byte	1
rev_scale_h:	.byte	1
neutral_l:	.byte	1	; Offset for neutral throttle (in CPU_MHZ)
neutral_h:	.byte	1
max_pwm:	.byte	1	; MaxPWM for MK (NOTE: 250 while stopped is magic and enables v2)
motor_count:	.byte	1	; Motor number for serial control
;**** **** **** **** ****
; The following entries are block-copied from/to EEPROM
eeprom_sig_l:	.byte	1
eeprom_sig_h:	.byte	1
puls_high_l:	.byte	1	; -,
puls_high_h:	.byte	1	;  |
puls_low_l:	.byte	1	;  |- saved pulse lengths during throttle calibration
puls_low_h:	.byte	1	;  |  (order used by rc_prog)
puls_neutral_l:	.byte	1	;  |
puls_neutral_h:	.byte	1	; -'
eeprom_end:	.byte	1
;-----bko-----------------------------------------------------------------
;**** **** **** **** ****
.cseg
.org 0
;**** **** **** **** ****
; ATmega8 interrupts

;.equ	INT0addr=$001	; External Interrupt0 Vector Address
;.equ	INT1addr=$002	; External Interrupt1 Vector Address
;.equ	OC2addr =$003	; Output Compare2 Interrupt Vector Address
;.equ	OVF2addr=$004	; Overflow2 Interrupt Vector Address
;.equ	ICP1addr=$005	; Input Capture1 Interrupt Vector Address
;.equ	OC1Aaddr=$006	; Output Compare1A Interrupt Vector Address
;.equ	OC1Baddr=$007	; Output Compare1B Interrupt Vector Address
;.equ	OVF1addr=$008	; Overflow1 Interrupt Vector Address
;.equ	OVF0addr=$009	; Overflow0 Interrupt Vector Address
;.equ	SPIaddr =$00a	; SPI Interrupt Vector Address
;.equ	URXCaddr=$00b	; USART Receive Complete Interrupt Vector Address
;.equ	UDREaddr=$00c	; USART Data Register Empty Interrupt Vector Address
;.equ	UTXCaddr=$00d	; USART Transmit Complete Interrupt Vector Address
;.equ	ADCCaddr=$00e	; ADC Interrupt Vector Address
;.equ	ERDYaddr=$00f	; EEPROM Interrupt Vector Address
;.equ	ACIaddr =$010	; Analog Comparator Interrupt Vector Address
;.equ	TWIaddr =$011	; Irq. vector address for Two-Wire Interface
;.equ	SPMaddr =$012	; SPM complete Interrupt Vector Address
;.equ	SPMRaddr =$012	; SPM complete Interrupt Vector Address

;-----bko-----------------------------------------------------------------
; Reset and interrupt jump table
; When multiple interrupts are pending, the vectors are executed from top
; (ext_int0) to bottom.
		rjmp reset	; reset
		rjmp rcp_int	; ext_int0
		reti		; ext_int1
		reti		; t2oc_int
		ijmp		; t2ovfl_int
		rjmp rcp_int	; icp1_int
		rjmp t1oca_int	; t1oca_int
		reti		; t1ocb_int
		rjmp t1ovfl_int	; t1ovfl_int
		reti		; t0ovfl_int
		reti		; spi_int
		rjmp urxc_int	; urxc
		reti		; udre
		reti		; utxc
		reti		; adc_int
		reti		; eep_int
		reti		; aci_int
		rjmp i2c_int	; twi_int
		reti		; spmc_int

eeprom_defaults_w:
	.db low(EEPROM_SIGN), high(EEPROM_SIGN)
	.db byte1(FULL_RC_PULS * CPU_MHZ), byte2(FULL_RC_PULS * CPU_MHZ)
	.db byte1(STOP_RC_PULS * CPU_MHZ), byte2(STOP_RC_PULS * CPU_MHZ)
	.db byte1((FULL_RC_PULS + STOP_RC_PULS) * CPU_MHZ / 2), byte2((FULL_RC_PULS + STOP_RC_PULS) * CPU_MHZ / 2)

;-----bko-----------------------------------------------------------------
; Timing and motor debugging
.macro flag_on
	.if MOTOR_DEBUG
		sbi	PORTB, 4
	.endif
.endmacro
.macro flag_off
	.if MOTOR_DEBUG
		cbi	PORTB, 4
	.endif
.endmacro
.macro sync_on
	.if MOTOR_DEBUG
		sbi	PORTB, 3
	.endif
.endmacro
.macro sync_off
	.if MOTOR_DEBUG
		cbi	PORTB, 3
	.endif
.endmacro

;-----bko-----------------------------------------------------------------
; init after reset

reset:		clr	r0
		out	SREG, r0		; Clear interrupts and flags

	; Set up stack
		ldi	ZH, high(RAMEND)
		ldi	ZL, low(RAMEND)
		out	SPH, ZH
		out	SPL, ZL
	; Clear RAM and all registers
clear_loop:	st	-Z, r0
		cpi	ZL, SRAM_START
		cpc	ZH, r0
		brne	clear_loop1
		ldi	ZL, 30			; Start clearing registers
clear_loop1:	cp	ZL, r0
		cpc	ZH, r0
		brne	clear_loop		; Leaves with all registers (r0 through ZH) at 0

	; Save original OSCCAL and reset cause
		in	i_sreg, OSCCAL
		sts	orig_osccal, i_sreg
		in	i_sreg, MCUCSR
		out	MCUCSR, r0

	; portB - all FETs off
		ldi	temp1, INIT_PB
		out	PORTB, temp1
		ldi	temp1, DIR_PB | (MOTOR_DEBUG<<3) | (MOTOR_DEBUG<<4)
		out	DDRB, temp1

	; portC reads comparator inputs
		ldi	temp1, INIT_PC
		out	PORTC, temp1
		ldi	temp1, DIR_PC
		out	DDRC, temp1

	; portD reads rc-puls + AIN0 ( + RxD, TxD for debug )
		ldi	temp1, INIT_PD
		out	PORTD, temp1
		ldi	temp1, DIR_PD
		out	DDRD, temp1

	; Start timers except output PWM
		ldi	temp1, T0CLK		; timer0: beep control, delays
		out	TCCR0, temp1
		ldi	temp1, T1CLK		; timer1: commutation timing,
		out	TCCR1B, temp1		; RC pulse measurement
		out	TCCR2, ZH		; timer2: PWM, stopped

	; Enable watchdog (WDTON may be set or unset)
		ldi	temp1, (1<<WDCE)+(1<<WDE)
		out	WDTCR, temp1
		ldi	temp1, (1<<WDE)		; Fastest option: ~16.3ms timeout
		out	WDTCR, temp1

	; Read EEPROM block to RAM
		rcall	wait120ms
		rcall	eeprom_read_block	; Also calls osccal_set

	; Check EEPROM signature
		ldi	XL, low(eeprom_sig_l) + 2
		ld	temp2, -X
		ld	temp1, -X		; Leave X at eeprom_sig_l
		subi	temp1, low(EEPROM_SIGN)
		sbci	temp2, high(EEPROM_SIGN)
		breq	eeprom_good

	; Signature not good: set defaults in RAM, but do not write
	; to the EEPROM until we actually set something non-default
		ldi	ZL, low(eeprom_defaults_w << 1)
eeprom_default:	lpm	temp1, Z+
		st	X+, temp1
		cpi	XL, low(eeprom_end)
		brne	eeprom_default
eeprom_good:

	; Check reset cause
		sbrs	i_sreg, PORF		; Power-on reset
		rjmp	init_no_porf
		rcall	beep_f1			; Usual startup beeps
		rcall	beep_f2
		rcall	beep_f3
		rjmp	control_start
init_no_porf:
		sbrs	i_sreg, BORF		; Brown-out reset
		rjmp	init_no_borf
		rcall	beep_f3			; "dead cellphone"
		rcall	beep_f1
		sbr	flags0, (1<<NO_CALIBRATION)
		rjmp	control_start
init_no_borf:
		sbrs	i_sreg, EXTRF		; External reset
		rjmp	init_no_extrf
		rcall	beep_f4			; Single beep
		rjmp	control_start
init_no_extrf:
		sbrs	i_sreg, WDRF		; Watchdog reset
		rjmp	init_no_wdrf
init_wdrf1:	rcall	beep_f1			; "siren"
		rcall	beep_f1
		rcall	beep_f3
		rcall	beep_f3
		rjmp	init_wdrf1		; Loop forever
init_no_wdrf:

	; Unknown reset cause: Beep out all 8 bits
	; Sometimes I can cause this by touching the oscillator.
init_bitbeep1:	rcall	wait240ms
		mov	i_temp1, i_sreg
		ldi	i_temp2, 8
init_bitbeep2:	sbrs	i_temp1, 0
		rcall	beep_f2
		sbrc	i_temp1, 0
		rcall	beep_f4
		rcall	wait120ms
		lsr	i_temp1
		dec	i_temp2
		brne	init_bitbeep2
		rjmp	init_bitbeep1		; Loop forever

;-----bko-----------------------------------------------------------------
; timer2 overflow compare interrupt (output PWM) -- the interrupt vector
; actually "ijmp"s to Z which should point to one of these entry points.
;
; We try to avoid clobbering (and thus needing to save/restore) flags;
; in, out, mov, ldi, etc. do not modify any flags, while dec does.
;
; The comparator (ACSR) is saved at the very end of the ON cycle, but
; since the nFET takes at least half a microsecond to turn off and the
; AVR buffers ACO for a few cycles, we do it after turning off the drive
; pin. For low duty cycles (with a longer off period), testing shows that
; waiting an extra 0.5us - 0.75us (8-12 cycles at 16MHz) actually helps
; to improve zero-crossing detection accuracy significantly, perhaps
; because the driven-low phase has had a chance to finish swinging down.
; However, some tiny boards such as 10A or less may have very low gate
; charge/capacitance, and so can turn off faster. We used to wait 8/9
; cycles, but now we wait 5 cycles (5/16ths of a microsecond), which
; still helps on ~30A boards without breaking 10A boards.
;
; We reload TCNT2 as the very last step so as to reduce PWM dead areas
; between the reti and the next interrupt vector execution, which still
; takes a good 4 (reti) + 4 (interrupt call) + 2 (ijmp) cycles. We also
; try to keep the fet switch off as close to this as possible to avoid a
; significant bump at FULL_POWER.
;
; The pwm_*_high entry points are only called when the particular on/off
; cycle is longer than 8 bits. This is tracked in tcnt2h.

.if MOTOR_BRAKE
pwm_brake_again:
		dec	tcnt2h
		out	SREG, i_sreg
		reti

pwm_brake_on:	in	i_sreg, SREG
		cpse	tcnt2h, ZH
		rjmp	pwm_brake_again
		nFET_brake i_temp1
		ldi	i_temp1, 0xff
		cp	off_duty_l, i_temp1	; Check for 0 off-time
		cpc	off_duty_h, ZH
		breq	pwm_brake_on1
		ldi	ZL, pwm_brake_off	; Not full on, so turn it off next
		ldi	i_temp2, 1 << BRAKE_SPEED
		sub	sys_control_l, i_temp2
		brne	pwm_brake_on1
		neg	duty_l			; Increase duty
		sbc	duty_h, i_temp1		; i_temp1 is 0xff aka -1
		com	duty_l
		com	off_duty_l		; Decrease off duty
		sbc	off_duty_l, ZH
		sbc	off_duty_h, ZH
		com	off_duty_l
pwm_brake_on1:	mov	tcnt2h, duty_h
		out	SREG, i_sreg
		out	TCNT2, duty_l
		reti

pwm_brake_off:	in	i_sreg, SREG
		cpse	tcnt2h, ZH
		rjmp	pwm_brake_again
		ldi	ZL, pwm_brake_on
		mov	tcnt2h, off_duty_h
		all_nFETs_off i_temp1
		out	SREG, i_sreg
		out	TCNT2, off_duty_l
		reti
.endif

pwm_on_high:
		in	i_sreg, SREG
		dec	tcnt2h
		brne	pwm_on_again
		ldi	ZL, pwm_on
pwm_on_again:	out	SREG, i_sreg
		reti
pwm_off_high:
		in	i_sreg, SREG
		dec	tcnt2h
		brne	pwm_off_again
		ldi	ZL, pwm_off
pwm_off_again:	out	SREG, i_sreg
		reti

pwm_on:
		.if COMP_PWM
		sbrc	flags2, A_FET
		ApFET_off
		sbrc	flags2, B_FET
		BpFET_off
		sbrc	flags2, C_FET
		CpFET_off
		.endif
		sbrc	flags2, A_FET
		AnFET_on
		sbrc	flags2, B_FET
		BnFET_on
		sbrc	flags2, C_FET
		CnFET_on
		ldi	ZL, pwm_off
		cpse	duty_h, ZH
		ldi	ZL, pwm_off_high
		mov	tcnt2h, duty_h
		out	TCNT2, duty_l
		reti

pwm_wdr:					; Just reset watchdog
		wdr
		reti

pwm_off:
		wdr				; 1 cycle: watchdog reset
		sbrc	flags1, FULL_POWER	; 2 cycles to skip if not full power
		rjmp	pwm_on			; None of this off stuff if full power
		ldi	ZL, pwm_on		; 1 cycle
		cpse	off_duty_h, ZH		; 1 cycle if not zero, 2 if zero
		ldi	ZL, pwm_on_high		; 1 cycle
		mov	tcnt2h, off_duty_h	; 1 cycle
		sbrc	flags2, A_FET		; 1 cycle if not, 2 cycles if skip
		AnFET_off			; 2 cycles (off at 10 cycles from entry)
		sbrc	flags2, B_FET		; Offset by 2 cycles here,
		BnFET_off			; but still equal on-time
		sbrc	flags2, C_FET
		CnFET_off
		.if COMP_PWM
		sbrc	flags2, A_FET
		ApFET_on
		sbrc	flags2, B_FET
		BpFET_on
		sbrc	flags2, C_FET
		CpFET_on
		.endif
		out	TCNT2, off_duty_l	; 1 cycle
		reti				; 4 cycles

.if high(pwm_off)
.error "high(pwm_off) is non-zero; please move code closer to start or use 16-bit (ZH) jump registers"
.endif
;-----bko-----------------------------------------------------------------
; timer output compare interrupt
t1oca_int:	in	i_sreg, SREG
		lds	i_temp1, ocr1ax
		subi	i_temp1, 1
		brcc	t1oca_int1
		cbr	flags0, (1<<OCT1_PENDING)	; signal OCT1A passed
t1oca_int1:	sts	ocr1ax, i_temp1
		out	SREG, i_sreg
		reti
;-----bko-----------------------------------------------------------------
; timer1 overflow interrupt (happens every 4096�s)
t1ovfl_int:	in	i_sreg, SREG
		lds	i_temp1, tcnt1x
		inc	i_temp1
		sts	tcnt1x, i_temp1
		andi	i_temp1, 15			; Every 16 overflows
		brne	t1ovfl_int1
		cpse	rc_timeout, ZH
		dec	rc_timeout
t1ovfl_int1:	out	SREG, i_sreg
		reti
;-----bko-----------------------------------------------------------------
; NOTE: This interrupt uses the 16-bit atomic timer read/write register
; by reading TCNT1L and TCNT1H, so this interrupt must be disabled before
; any other 16-bit timer options happen that might use the same register
; (see "Accessing 16-bit registers" in the Atmel documentation)
; icp1 = rc pulse input, if enabled
rcp_int:
	.if USE_ICP || USE_INT0
		.if USE_ICP
		in	i_temp1, ICR1L		; get captured timer values
		in	i_temp2, ICR1H
		in	i_sreg, TCCR1B		; abuse i_sreg to hold value
		sbrs	i_sreg, ICES1		; evaluate edge of this interrupt
		.else
		in	i_temp1, TCNT1L		; get timer1 values
		in	i_temp2, TCNT1H
		.if USE_INT0 == 1
		sbis	PIND, rcp_in		; evaluate edge of this interrupt
		.else
		sbic	PIND, rcp_in		; inverted signalling
		.endif
		.endif
		rjmp	falling_edge
rising_edge:
		in	i_sreg, SREG
		; Stuff this rise time plus MAX_RC_PULS into OCR1B.
		; We use this both to save the time it went high and
		; to get an interrupt to indicate high timeout.
		subi	i_temp1, byte1(-MAX_RC_PULS*CPU_MHZ)
		sbci	i_temp2, byte1(-1 - byte2(MAX_RC_PULS*CPU_MHZ))
		out	OCR1BH, i_temp2
		out	OCR1BL, i_temp1
		rcp_int_falling_edge i_temp1	; Set next int to falling edge
		ldi	i_temp1, (1<<OCF1B)	; Clear OCF1B flag
		out	TIFR, i_temp1
		out	SREG, i_sreg
		reti

rcpint_fail:
		in	i_sreg, SREG
		cpse	rc_timeout, ZH
		dec	rc_timeout
		rjmp	rcpint_exit

falling_edge:
		in	i_sreg, TIFR
		sbrc	i_sreg, OCF1B		; Too long high would set OCF1B
		rjmp	rcpint_fail
		in	i_sreg, SREG
		movw	rx_l, i_temp1		; Guaranteed to be valid, store immediately
		in	i_temp1, OCR1BL		; No atomic temp register used to read OCR1* registers
		in	i_temp2, OCR1BH
		subi	i_temp1, byte1(MAX_RC_PULS*CPU_MHZ)	; Put back to start time
		sbci	i_temp2, byte2(MAX_RC_PULS*CPU_MHZ)
		sub	rx_l, i_temp1		; Subtract start time from current time
		sbc	rx_h, i_temp2
.if byte3(MAX_RC_PULS*CPU_MHZ)
.error "MAX_RC_PULS*CPU_MHZ too high to fit in two bytes -- adjust it or the rcp_int code"
.endif
		sbr	flags1, (1<<EVAL_RC)
rcpint_exit:	rcp_int_rising_edge i_temp1	; Set next int to rising edge
		out	SREG, i_sreg
		reti
	.endif
;-----bko-----------------------------------------------------------------
i2c_int:
	.if USE_I2C
		in	i_sreg, SREG
		in	i_temp1, TWSR
		cpi	i_temp1, 0x00		; 00000000b bus error due to illegal start/stop condition
		breq	i2c_io_error
		cpi	i_temp1, 0x60		; 01100000b rx-mode: own SLA+W
		breq	i2c_rx_init
		cpi	i_temp1, 0x80		; 10000000b rx-mode: data available
		breq	i2c_rx_data
		cpi	i_temp1, 0xa0		; 10100000b stop/restart condition (end of message)
		breq	i2c_rx_stop
		cpi	i_temp1, 0xa8		; 10101000b tx-mode: own SLA+R
		breq	i2c_ack
		cpi	i_temp1, 0xb8		; 10111000b tx-mode: data request
		breq	i2c_tx_data
		cpi	i_temp1, 0xf8		; 11111000b no relevant state information
		breq	i2c_io_error
		brne	i2c_unknown		; unknown state, reset all ;-)
i2c_rx_stop:	sbrs	flags0, I2C_FIRST
		sbr	flags1, (1<<EVAL_RC)+(1<<I2C_MODE)	; i2c message received
i2c_unknown:	ldi	i_temp1, (1<<TWIE)+(1<<TWEN)+(1<<TWEA)+(1<<TWINT)
		rjmp	i2c_out
i2c_rx_init:	sbrs	flags1, EVAL_RC		; Skip this message if last one not received
		sbr	flags0, (1<<I2C_FIRST)+(1<<I2C_SPACE_LEFT)
		rjmp	i2c_ack
i2c_rx_data:	sbrs	flags0, I2C_SPACE_LEFT	; Receive buffer has room?
		rjmp	i2c_ack			; No, skip
		sbrs	flags0, I2C_FIRST
		rjmp	i2c_rx_data1
		in	rx_h, TWDR		; Receive high byte from bus
		mov	rx_l, ZH		; Zero low byte (we may not receive it)
		cbr	flags0, (1<<I2C_FIRST)
		rjmp	i2c_ack
i2c_rx_data1:	in	rx_l, TWDR		; Receive low byte from bus (MK FlightCtrl "new protocol")
		cbr	flags0, (1<<I2C_SPACE_LEFT)
		rjmp	i2c_ack
i2c_tx_init:	out	TWDR, ZH		; Send 0 as Current (dummy)
		ldi	i_temp1, 250		; Prepare MaxPWM value (250 when stopped enables proto v2 for MK)
		sbrc	flags1, POWER_OFF
i2c_tx_datarep:	ldi	i_temp1, 255		; Send MaxPWM 255 when running (and repeat for Temperature)
		sts	max_pwm, i_temp1
		rjmp	i2c_ack
i2c_tx_data:	lds	i_temp1, max_pwm	; MaxPWM value (has special meaning for MK)
		out	TWDR, i_temp1
		rjmp	i2c_tx_datarep		; Send 255 for Temperature for which we should get a NACK (0xc0)
i2c_io_error:	in	i_temp1, TWCR
		sbr	i_temp1, (1<<TWSTO)+(1<<TWINT)
		rjmp	i2c_out
i2c_ack:	in	i_temp1, TWCR
		sbr	i_temp1, (1<<TWINT)
i2c_out:	out	TWCR, i_temp1
i2c_ret:	out	SREG, i_sreg
		reti
	.endif
;-----bko-----------------------------------------------------------------
urxc_int:
	; This is Bernhard's serial protocol implementation in the UART
	; version here: http://home.versanet.de/~b-konze/blc_6a/blc_6a.htm
	; This seems to be implemented for a project described here:
	; http://www.control.aau.dk/uav/reports/10gr833/10gr833_student_report.pdf
	; The UART runs at 38400 baud, N81. Input is ignored until >= 0xf5
	; is received, where we start counting to MOTOR_ID, at which
	; the received byte is used as throttle input. 0 is POWER_OFF,
	; >= 200 is FULL_POWER.
	.if USE_UART
		in	i_sreg, SREG
		in	i_temp1, UDR
		cpi	i_temp1, 0xf5		; Start throttle byte sequence
		breq	urxc_x3d_sync
		sbrs	flags0, UART_SYNC
		rjmp	urxc_exit		; Throw away if not UART_SYNC
		brcc	urxc_unknown
		lds	i_temp2, motor_count
		dec	i_temp2
		brne	urxc_set_exit		; Skip when motor_count != 0
		mov	rx_h, i_temp1		; Save 8-bit input
		sbr	flags1, (1<<EVAL_RC)+(1<<UART_MODE)
urxc_unknown:	cbr	flags0, (1<<UART_SYNC)
		rjmp	urxc_exit
urxc_x3d_sync:	sbr	flags0, (1<<UART_SYNC)
		ldi	i_temp2, MOTOR_ID	; Start counting down from MOTOR_ID
urxc_set_exit:	sts	motor_count, i_temp2
urxc_exit:	out	SREG, i_sreg
		reti
	.endif
;-----bko-----------------------------------------------------------------
; beeper: timer0 is set to 1�s/count
beep_f1:	ldi	temp4, 200
		ldi	temp2, 80
		BpFET_on
		AnFET_on
		rjmp	beep

beep_f2:	ldi	temp4, 180
		ldi	temp2, 100
		CpFET_on
		BnFET_on
		rjmp	beep

beep_f3:	ldi	temp4, 160
		ldi	temp2, 120
		ApFET_on
		CnFET_on
		rjmp	beep

beep_f4:	ldi	temp4, 140
		ldi	temp2, 140
		CpFET_on
		AnFET_on
		; Fall through
;-----bko-----------------------------------------------------------------
; Interrupts no longer need to be disabled to beep, but the PWM interrupt
; must be muted first
beep:		in	temp5, PORTB		; Save ON state
		in	temp6, PORTC
		in	temp7, PORTD
beep_on:	out	PORTB, temp5		; Restore ON state
		out	PORTC, temp6
		out	PORTD, temp7
		out	TCNT0, ZH
beep_BpCn10:	in	temp1, TCNT0
		cpi	temp1, 2*CPU_MHZ	; 32�s on
		brlo	beep_BpCn10
		all_nFETs_off temp3
		all_pFETs_off temp3
		ldi	temp3, CPU_MHZ		; 2040�s off
beep_BpCn12:	out	TCNT0, ZH
		wdr
beep_BpCn13:	in	temp1, TCNT0
		cp	temp1, temp4
		brlo	beep_BpCn13
		dec	temp3
		brne	beep_BpCn12
		dec	temp2
		brne	beep_on
		ret

wait240ms:	rcall	wait120ms
wait120ms:	rcall	wait60ms
wait60ms:	rcall	wait30ms
wait30ms:	ldi	temp2, 15
beep_BpCn20:	ldi	temp3, CPU_MHZ
beep_BpCn21:	out	TCNT0, ZH
		ldi	temp1, (1<<TOV0)	; Clear TOV0 by setting it
		out	TIFR, temp1
		wdr
beep_BpCn22:	in	temp1, TIFR
		sbrs	temp1, TOV0
		rjmp	beep_BpCn22
		dec	temp3
		brne	beep_BpCn21
		dec	temp2
		brne	beep_BpCn20
		ret
;-----bko-----------------------------------------------------------------
; Read from or write to the EEPROM block. To avoid duplication, we use the
; global interrupts flag (I) to enable writing versus reading mde. Only
; changed bytes are written. We restore OSCCAL to the boot-time value as
; the EEPROM timing is affected by it. We always return by falling through
; to osccal_set.
eeprom_read_block:				; When interrupts disabled
eeprom_write_block:				; When interrupts enabled
		lds	temp1, orig_osccal
		out	OSCCAL, temp1
		ldi	YL, low(eeprom_sig_l)
		ldi	YH, high(eeprom_sig_l)
		ldi	temp1, low(EEPROM_OFFSET)
		ldi	temp2, high(EEPROM_OFFSET)
eeprom_rw1:	wdr
		sbic	EECR, EEWE
		rjmp	eeprom_rw1		; Loop while writing EEPROM
		in	temp3, SPMCR
		sbrc	temp3, SPMEN
		rjmp	eeprom_rw1		; Loop while flashing
		cpi	YL, low(eeprom_end)
		breq	eeprom_rw4
		out	EEARH, temp2
		out	EEARL, temp1
		adiw	temp1, 1
		sbi	EECR, EERE		; Read existing EEPROM byte
		in	temp3, EEDR
		brie	eeprom_rw2
		st	Y+, temp3		; Store the byte to RAM
		rjmp	eeprom_rw1
eeprom_rw2:	ld	temp4, Y+		; Compare with the byte in RAM
		out	EEDR, temp4
		cli
		sbi	EECR, EEMWE
		cpse	temp3, temp4
		sbi	EECR, EEWE
		sei
		rjmp	eeprom_rw1
eeprom_rw4:	rcall	wait30ms
		; Fall through to set the oscillator calibration
;-----bko-----------------------------------------------------------------
; Set the oscillator calibration for 8MHz operation, or set it to 0xff for
; approximately 16MHz operation even without an external oscillator. This
; should be safe as long as we restore it during EEPROM accesses. This
; will have no effect on boards with external oscillators, except that
; the EEPROM still uses the internal oscillator (at 1MHz).
osccal_set:
.if CPU_MHZ == 16
		ldi	temp1, 0xff		; Almost 16MHz
.else
		ldi	temp1, 0x9f		; Almost 8MHz
.endif
		out	OSCCAL, temp1
		ret
;-----bko-----------------------------------------------------------------
; Shift left temp7:temp6:temp5 temp1 times.
lsl_temp567:
		lsl	temp5
		rol	temp6
		rol	temp7
		dec	temp1
		brne	lsl_temp567
		ret
;-----bko-----------------------------------------------------------------
; Multiply temp1:temp2 by temp3:temp4 and add high 16 bits of result to Y.
; Clobbers temp5, temp6, temp7.
mul_y_12x34:
		mul	temp1, temp3		; Scale raw pulse length to POWER_RANGE: 16x16->32 (bottom 16 discarded)
		mov	temp7, temp6		; Save byte 2 of result, discard byte 1 already
		mul	temp2, temp3
		add	temp7, temp5
		adc	YL, temp6
		adc	YH, ZH
		mul	temp1, temp4
		add	temp7, temp5
		adc	YL, temp6
		adc	YH, ZH
		mul	temp2, temp4
		add	YL, temp5
		adc	YH, temp6		; Product is now in Y, flags set
		ret
;-----bko-----------------------------------------------------------------
; Unlike the normal evaluate_rc, we look here for programming mode (pulses
; above PROGRAM_RC_PULS), unless we have received I2C or UART input.
;
; With pulse width modulation (PWM) input, we have to be careful about
; oscillator drift. If we are running on a board without an external
; crystal/resonator/oscillator, the internal RC oscillator must be used,
; which can drift significantly with temperature and voltage. So, we must
; use some margins while calibrating. The internal RC speeds up when cold,
; causing arming problems if the learned pulse is too low. Likewise, the
; internal RC slows down when hot, making it impossible to reach full
; throttle.
evaluate_rc_init:
		.if USE_UART
		sbrc	flags1, UART_MODE
		rjmp	evaluate_rc_uart
		.endif
		.if USE_I2C
		sbrc	flags1, I2C_MODE
		rjmp	evaluate_rc_i2c
		.endif
		.if USE_ICP || USE_INT0
		cbr	flags1, (1<<EVAL_RC)
	; If input is above PROGRAM_RC_PULS, we try calibrating throttle
		ldi	YL, low(puls_high_l)	; Start with high pulse calibration
		ldi	YH, high(puls_high_l)
		sbrc	flags0, NO_CALIBRATION	; Is it safe to calibrate now?
		rjmp	evaluate_rc_puls
		rjmp	rc_prog1
rc_prog0:	rcall	wait240ms		; Wait for stick movement to settle
	; Collect average of throttle input pulse length
rc_prog1:	movw	temp3, rx_l		; Save the starting pulse length
		wdr
rc_prog2:	mul	ZH, ZH			; Clear 24-bit result registers (0 * 0 -> temp5:temp6)
		clr	temp7
		cpi	YL, low(puls_high_l)	; Are we learning the high pulse?
		brne	rc_prog3		; No, maybe the low pulse
		cpi	temp3, byte1(PROGRAM_RC_PULS * CPU_MHZ)
		ldi	temp1, byte2(PROGRAM_RC_PULS * CPU_MHZ)
		cpc	temp4, temp1
		brcs	evaluate_rc_puls	; Lower than PROGRAM_RC_PULS - exit programming
		ldi	temp1, 32 * 31/32	; Full speed pulse averaging count (slightly below exact)
		rjmp	rc_prog5
rc_prog3:	lds	temp1, puls_high_l	; If not learning the high pulse, we should stay below it
		cp	temp3, temp1
		lds	temp1, puls_high_h
		cpc	temp4, temp1
		brcc	rc_prog1		; Restart while pulse not lower than learned high pulse
		cpi	YL, low(puls_low_l)	; Are we learning the low pulse?
		brne	rc_prog4		; No, must be the neutral pulse
		ldi	temp1, 32 * 17/16	; Stop/reverse pulse (slightly above exact)
		rjmp	rc_prog5
rc_prog4:	lds	temp1, puls_low_l
		cp	temp3, temp1
		lds	temp1, puls_low_h
		cpc	temp4, temp1
		brcs	rc_prog1		; Restart while pulse lower than learned low pulse
		ldi	temp1, 32		; Neutral pulse measurement (exact)
rc_prog5:	mov	tcnt2h, temp1		; Abuse tcnt2h as pulse counter
rc_prog6:	wdr
		sbrs	flags1, EVAL_RC		; Wait for next pulse
		rjmp	rc_prog6
		cbr	flags1, (1<<EVAL_RC)
		movw	temp1, rx_l		; Atomic copy of new rc pulse length
		add	temp5, temp1		; Accumulate 24-bit average
		adc	temp6, temp2
		adc	temp7, ZH
		sub	temp1, temp3		; Subtract the starting pulse from this one
		sbc	temp2, temp4		; to find the drift since the starting pulse
	; Check for excessive drift with an emulated signed comparison -
	; add the drift amount to offset the negative side to 0
		subi	temp1, byte1(-MAX_DRIFT_PULS * CPU_MHZ)
		sbci	temp2, -1 - byte2(MAX_DRIFT_PULS * CPU_MHZ)
	; ..then subtract the 2*drift + 1 -- carry will be clear if
	; we drifted outside of the range
		subi	temp1, byte1(2 * MAX_DRIFT_PULS * CPU_MHZ + 1)
		sbci	temp2, byte2(2 * MAX_DRIFT_PULS * CPU_MHZ + 1)
		brcc	rc_prog0		; Wait and start over if input moved
		dec	tcnt2h
		brne	rc_prog6		; Loop until average accumulated
		ldi	temp1, 3
		rcall	lsl_temp567		; Multiply by 8 (so that 32 loops makes average*256)
		st	Y+, temp6		; Save the top 16 bits as the result
		st	Y+, temp7
	; One beep: high (full speed) pulse received
		rcall	beep_f3
		cpi	YL, low(puls_high_l+2)
		breq	rc_prog1		; Go back to get low pulse
	; Two beeps: low (stop/reverse) pulse received
		rcall	wait30ms
		rcall	beep_f3
		cpi	YL, low(puls_low_l+2)
		.if RC_PULS_REVERSE
		breq	rc_prog1		; Go back to get neutral pulse
		.else
		breq	rc_prog_done
		.endif
	; Three beeps: neutral pulse received
		rcall	wait30ms
		rcall	beep_f3
rc_prog_done:	rcall	eeprom_write_block
		rjmp	puls_scale		; Calculate the new scaling factors
		.endif
;-----bko-----------------------------------------------------------------
evaluate_rc:
		.if USE_UART
		sbrc	flags1, UART_MODE
		rjmp	evaluate_rc_uart
		.endif
		.if USE_I2C
		sbrc	flags1, I2C_MODE
		rjmp	evaluate_rc_i2c
		.endif
	; Fall through to evaluate_rc_puls
;-----bko-----------------------------------------------------------------
.if USE_ICP || USE_INT0
evaluate_rc_puls:
		cbr	flags1, (1<<EVAL_RC)
		lds	YL, neutral_l
		lds	YH, neutral_h
		movw	temp1, rx_l		; Atomic copy of rc pulse length
		sub	temp1, YL
		sbc	temp2, YH
		brcc	puls_plus
		.if RC_PULS_REVERSE
		.if MOTOR_REVERSE
		cbr	flags1, (1<<REVERSE)
		.else
		sbr	flags1, (1<<REVERSE)
		.endif
		com	temp2
		neg	temp1
		sbci	temp2, -1
		lds	temp3, rev_scale_l
		lds	temp4, rev_scale_h
		rjmp	puls_not_zero
		.endif
		; Fall through
puls_zero:	clr	YL
		clr	YH
		rjmp	rc_not_full
puls_plus:
		.if MOTOR_REVERSE
		sbr	flags1, (1<<REVERSE)
		.else
		cbr	flags1, (1<<REVERSE)
		.endif
		lds	temp3, fwd_scale_l
		lds	temp4, fwd_scale_h
puls_not_zero:
		.if RCP_DEADBAND
		subi	temp1, byte1(RCP_DEADBAND * CPU_MHZ)
		sbci	temp2, byte2(RCP_DEADBAND * CPU_MHZ)
		brmi	puls_zero
		.endif
.endif
	; The following is used by all input modes
rc_do_scale:	ldi	YL, byte1(MIN_DUTY)	; Offset result so that 0 is MIN_DUTY
		ldi	YH, byte2(MIN_DUTY)
		rcall	mul_y_12x34		; Scaled result is now in Y
		cpi	YL, byte1(MAX_POWER)
		ldi	temp1, byte2(MAX_POWER)
		cpc	YH, temp1
		brlo	rc_not_full
		ldi	YL, byte1(MAX_POWER)
		ldi	YH, byte2(MAX_POWER)
rc_not_full:	ldi	temp1, RCP_TOT		; Check rc_timeout
		sbrc	flags0, SET_DUTY
		ldi	temp1, 2		; Shorter rc_timeout when driving
		cp	rc_timeout, temp1
		adc	rc_timeout, ZH		; Increment rc_timeout if not at limit
		sts	rc_duty_l, YL
		sts	rc_duty_h, YH
		sbrc	flags0, SET_DUTY
		rjmp	set_new_duty_l		; Skip reload into YL:YH
		ret
;-----bko-----------------------------------------------------------------
.if USE_I2C
evaluate_rc_i2c:
		movw	YL, rx_l		; Atomic copy of 16-bit input
		cbr	flags1, (1<<EVAL_RC)+(1<<REVERSE)
		.if MOTOR_REVERSE
		sbr	flags1, (1<<REVERSE)
		.endif
	; MK sends one or two bytes, if supported, and if low bits are
	; non-zero. We store the first received byte in rx_h, second
	; in rx_l. There are 3 low bits which are stored at the low
	; side of the second byte, so we must shift them to line up with
	; the high byte. The high bits become less significant, if set.
		lsl	YL			; 00000xxxb -> 0000xxx0b
		swap	YL			; 0000xxx0b -> xxx00000b
		adiw	YL, 0			; 16-bit zero-test
		breq	rc_not_full
	; Scale so that YH == 247 is MAX_POWER, to support reaching full
	; power from the highest MaxGas setting in MK-Tools. Bernhard's
	; original version reaches full power at around 245.
		movw	temp1, YL
		ldi	temp3, low(0x100 * (POWER_RANGE - MIN_DUTY) / 247)
		ldi	temp4, high(0x100 * (POWER_RANGE - MIN_DUTY) / 247)
		rjmp	rc_do_scale		; The rest of the code is common
.endif
;-----bko-----------------------------------------------------------------
.if USE_UART
evaluate_rc_uart:
		mov	YH, rx_h		; Copy 8-bit input
		cbr	flags1, (1<<EVAL_RC)+(1<<REVERSE)
		.if MOTOR_REVERSE
		sbr	flags1, (1<<REVERSE)
		.endif
		ldi	YL, 0
		cpi	YH, 0
		breq	rc_not_full
	; Scale so that YH == 200 is MAX_POWER.
		movw	temp1, YL
		ldi	temp3, low(0x100 * (POWER_RANGE - MIN_DUTY) / 200)
		ldi	temp4, high(0x100 * (POWER_RANGE - MIN_DUTY) / 200)
		rjmp	rc_do_scale		; The rest of the code is common
.endif
;-----bko-----------------------------------------------------------------
; Calculate the neutral offset and forward (and reverse) scaling factors
; to line up with the high/low (and neutral) pulse lengths.
puls_scale:
		.if RC_PULS_REVERSE
		lds	temp1, puls_neutral_l
		lds	temp2, puls_neutral_h
		.else
		lds	temp1, puls_low_l
		lds	temp2, puls_low_h
		.endif
		sts	neutral_l, temp1
		sts	neutral_h, temp2
	; Find the distance to full throttle and fit it to match the
	; distance between FULL_RC_PULS and STOP_RC_PULS by walking
	; for the lowest 16.16 multiplier that just brings us in range.
		lds	temp3, puls_high_l
		lds	temp4, puls_high_h
		sub	temp3, temp1
		sbc	temp4, temp2
		rcall	puls_find_multiplicand
		sts	fwd_scale_l, temp1
		sts	fwd_scale_h, temp2
		.if RC_PULS_REVERSE
		lds	temp3, puls_neutral_l
		lds	temp4, puls_neutral_h
		lds	temp1, puls_low_l
		lds	temp2, puls_low_h
		sub	temp3, temp1
		sbc	temp4, temp2
		rcall	puls_find_multiplicand
		sts	rev_scale_l, temp1
		sts	rev_scale_h, temp2
		.endif
		ret
;-----bko-----------------------------------------------------------------
; Find the lowest 16.16 multiplicand that brings us to full throttle
; (POWER_RANGE - MIN_DUTY) when multplied by temp3:temp4.
; The range we are looking for is around 3000 - 10000:
; m = (POWER_RANGE - MIN_DUTY) * 65536 / (1000us * 16MHz)
; If the input range is < 100us at 8MHz, < 50us at 16MHz, we return
; too low a multiplicand (higher won't fit in 16 bits).
puls_find_multiplicand:
		.if RCP_DEADBAND
		subi	temp3, byte1(RCP_DEADBAND * CPU_MHZ)
		sbci	temp4, byte2(RCP_DEADBAND * CPU_MHZ)
		.endif
		ldi	temp1, byte1((POWER_RANGE - MIN_DUTY) * 65536 / MAX_RC_PULS / CPU_MHZ)
		ldi	temp2, byte2((POWER_RANGE - MIN_DUTY) * 65536 / MAX_RC_PULS / CPU_MHZ)
puls_find1:	adiw	temp1, 1
		wdr
		cpi	temp2, 0xff
		cpc	temp1, temp2
		breq	puls_find_fail		; Return if we reached 0xffff
	; Start with negative POWER_RANGE so that 0 is full throttle
		ldi	YL, low(MIN_DUTY - POWER_RANGE)
		ldi	YH, high(MIN_DUTY - POWER_RANGE)
		rcall	mul_y_12x34
	; We will always be increasing the result in steps of less than 1,
	; so we can test for just zero rather than a range.
		brne	puls_find1
puls_find_fail:	ret
;-----bko-----------------------------------------------------------------
update_timing:
		cli
		in	temp1, TCNT1L
		in	temp2, TCNT1H
		lds	temp3, tcnt1x
		in	temp4, TIFR
		sei
		cpi	temp2, 0x80		; tcnt1x is right when TCNT1h[7] set;
		sbrc	temp4, TOV1		; otherwise, if TOV1 is/was pending,
		adc	temp3, ZH		; increment our copy of tcnt1x.

	; Calculate the timing from the last two zero-crossings
		lds	YL, last_tcnt1_l	; last -> Y
		lds	YH, last_tcnt1_h
		lds	temp7, last_tcnt1_x
		sts	last_tcnt1_l, temp1
		sts	last_tcnt1_h, temp2
		sts	last_tcnt1_x, temp3
		lds	temp5, l2_tcnt1_l	; last2 -> temp5
		lds	temp6, l2_tcnt1_h
		lds	temp4, l2_tcnt1_x
		sts	l2_tcnt1_l, YL
		sts	l2_tcnt1_h, YH
		sts	l2_tcnt1_x, temp7

	; Cancel DC bias by starting our timing from the average of the
	; last two zero-crossings. Commutation phases always alternate.
	; Next start = (cur(c) - last2(a)) / 2 + last(b)
	; -> start=(c-b+(c-a)/2)/2+b
	;
	;                  (c - a)
	;         (c - b + -------)
	;                     2
	; start = ----------------- + b
	;                 2

		sub	temp1, temp5		; c' = c - a
		sbc	temp2, temp6
		sbc	temp3, temp4

	; Limit maximum RPM (fastest timing)
		cpi	temp1, byte1(TIMING_MAX*CPU_MHZ/2)
		ldi	temp4, byte2(TIMING_MAX*CPU_MHZ/2)
		cpc	temp2, temp4
		ldi	temp4, byte3(TIMING_MAX*CPU_MHZ/2)
		cpc	temp3, temp4
		brcc	update_timing1
		ldi	temp1, byte1(TIMING_MAX*CPU_MHZ/2)
		ldi	temp2, byte2(TIMING_MAX*CPU_MHZ/2)
		ldi	temp3, byte3(TIMING_MAX*CPU_MHZ/2)
		lsr	sys_control_h		; limit by reducing power
		ror	sys_control_l
		rjmp	update_timing2
update_timing1:

	; Limit minimum RPM (slowest timing)
		cpi	temp2, byte2(TIMING_MIN*CPU_MHZ/2)
		ldi	temp4, byte3(TIMING_MIN*CPU_MHZ/2)
		cpc	temp3, temp4
		brcs	update_timing2
		ldi	temp3, byte3(TIMING_MIN*CPU_MHZ/2)
		ldi	temp2, byte2(TIMING_MIN*CPU_MHZ/2)
		ldi	temp1, byte1(TIMING_MIN*CPU_MHZ/2)
update_timing2:

	; Calculate a hopefully sane duty cycle limit from this timing,
	; to prevent excessive current if high duty is requested when the
	; current duty is low. This is the best we can do without a current
	; sensor. The actual current will depend on motor KV and voltage,
	; so this is just an approximation. It would be nice if we could
	; do this with math instead of two constants, but we need a divide.
	; Clobbers only temp4. Fastest in case of fastest timing.
		cpi	temp2, byte2(TIMING_RANGE2*CPU_MHZ/2)
		ldi	temp4, byte3(TIMING_RANGE2*CPU_MHZ/2)
		cpc	temp3, temp4
		ldi	temp4, low(MAX_POWER)
		sts	timing_duty_l, temp4
		ldi	temp4, high(MAX_POWER)
		brcs	update_timing4
		cpi	temp2, byte2(TIMING_RANGE1*CPU_MHZ/2)
		ldi	temp4, byte3(TIMING_RANGE1*CPU_MHZ/2)
		cpc	temp3, temp4
		ldi	temp4, low(PWR_MAX_RPM2)
		sts	timing_duty_l, temp4
		ldi	temp4, high(PWR_MAX_RPM2)
		brcs	update_timing4
		ldi	temp4, low(PWR_MAX_RPM1)
		sts	timing_duty_l, temp4
		ldi	temp4, high(PWR_MAX_RPM1)
update_timing4:	sts	timing_duty_h, temp4

		mov	temp4, temp2		; Copy high and check extended byte
		cpse	temp3, ZH		; We work with 1/256th of timing
		ldi	temp4, 0xff
.if TIMING_MAX*CPU_MHZ / 0x100 < 3
.error "TIMING_MAX is too fast for at least 3 zero-cross checks -- increase it or adjust this"
.endif
		sts	zc_filter_time, temp4	; Save zero cross filter time

		lsr	temp3			; c'>>= 1 (shift to 60 degrees)
		ror	temp2
		ror	temp1

		lds	temp5, last_tcnt1_l	; restore original c as a'
		lds	temp6, last_tcnt1_h
		lds	temp4, last_tcnt1_x
		sub	temp5, YL		; a'-= b
		sbc	temp6, YH
		sbc	temp4, temp7

		add	temp5, temp1		; a'+= c'
		adc	temp6, temp2
		adc	temp4, temp3
		lsr	temp4			; a'>>= 1
		ror	temp6
		ror	temp5
		add	YL, temp5		; b+= a' -> YL:YH:temp7 become next start
		adc	YH, temp6
		adc	temp7, temp4

		movw	temp5, YL		; Copy YL:YH:temp7 to temp5
		mov	temp4, temp7
		add	temp5, temp1
		adc	temp6, temp2
		adc	temp4, temp3
		add	temp5, temp1
		adc	temp6, temp2
		adc	temp4, temp3
		sts	t_zc_wait_l, temp5	; save zero crossing timeout (120 degrees)
		sts	t_zc_wait_h, temp6
		sts	t_zc_wait_x, temp4

		ldi	temp4, (30 - MOTOR_ADVANCE) * 256 / 60
		rcall	update_timing_add_degrees
		push	YL
		push	YH
		push	temp7
		ldi	temp4, 13 * 256 / 60
		rcall	update_timing_add_degrees
		sts	t_minblank_l, YL
		sts	t_minblank_h, YH
		sts	t_minblank_x, temp7
		ldi	temp4, 29 * 256 / 60
		rcall	update_timing_add_degrees
		sts	t_maxblank_l, YL
		sts	t_maxblank_h, YH
		sts	t_maxblank_x, temp7

		pop	temp7
		pop	YH
		pop	YL
		rcall	set_ocr1a_abs		; Set commutation timeout

		sbrc	flags1, EVAL_RC
		rjmp	evaluate_rc		; Set new duty either way
		rjmp	set_new_duty
;-----bko-----------------------------------------------------------------
; Multiply the 24-bit timing in temp1:temp2:temp3 by temp4 and add the top
; 24-bits to YL:YH:temp7.
update_timing_add_degrees:
		mul	temp1, temp4
		add	YL, temp6		; Discard byte 1 already
		adc	YH, ZH
		adc	temp7, ZH
		mul	temp2, temp4
		add	YL, temp5
		adc	YH, temp6
		adc	temp7, ZH
		mul	temp3, temp4
		add	YH, temp5
		adc	temp7, temp6
		ret
;-----bko-----------------------------------------------------------------
; Set OCT1_PENDING until the absolute time specified by YL:YH:temp7 passes.
; Returns current TCNT1(L:H:X) value in temp1:temp2:temp3.
;
; tcnt1x may not be updated until many instructions later, even with
; interrupts enabled, because the AVR always executes one non-interrupt
; instruction between interrupts, and several other higher-priority
; interrupts may (have) come up. So, we must save tcnt1x and TIFR with
; interrupts disabled, then do a correction.
set_ocr1a_abs:
		ldi	temp4, (1<<TOIE1)+(1<<TOIE2)
		out	TIMSK, temp4		; Disable OCIE1A temporarily
		ldi	temp4, (1<<OCF1A)
		cli
		out	OCR1AH, YH
		out	OCR1AL, YL
		out	TIFR, temp4		; Clear any pending OCF1A interrupt
		in	temp1, TCNT1L
		in	temp2, TCNT1H
		lds	temp3, tcnt1x
		in	temp4, TIFR
		sei
		sbr	flags0, (1<<OCT1_PENDING)
		cpi	temp2, 0x80		; tcnt1x is right when TCNT1h[7] set;
		sbrc	temp4, TOV1		; otherwise, if TOV1 is/was pending,
		adc	temp3, ZH		; increment our copy of tcnt1x.
		sub	YL, temp1		; Check that time might have already
		sbc	YH, temp2		; passed -- if so, clear pending flag.
		sbc	temp7, temp3
		sts	ocr1ax, temp7
		brpl	set_ocr1a_abs1		; Skip set if time has passed
		cbr	flags0, (1<<OCT1_PENDING)
set_ocr1a_abs1:	ldi	temp4, (1<<TOIE1)+(1<<OCIE1A)+(1<<TOIE2)
		out	TIMSK, temp4		; Enable OCIE1A again
		ret
;-----bko-----------------------------------------------------------------
; Set OCT1_PENDING until the relative time specified by YL:YH:temp7 passes.
set_ocr1a_rel:	adiw	YL, 7			; Compensate for timer increment during in-add-out
		ldi	temp4, (1<<OCF1A)
		cli
		in	temp1, TCNT1L
		in	temp2, TCNT1H
		add	YL, temp1
		adc	YH, temp2
		out	OCR1AH, YH
		out	OCR1AL, YL
		out	TIFR, temp4		; Clear any pending OCF1A interrupt (7 cycles from TCNT1 read)
		sts	ocr1ax, temp7
		sbr	flags0, (1<<OCT1_PENDING)
		sei
		ret
;-----bko-----------------------------------------------------------------
wait_OCT1_tot:	sbrc	flags1, EVAL_RC
		rcall	evaluate_rc
		sbrc	flags0, OCT1_PENDING
		rjmp	wait_OCT1_tot		; Wait for commutation time
		ret
;-----bko-----------------------------------------------------------------
set_new_duty:	lds	YL, rc_duty_l
		lds	YH, rc_duty_h
set_new_duty_l:	lds	temp1, timing_duty_l
		lds	temp2, timing_duty_h
		cp	YL, temp1
		cpc	YH, temp2
		brcs	set_new_duty10
		movw	YL, temp1		; Limit duty to timing_duty
set_new_duty10:	cp	YL, sys_control_l
		cpc	YH, sys_control_h
		brcs	set_new_duty11
		movw	YL, sys_control_l	; Limit duty to sys_control
set_new_duty11:
.if SLOW_THROTTLE
		; If sys_control is higher than twice the current duty,
		; limit it to that. This means that a steady-state duty
		; cycle can double at any time, but any larger change will
		; be rate-limited.
		ldi	temp1, low(PWR_MIN_START)
		ldi	temp2, high(PWR_MIN_START)
		cp	YL, temp1
		cpc	YH, temp2
		brcs	set_new_duty12
		movw	temp1, YL		; temp1:temp2 >= PWR_MIN_START
set_new_duty12:	lsl	temp1
		rol	temp2
		cp	sys_control_l, temp1
		cpc	sys_control_h, temp2
		brcs	set_new_duty13
		movw	sys_control_l, temp1
set_new_duty13:
.endif
		ldi	temp1, low(MAX_POWER)
		ldi	temp2, high(MAX_POWER)
		sub	temp1, YL		; Calculate OFF duty
		sbc	temp2, YH
		breq	set_new_duty_full
		cbr	flags1, (1<<FULL_POWER)
		cp	YL, ZH
		cpc	YH, ZH
		breq	set_new_duty_zero
		; Not off and not full power
		; Halve PWM frequency when starting (helps hard drive startup)
		lds	temp3, goodies
		cpi	temp3, ENOUGH_GOODIES
		brcc	set_new_duty_set
		lsl	temp1
		rol	temp2
		lsl	YL
		rol	YH
set_new_duty_set:
		cbr	flags1, (1<<POWER_OFF)
set_new_duty_set_off:
		com	YL			; Save one's complement of both
		com	temp1			; low bytes for up-counting TCNT2
		movw	duty_l, YL		; Atomic set of new ON duty for PWM interrupt
		movw	off_duty_l, temp1	; Atomic set of new OFF duty for PWM interrupt
		ret
set_new_duty_full:
		; Full power
		sbr	flags1, (1<<FULL_POWER)
		rjmp	set_new_duty_set
set_new_duty_zero:
		; Power off
		sbr	flags1, (1<<POWER_OFF)
		rjmp	set_new_duty_set_off
;-----bko-----------------------------------------------------------------
switch_power_off:
		out	TCCR2, ZH		; Disable PWM
		ldi	temp1, (1<<TOV2)
		out	TIFR, temp1		; Clear pending PWM interrupts
		ldi	ZL, low(pwm_wdr)	; Stop PWM switching
		all_pFETs_off temp1
		all_nFETs_off temp1
		ret
;-----bko-----------------------------------------------------------------
control_start:
	; status led on
		GRN_on

		rcall	puls_scale

	; init registers and interrupts
		ldi	temp1, (1<<TOIE1)+(1<<OCIE1A)+(1<<TOIE2)
		out	TIFR, temp1		; clear TOIE1, OCIE1A, and TOIE2
		out	TIMSK, temp1		; enable TOIE1, OCIE1A, and TOIE2 interrupts

		.if defined(HK_PROGRAM_CARD)
	; This program card seems to send data at 1200 baud N81,
	; Messages start with 0xdd 0xdd, have 7 bytes of config,
	; and end with 0xde, sent two seconds after power-up or
	; after any jumper change.
		.equ	BAUD_RATE = 1200
		.equ	UBRR_VAL = F_CPU / BAUD_RATE / 16 - 1
		ldi	temp1, high(UBRR_VAL)
		out	UBRRH, temp1
		ldi	temp1, low(UBRR_VAL)
		out	UBRRL, temp1
		ldi	temp1, (1<<RXEN)	; Do programming card rx by polling
		out	UCSRB, temp1
		ldi	temp1, (1<<URSEL)|(1<<UCSZ1)|(1<<UCSZ0)
		out	UCSRC, temp1
		.endif

	; init input sources (i2c and/or rc-puls)
		.if USE_UART && !defined(HK_PROGRAM_CARD)
		.equ	BAUD_RATE = 38400
		.equ	UBRR_VAL = F_CPU / BAUD_RATE / 16 - 1
		ldi	temp1, high(UBRR_VAL)
		out	UBRRH, temp1
		ldi	temp1, low(UBRR_VAL)
		out	UBRRL, temp1
		ldi	temp1, (1<<RXEN)+(0<<RXCIE)	; We don't actually tx
		out	UCSRB, temp1
		ldi	temp1, (1<<URSEL)|(1<<UCSZ1)|(1<<UCSZ0)	; N81
		out	UCSRC, temp1
		in	temp1, UDR
		in	temp1, UDR
		in	temp1, UDR
		sbi	UCSRA, RXC		; clear flag
		sbi	UCSRB, RXCIE		; enable reception irq
		.endif
		.if USE_I2C
		sbr	flags0, (1<<I2C_FIRST)+(1<<I2C_SPACE_LEFT)
		ldi	temp1, I2C_ADDR + (MOTOR_ID << 1)
		out	TWAR, temp1
		ldi	temp1, (1<<TWIE)+(1<<TWEN)+(1<<TWEA)+(1<<TWINT)
		out	TWCR, temp1
		.endif
		.if USE_INT0 || USE_ICP
		rcp_int_rising_edge temp1
		rcp_int_enable temp1
		.endif

		sei				; enable all interrupts

i_rc_puls1:	clr	rc_timeout
		cbr	flags1, (1<<EVAL_RC)+(1<<I2C_MODE)+(1<<UART_MODE)
i_rc_puls2:	wdr
		.if defined(HK_PROGRAM_CARD)
		.endif
		sbrs	flags1, EVAL_RC
		rjmp	i_rc_puls2
		rcall	evaluate_rc_init
		lds	YL, rc_duty_l
		lds	YH, rc_duty_h
		adiw	YL, 0			; Test for zero
		brne	i_rc_puls1
		ldi	temp1, 10		; wait for this count of receiving power off
		cp	rc_timeout, temp1
		brlo	i_rc_puls2
		.if USE_I2C
		sbrs	flags1, I2C_MODE
		out	TWCR, ZH		; Turn off I2C and interrupt
		.endif
		.if USE_UART
		sbrs	flags1, UART_MODE
		out	UCSRB, ZH		; Turn off UART and interrupt
		.endif
		.if USE_INT0 || USE_ICP
		mov	temp1, flags1
		andi	temp1, (1<<I2C_MODE)+(1<<UART_MODE)
		breq	i_rc_puls3
		rcp_int_disable temp1		; Turn off RC pulse interrupt
i_rc_puls3:
		.endif
		rcall	beep_f4			; signal: rcpuls ready
		rcall	beep_f4
		rcall	beep_f4
	; Fall through to init_startup
;-----bko-----------------------------------------------------------------
init_startup:
		rcall	switch_power_off	; Disables PWM timer, turns off all FETs
		cbr	flags0, (1<<SET_DUTY)	; Do not yet set duty on input
		.if MOTOR_BRAKE
		ldi	YL, low(BRAKE_POWER)
		ldi	YH, high(BRAKE_POWER)
		ldi	temp1, low(MAX_POWER)
		ldi	temp2, high(MAX_POWER)
		sub	temp1, YL		; Calculate OFF duty
		sbc	temp2, YH
		rcall	set_new_duty_set_off
		ldi	ZL, low(pwm_brake_off)	; Enable PWM brake mode
		clr	sys_control_l		; Abused as duty update divisor
		ldi	temp1, T2CLK
		out	TCCR2, temp1		; Enable PWM, cleared later by switch_power_off
		.endif
		.if BEACON
		clr	temp4			; Wait 256 30ms periods before first beep
		.endif
wait_for_power_on:
		wdr
		.if BEACON
		tst	rc_timeout
		brne	wait_for_power_on1
		rcall	wait30ms
		dec	temp4
		brne	wait_for_power_on1
		rcall	beep_f3
		ldi	temp4, 80		; Beep every 256 - 80 30ms periods
wait_for_power_on1:
		.endif
		sbrs	flags1, EVAL_RC
		rjmp	wait_for_power_on
		rcall	evaluate_rc		; Only get rc_duty, don't set duty
		lds	YL, rc_duty_l
		lds	YH, rc_duty_h
		adiw	YL, 0			; Test for zero
		breq	wait_for_power_on
		tst	rc_timeout
		breq	wait_for_power_on

start_from_running:
		rcall	switch_power_off
		comp_init temp1			; init comparator
		RED_off

		rcall	wait_timeout		; Set sys_control (start power), STARTUP flag
		sbr	flags0, (1<<SET_DUTY)
		rcall	update_timing		; Clears POWER_OFF, sets duty, sets last_tcnt1

		rcall	com5com6		; Enable pFET if not POWER_OFF
		rcall	com6com1		; Set comparator phase and nFET vector
		cbr	flags2, ALL_FETS	; Disable PWM (powerskip) 6 cycles at start
		ldi	temp1, 6		; to see if motor is running and align to it.
		sts	powerskip, temp1
		ldi	temp1, ENOUGH_GOODIES	; If we can start without a timeout, not need
		sts	goodies, temp1		; for blanking. Prime goodies.
		ldi	temp1, T2CLK
		out	TCCR2, temp1		; Enable PWM (ZL has been set to pwm_wdr)

;-----bko-----------------------------------------------------------------
; **** running control loop ****

run1:		sbrc	flags1, REVERSE
		rjmp	run_reverse

run_forward:	rcall	wait_for_high
		rcall	com1com2
		rcall	wait_for_low
		rcall	com2com3
		rcall	wait_for_high
		rcall	com3com4
		sync_on
		rcall	wait_for_low
		rcall	com4com5
		sync_off
		rcall	wait_for_high
		rcall	com5com6
		rcall	wait_for_low
		rcall	com6com1
		rjmp	run6

run_reverse:	rcall	wait_for_low
		rcall	com1com6
		rcall	wait_for_high
		rcall	com6com5
		rcall	wait_for_low
		rcall	com5com4
		sync_on
		rcall	wait_for_high
		rcall	com4com3
		sync_off
		rcall	wait_for_low
		rcall	com3com2
		rcall	wait_for_high
		rcall	com2com1
run6:
		.if MOTOR_BRAKE
		; Brake immediately whenever power is off
		sbrc	flags1, POWER_OFF
		rjmp	run_to_brake
		.else
		; If last commutation timed out and power is off, return to init_startup
		lds	temp1, goodies
		cpi	temp1, 0
		sbrc	flags1, POWER_OFF
		breq	run_to_brake
		.endif
		movw	YL, sys_control_l
		adiw	YL, 0			; Test for zero
		breq	start_from_running
		lds	temp1, goodies
		cpi	temp1, ENOUGH_GOODIES
		brcc	run6_2
		inc	temp1
		sts	goodies, temp1
		; Build up sys_control to PWR_MAX_START in steps.
		adiw	YL, ((PWR_MAX_START - PWR_MIN_START) + 3) / 4
		ldi	temp1, low(PWR_MAX_START)
		ldi	temp2, high(PWR_MAX_START)
		rjmp	run6_3

run6_2:		cbr	flags1, (1<<STARTUP)
		; Build up sys_control to MAX_POWER in steps.
		; If SLOW_THROTTLE is disabled, this only limits
		; initial start ramp-up; once running, sys_control
		; will stay at MAX_POWER unless timing is lost.
		.equ SLOW_THROTTLE_STEPS = (POWER_RANGE + 31) / 32
		.if SLOW_THROTTLE_STEPS > 63
		subi	YL, byte1(-SLOW_THROTTLE_STEPS)
		sbci	YH, -1 - byte2(SLOW_THROTTLE_STEPS)
		.else
		adiw	YL, SLOW_THROTTLE_STEPS
		.endif
		ldi	temp1, low(MAX_POWER)
		ldi	temp2, high(MAX_POWER)
run6_3:		cp	YL, temp1
		cpc	YH, temp2
		brcs	run6_4
		movw	sys_control_l, temp1
		rjmp	run1
run6_4:		movw	sys_control_l, YL
		rjmp	run1

restart_control:
		rcall	switch_power_off
		rcall	wait30ms
		rcall	beep_f3
		rcall	beep_f2
		rcall	wait30ms
run_to_brake:	rjmp	init_startup

;-----bko-----------------------------------------------------------------
demag_timeout:
		ldi	ZL, low(pwm_wdr)	; Stop PWM switching
		; Interrupts will not turn on any FETs now
		.if COMP_PWM
		; Turn off complementary PWM if it was on,
		; but leave on the high side commutation FET.
		sbrc	flags2, A_FET
		ApFET_off
		sbrc	flags2, B_FET
		BpFET_off
		sbrc	flags2, C_FET
		CpFET_off
		.endif
		all_nFETs_off temp1
		cbr	flags2, ALL_FETS
		rjmp	wait_commutation
;-----bko-----------------------------------------------------------------
wait_timeout:	sts	goodies, ZH
		sbr	flags1, (1<<STARTUP)
		ldi	YL, low(PWR_MIN_START)	; Reduce power since this
		ldi	YH, high(PWR_MIN_START)	; should only happen in a
		movw	sys_control_l, YL	; motor stall situation.
		ret
;-----bko-----------------------------------------------------------------
wait_for_low:	cbr	flags1, (1<<ACO_EDGE_HIGH)
		rjmp	wait_for_edge
;-----bko-----------------------------------------------------------------
wait_for_high:	sbr	flags1, (1<<ACO_EDGE_HIGH)
;-----bko-----------------------------------------------------------------
; Here we wait for the zero-crossing on the undriven phase to synchronize
; with the motor timing. The voltage of the undriven phase should cross
; the average of all three phases at half of the way into the 60-degree
; commutation period.
;
; The voltage on the undriven phase is affected by noise from PWM (mutual
; inductance) and also the demagnetization from the previous commutation
; step. Demagnetization time is proportional to motor current, and in
; extreme cases, may take more than 30 degrees to complete. To avoid
; sensing erroneous early zero-crossings in this case and losing motor
; synchronization, we check that demagnetization has finished after the
; minimum blanking period. If we do not see it by the maximum blanking
; period (about 30 degrees since we commutated last), we turn off power
; and ontinue as if the ZC had occurred. PWM is enabled again after the
; next commutation step.
;
; Normally, we wait for the blanking window to pass, look for the
; comparator to swing as the sign of the zero crossing, wait for the
; timing delay, and then commutate.
;
; Simulations show that the demagnetization period shows up on the phase
; being monitored by the comparator with no PWM-induced noise. As such,
; we do not need any filtering. However, it may not show up immediately
; due to filtering capacitors, hence the initial blind minimum blanking
; period.
;
wait_for_edge:
		lds	temp1, powerskip	; Are we trying to track a maybe running motor?
		tst	temp1
		breq	wait_pwm_enable
		dec	temp1
		sts	powerskip, temp1
		sbrs	flags1, STARTUP
		rjmp	wait_for_blank
	; Special case when powerskipping during start: skip blanking, use
	; timeoutMIN, skip demag check, and use a short zc_filter_time.
	; The idea here is to learn the timing of a possibly-spinning motor
	; while not driving it, which would induce demagnetization and PWM
	; noise that we cannot ignore until we konw the timing. If this
	; times out, we enable power and start as normal.
		ldi	YL, byte1(timeoutMIN*CPU_MHZ)
		ldi	YH, byte2(timeoutMIN*CPU_MHZ)
		ldi	temp4, byte3(timeoutMIN*CPU_MHZ)
		mov	temp7, temp4
		rcall	set_ocr1a_rel
		ldi	XL, 4
		mov	XH, XL
		rjmp	wait_for_edge2
wait_pwm_enable:
		cpi	ZL, low(pwm_wdr)
		brne	wait_pwm_running
		ldi	ZL, low(pwm_off)	; Re-enable PWM if disabled for powerskip or sync loss avoidance
wait_pwm_running:
		sbrs	flags1, STARTUP
		rjmp	wait_for_blank
	; Powered startup: skip blanking and commutation wait,
	; and use a fixed zc_filter_time until goodies reaches
	; ENOUGH_GOODIES and we clear the STARTUP flag.
		lds	YL, wt_OCT1_tot_l	; Load the start commutation
		lds	YH, wt_OCT1_tot_h	; timeout into YL:YH:temp7 and
		lds	temp7, wt_OCT1_tot_x	; subtract a "random" amount
		in	temp4, TCNT0
		andi	temp4, 0x1f
		sub	YH, temp4
		sbc	temp7, ZH
		brcs	start_timeout1
		cpi	YL, byte1(timeoutMIN*CPU_MHZ)
		ldi	temp4, byte2(timeoutMIN*CPU_MHZ)
		cpc	YH, temp4
		ldi	temp4, byte3(timeoutMIN*CPU_MHZ)
		cpc	temp7, temp4
		brcc	start_timeout2
start_timeout1:	ldi	YL, byte1(timeoutSTART*CPU_MHZ)
		ldi	YH, byte2(timeoutSTART*CPU_MHZ)
		ldi	temp4, byte3(timeoutSTART*CPU_MHZ)
		mov	temp7, temp4
start_timeout2:	sts	wt_OCT1_tot_l, YL
		sts	wt_OCT1_tot_h, YH
		sts	wt_OCT1_tot_x, temp7
		rcall	set_ocr1a_rel
		ldi	temp4, 0xff		; Force full zc_filter_time.
		sts	zc_filter_time, temp4
		rjmp	wait_for_demag

wait_for_blank:
		lds	YL, t_minblank_l
		lds	YH, t_minblank_h
		lds	temp7, t_minblank_x
		rcall	set_ocr1a_abs		; Wait for the blanking period
		rcall	wait_OCT1_tot

		lds	YL, t_maxblank_l
		lds	YH, t_maxblank_h
		lds	temp7, t_maxblank_x
		rcall	set_ocr1a_abs		; Wait up until the expected ZC point

wait_for_demag:
		sbrs	flags0, OCT1_PENDING
		rjmp	demag_timeout
		sbrc	flags1, EVAL_RC
		rcall	evaluate_rc
		in	temp3, ACSR
		eor	temp3, flags1
		sbrc	temp3, ACO		; Check for opposite level (demagnetization)
		rjmp	wait_for_demag

		lds	YL, t_zc_wait_l
		lds	YH, t_zc_wait_h
		lds	temp7, t_zc_wait_x
		sbrs	flags1, STARTUP
		rcall	set_ocr1a_abs

wait_for_edge1:	lds	XH, zc_filter_time
		mov	XL, XH
wait_for_edge2:	sbrs	flags0, OCT1_PENDING
		rjmp	wait_timeout
		sbrc	flags1, EVAL_RC
		rcall	evaluate_rc
		in	temp3, ACSR
		eor	temp3, flags1
		sbrc	temp3, ACO
		rjmp	wait_for_edge3
		cp	XL, XH			; Not yet crossed
		adc	XL, ZH			; Increment if not at zc_filter
		rjmp	wait_for_edge2
wait_for_edge3:	dec	XL			; Zero-cross has happened
		brne	wait_for_edge2		; Check again unless temp1 is zero

wait_commutation:
		rcall	update_timing
		flag_on
		sbrs	flags1, STARTUP
		rcall	wait_OCT1_tot
		flag_off
		cpse	rc_timeout, ZH
		ret
		pop	temp1			; Throw away return address
		pop	temp1
		rjmp	restart_control		; Restart control immediately on RC timeout
;-----bko-----------------------------------------------------------------
; *** commutation utilities ***
com1com2:	; Bp off, Ap on
		set_comp_phase_b temp1
		BpFET_off
		sbrs	flags1, POWER_OFF
		ApFET_on
		ret

com2com1:	; Bp on, Ap off
		set_comp_phase_a temp1
		ApFET_off
		sbrs	flags1, POWER_OFF
		BpFET_on
		ret

com2com3:	; Cn off, Bn on
		set_comp_phase_c temp1
		cli
		cbr	flags2, ALL_FETS
		sbrs	flags1, POWER_OFF
		sbr	flags2, (1<<B_FET)
		.if COMP_PWM
		CpFET_off
		.endif
		in	temp1, CnFET_port
		CnFET_off
		in	temp2, CnFET_port
		cpse	temp1, temp2
		BnFET_on
		sei
		ret

com3com2:	; Cn on, Bn off
		set_comp_phase_b temp1
		cli
		cbr	flags2, ALL_FETS
		sbrs	flags1, POWER_OFF
		sbr	flags2, (1<<C_FET)
		.if COMP_PWM
		BpFET_off
		.endif
		in	temp1, BnFET_port
		BnFET_off
		in	temp2, BnFET_port
		cpse	temp1, temp2
		CnFET_on
		sei
		ret

com3com4:	; Ap off, Cp on
		set_comp_phase_a temp1
		ApFET_off
		sbrs	flags1, POWER_OFF
		CpFET_on
		ret

com4com3:	; Ap on, Cp off
		set_comp_phase_c temp1
		CpFET_off
		sbrs	flags1, POWER_OFF
		ApFET_on
		ret

com4com5:	; Bn off, An on
		set_comp_phase_b temp1
		cli
		cbr	flags2, ALL_FETS
		sbrs	flags1, POWER_OFF
		sbr	flags2, (1<<A_FET)
		.if COMP_PWM
		BpFET_off
		.endif
		in	temp1, BnFET_port
		BnFET_off
		in	temp2, BnFET_port
		cpse	temp1, temp2
		AnFET_on
		sei
		ret

com5com4:	; Bn on, An off
		set_comp_phase_a temp1
		cli
		cbr	flags2, ALL_FETS
		sbrs	flags1, POWER_OFF
		sbr	flags2, (1<<B_FET)
		.if COMP_PWM
		ApFET_off
		.endif
		in	temp1, AnFET_port
		AnFET_off
		in	temp2, AnFET_port
		cpse	temp1, temp2
		BnFET_on
		sei
		ret

com5com6:	; Cp off, Bp on
		set_comp_phase_c temp1
		CpFET_off
		sbrs	flags1, POWER_OFF
		BpFET_on
		ret

com6com5:	; Cp on, Bp off
		set_comp_phase_b temp1
		BpFET_off
		sbrs	flags1, POWER_OFF
		CpFET_on
		ret

com6com1:	; An off, Cn on
		set_comp_phase_a temp1
		cli
		cbr	flags2, ALL_FETS
		sbrs	flags1, POWER_OFF
		sbr	flags2, (1<<C_FET)
		.if COMP_PWM
		ApFET_off
		.endif
		in	temp1, AnFET_port
		AnFET_off
		in	temp2, AnFET_port
		cpse	temp1, temp2
		CnFET_on
		sei
		ret

com1com6:	; An on, Cn off
		set_comp_phase_c temp1
		cli
		cbr	flags2, ALL_FETS
		sbrs	flags1, POWER_OFF
		sbr	flags2, (1<<A_FET)
		.if COMP_PWM
		CpFET_off
		.endif
		in	temp1, CnFET_port
		CnFET_off
		in	temp2, CnFET_port
		cpse	temp1, temp2
		AnFET_on
		sei
		ret

.if BOOT_LOADER
;-----bko-----------------------------------------------------------------
; Simple boot loader on PWM input pin.
;
; We stay here as long as the input pin is pulled high, which is typical
; for the Turnigy USB Linker. The Turnigy USB Linker sports a SiLabs MCU
; (5V tolerant I/O) which converts 9600baud serial output from a SiLabs
; CP2102 USB-to-serial converter to a half duplex wire encoding which
; avoids signalling that can look like valid drive pulses. All bits are
; either one or two pulses, as opposed to a serial UART which could go
; high or low for a long time. This means it _should_ be safe to signal
; even to an armed ESC, as long as the low end has not been calibrated
; or set to start at pulses shorter than the linker timing.
;
; All transmissions have a leader of three 0xff bytes plus one 0-bit.
; Bit encoding starts at the least significant bit and is 8 bits wide.
; 1-bits are encoded as 64.0us high, 72.8us low (135.8us total).
; 0-bits are encoded as 27.8us high, 34.5us low, 34.4us high, 37.9 low
; (134.6us total)
; End of encoding adds 34.0us high, then return to input mode.
; The last 0-bit low time is 32.6us instead of 37.9us, for some reason.
;
; We always learn the actual timing from the host's leader. It seems to
; be possible to respond faster or slower, but faster will cause drops
; between the host and its serial-to-USB conversion at 9600baud. It does
; seem to work to use an average of high and low times as the actual bit
; timing, but since it doesn't quite fit in one byte at clk/8 at 16MHz,
; we store the high and low times separately, and copy the same timings.
; We should still work even at many times the bit rate.
;
; We support self-flashing ourselves (yo dawg), but doing so in a way
; that can still respond after each page update is a bit tricky. Some
; nops are present for future expansion without bumping addresses.
;
; We implement STK500v2, as recommended by the avrdude author, rather
; than implementing a random new protocol. STK500v2 protocol is the only
; serial protocol that passes the chip signature bytes directly instead
; of using a lookup table. However, avrdude uses CMD_SPI_MULTI to get
; these, which is for direct SPI access. We have to catch this and fake
; the response. We respond to CMD_SIGN_ON with "AVRISP_2", which keeps
; all messaes in the same format and with xor-checksums. We could say
; "AVRISP_MK2" and drop the message structure after sign-on, but then
; there is nothing to synchronize messages or do checksums.
;
; Note that to work with the Turnigy USB linker, the baud rate must be
; set to 9600.
;
; Registers:
; r0: Temporary, spm data (temp5)
; r1: Temporary, spm data (temp6)
; r2: Half-bit low time in timer2 ticks
; r3: Half-bit high time in timer2 ticks
; r4: Quarter-bit average time in timer2 ticks
; r5: stk500v2 message checksum (xor)
; r6: stk500v2 message length low
; r7: stk500v2 message length high
; r8: 7/8th bit time in timer2 ticks
; r9: Unused
; r10: Doubled (word) address l
; r11: Doubled (word) address h
; r12: Address l
; r13: Address h
; r14: Temporary (for checking TIFR, Z storage) (temp7)
; r15: Temporary (Z storage)
; r16: Zero
; r17: EEPROM read/write flags
; r18: Unused
; r19: Unused
; r20: Set for clearing TOV2/OCF2 flags
; r21: Timeout
; r22: Byte storage for bit shifting rx/tx (temp3)
; r23: Temporary (temp4)
; r24: Loop counter (temp1)
; r25: Loop counter (temp2)
; X: TX pointer
; Y: RX pointer
; Z: RX jump state pointer
;
; We keep the RX buffer just past start of RAM,
; and start building the response at the start of ram.
; The whole RAM area is used as the RX/TX buffer.
.equ	RX_BUFFER = SRAM_START + 32
.equ	TX_BUFFER = SRAM_START

; Number of RX timeouts / unsuccessful restarts before exiting boot loader
; If we get stray pulses or continuous high/low with no successful bytes
; received, we will exit the boot loader after this many tries.
.equ	BOOT_RX_TRIES = 20

; STK message constants
.equ	MESSAGE_START			= 0x1b
.equ	TOKEN				= 0x0e

; STK general command constants
.equ	CMD_SIGN_ON			= 0x01
.equ	CMD_SET_PARAMETER		= 0x02
.equ	CMD_GET_PARAMETER		= 0x03
.equ	CMD_SET_DEVICE_PARAMETERS	= 0x04
.equ	CMD_OSCCAL			= 0x05
.equ	CMD_LOAD_ADDRESS		= 0x06
.equ	CMD_FIRMWARE_UPGRADE		= 0x07
.equ	CMD_CHECK_TARGET_CONNECTION	= 0x0d
.equ	CMD_LOAD_RC_ID_TABLE		= 0x0e
.equ	CMD_LOAD_EC_ID_TABLE		= 0x0f

; STK ISP command constants
.equ	CMD_ENTER_PROGMODE_ISP		= 0x10
.equ	CMD_LEAVE_PROGMODE_ISP		= 0x11
.equ	CMD_CHIP_ERASE_ISP		= 0x12
.equ	CMD_PROGRAM_FLASH_ISP		= 0x13
.equ	CMD_READ_FLASH_ISP		= 0x14
.equ	CMD_PROGRAM_EEPROM_ISP		= 0x15
.equ	CMD_READ_EEPROM_ISP		= 0x16
.equ	CMD_PROGRAM_FUSE_ISP		= 0x17
.equ	CMD_READ_FUSE_ISP		= 0x18
.equ	CMD_PROGRAM_LOCK_ISP		= 0x19
.equ	CMD_READ_LOCK_ISP		= 0x1a
.equ	CMD_READ_SIGNATURE_ISP		= 0x1b
.equ	CMD_READ_OSCCAL_ISP		= 0x1c
.equ	CMD_SPI_MULTI			= 0x1d

; STK status constants
.equ	STATUS_CMD_OK			= 0x00
.equ	STATUS_CMD_TOUT			= 0x80
.equ	STATUS_RDY_BSY_TOUT		= 0x81
.equ	STATUS_SET_PARAM_MISSING	= 0x82
.equ	STATUS_CMD_FAILED		= 0xc0
.equ	STATUS_CKSUM_ERROR		= 0xc1
.equ	STATUS_CMD_UNKNOWN		= 0xc9
.equ	STATUS_CMD_ILLEGAL_PARAMETER	= 0xca

; STK parameter constants
.equ	PARAM_BUILD_NUMBER_LOW		= 0x80
.equ	PARAM_BUILD_NUMBER_HIGH		= 0x81
.equ	PARAM_HW_VER			= 0x90
.equ	PARAM_SW_MAJOR			= 0x91
.equ	PARAM_SW_MINOR			= 0x92
.equ	PARAM_VTARGET			= 0x94
.equ	PARAM_VADJUST			= 0x95 ; STK500 only
.equ	PARAM_OSC_PSCALE		= 0x96 ; STK500 only
.equ	PARAM_OSC_CMATCH		= 0x97 ; STK500 only
.equ	PARAM_SCK_DURATION		= 0x98 ; STK500 only
.equ	PARAM_TOPCARD_DETECT		= 0x9a ; STK500 only
.equ	PARAM_STATUS			= 0x9c ; STK500 only
.equ	PARAM_DATA			= 0x9d ; STK500 only
.equ	PARAM_RESET_POLARITY		= 0x9e ; STK500 only, and STK600 FW version <= 2.0.3
.equ	PARAM_CONTROLLER_INIT		= 0x9f

; Support listening on ICP pin (on AfroESCs)
.if defined(USE_ICP) && USE_ICP
.equ	RCP_PORT = PORTB
.equ	RCP_DDR = DDRB
.else
.equ	RCP_PORT = PORTD
.equ	RCP_DDR = DDRD
.endif

; THIRDBOOTSTART on the ATmega8 is 0xe00.
; Fuses shold have BOOTSZ1 set, BOOTSZ0 unset, BOOTRST set.
; Last nibble of hfuse should be A or 2 to save EEPROM on chip erase.
; Do not set WTDON. Implementing support for it here is big/difficult.
.equ BOOT_START = THIRDBOOTSTART
.org BOOT_START
boot_reset:	ldi	ZL, high(RAMEND)	; Set up stack
		ldi	ZH, low(RAMEND)
		out	SPH, ZH
		out	SPL, ZL
		ldi	r16, 0			; Use r16 as zero
		ldi	ZL, low(stk_rx_start)
		ldi	ZH, high(stk_rx_start)
		ldi	YL, low(RX_BUFFER)
		ldi	YH, high(RX_BUFFER)
		ldi	XL, low(TX_BUFFER)
		ldi	XH, high(TX_BUFFER)
		ldi	r20, (1<<CS21)		; timer2: clk/8 ... 256 ticks @ 16MHz = 128us; @ 8MHz = 256us
		out	TCCR2, r20
		ldi	r21, -BOOT_RX_TRIES
boot_rx_time:	inc	r21
		breq	boot_exit		; Exit if too many unsuccessful rx restarts
		ldi	r20, (1<<TOV2)+(1<<OCF2)
		out	TCNT2, r16
		out	TIFR, r20
boot_rx_time1:	cpi	XL, low(TX_BUFFER)
		breq	boot_rx_no_tx
		in	r14, TIFR
		sbrc	r14, TOV2
		rjmp	boot_tx_bytes
boot_rx_no_tx:	sbic	PIND, rcp_in
		rjmp	boot_rx_time1		; Loop while high, waiting for low edge
		out	TCNT2, r16
		out	TIFR, r20
boot_rx_time2:	in	r14, TIFR
		sbrc	r14, TOV2
boot_exit:	rjmp	FLASHEND + 1		; Low too long -- exit boot loader
		sbis	PIND, rcp_in		; Loop whlle low
		rjmp	boot_rx_time2
		out	TCNT2, r16
		out	TIFR, r20		; Start measuring high time
boot_rx_time3:	in	r14, TIFR
		sbrc	r14, TOV2
		rjmp	boot_rx_time		; High too long, start over
		sbic	PIND, rcp_in		; Loop whlle high, waiting for low edge
		rjmp	boot_rx_time3
		in	r3, TCNT2		; Save learned high time
		out	TCNT2, r16
		out	TIFR, r20		; Start measuring low time
boot_rx_time4:	in	r14, TIFR
		sbrc	r14, TOV2
		rjmp	FLASHEND + 1		; Low too long, exit boot loader
		sbis	PIND, rcp_in		; Loop whlle low, waiting for high edge
		rjmp	boot_rx_time4
		in	r2, TCNT2		; Save learned low time
		mov	r0, r2
		add	r0, r3
	; C:r0 now contains the number of timer2 ticks for one bit.
	; 7/8ths of this should be just enough to see two high to
	; low transitions for 0-bits, or one high-to-low for 1-bits.
	; Subtract 1/8th to get a time at which we check the edge
	; count and then wait for the next bit.
		mov	r8, r0			; C:r8 holds full time (9-bit)
		ror	r0			; r0 now holds half time (8-bit)
		lsr	r0
		mov	r4, r0			; Save quarter bit time (for tx)
		lsr	r0
		sbc	r8, r0			; Subtract 1/8th, rounding, unwrapping from 9th bit overflow
		com	r8			; Store one's complement for setting timer value
		com	r2			; Same for half-bit low time
		com	r3			; Same for half-bit high time
		com	r4			; Same for quarter-bit average time
		ldi	r22, 0b11100000		; Start with two leader bits and sentinel bit preloaded
		ldi	r24, 3			; Skip storing of 3 leader bytes
	; Bit-decoding: Set high-to-low edge counting timer (r8), and wait
	; for it to expire.
boot_rx:	out	TCNT2, r8
		out	TIFR, r20
boot_rx0:	in	r14, TIFR
		sbrc	r14, TOV2
		rjmp	FLASHEND + 1		; Low too long, exit boot loader
		sbis	PIND, rcp_in
		rjmp	boot_rx0
		out	TCNT2, r8		; Count falling edges for 75% of one bit time
		out	TIFR, r20
boot_rx1:	in	r14, TIFR
		sbrc	r14, TOV2
		rjmp	boot_rx_time		; High too long (or EOT), start over
		sbic	PIND, rcp_in
		rjmp	boot_rx1
		sec				; Receiving 1-bit
boot_rx2:	in	r14, TIFR
		sbrc	r14, TOV2
		rjmp	boot_rx_bit		; Timeout, must be 1-bit
		sbis	PIND, rcp_in
		rjmp	boot_rx2
boot_rx3:	in	r14, TIFR
		sbrc	r14, TOV2
		rjmp	boot_rx_time		; Hmm, timed out during second high
		sbic	PIND, rcp_in
		rjmp	boot_rx3
		clc				; Receiving 0-bit
boot_rx4:	in	r14, TIFR
		sbrc	r14, TOV2
		rjmp	boot_rx_bit		; Timeout, must be 0-bit
		sbis	PIND, rcp_in
		rjmp	boot_rx4

boot_tx_bytes:
		out	OCR2, r4		; Set OCF2 at quarter timing
		ldi	r24, 24			; Leader is 24 1-bits, 1 0-bit
boot_tx_leader:
		sbi	RCP_PORT, rcp_in	; Drive high
		sbi	RCP_DDR, rcp_in
		out	TCNT2, r3
		out	TIFR, r20
boot_tx_lead1:	in	r14, TIFR
		sbrs	r14, TOV2
		rjmp	boot_tx_lead1
		cbi	RCP_PORT, rcp_in	; Drive low
		out	TCNT2, r2
		out	TIFR, r20
boot_tx_lead2:	in	r14, TIFR
		sbrs	r14, TOV2
		rjmp	boot_tx_lead2
		dec	r24
		brne	boot_tx_leader

		ldi	YL, low(TX_BUFFER)
		ldi	YH, high(TX_BUFFER)

		ldi	r22, 0
		ldi	r24, 1
		rjmp	boot_tx_bits		; Send single start bit first

	; Interleaving rx/tx here to avoid branching trampolines.
boot_rx_bit:	ror	r22			; Roll rx bit in carry into r22
		brcc	boot_rx			; More bits to receive unless sentinel bit reached carry flag
		subi	r24, 1
		brcc	boot_rx_skip		; Don't store leader bytes
		ldi	r21, -BOOT_RX_TRIES	; Clear timeout on byte received
		ijmp				; Jump to current state handler

boot_tx:	cp	YL, XL
		cpc	YH, XH
		breq	boot_tx_end
		ld	r22, Y+
		ldi	r24, 8			; Send 8 bits
boot_tx_bits:	lsr	r22			; Put next bit in carry flag
		sbi	RCP_PORT, rcp_in	; Drive high
		out	TCNT2, r3
		out	TIFR, r20
boot_tx1:	in	r14, TIFR
		brcs	boot_tx2
		sbrc	r14, OCF2
		out	RCP_PORT, r16		; Drive low
boot_tx2:	sbrs	r14, TOV2
		rjmp	boot_tx1
		cbi	RCP_PORT, rcp_in
		brcs	boot_tx_low
		sbi	RCP_PORT, rcp_in	; Drive high
boot_tx_low:	out	TCNT2, r2
		out	TIFR, r20
boot_tx3:	in	r14, TIFR
		brcs	boot_tx4
		sbrc	r14, OCF2
		out	RCP_PORT, r16		; Drive low
boot_tx4:	sbrs	r14, TOV2
		rjmp	boot_tx3
		dec	r24
		brne	boot_tx_bits
		rjmp	boot_tx
	; Go high for a quarter bit time at the end
boot_tx_end:	sbi	RCP_PORT, rcp_in	; Drive high
		out	TCNT2, r3
		out	TIFR, r20
		ldi	YL, low(RX_BUFFER)
		ldi	YH, high(RX_BUFFER)
		ldi	XL, low(TX_BUFFER)
		ldi	XH, high(TX_BUFFER)
boot_tx_end1:	in	r14, TIFR
		sbrs	r14, OCF2
		rjmp	boot_tx_end1
		cbi	RCP_DDR, rcp_in		; Stop driving
		out	RCP_PORT, r16		; Turn off
		rjmp	boot_rx_time

boot_rx_cont:	ldi	r24, 0
boot_rx_skip:	ldi	r22, 0b10000000		; Restart with sentinel bit preloaded
		rjmp	boot_rx

; Simple implementation of stk500v2
; Do not clobber registers needed to reply: r2, r3, r8, r16, r20
stk_rx_restart:	ldi	ZL, low(stk_rx_start)
		ldi	ZH, high(stk_rx_start)
		ldi	YL, low(RX_BUFFER)
		ldi	YH, high(RX_BUFFER)
		rjmp	boot_rx_cont
		lds	r0, 0			; Future expansion nops
		lds	r0, 0
		lds	r0, 0
		lds	r0, 0
		lds	r0, 0
		lds	r0, 0
		lds	r0, 0
		lds	r0, 0
stk_rx_start:	nop				; Future expansion nops
		nop
		cpi	r22, MESSAGE_START
		brne	boot_rx_cont
		mov	r5, r22			; Start checksum in r5
		adiw	ZL, stk_rx_seq - stk_rx_start
		rjmp	boot_rx_cont
stk_rx_seq:	mov	i_sreg, r22		; Store sequence number in i_sreg
		eor	r5, r22
		adiw	ZL, stk_rx_size_h - stk_rx_seq
		rjmp	boot_rx_cont
stk_rx_size_h:	mov	r7, r22			; Store message length high in r7
		eor	r5, r22
		adiw	ZL, stk_rx_size_l - stk_rx_size_h
		rjmp	boot_rx_cont
stk_rx_size_l:	mov	r6, r22			; Store message length low in r6
		eor	r5, r22
		adiw	ZL, stk_rx_token - stk_rx_size_l
		rjmp	boot_rx_cont
stk_rx_token:	cpi	r22, TOKEN
		brne	stk_rx_restart
		eor	r5, r22
		adiw	ZL, stk_rx_body - stk_rx_token
		rjmp	boot_rx_cont
stk_rx_body:	st	Y+, r22
		eor	r5, r22
		cpi	YL, low(RAMEND)
		ldi	r24, high(RAMEND)
		cpc	YH, r24
		brcc	stk_rx_restart
		ldi	r24, 1
		sub	r6, r24
		sbc	r7, r16
		brne	stx_rx_cont
		adiw	ZL, stk_rx_cksum - stk_rx_body
stx_rx_cont:	rjmp	boot_rx_cont
stk_rx_cksum:	cpse	r22, r5
		rjmp	stk_rx_restart		; Restart if bad checksum
stk_rx:
	; Good checksum -- process message
	; We can use Z and Y now, since we will set it back to start in stk_rx_restart
	; Load the first three bytes into r22, r25, r24.
		ldi	YL, low(RX_BUFFER)	; Number of bytes to rx
		ldi	YH, high(RX_BUFFER)
		ld	r22, Y+			; Command byte
		ld	r25, Y+			; Parameter or address/count high,
		ld	r24, Y+			; Address/count low
	; Start the beginning of a typical response message
		movw	ZL, XL			; Start checksumming from here
		ldi	r23, MESSAGE_START
		st	Z, r23			; Message start
		std	Z+1, i_sreg		; Sequence number
		std	Z+2, r16		; Message body size high
		ldi	r23, 2
		std	Z+3, r23		; Message body size low
		ldi	r23, TOKEN
		std	Z+4, r23		; Message token
		std	Z+5, r22		; Command
		std	Z+6, r16		; Typical status OK (STATUS_CMD_OK)
		adiw	XL, 7
	; Check which command we received
		cpi	r22, CMD_SIGN_ON
		brne	scmd1			; Inverted tests for branch reach
		ldi	r24, SIGNATURE_LENGTH + 3
		std	Z+3, r24		; Messsage body size low
		ldi	r24, SIGNATURE_LENGTH
		st	X+, r24			; Signature size
		movw	YL, ZL
		ldi	ZL, low(avrisp_response_w << 1)
		ldi	ZH, high(avrisp_response_w << 1)
scmd_sign_on1:	lpm	r24, Z+
		st	X+, r24
		cpi	ZL, low((avrisp_response_w << 1) + SIGNATURE_LENGTH)
		brne	scmd_sign_on1
		movw	ZL, YL
scmd_send_chksum:
		ld	r24, Z+
chksum1:	ld	r22, Z+
		eor	r24, r22
		cp	ZL, XL
		cpc	ZH, XH
		brne	chksum1
		st	X+, r24			; Store xor checksum
		rjmp	stk_rx_restart
scmd1:		cpi	r22, CMD_SPI_MULTI
		brne	scmd2
	; avrdude uses spi_multi spi passthrough mode to check fuse bytes,
	; so we emulate this. Constants from the Arduino stk500v2 example
	; boot loader.
		mov	r23, r25		; Save NumTx in r23
		ldi	r25, 0			; Zero-extend r24
		adiw	r24, 3			; Command, status, rx'd bytes, status
		std	Z+3, r24		; Message body size low
		std	Z+2, r25		; Message body size high
		sbiw	r24, 3			; Back to just byte count
scmd_multi1:	st	X+, r16			; Fill return bufferwith zeroes
		dec	r24
		brne	scmd_multi1
	; Check for signature probe
	; Mirror address in result
		ld	r24, Y+			; RxStartAddr
		ld	r22, Y+			; TxData
		cpi	r22, 0x30		; Read signature bytes?
		cpc	r24, r16		; Only support RxStartAddr == 0
		ldi	r25, 4
		cpc	r23, r25		; Only support NumRx == 4
		brne	scmd_multi3
		std	Z+8, r22		; Echo back command
		ld	r24, Y+			; Address high
		cpi	r24, 0
		brne	scmd_multi3
		ld	r22, Y+			; Address low
		cpi	r22, 0
		ldi	r24, SIGNATURE_000	; atmega8 == 0x1e 0x93 0x07
		breq	scmd_multi2
		cpi	r22, 1
		ldi	r24, SIGNATURE_001
		breq	scmd_multi2
		cpi	r22, 2
		ldi	r24, SIGNATURE_002
		brne	scmd_multi3
scmd_multi2:	std	Z+10, r24		; Signature byte
scmd_multi3:	st	X+, r16			; STATUS_CMD_OK
		rjmp	scmd_send_chksum

scmd_load_address:
		cp	r24, r16
		cpc	r25, r16
		brne	scmd_fail
		ld	r13, Y+			; Save address
		ld	r12, Y+
		movw	r10, r12
		lsl	r10
		rol	r11
		rjmp	scmd_send_chksum
scmd2:
		cpi	r22, CMD_GET_PARAMETER
		breq	scmd_get_parameter
		cpi	r22, CMD_SET_PARAMETER
		breq	scmd_send_chksum	; Blind OK
		cpi	r22, CMD_ENTER_PROGMODE_ISP
		breq	scmd_send_chksum	; Blind OK
		cpi	r22, CMD_LEAVE_PROGMODE_ISP
		breq	scmd_send_chksum	; Blind OK
		cpi	r22, CMD_LOAD_ADDRESS
		breq	scmd_load_address
		cpi	r22, CMD_CHIP_ERASE_ISP
		breq	scmd_chip_erase
	; Commands after here are all read/write eeprom/flash types
		cpi	r24, low(RAMEND - TX_BUFFER - 12)
		ldi	r23, high(RAMEND - TX_BUFFER - 12)
		cpc	r25, r23
		brcc	scmd_fail		; Not enough RAM for that many bytes
		cpi	r22, CMD_READ_FLASH_ISP
		breq	scmd_read_flash
		cpi	r22, CMD_READ_EEPROM_ISP
		breq	scmd_read_eeprom
		adiw	YL, 7			; Skip useless write command bytes
		cpi	r22, CMD_PROGRAM_EEPROM_ISP
		breq	scmd_program_eeprom
		cpi	r22, CMD_PROGRAM_FLASH_ISP
		breq	scmd_program_flash
		nop				; Future expansion
		nop
scmd_fail:	ldi	r24, STATUS_CMD_FAILED
		std	Z+6, r24
		rjmp	scmd_send_chksum

scmd_get_parameter:
		cpi	r25, PARAM_HW_VER
		ldi	r24, 0xf
		breq	scmd_get_parameter_good
		cpi	r25, PARAM_SW_MAJOR
		ldi	r24, 0x2
		breq	scmd_get_parameter_good
		cpi	r25, PARAM_SW_MINOR
		ldi	r24, 0xa
		breq	scmd_get_parameter_good
		cpi	r25, PARAM_VTARGET
		ldi	r24, 50
		breq	scmd_get_parameter_good
		cpi	r25, PARAM_BUILD_NUMBER_LOW
		ldi	r24, 0
		breq	scmd_get_parameter_good
		cpi	r25, PARAM_BUILD_NUMBER_HIGH
		brne	scmd_fail
scmd_get_parameter_good:
		st	X+, r24
		ldi	r24, 3
		std	Z+3, r24		; Messsage body size low
		rjmp	scmd_send_chksum

scmd_read_flash:
		rcall	scmd_blob_message_size
		movw	YL, ZL			; Save Z
		movw	ZL, r10			; lpm can only use Z
scmd_read_rwwse_wait:
		rcall	boot_rwwsb_wt
		sbrc	r23, RWWSB
		rjmp	scmd_read_rwwse_wait	; Wait if flash still completing
scmd_read_fl1:	lpm	r22, Z+
		st	X+, r22
		sbiw	r24, 1
		brne	scmd_read_fl1
		movw	r10, ZL			; Save updated word address
		movw	ZL, YL			; Restore Z
		st	X+, r16			; STATUS_CMD_OK at end
		rjmp	scmd_send_chksum

scmd_read_eeprom:
		rcall	scmd_blob_message_size
		ldi	r17, (1<<EERE)
scmd_read_ee1:	rcall	boot_eeprom_rw		; Uses and increments byte address
		in	r22, EEDR
		st	X+, r22
		sbiw	r24, 1
		brne	scmd_read_ee1
		st	X+, r16			; STATUS_CMD_OK at end
		rjmp	scmd_send_chksum

; For chip erase, we just nuke the EEPROM.
scmd_chip_erase:
		clr	r12
		clr	r13
		ldi	r24, low(EEPROMEND+1)
		ldi	r25, high(EEPROMEND+1)
		set
scmd_program_eeprom:
		ldi	r17, (1<<EEMWE)+(1<<EEWE)
scmd_write_ee1:	ldi	r22, 0xff
		brts	scmd_write_ee2
		ld	r22, Y+
scmd_write_ee2:	rcall	boot_eeprom_rw
		sbiw	r24, 1
		brne	scmd_write_ee1
		clt
		rjmp	scmd_send_chksum

scmd_program_flash:
		cbr	r24, 0			; Round down
		ldi	r22, (1<<SPMEN)		; Store to temporary page buffer
		movw	r14, ZL			; Save Z
		movw	ZL, r10			; Load word address for page write
scmd_write_fl1:	ld	r0, Y+
		ld	r1, Y+
		rcall	boot_spm
		adiw	ZL, 2
		sbiw	r24, 2
		brne	scmd_write_fl1
		movw	r0, ZL			; Stash new address
		movw	ZL, r10			; Load old word address
		movw	r10, r0			; Save new word address
		ldi	r22, (1<<PGERS)+(1<<SPMEN)
		cpi	ZL, low(2*(boot_wr_flash & ~(PAGESIZE-1)))
		ldi	r23, high(2*(boot_wr_flash & ~(PAGESIZE-1)))
		cpc	ZH, r23
		breq	scmd_write_fl3		; Unless we are overwriting it,
		rcall	boot_wr_flash		; use the normal boot_wr_flash
scmd_write_fl2:	movw	ZL, r14			; Restore Z
		rjmp	scmd_send_chksum
scmd_write_fl3:	rcall	scmd_spm		; Erase page
		ldi	r22, (1<<PGWRT)+(1<<SPMEN)
		rcall	scmd_spm		; Write page
		ldi	r22, (1<<RWWSRE)+(1<<SPMEN)
		rcall	scmd_spm		; Re-enable RWW section
		rjmp	scmd_write_fl2
scmd_spm_wait:	in	r23, SPMCR		; Wait for previous SPM to finish
		sbrc	r23, SPMEN
		rjmp	scmd_spm_wait
scmd_ee_wait:	sbic	EECR, EEWE		; Wait for EEPROM write to finish
		rjmp	scmd_ee_wait
		ret
scmd_spm:	rcall	scmd_spm_wait
		out	SPMCR, r22		; Set SPM mode
		spm
		ret

scmd_blob_message_size:
		adiw	r24, 3			; Command, status, (data), status
		std	Z+2, r25		; Message body size high
		std	Z+3, r24		; Message body size low
		sbiw	r24, 3			; Back to just the byte count
		ret

boot_eeprom_rw:	rcall	boot_spm_wait
		out	EEARH, r13
		out	EEARL, r12
		sec
		adc	r12, r16		; Increment address
		adc	r13, r16
		mov	r23, r22		; Save desired value
		sbi	EECR, EERE		; Read existing EEPROM byte
		in	r22, EEDR
		cpse	r22, r23		; Return if byte matches
		sbrs	r17, EEMWE		; Return if only reading
		ret
		out	EEDR, r23		; Set new byte
		sbi	EECR, EEMWE		; Write arming
		out	EECR, r17		; Write
		ret

; Keep these addresses within a page so that we can self-update.
.org FLASHEND + 1 - 32
description:
	.db "http://github.com/sim-/tgy/", 0	; Hello!
avrisp_response_w:
	.equ SIGNATURE_LENGTH = 8
	.db "AVRISP_2"				; stk500v2 signature

boot_spm_wait:	in	r23, SPMCR		; Wait for previous SPM to finish
		sbrc	r23, SPMEN
		rjmp	boot_spm_wait
boot_ee_wait:	sbic	EECR, EEWE		; Wait for EEPROM write to finish
		rjmp	boot_ee_wait
		ret
boot_wr_flash:	rcall	boot_spm		; Erase page
		ldi	r22, (1<<PGWRT)+(1<<SPMEN)
		rcall	boot_spm		; Write page
boot_rwwsb_wt:	ldi	r22, (1<<RWWSRE)+(1<<SPMEN)
boot_spm:	rcall	boot_spm_wait
		out	SPMCR, r22		; Set SPM mode
		spm
		ret
.endif
.exit
