	.data						#data segment
prompt:	.asciiz "Enter string with numbers: \n"		#string
buf:	.space 100					#buffer for users string
num:	.space 100					#buffer for numbers
temp:	.space 100					#temporary buffer for numbers
	.text						#text segment
	.globl main					#visible outside
main:
	li $v0, 4					#print string
	la $a0, prompt					#from this
	syscall
	li $v0, 8					#read string
	la $a0, buf					#to this
	li $a1, 100					#max this
	syscall
	li $t0, 0					#first local -> max number
	li $t1, 0					#second local -> actual number
	la $t2, buf					#third local -> address of buffer
	lb $t3, ($t2)					#fourth local -> first byte from buffer
	la $t4, num					#fifth local -> address of numbers buffer
	la $t5, ($t4)					#sixth local -> static address to buffer
	la $t6, temp					#seventh local -> address of temp buffer
	la $t7, ($t6)					#eigth local -> static address to temp buffer 
	beqz $t3, end					#check if equal \0 then go to label "end"
loop:	
	blt $t3, '0', next				#check if first is lesser than second then go to label "next"
	bgt $t3, '9', next				#check if first is greater than second then go to label "next"
	sb $t3, ($t6)					#save byte to temp buffer
	addi $t6, $t6, 1				#next element of temp buffer
	addi $t1, $t1, 1				#actual number + 1
	addi $t2, $t2, 1				#go to next char of string
	lb $t3, ($t2)					#get byte from buffer
	bnez $t3, loop					#check if not equal \0 then go to label "loop"
bufnum:	
	sb $zero, ($t6)					#add \0 on the end of temp buffer
	move $t0, $t1					#move from
	la $t1, ($t6)					#save end address of temp buffer
	la $t6, ($t7)					#first element of temp buffer
	la $t4, ($t5)					#first element of number buffer
	jal load					#go to load and return
	li $t1, 0					#clear temporary counter
	la $t6, ($t7)					#first element of temp buffer
	lb $t3, ($t2)					#next element of string
	bnez $t3, loop					#check if not equal \0 then go to label "loop"
	beqz $t3, end					#check if equal \0 then go to label "end"
load:
	lb $t3, ($t6)					#load element from temp buffer
	sb $t3, ($t4)					#save element to number buffer
	addi $t6, $t6, 1				#next address of temp buffer
	addi $t4, $t4, 1				#next address of number buffer
	bne $t6, $t1, load				#check if address is not the end address of temp buffer, then go to label "load"
	jr $ra						#return
next:
	bgt $t1, $t0, bufnum				#check if first is greater than second then go to label "bufnum"
	li $t1, 0					#first is 0 now
	addi $t2, $t2, 1				#go to the next address
	lb $t3, ($t2)					#get value
	bnez $t3, loop					#check if not equal \0 then go to label "loop"
end:
	li $v0, 4					#print string
	la $a0, num					#from this
	syscall						
	li $v0, 10					#terminate execution
	syscall
