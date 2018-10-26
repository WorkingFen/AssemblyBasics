	.data						#data segment
prompt:	.asciiz "Enter string with numbers: \n"		#string
buf:	.space 100					#buffer for users string
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
	la $t0, buf					#first local -> address of buffer
	la $t1, ($t0)					#second local -> static address to buffer
	lb $t2, ($t0)					#third local -> first byte from buffer
	la $t3, temp					#fourth local -> address of numbers buffer
	beqz $t2, end					#check if equal \0 then go to label "end"
loop:	
	blt $t2, '0', next				#check if first is lesser than second then go to label "next"
	bgt $t2, '9', next				#check if first is greater than second then go to label "next"
	sb $t2, ($t3)					#save byte to temp buffer
	addi $t3, $t3, 1				#next element of temp buffer
	addi $t0, $t0, 1				#go to next char of string
	lb $t2, ($t0)					#get byte from buffer
	bnez $t2, loop					#check if not equal \0 then go to label "loop"
	beqz $t2, reve					#check if equal \0 then go to label "reve"
next:
	addi $t0, $t0, 1				#go to the next address
	lb $t2, ($t0)					#get value
	bnez $t2, loop					#check if not equal \0 then go to label "loop"
reve:	
	la $t0, ($t1)					#first element of buffer
	lb $t2, ($t0)					#load element from buffer
	subu $t3, $t3, 1				#decrease address of temp
loop2:	
	blt $t2, '0', next2				#check if first is lesser than second then go to label "next2"
	bgt $t2, '9', next2				#check if first is greater than second then go to label "next2"
	lb $t1, ($t3)					#load byte from temp
	sb $t1, ($t0)					#save byte to buffer
	subu $t3, $t3, 1				#previous element of temp buffer
	addi $t0, $t0, 1				#go to next char of string
	lb $t2, ($t0)					#get byte from buffer
	bnez $t2, loop2					#check if not equal \0 then go to label "loop2"
	beqz $t2, end					#check if equal \0 then go to label "end"
next2:
	addi $t0, $t0, 1				#go to the next address
	lb $t2, ($t0)					#get value
	bnez $t2, loop2					#check if not equal \0 then go to label "loop2"
end:
	li $v0, 4					#print string
	la $a0, buf					#from this
	syscall						
	li $v0, 10					#terminate execution
	syscall
