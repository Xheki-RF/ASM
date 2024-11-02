INCLUDE   "m8def.inc"
.DEF			U_MAXH	= R2
.DEF 		U_MAXL	= R3
.DEF			I_MAXH	= R4
.DEF			I_MAXL	= R5

.DEF			COUNT	= R20
.DEF			CNT_RST 	= R21
.DEF			digit	= R22

.DEF			templ	= R16
.DEF			temph	= R17

.DSEG
DigitTable:    
.BYTE       	10

.CSEG
.ORG        0x0000
rjmp        	Start

.ORG        0x009
rjmp        	TIM0_OVF

.ORG        0x00E
rjmp        	ACP

TIM0_OVF:						
     rjmp		ACP
     reti

ACP:     
     in        templ, ADCL		;считывание значение АЦП		
     in        temph, ADCH		;считывание значение АЦП
     sbic 	ADMUX, 0		
     rjmp 	CURRENT			

;поиск максимальной амплитуды напряжения (старший регистр)
VOLTAGE:     
     cp 		temph, U_MAXH		
     brsh 	CMP_U_MAXL		
     brlo 	SWITCH_ACP  		

;поиск максимальной амплитуды напряжения (младший регистр)
CMP_U_MAXL:
     cp  		templ, U_MAXL		
     brlo 	SWITCH_ACP		
     mov 		U_MAXH, temph		
     mov 		U_MAXL, templ		

;поиск максимальной тока (старший регистр)      
CURRENT:
     cp 		temph, I_MAXH		
     brsh 	CMP_I_MAXL		
     brlo 	SWITCH_ACP  		

;поиск максимальной амплитуды тока (младший регистр)
CMP_I_MAXL:
     cp  		templ, I_MAXL		
     brlo 	SWITCH_ACP		
     mov 		I_MAXH, temph		
     mov 		I_MAXL, templ		

;переключение между АЦП и сброс таймера    
SWITCH_ACP:   
     ldi       R19, 0x01		
     in        R18, ADMUX	
     eor      	R18, R19		
     out       ADMUX, R18		
     
     ldi		R29, 0x00		
     out		TCCR0, R29	;сброс таймера

;проверка времени 1   
TIME_CHECK:     
     dec 		COUNT			
     tst 		COUNT			
     brne 	RETURN		

;проверка времени 2      
TIME_RESETS_CHECK:
     dec 		CNT_RST			
     tst 		CNT_RST			
     brne 	RETURN		
  
     tst 		COUNT			
     brne 	RETURN		
     rcall 	kWh			
     ret


RETURN:    
     reti

;основные настройки   
Start:
     ldi       R21, LOW(RAMEND)    	;инициализация стека
     out 	 	SPL, R21
     ldi       R21, HIGH(RAMEND)
     out       SPH, R21
     
     ;Таблица с кодами чисел
     ldi    	ZL, LOW(DigitTable)
     ldi    	ZH, HIGH(DigitTable)
      
     ldi    	digit, 0b00111111    	;Код для 0
     st     	Z+, digit
     ldi    	digit, 0b00000110    	;Код для 1
     st     	Z+, digit
     ldi    	digit, 0b01011011    	;Код для 2
     st     	Z+, digit
     ldi    	digit, 0b01001111    	;Код для 3
     st     	Z+, digit
     ldi    	digit, 0b01100110    	;Код для 4
     st     	Z+, digit
     ldi    	digit, 0b01101101    	;Код для 5
     st     	Z+, digit
     ldi    	digit, 0b01111101    	;Код для 6
     st     	Z+, digit
     ldi    	digit, 0b00000111    	;Код для 7
     st     	Z+, digit
     ldi    	digit, 0b01111111    	;Код для 8
     st     	Z+, digit
     ldi    	digit, 0b01101111    	;Код для 9
     st     	Z+, digit
      
     ; Инициализация портов ввода-вывода
     ldi       R21, 0b00000111        	;настройка на выход
     out       DDRB, R21
     clr       R21
      
     ldi       R21, 0b0000000          ;настройка на выход
     out       DDRC, R21
     clr       R21
     
     ser		R21
     out		DDRD, R21		;настройка на выход
     clr		R21
      
     ldi		R21, (1 << ADEN) |  (1 << ADSC) | (1 << ADFR) | (1 << ADIE) | (1 << ADPS2) | (1 << ADPS1) | (1 << ADPS0) 		
;настройка регистра ADMUX
     out       ADCSR, R21
     clr       R21
      
     ldi		R21, (1 << REFS0) 	;настройка регистра ADMUX
     out       ADMUX, R21
     
     ldi    	R21, (1 << TOIE0)	;настройка регистра TIMSK
     out    	TIMSK, R21
    
     ldi    	R21, (1 << CS00) | (1 << CS01) 
;настройка регистра TCCR0
     out    	TCCR0, R21
      
     sei
    
     ;Регистры для хранения амплитуд
     clr 		U_MAXL
     clr 		U_MAXH
     clr 		I_MAXL
     clr 		I_MAXH
      
     ;Проверка времени
     ldi 		COUNT, 250
     ldi 		CNT_RST, 200
Loop:
     brid     	_Loop ;перейти, если глобальные прерывания запрещены
     rjmp     	Loop

_Loop:
    ;Вывод цифр на ССИ
    clr 		R16
    out 		PORTB, R16
    ldi 		ZL, low(DigitTable)
    add 		ZL, R10
    clr 		R16
    ld 		R16, Z+
    out 		PORTD, R16
    ldi 		R16, 0b00000001
    out 		PORTB, R16
    rcall 	Delay			;вызов задержки
    
    clr 		R16
    out 		PORTB, R16
    ldi 		ZL, low(DigitTable)
    add 		ZL, R11
    clr 		R16
    ld 		R16, Z+
    out 		PORTD, R16
    ldi 		R16, 0b00000010
    out 		PORTB, R16
    rcall 	Delay			;вызов задержки
    
    clr 		R16
    out 		PORTB, R16
    ldi 		ZL, low(DigitTable)
    add 		ZL, R12
    clr 		R16
    ld 		R16, Z+
    out 		PORTD, R16
    ldi 		R16, 0b00000100
    out 		PORTB, R16
    rcall 	Delay			;вызов задержки
     
    rjmp 		_Loop

;основная часть программы 
kWh:     
    clr		R16			
    out		ADCSR, R16		;отключение АЦП

    ldi 		templ, 0b10001101
    ldi 		temph, 0b00000010 	;загрузка числа 653 в temp
     
    ;Вычисление среднего напряжения
    mov 		XH, U_MAXH		
    mov 		XL, U_MAXL		
    rcall 	Multi			
;вызов подпрограммы умножения 16-ти битного числа на 16-ти битное
     
    ldi 		R16, 10			;загрузка числа 10 в регистр R16

;деление на 1024
Shift_Loop:
    rcall 	RShift	;вызов подпрограммы битового сдвига вправо 
    dec 		R16		
    tst 		R16			
    brne 		Shift_loop	

     
    mov 		U_MAXH, R22		
    mov 		U_MAXL, R23		

    ;Вычисление средней силы тока
    mov 		XH, I_MAXH		
    mov 		XL, I_MAXL		
     
    ldi 		templ, 0b10001101
    ldi 		temph, 0b00000010 	;загрузка числа 653 в temp 
    rcall 	Multi		
      
    ldi 		R16, 10			


;деление на 1024
_Shift_Loop:
     rcall 	RShift	;вызов подпрограммы битового сдвига вправо 
     dec 		R16			
     tst 		R16			
     brne 	_Shift_loop 	
     
     mov 		I_MAXH, R22		
     mov 		I_MAXL, R23		
  
     ;Получение изначальное силы тока - умножение на 2
     lsl  	I_MAXL			;сдвиг влево
     rol 		I_MAXH			;сдвиг влево
    
     ;Получение исходного напряжения 
     ldi 		templ, 44		
     ldi 		temph, 0
     mov 		XH, U_MAXH	
     mov 		XL, U_MAXL	
     rcall 	Multi	

     ;Полученное напряжение
     mov 		U_MAXH, R22	
     mov 		U_MAXL, R23	
     
     ;Вычисление мощности 
     mov 		XH, U_MAXH		
     mov 		XL, U_MAXL		
     mov 		temph, I_MAXH		
     mov 		templ, I_MAXL		
     rcall 	Multi	
     
;Умножение числа, содержащегося в регистрах R20:R21:R22:R23, на 25
     ldi 		R16, 25		
     rcall 	Multi_32_8
		
     mov 		R23, R14		
     mov 		R22, R13		
     mov 		R21, R12		
     mov 		R20, R11		
     
;Умножение числа, содержащегося в регистрах R20:R21:R22:R23, на 100
     ldi 		R16, 100		
     rcall 	Multi_32_8	
     
;R10:R11:R12:R13:R14
;Для преобразования значений с АЦП в физические величины нужно совершить сдвиг вправо 20 раз 
;Также, число 3600 можно представить в виде: 225 * 2^4
;Тогда, можно будет поделить сразу на 2^24

     ldi 		R16, 24 		

;Деление на 2^24
__Shift_Loop:
     rcall 	RShift_40bit	
     dec 		R16			
     tst 		R16			
     brne 	__Shift_loop 	
     
;Деление полученного результата, хранящегося в регистрах R13:R14, на 225
     rcall 	DIV_16_to_8 	
     mov 		R15, R16		

     ;Вывод получившегося значения на ССИ
     ;Значение в Вт * ч находится в регистре R15
     
     ;Первая цифра - R10
     ldi 		R17, 100		
     mov 		R14, R15		
     clr 		R16 			
     rcall 	DIV_8_to_8		
     mov 	R10, R16		
      
     ;Вторая цифра - R11
     mul 		R16, R17		
     sub 		R15, R0			
     ldi 		R17, 10			
     mov 		R14, R15		
     clr 		R16			
     rcall 	DIV_8_to_8		
     mov 		R11, R16		
    
     ;Третья цифра - R12
     mul 		R16, R17	
     sub 		R15, R0	
     mov 		R12, R15 		
     ret

 Multi:
     clr 		R20			
     clr 		R21			
     clr 		R22			
     clr 		R23			
 
     mul     	XL, templ     
     mov    	R23, R0	   
     mov    	R22, R1	   
    
     mul     	XL, temph        	
     add    	R22, R0			
     mov    	R21, R1			
     adc    	R21, R20		
    
     mul    	XH, templ       	
     add    	R22, R0
     adc    	R21, R1
     adc    	R20, R20
    
     mul    	XH, temph        	
     add    	R21, R0
     adc    	R20, R1  
     ret
    
Multi_32_8:
    ;R20:R21:R22:R23 * 25
    ;Регистры для хранения итогового результата
     clr 		R10 				;R10:R11:R12:R13:R14
     clr 		R11
     clr 		R12
     clr 		R13
     clr 		R14
     clr 		R15
      
     mul    	R23, R16	    		;XL*Y     R26:R27
     mov   	R14, R0
     mov   	R13, R1
    
     mul     	R22, R16            ;XL1*Y    R25:R26:R27
     add    	R13, R0
     adc    	R12, R1
     adc    	R11, R15
    
     mul     	R21, R16            ;XH1*Y    R24:R25:R26:R27
     add    	R12, R0
     adc    	R11, R1
     adc    	R10, R15
    
     mul     	R20, R16            ;XH*Y     R23:24:R25:R27:R27
     add    	R11, R0
     adc    	R10, R1
     ret 
    

 RShift:
     lsr 		R20
     ror 		R21
     ror 		R22
     ror 		R23
     ret
    
RShift_40bit:
     lsr 		R10
     ror 		R11
     ror 		R12
     ror 		R13
     ror 		R14
     ret
    
DIV_16_to_8:
     mov    	R17, R13          	;XH   
     mov    	R16, R14          	;XL
     ldi    	R20, 225          	;Y    

     tst    	R20
     breq    	dv3
     clr    	R18
     clr    	R19
     clr    	R21
     ldi    	R22, 16

dv1:
     lsl    	R16
     rol    	R17
     rol    	R18
     rol    	R19
     sub    	R18, R20
     sbc    	R19, R21
     ori    	R16, 0x01
     brcc    	dv2
     add    	R18, R20
     adc    	R19, R21
     andi    	R16, 0xFE

dv2:
     dec     	R22
     brne    	dv1
     clc
     ret

dv3:
     sec
     ret

DIV_8_to_8:
     clc
     cp        R14, R17
     brcc    	PC + 2
     ret
     sub    	R14, R17
     inc    	R16
     rjmp    	DIV_8_to_8
    
Delay:
     ldi 	R16, 0x40
     ldi 	R17, 0x10
     Keep_delaying:
        dec 	R17
        tst 	R17
        brne 	Keep_delaying
        dec 	R16
        tst 	R16
        brne 	Keep_delaying - 1
    ret
