TITLE Designing low-level I/O Procedures and Macros   (program05.asm)

; Author: Kevin Joy
; Last Modified: 8/10/20 <-- used an extra day
; OSU email address: joyke@oregonstate.edu
; Course number/section: CS271/400
; Assignment Number: 5		       Due Date: 8/9/20
; Description: Takes in 10 unsigned decimal integers as a string, converts the string to decimal, sums and displays the running total,
	; displays the input integers, displays the grand total sum, displays the average, displays fairwell message.

INCLUDE Irvine32.inc

INPUT_AMOUNT = 10
LOW_VALID = 48
HIGH_VALID = 57

; description: reads and saves user input characters from the keyboard.
; receives: OFFSET buffer, SIZEOF buffer
; returns: byte_count, buffer
; preconditions: there must be a buffer address and buffer size available for the macro to store characters.
; registers changed: none (saved to stack)

getString MACRO buffer_address, buffer_size
	pushad

  ; read string into input buffer and save byte count of input
	mov				edx, buffer_address
	mov				ecx, buffer_size
	call			ReadString

	popad
ENDM

; description: writes a string to console
; receives: the offset of a string
; returns: none
; preconditions: none 
; registers changed: none (saved to stack)

displayString MACRO	string
	pushad
	
	mov				edx, string
	call			WriteString

	popad
ENDM

.data

intro_1				BYTE		"Designing low-level I/O Procedures and Macros by Kevin Joy",0
intro_2				BYTE		"Please provide 10 unnsigned decimal integers.",0
intro_3				BYTE		"Each number needs to be small enough to fit inside a 32 bit register. After you input the decimals, a list of the integers, their sum, and their average value will be displayed.",0
prompt_1			BYTE		".) Please enter an unsigned integer: ",0
prompt_2			BYTE		"Please enter a valid unsigned integer: ",0
warning_1			BYTE		"ERROR: You did not enter an unsigned number or your number was too big.",0
entered_txt			BYTE		"You entered the following numbers: ",0
sum_txt				BYTE		"The sum of these numbers is: ",0
average_txt			BYTE		"The floor of average is: ",0
comma_txt			BYTE		", ",0
running_sub_total	BYTE		"Running subtotal: ",0
farewell			BYTE		"Goodbye!",0
ec_1				BYTE		"**EC: Number each line of user input and display a running subtotal.",0
buffer				BYTE 200 DUP(0)				    ; holds user input integers in ascii string form
output_buffer		BYTE 200 DUP(0)					; holds output integers in ascii string form
decimal_array		DWORD	INPUT_AMOUNT DUP(?)		; holds input numbers converted into decimal
converted_int		DWORD		0				    ; holds the converted integer value
sum					DWORD		0					; holds sum of inputs
average				DWORD		0					; holds average of inputs
decimal_count		DWORD		0					; stores count of decimals in an int

.code
Main PROC

  ; display introduction
	push			OFFSET ec_1
	push			OFFSET intro_3
	push			OFFSET intro_2
	push			OFFSET intro_1
	call			Introduction

  ; setup loop for inputing a given amount of items
	mov				ecx, 1
input_loop:

  ; gather user data
	mov				eax, ecx
	call			WriteDec
	displayString	OFFSET prompt_1
	push			SIZEOF buffer
	push			OFFSET buffer
	call			ReadVal

  ; validate input
	push			OFFSET decimal_count				; address of decimal_count
	push			OFFSET prompt_2
	push			OFFSET Warning_1
	push			LOW_VALID
	push			HIGH_VALID
	push			OFFSET converted_int
	push			SIZEOF buffer
	push			OFFSET buffer
	call			Validate

  ; calculate running total
	push			OFFSET converted_int
	push			OFFSET sum
	call			CalculateSum

  ; display running total
	displayString	OFFSET running_sub_total
	mov				eax, sum
	call			WriteDec
	call			CrLf
	call			CrLf

  ; insert input into decimal array
	push			ecx									; number of loop iteration for user input
	push			converted_int								
	push			OFFSET decimal_array
	call			InsertArray

  ; loop instructions
	mov				eax, INPUT_AMOUNT
	add				ecx,1
	cmp				ecx, eax
	jg				input_done
	jmp				input_loop

input_done:

  ; calculate the average of inputs
  	push			INPUT_AMOUNT
	push			sum
	push			OFFSET average
	call			CalculateAverage


  ; display output
	displayString	OFFSET entered_txt
	call			CrLf

  ; setup loop for inputing a given amount of items
	mov				ecx, 1
display_loop:
  ; calculate current index
	mov				eax, ecx
	sub				eax, 1								; adjust loop count to index
	mov				ebx, 4														
	mul				ebx									; adjust index to dword size
	mov				ebx, OFFSET decimal_array
	add				ebx, eax							; address of current index

  ; convert the digits back to a string and display
	push			LOW_VALID
	push			OFFSET decimal_count
	push			OFFSET output_buffer
	push			[ebx]								; value at index of decimal_array
	call			WriteVal

  ; loop instructions
	mov				eax, INPUT_AMOUNT
	add				ecx,1
	cmp				ecx, eax
	jg				display_done
	
  ; display formating
	displayString	OFFSET comma_txt

	jmp				display_loop

display_done:
	call			CrLf
	call			CrLf

  ; display sum
	displayString	OFFSET sum_txt
	push			LOW_VALID
	push			OFFSET decimal_count
	push			OFFSET output_buffer
	push			sum									; value at index of decimal_array
	call			WriteVal
	call			CrLf

  ; display average
	displayString	OFFSET average_txt
  	push			LOW_VALID
	push			OFFSET decimal_count
	push			OFFSET output_buffer
	push			average								; value at index of decimal_array
	call			WriteVal
	call			CrLf
	call			CrLf

  ; display goodbye
	displayString	OFFSET farewell
	call			CrLf

	exit	; exit to operating system
Main ENDP


; description: displays a brief introduction of the program with title and programmer name and extra credit.
; receives: OFFSET prompt_1 [ebp+8], OFFSET prompt_2 [ebp+12], OFFSET prompt_3 [ebp+16], OFFSET ec_1 [ebp+20]
; returns: none
; preconditions: none 
; registers changed: none (saved to stack)

Introduction PROC
	push			ebp
	mov				ebp,esp
	pushad

	displayString	[ebp+8]								; address of prompt_1
	call			CrLf

	displayString	[ebp+20]							; address of ec_1	
	call			CrLf
	call			CrLf

	displayString	[ebp+12]							; address of prompt_2
	call			CrLf
	call			CrLf
	
	displayString	[ebp+16]							; address of prompt_3	
	call			CrLf
	call			CrLf
				
	popad
	pop				ebp
	ret				16
Introduction ENDP

; description: saves a user input string, and saves character count of input string
; receives: OFFSET buffer [ebp+8], SIZEOF buffer [ebp+12]
; returns: user input string
; preconditions: none 
; registers changed: none (saved to stack)

ReadVal PROC
	push			ebp
	mov				ebp, esp
	pushad
	
	getString		[ebp+8], [ebp+12]					; address of buffer, size of buffer

	popad
	pop				ebp
	ret				8
ReadVal	ENDP


; description: validates that the user input consists entirely of ascii char values.
; receives: OFFSET buffer [ebp+8], SIZEOF buffer [ebp+12], OFFSET converted_int [ebp+16], 
	;value of HIGH_VALID [ebp+20], value of LOW_VALID [ebp+24], OFFSET of Warning_1 [ebp+28], 
	;OFFSET of prompt_2 [ebp+32], value of loop count [epb+36]
; returns: a valid user input string
; preconditions: a string has been entered by the user
; registers changed: none (saved to stack)

Validate PROC
	push			ebp
	mov				ebp, esp
	pushad

  ; re-initialize converted_int to 0
	mov				eax, [ebp+16]						; address of converted_int
	mov				ebx, 0
	mov				[eax], ebx

re_validate:
  ; prepare registers
	mov				edx, [ebp+8]						; address of buffer
	mov				eax, 0
	mov				ecx, 0
	mov				esi, edx

; re-initialize decimal_count
	mov				ebx, [ebp+36]						; address of decimal_count
	mov				eax, 0
	mov				[ebx], eax

string_index:
  ; add 1 to decimal_count
	mov				ebx, [ebp+36]						; address of decimal_count
	mov				eax, 1
	add				[ebx], eax
	mov				eax, 0

  ; load the current ascii value into the eax register.
	lodsb

  ; check if end of string has been reached
	cmp				eax, 0
	je				end_of_string

  ; check if the input ascii value is a valid input character
	mov				ebx, [ebp+20]						; value of HIGH_VALID
	cmp				eax, ebx
	ja				invalid
	mov				ebx, [ebp+24]						; value of LOW_VALID
	cmp				eax, ebx	
	jb				invalid

  ; convert the input to decimal value
	push			[ebp+16]							; address of converted_int
	push			[ebp+24]							; value of LOW_VALID
	push			eax									; value of current ascii char
	call			ConvertDecimal
	jc				invalid								; if carry flag is set from ConvertDecimal
	jmp				string_index

invalid:
  ; re-initialize converted_int to 0
	mov				eax, [ebp+16]						; address of converted_int
	mov				ebx, 0
	mov				[eax], ebx

  ; re-enter and re-validate the input
	displayString	[ebp+28]							; address of Warning_1
	call			CrLf	
	displayString	[ebp+32]							; address of Prompt_2
	getString		[ebp+8], [ebp+12]					; address of buffer, size of buffer
	jmp				re_validate	

end_of_string:

  ; if end of string is the first input, invalid
	mov				eax, [ebp+36]						; address of decimal count
	mov				ebx, 1
	cmp				[eax], ebx
	je				invalid

  ; re-initialize decimal_count to 0
	mov				ebx, [ebp+36]						; address of decimal_count
	mov				eax, 0
	mov				[ebx], eax

	popad
	pop				ebp
	ret				32
Validate ENDP


; description: converts the ascii character into a decimal value
; receives: value of current ascii char [ebp+8], value of LOW_VALID [ebp+12], OFFSET of converted_int [ebp+16]
; returns: an integer in converted_int
; preconditions: A string of valid integers has been populated
; registers changed: none (saved to stack)

ConvertDecimal	PROC
	push			ebp
	mov				ebp, esp
	pushad

  ; prepare registers
	mov				eax, [ebp+8]						; value of current ascii char
	mov				ecx, [ebp+16]						; address of converted_int
	mov				ebx, [ecx]							; value of converted_int
	mov				esi, edx

  ; convert ascii character to decimal
	mov				ecx, [ebp+12]						; value of LOW_VALID
	sub				eax, ecx

  ; input the converted decimal it its proper "tens place"
	xchg			eax, ebx
	mov				ecx, 10	   								
	mul				ecx									; move decimal place on previous integer to the right by 1 space
	jc				carry_flag_set
	add				eax, ebx							; add the next decimal to the end
	xchg			eax, ebx							; exchange registers again so lodsb doesn't overwrite our stored integer
	
  ; store current value in variable
	mov				eax, [ebp+16]						; address of converted_int
	mov				[eax], ebx
	
carry_flag_set:
	popad
	pop				ebp
	ret				12
ConvertDecimal ENDP


; description: inserts the input string as an integer in a new array
; receives: OFFSET decimal_array [ebp+8], value of converted_int [ebp+12], user input loop iteration [ebp+16]
; returns: an array of integers
; preconditions: a string of valid ascii integer characters has been converted to a string of integer values
; registers changed: none (saved to stack)

InsertArray PROC
	push			ebp
	mov				ebp,esp
	pushad

	mov				eax, [ebp+16]						; user input loop iteration
	sub				eax, 1								; adjust to index value
	mov				ebx, 4
	mul				ebx									; adjust for dword size		
	
	mov				ebx, [ebp+8]						; address of decimal_array
	add				ebx, eax							; adjust to current index
	mov				ecx, [ebp+12]						; value of converted_int
	mov				[ebx], ecx

	popad
	pop				ebp
	ret				12		
InsertArray ENDP


; description: calculates the running sum of each user input
; receives: OFFSET sum [ebp+8], OFFSET converted_int [ebp+12]
; returns: value of converted_int
; preconditions: one or more integers have been intput and converted to decimal
; registers changed: none (saved to stack)

CalculateSum PROC
	push			ebp
	mov				ebp,esp
	pushad

	mov				eax, [ebp+8]						; address of sum
	mov				ebx, [ebp+12]						; address of converted_int
	mov				ecx, [ebx]							; value of converted_int
	add				[eax], ecx

	popad
	pop				ebp
	ret				8
CalculateSum ENDP


; description: Takes a sum of integers and calculates the average.
; receives: OFFSET of average [ebp+8], value of sum [ebp+12], value of INPUT_AMOUNT [ebp+16]
; returns: value of average
; preconditions: a list of integers have been entered, converted to decimal, and sumed.
; registers changed: none (saved to stack)

CalculateAverage PROC
	push			ebp
	mov				ebp,esp
	pushad

	; calculate average of all inputs
	mov				edx, 0
	mov				eax, [ebp+12]						; value of sum
	mov				ebx, [ebp+16]						; value of INPUT_AMOUNT
	div				ebx
	mov				ebx, [ebp+8]						; address of average
	mov				[ebx], eax

	popad
	pop				ebp
	ret				12
CalculateAverage ENDP


; description: takes an integer value, converts the digits to ascii value, prints string to console.
; receives: value of current decimal_array index [ebp+8], OFFSET output_buffer [ebp+12], OFFSET decimal_count [ebp+16], value LOW_VALID [ebp+20]
; returns: output_buffer
; preconditions: an array of integers must be populated, and an index of array passed in 
; registers changed: none (saved to stack)

WriteVal PROC
	push			ebp
	mov				ebp, esp
	pushad

  ; convert each decimal to it's ascii char value in reverse order and save on stack
	mov				eax, [ebp+8]						; value at index of decimal_array
	mov				ecx, 0								; ecx counts decimal number in integer

count_loop:
	
  ; divide the current integer by 10 to get the last digit as a quotient
	mov				edx, 0
	add				ecx, 1													
	mov				ebx, 10
	div				ebx

  ; convert the quotient to it's ascii value and save on stack
	add				edx, [ebp+20]						; value of LOW_VALID (ascii 0)
	push			edx									; save the quotient on the stack
	
	mov				ebx, 0													
	cmp				eax, ebx							; find end of string
	je				count_loop_done
	jmp				count_loop
count_loop_done:

 ; pop the the stack into the output_buffer and display
	mov				eax, [ebp+12]						; address of output_buffer
pop_loop:
	pop				[eax]
	displayString	eax									; address of output_buffer
	add				eax, 4								; increment to next index in output_buffer
	loop			pop_loop

	popad
	pop				ebp
	ret				16
WriteVal ENDP

END MAIN





















