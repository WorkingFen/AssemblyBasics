	.data						#data segment
prompt: .asciiz "Enter string with numbers: \n"		#string
buf:	.space 100					#buffer for users string
	.text						#text segment
	.globl main					#visible outside
main:	
	li $v0, 4					#print string
	la $a0, prompt					#from this
	syscall
	li $v0, 8					#read string
	la $a0, buf					#to this
	li $a1, 100					#max 100 bytes
	syscall
	la $t0, buf					#first local -> address of buffer
	lbu $t1, ($t0)					#second local -> first byte from buffer
	li $t2, 0					#third local -> actual number
	li $t3, 0					#fourth local -> temp number
	beqz $t1, end					#check if equal zero then go to label "end"
loop:
	blt $t1, '0', next				#check if first lesser than second then go to label next
	bgt $t1, '9', next				#check if first greater than second then go to label next
	addi $t3, $t3, 1 				#add one to counter
	addi $t0, $t0, 1				#next address of buffer
	lbu $t1, ($t0)					#get next element
	bnez $t1, loop 					#check if not equal zero then go to label "loop"
next:
	bgtz $t3, count					#check if first is greater than second then go to label "save"
	addi $t0, $t0, 1				#next address
	lbu $t1, ($t0)					#get next element
	bnez $t1, loop					#check if not equal zero then go to label "loop"
	beqz $t1, end					#check if equal zero then go to label "end"
count:
	addi $t2, $t2, 1				#add one to decimal counter
	li $t3, 0					#temp is zero now
	addi $t0, $t0, 1				#next address of buffer
	lbu $t1, ($t0)					#get next element
	bnez $t1, loop					#check if not equal zero then to got label "loop"
end:
	li $v0, 1					#print integer
	la $a0, ($t2)					#from this
	syscall
	li $v0, 10					#terminate execution
	syscall
