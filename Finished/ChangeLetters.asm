	.data							#data segment
prompt:	.asciiz "Enter string [letters only]: \n"		#string
	.align 2						#natural alignment to n -> 2^n; Here 2^2 = 4
buf:	.space 100						#buffer
	.text							#text segment
	.globl main						#visible outside
main:
	li $v0, 4						#print string
	la $a0, prompt						#from this
	syscall
	li $v0, 8						#read string
	la $a0, buf						#to this
	li $a1, 100						#max length
	syscall
	la $t0, buf						#get address of buffer
loop:
	lw $t1, ($t0)						#load first word
	andi $t2, $t1, 0xFF					#get first letter of the word with use of the mask
	ble $t2, ' ', end					#check if it isn't a control character or space
	move $t3, $t2						#move first letter to new local
	
	srl $t2, $t1, 8						#move to next letter
	andi $t2, $t2, 0xFF					#get second letter
	ble $t2, ' ', end					#check if it isn't a control character or space
	sll $t2, $t2, 16					#move to third place of the word
	or $t3, $t3, $t2					#add to local
	
	srl $t2, $t1, 16					#move to next letter
	andi $t2, $t2, 0xFF					#get third letter
	ble $t2, ' ', end					#check if it isn't a control character or space
	sll $t2, $t2, 8						#move to second place of the word
	or $t3, $t3, $t2					#add to local
	
	srl $t2, $t1, 24					#move to next letter
	andi $t2, $t2, 0xFF					#get fourth letter
	ble $t2, ' ', end					#check if it isn't a control character or space
	sll $t2, $t2, 24					#move to fourth place of the word
	or $t3, $t3, $t2					#add to local
	
	sw $t3, ($t0)						#save new word to original word
	addi $t0, $t0, 4					#get another word
	b loop							#go to loop once more
end:
	li $v0, 4						#print string
	la $a0, buf						#from this
	syscall							
	li $v0, 10						#terminate execution
	syscall
