	.data
# -------------Text To Show --------------------------------------------------------------
prompt:	.ascii "ZBuffer Algorithm simulator.\n"
	.asciiz "Please insert coordinates (x,y,z)(1-100) of first vertex of first triangle\n"
nvert:	.asciiz "Please insert coordinates (x,y,z)(1-100) of next vertex of the triangle\n"
stri:	.asciiz "Please insert coordinates (x,y,z)(1-100) of first vertex of second triangle\n"
fin:	.asciiz "The result .bmp file is ready\n"
err:	.asciiz "Error occured while loading file. Check if it is in catalog with MARS 4.5\n"

file:	.asciiz "canvas.bmp"					#File's name "canvas.bmp" [100x100]; for "test.bmp" [8x8]
filein:	.asciiz "canvasout.bmp"					#File's name "canvasout.bmp" [100x100]; for "testout.bmp" [8x8]
	
	.align 2
pixels:	.space 4						#Quantity of pixels
bmaddr:	.space 4						#Bitmap address
color:	.space 4						#Color of new pixels
vertex: .space 12						#Buffer of vertices [Three vertices for 4 bytes]
noline:	.space 4						#Which line [0 if first, 1 if second, 2 if third]
abcpl:	.space 12						#A, b and c [For equation of plane]
nexttr:	.space 4						#Next triangle [True or False/ 1 or 0]
minX:	.space 4						#Minimal Y
maxX:	.space 4						#Maximum Y
minY:	.space 4						#Minimal Y
maxY:	.space 4						#Maximum Y
denom:	.space 4						#Denominator
alfa:	.space 4						#Baricentric alfa
beta:	.space 4						#Baricentric beta
gamma:	.space 4						#Baricentric gamma

fdesc:	.space 4						#File descriptor
# -------------BMP File Header -----------------------------------------------------------
id:	.space 4						#"BM" ID field ![Should be space 2]
fsize:	.space 4						#Size of the BMP file
appsp:	.space 4						#Application specific
offp:	.space 4						#Offset where the pixel array can be found
nodib:	.space 4						#Number of bytes in the DIB header
width:	.space 4						#Width in pixels
height:	.space 4						#Height in pixels
noplan:	.space 4						#Number of planes ![Should be space 2]
nobpp:	.space 4						#Number of bits per pixel ![Should be space 2]
bdcom:	.space 4						#Pixel array compression used
rawbd:	.space 4						#Size of the raw bitmap data
resho:	.space 4						#Print resolution of the image/ horizontal
resve:	.space 4						#Print resolution of the image/ vertical
nocol:	.space 4						#Number of colors in the palette
imcol:	.space 4						#Number of important colors [0 means all colors are important]
pixel:	.space 4						#Space for one pixel [Pixel as z,B,G,R]
padd:	.space 4						#Space for padding [Padding should be two 0 or other chars]

# -------------Macro: to know what I am doing --------------------------------------------
.macro get_xcoor(%from, %dest, %step)
	li $v0, 4						#Print string
	la $a0, %from						#From this
	syscall
	li $v0, 5						#Read int /Get x
	syscall
	move $t0, $v0
	andi $t1, $t0, 0xFF
	sw $t1, %dest+%step
.end_macro

.macro get_coor(%shift, %dest, %step)
	li $v0, 5						#Read int
	syscall
	move $t0, $v0
	andi $t1, $t0, 0xFF					#Get two least significant bits
	sll $t1, $t1, %shift
	lw $t0, %dest+%step
	or $t0, $t0, $t1
	sw $t0, %dest+%step					#Add new coordinate to vertex
.end_macro

.macro swap_coor(%fir, %sec, %temp)
	move %temp, %fir
	move %fir, %sec
	move %sec, %temp
.end_macro

.macro get_bytes(%from, %dest, %size)
	li $v0, 14						#Read from file
	lw $a0, %from
	la $a1, %dest
	li $a2, %size						#How many bytes
	syscall
.end_macro

.macro save_bytes(%to, %from, %size)
	li $v0, 15						#Write to file
	lw $a0, %to
	la $a1, %from
	li $a2, %size						#How many bytes
	syscall
.end_macro

.macro open_file(%file, %flag)
	li $v0, 13
	la $a0, %file
	li $a1, %flag						#Flag: 0 - read-only; 1 - write-only
	li $a2, 0
	syscall							#File descriptor in $v0
	
	bltz $v0, error
	sw $v0, fdesc						#Save file descriptor
.end_macro

.macro prepare_vertices(%from, %x1, %y1, %z1, %x2, %y2, %z2, %no)
	lb $t0, %from+%x1					#X of first vertex
	lb $t1, %from+%y1					#Y of first vertex
	lb $t2, %from+%z1					#Z of first vertex
	lb $t3, %from+%x2					#X of second vertex
	lb $t4, %from+%y2					#Y of second vertex
	lb $t5, %from+%z2					#Z of second vertex
	li $t6, %no
	sb $t6, noline
	bgt $t0, $t3, swap					#Check if X1 is greater than X2, if true swap vertices
.end_macro

.macro prepare_factor(%from, %a1, %b1, %a2, %b2, %a3, %b3, %to, %step)
	lb $t0, %from+%a1					#First coordinate of first vertex [A1]
	lb $t1, %from+%b1					#Second coordinate of first vertex [B1]
	lb $t2, %from+%a2					#First coordinate of second vertex [A2]
	lb $t3, %from+%b2					#Second coordinate of second vertex [B2]
	lb $t4, %from+%a3					#First coordinate of third vertex [A3]
	lb $t5, %from+%b3					#Second coordinate of third vertex [B3]
	sub $t6, $t0, $t2					#(A1-A2)
	sub $t7, $t1, $t3					#(B1-B2)
	sub $t8, $t2, $t4					#(A2-A3)
	sub $t9, $t3, $t5					#(B2-B3)
	mult $t6, $t9
	mflo $t6						#(A1-A2)(B2-B3)
	mult $t7, $t8
	mflo $t7						#(B1-B2)(A2-A3)
	sub $t6, $t6, $t7					#(A1-A2)(B2-B3)-(B1-B2)(A2-A3) => factor
	la $t9, %to+%step
	sw $t6, ($t9)
.end_macro

.macro prepare_pixel(%width, %t0, %t1, %t2, %t3)
	move %t0, %t1						#Yk
	addi %t0, %t0, -1					#(Yk-1)
	lw %t2, %width						#Width
	mult %t0, %t2						#(Yk-1)*Width
	mflo %t0						#%t0 := (Yk-1)*Width
	move %t2, %t3						#Xk
	addi %t2, %t2, -1					#(Xk-1)
	addu %t0, %t0, %t2					#(Yk-1)*Width+(Xk-1)
	li %t2, 4						#4
	mult %t0, %t2						#[(Yk-1)*Width+(Xk-1)]*4
	mflo %t2						#Result := [(Yk-1)*8+(Xk-1)]*4 -> Pixel in bitmap
.end_macro

.macro get_pixel(%from, %t0, %t1)
	lw %t0, %from						#Load address of bitmap
	addu %t0, %t0, %t1					#Go to address of proper pixel
	lw %t1, (%t0)						#Load pixel
	srl %t1, %t1, 24					#Get Z of pixel
.end_macro

.macro draw(%color, %t0, %t1, %t2)
	lw %t0, %color						#0xbBgGrR [Color] Could be anything, that's why I have next line
	sll %t1, %t1, 24					#0xzZ000000
	or %t0, %t0, %t1					#0xzZbBgGrR
	sw %t0, (%t2)						#Save new pixel on bitmap
	srl %t1, %t1, 24					#0x000000zZ
.end_macro

.macro exloop(%loop, %noline, %nxtrn, %t0, %t1, %t2, %t3)
	ble %t0, %t1, %loop					#If it isn't last element of line
	lb %t2, %noline
	li %t3, 3
	beq %t2, %t3, %nxtrn					#If it was last line
	b nextl
.end_macro

.macro find_maxmin(%from, %A1, %A2, %A3, %maxA, %minA, %go)
	lb $t0, %from+%A1					#Coordinate of first vertex [A1]
	lb $t1, %from+%A2					#Coordinate of second vertex [A2]
	lb $t2, %from+%A3					#Coordinate of third vertex [A3]
	
	bgt $t0, $t1, c1g2					#Check if A1 > A2
	bgt $t2, $t1, c3g2					#Check if A3 > A2
	bgt $t2, $t0, c3g1					#Check if A3 > A1
	sb $t1, %maxA						#A2 is max
	sb $t2, %minA						#A3 is min
	b %go
c1g2:
	bgt $t1, $t2, c2g3					#Check if A2 > A3
	bgt $t0, $t2, c1g3					#Check if A1 > A3
	sb $t2, %maxA						#A3 is max
	sb $t1, %minA						#A2 is min
	b %go
c2g3:
	sb $t0, %maxA						#A1 is max
	sb $t2, %minA						#A3 is min
	b %go
c1g3:
	sb $t0, %maxA						#A1 is max
	sb $t1, %minA						#A2 is min
	b %go
c3g2:
	sb $t2, %maxA						#A3 is max
	sb $t0, %minA						#A1 is min
	b %go
c3g1:	
	sb $t1, %maxA						#A2 is max
	sb $t0, %minA						#A1 is min
.end_macro

.macro prepare_denominator(%from, %A1, %A2, %B1, %B2, %C1, %C2, %to)
	lb $t0, %from+%A1					#First coordinate of first vertex [A1]
	lb $t1, %from+%A2					#Second coordinate of first vertex [A2]
	lb $t2, %from+%B1					#First coordinate of second vertex [B1]
	lb $t3, %from+%B2					#Second coordinate of second vertex [B2]
	lb $t4, %from+%C1					#First coordinate of third vertex [C1]
	lb $t5, %from+%C2					#Second coordinate of third vertex [C2]
	
	mult $t0, $t3
	mflo $t6						#A1*B2
	mult $t1, $t2
	mflo $t7						#A2*B1
	subu $t8, $t1, $t3					#[A2-B2]
	subu $t9, $t2, $t0					#[B1-A1]
	mult $t4, $t8
	mflo $t4						#C1*[A2-B2]
	mult $t5, $t9
	mflo $t5						#C2*[B1-A1]
	addu $t4, $t4, $t5					#C1*[A2-B2] + C2*[B1-A1]
	addu $t4, $t4, $t6					#C1*[A2-B2] + C2*[B1-A1] + A1*B2
	subu $t4, $t4, $t7					#C1*[A2-B2] + C2*[B1-A1] + A1*B2 - A2*B1
	sw $t4, %to
.end_macro

.macro bar_factor(%from, %A1, %A2, %B1, %B2, %C1, %C2, %to, %go)
	lb $t0, %from+%A1					#First coordinate of first vertex [A1]
	lb $t1, %from+%A2					#Second coordinate of first vertex [A2]
	lb $t2, %from+%B1					#First coordinate of second vertex [B1]
	lb $t3, %from+%B2					#Second coordinate of second vertex [B2]
	
	subu $t4, $t1, $t3					#[A2-B2]
	subu $t5, $t2, $t0					#[B1-A1]
	mult $t0, $t3
	mflo $t0						#A1*B2
	mult $t1, $t2
	mflo $t1						#A2*B1
	mult $t4, %C1
	mflo $t4						#C1*[A2-B2]
	mult $t5, %C2
	mflo $t5						#C2*[B1-A1]
	addu $t4, $t4, $t5					#C1*[A2-B2] + C2*[B1-A1]
	addu $t4, $t4, $t0					#C1*[A2-B2] + C2*[B1-A1] + A1*B2
	subu $t4, $t4, $t1					#C1*[A2-B2] + C2*[B1-A1] + A1*B2 - A2*B1
	bltz $t4, %go
	sw $t4, %to
.end_macro

# ========================================================================================

	.text
	.globl main
# -------------Start ---------------------------------------------------------------------
main:	
	#First vertex with title
	get_xcoor(prompt, vertex, 0)				#Get x
	get_coor(8, vertex, 0)					#Get y
	get_coor(16, vertex, 0)					#Get z
	
	#Second vertex
	get_xcoor(nvert, vertex, 4)				#Get x
	get_coor(8, vertex, 4)					#Get y
	get_coor(16, vertex, 4)					#Get z
	
	#Third vertex
	get_xcoor(nvert, vertex, 8)				#Get x
	get_coor(8, vertex, 8)					#Get y
	get_coor(16, vertex, 8)					#Get z
	
	li $t1, 0x4060DD
	sw $t1, color						#Set color of first triangle
	
	li $t1, 1						#True
	sw $t1, nexttr						#So get next triangle after drawing this one
		
# -------------Open File To Load----------------------------------------------------------
	open_file(file, 0)

# -------------Load File Header ----------------------------------------------------------
	get_bytes(fdesc, id, 2)					#Load ID -> "BM"
	get_bytes(fdesc, fsize, 4)				#Load file size 
	get_bytes(fdesc, appsp, 4)				#Load application specific
	get_bytes(fdesc, offp, 4)				#Load offset
	get_bytes(fdesc, nodib, 4)				#Load number of bytes in DIB header
	get_bytes(fdesc, width, 4)				#Load width
	get_bytes(fdesc, height, 4)				#Load height
	
	#Calculate how many pixels are there
	lw $t0, width
	lw $t1, height
	multu $t0, $t1
	mflo $t0
	li $t1, 4
	multu $t0, $t1
	mflo $t0
	sw $t0, pixels
	#Allocate memory for all pixels
	li $v0, 9
	lw $a0, pixels
	syscall
	sw $v0, bmaddr
	
	get_bytes(fdesc, noplan, 2)				#Load number of planes
	get_bytes(fdesc, nobpp, 2)				#Load number of bits per pixel
	get_bytes(fdesc, bdcom, 4)				#Load pixel array compression
	get_bytes(fdesc, rawbd, 4)				#Load size of the raw bitmap data
	get_bytes(fdesc, resho, 4)				#Load print resolution of the image /horizontal
	get_bytes(fdesc, resve, 4)				#Load print resolution of the image /vertical
	get_bytes(fdesc, nocol, 4)				#Load number of colors
	get_bytes(fdesc, imcol, 4)				#Load number of important colors
	
# -------------Load Pixels ---------------------------------------------------------------
	lw $t0, width						#Load width in pixels
	lw $t1, height						#Load height in pixels
	li $t2, 0						#Iterator defining column
	li $t3, 0						#Iterator defining row
	lw $t6, bmaddr						#Load address of bitmap
lpixeh:	
	addiu $t3, $t3, 1					#Iterate in rows
lpixew:
	addiu $t2, $t2, 1					#Iterate in columns
	get_bytes(fdesc, pixel, 3)				#Get pixel
	lw $t4, pixel						#Load from buffer
	li $t5, 0xFF						#0xFF
	sll $t5, $t5, 24					#Shift left to state 0xFF000000
	or $t4, $t4, $t5					#Or with loaded pixel to state 0xFFbBgGrR
	sw $t4, ($t6)						#Save pixel to bitmap
	addiu $t6, $t6, 4					#Go to next address of bitmap
	blt $t2, $t0, lpixew					#If iterator is lesser than width, go to lpixew [Loop]
	li $t2, 0						#Change iterator to 0
	and $t4, $t0, 0x3					#Mod 4 -> Get to know what size padding is
	
	li $v0, 14						#Read padding from file
	lw $a0, fdesc						#File descriptor
	la $a1, padd						#To padding buffer
	la $a2, ($t4)						#How many bytes
	syscall
	
	blt $t3, $t1, lpixeh					#If iterator is lesser than height, go to lpixeh [Loop]
	li $t3, 0						#Change iterator to 0
	
# -------------Close File ----------------------------------------------------------------
	li $v0, 16
	lw $a0, fdesc
	syscall
	
# -------------Prepare plane -------------------------------------------------------------
	#Plane equation := [a(x-x0) + b(y-y0) + c(z-z0) = 0]
pplane:
	prepare_factor(vertex, 1, 2, 5, 6, 9, 10, abcpl, 0)	#Factor a
	prepare_factor(vertex, 2, 0, 6, 4, 10, 8, abcpl, 4)	#Factor b
	prepare_factor(vertex, 0, 1, 4, 5, 8, 9, abcpl, 8)	#Factor c

# -------------Find MAX and MIN Coordinates ----------------------------------------------
	find_maxmin(vertex, 0, 4, 8, maxX, minX, mimaY)		#Find max and min of X
mimaY:
	find_maxmin(vertex, 1, 5, 9, maxY, minY, denomi)	#Find max and min of Y

# -------------Prepare denominator -------------------------------------------------------
denomi:
	prepare_denominator(vertex, 0, 1, 4, 5, 8, 9, denom)	#Denominator for filling triangles

# -------------Prepare vertices ----------------------------------------------------------
	#First and Second Vertices
first:
	prepare_vertices(vertex, 0, 1, 2, 4, 5, 6, 1)		#First and second vertices
	ble $t0, $t3, lines					#Check if X1 is lesser or equal X2, if true go to lines
	
	#Second and Third Vertices
second:
	prepare_vertices(vertex, 4, 5, 6, 8, 9, 10, 2)		#Second and third vertices
	ble $t0, $t3, lines					#Check if X1 is lesser or equal X2, if true go to lines
	
	#Third and First Vertices
third:
	prepare_vertices(vertex, 8, 9, 10, 0, 1, 2, 3)		#Third and first vertices
	
#############################################################################################################################################################################################
# -------------Types of lines ------------------------------------------------------------
lines:
	subu $t6, $t3, $t0					#$t6 := deltaX
	li $t8, 2
	multu $t6, $t8
	mflo $t9						#$t9 := 2*deltaX
	bgt $t1, $t4, decl					#Check if Y1 is greater than Y2 [Line is declining]
	
	#Ascending [less than 45 and more than 0 degrees] and horizontal lines
ascen:
	subu $t7, $t4, $t1					#$t7 := deltaY
	multu $t7, $t8
	mflo $t7						#$t7 := 2*deltaY => a
	subu $t8, $t7, $t9					#$t8 := (2*deltaY - 2*deltaX) => b
	bgtz $t8, ascen45					#Check if line is more than 45 degrees
	subu $t9, $t7, $t6					#$t9 := (2*deltaY - deltaX) => p0
loopas:
	prepare_pixel(width, $t4, $t1, $t6, $t0)		#Pixel on bitmap
	get_pixel(bmaddr, $t4, $t6)				#Load pixel and get it's Z
	bgt $t2, $t6, nextas					#Check if Z of current pixel is greater than Z of pixel on bitmap
	draw(color, $t6, $t2, $t4)				#Draw pixel
nextas:
	bgtz $t9, upas						#Check if Pk greater than 0
	addu $t9, $t9, $t7					#Pk := Pk-1 + a
	addu $t0, $t0, 1					#Xk := Xk-1 + 1
	#Changing Z---------------------------------------------
	la $t4, abcpl
	lw $t5, ($t4)						#Plane a [Pa]
	la $t4, abcpl+8
	lw $t6, ($t4)						#Plane c [Pc]
	multu $t2, $t6
	mflo $t2						#Pc*Zk-1
	sub $t2, $t2, $t5					#Pc*Zk := Pc*Zk-1 - Pa
	div $t2, $t2, $t6					#Zk := Zk-1 - Pa/Pc
	#=======================================================
	exloop(loopas, noline, fill, $t0, $t3, $t4, $t6)	#Exit loop?									
upas:
	addu $t9, $t9, $t8					#Pk := Pk-1 + b
	addu $t0, $t0, 1					#Xk := Xk-1 + 1
	addu $t1, $t1, 1					#Yk := Yk-1 + 1
	#Changing Z---------------------------------------------
	la $t4, abcpl
	lw $t5, ($t4)						#Plane a [Pa]
	la $t4, abcpl+4
	lw $t6, ($t4)						#Plane b [Pb]
	add $t5, $t5, $t6					#Pa+Pb
	la $t4, abcpl+8
	lw $t6, ($t4)						#Plane c [Pc]
	multu $t2, $t6
	mflo $t2						#Pc*Zk-1
	sub $t2, $t2, $t5					#Pc*Zk := Pc*Zk-1 - [Pa+Pb]
	div $t2, $t2, $t6					#Zk := Zk-1 - Pa+Pb/Pc
	#=======================================================
	exloop(loopas, noline, fill, $t0, $t3, $t4, $t6)	#Exit loop?
		
	#Ascending [less than 90 and more than 45 degrees]
ascen45:
	subu $t6, $t4, $t1					#$t6 := deltaY
	li $t8, 2
	multu $t6, $t8
	mflo $t9						#$t9 := 2*deltaY
	subu $t7, $t3, $t0					#$t7 := deltaX
	multu $t7, $t8
	mflo $t7						#$t7 := 2*deltaX => a
	subu $t8, $t7, $t9					#$t8 := (2*deltaX - 2*deltaY) => b
	subu $t9, $t7, $t6					#$t9 := (2*deltaX - deltaY) => p0
loopas45:
	prepare_pixel(width, $t3, $t1, $t6, $t0)		#Pixel on bitmap
	get_pixel(bmaddr, $t3, $t6)				#Load pixel and get it's Z
	bgt $t2, $t6, onas45					#Check if Z of current pixel is greater than Z of pixel on bitmap
	draw(color, $t6, $t2, $t3)				#Draw pixel
onas45:
	bgtz $t9, upas45					#Check if Pk greater than 0
	addu $t9, $t9, $t7					#Pk := Pk-1 + a
	addu $t1, $t1, 1					#Yk := Yk-1 + 1
	#Changing Z---------------------------------------------
	la $t3, abcpl+4
	lw $t5, ($t3)						#Plane b [Pb]
	la $t3, abcpl+8
	lw $t6, ($t3)						#Plane c [Pc]
	multu $t2, $t6
	mflo $t2						#Pc*Zk-1
	sub $t2, $t2, $t5					#Pc*Zk := Pc*Zk-1 - Pb
	div $t2, $t2, $t6					#Zk := Zk-1 - Pb/Pc
	#=======================================================
	exloop(loopas45, noline, fill, $t1, $t4, $t3, $t6)	#Exit loop?
upas45:
	addu $t9, $t9, $t8					#Pk := Pk-1 + b
	addu $t0, $t0, 1					#Xk := Xk-1 + 1
	addu $t1, $t1, 1					#Yk := Yk-1 + 1
	#Changing Z---------------------------------------------
	la $t3, abcpl
	lw $t5, ($t3)						#Plane a [Pa]
	la $t3, abcpl+4
	lw $t6, ($t3)						#Plane b [Pb]
	add $t5, $t5, $t6					#Pa+Pb
	la $t3, abcpl+8
	lw $t6, ($t3)						#Plane c [Pc]
	multu $t2, $t6
	mflo $t2						#Pc*Zk-1
	sub $t2, $t2, $t5					#Pc*Zk := Pc*Zk-1 - [Pa+Pb]
	div $t2, $t2, $t6					#Zk := Zk-1 - Pa+Pb/Pc
	#=======================================================
	exloop(loopas45, noline, fill, $t1, $t4, $t3, $t6)	#Exit loop?
	
	#Declining lines [less than 0 and more than -45 degrees]
decl:
	subu $t7, $t1, $t4					#$t7 := deltaY
	mflo $t9						#$t9 := 2*deltaX
	multu $t7, $t8
	mflo $t7						#$t7 := 2*deltaY => a
	subu $t8, $t7, $t9					#$t8 := (2*deltaY - 2*deltaX) => b
	bgtz $t8, decl45					#Check if line is less than -45 degrees
	subu $t9, $t7, $t6					#$t9 := (2*deltaY - deltaX) => p0
loopde:	
	prepare_pixel(width, $t4, $t1, $t6, $t0)		#Pixel on bitmap
	get_pixel(bmaddr, $t4, $t6)				#Load pixel and get it's Z	
	bgt $t2, $t6, nextde					#Check if Z of current pixel is greater than Z of pixel on bitmap
	draw(color, $t6, $t2, $t4)				#Draw pixel
nextde:
	bgtz $t9, downde					#Check if Pk greater than 0
	addu $t9, $t9, $t7					#Pk := Pk-1 + a
	addu $t0, $t0, 1					#Xk := Xk-1 + 1
	#Changing Z---------------------------------------------
	la $t4, abcpl
	lw $t5, ($t4)						#Plane a [Pa]
	la $t4, abcpl+8
	lw $t6, ($t4)						#Plane c [Pc]
	multu $t2, $t6
	mflo $t2						#Pc*Zk-1
	sub $t2, $t2, $t5					#Pc*Zk := Pc*Zk-1 - Pa
	div $t2, $t2, $t6					#Zk := Zk-1 - Pa/Pc
	#=======================================================
	exloop(loopde, noline, fill, $t0, $t3, $t4, $t6)	#Exit loop?
downde:
	addu $t9, $t9, $t8					#Pk := Pk-1 + b
	addu $t0, $t0, 1					#Xk := Xk-1 + 1
	addu $t1, $t1, -1					#Yk := Yk-1 - 1
	#Changing Z---------------------------------------------
	la $t4, abcpl
	lw $t5, ($t4)						#Plane a [Pa]
	la $t4, abcpl+4
	lw $t6, ($t4)						#Plane b [Pb]
	sub $t5, $t5, $t6					#Pa-Pb
	la $t4, abcpl+8
	lw $t6, ($t4)						#Plane c [Pc]
	multu $t2, $t6
	mflo $t2						#Pc*Zk-1
	sub $t2, $t2, $t5					#Pc*Zk := Pc*Zk-1 - [Pa-Pb]
	div $t2, $t2, $t6					#Zk := Zk-1 - [Pa-Pb]/Pc
	#=======================================================
	exloop(loopde, noline, fill, $t0, $t3, $t4, $t6)	#Exit loop?
	
	#Declining lines [less than -45 and more than -90 degrees]
decl45:
	subu $t6, $t1, $t4					#$t6 := deltaY
	li $t8, 2
	multu $t6, $t8
	mflo $t9						#$t9 := 2*deltaY
	subu $t7, $t3, $t0					#$t7 := deltaX
	multu $t7, $t8
	mflo $t7						#$t7 := 2*deltaX => a
	subu $t8, $t7, $t9					#$t8 := (2*deltaX - 2*deltaY) => b
	subu $t9, $t7, $t6					#$t9 := (2*deltaX - deltaY) => p0
loopde45:
	prepare_pixel(width, $t3, $t1, $t6, $t0)		#Pixel on bitmap	
	get_pixel(bmaddr, $t3, $t6)				#Load pixel and get it's Z
	bgt $t2, $t6, underde45					#Check if Z of current pixel is greater than Z of pixel on bitmap
	draw(color, $t6, $t2, $t3)				#Draw pixel
underde45:
	bgtz $t9, downde45					#Check if Pk greater than 0
	addu $t9, $t9, $t7					#Pk := Pk-1 + a
	addu $t1, $t1, -1					#Yk := Yk-1 - 1
	#Changing Z---------------------------------------------
	la $t3, abcpl+4
	lw $t5, ($t3)						#Plane b [Pb]
	la $t3, abcpl+8
	lw $t6, ($t3)						#Plane c [Pc]
	multu $t2, $t6
	mflo $t2						#Pc*Zk-1
	add $t2, $t2, $t5					#Pc*Zk := Pc*Zk-1 +Pb
	div $t2, $t2, $t6					#Zk := Zk-1 + Pb/Pc
	#=======================================================
	exloop(loopde45, noline, fill, $t4, $t1, $t3, $t6)	#Exit loop?
downde45:
	addu $t9, $t9, $t8					#Pk := Pk-1 + b
	addu $t0, $t0, 1					#Xk := Xk-1 + 1
	addu $t1, $t1, -1					#Yk := Yk-1 - 1
	#Changing Z---------------------------------------------
	la $t3, abcpl
	lw $t5, ($t3)						#Plane a [Pa]
	la $t3, abcpl+4
	lw $t6, ($t3)						#Plane b [Pb]
	sub $t5, $t5, $t6					#Pa-Pb
	la $t3, abcpl+8
	lw $t6, ($t3)						#Plane c [Pc]
	multu $t2, $t6
	mflo $t2						#Pc*Zk-1
	sub $t2, $t2, $t5					#Pc*Zk := Pc*Zk-1 - [Pa-Pb]
	div $t2, $t2, $t6					#Zk := Zk-1 - [Pa-Pb]/Pc
	#=======================================================
	exloop(loopde45, noline, fill, $t4, $t1, $t3, $t6)	#Exit loop?
	
############################################################################################################################################################################################
# -------------Filling triangle ----------------------------------------------------------
fill:	
	lw $t6, minX						#Load minimal X coordinate
	lw $t7, minY						#Load minimal Y coordinate
	lw $t8, maxX						#Load maximal X coordinate
	addiu $t8, $t8, -1					#[maxX-1]
	lw $t9, maxY						#Load maximal Y coordinate
	addiu $t9, $t9, -1					#[maxY-1]
lfillr:	
	addiu $t7, $t7, 1					#Iterate in rows
lfillc:
	addiu $t6, $t6, 1					#Iterate in columns
	bar_factor(vertex, 4, 5, 8, 9, $t6, $t7, alfa, wrong)	#Alfa also check alfa coordinate, if wrong then go to label
	bar_factor(vertex, 8, 9, 0, 1, $t6, $t7, beta, wrong)	#Beta also check beta coordinate, if wrong then go to label
	bar_factor(vertex, 0, 1, 4, 5, $t6, $t7, gamma, wrong)	#Gamma also check gamma coordinate, if wrong then go to label
	b baric
wrong:
	blt $t6, $t8, lfillc					#If iterator is lesser than width, go to lpixew [Loop]
	lw $t6, minX						#Change iterator to minX
	blt $t7, $t9, lfillr					#If iterator is lesser than height, go to lpixeh [Loop]
	lw $t7, minY						#Change iterator to minY
	b nxtrn
baric:
	#Preparing Z---------------------------------------------
	la $t0, abcpl
	lw $t1, ($t0)						#Plane a [Pa]
	la $t0, abcpl+4
	lw $t2, ($t0)						#Plane b [Pb]
	la $t0, abcpl+8
	lw $t3, ($t0)						#Plane c [Pc]
	lb $t0, vertex+2					#Z of first vertex [Zk-1]
	mult $t0, $t3
	mflo $t0						#Pc*Zk-1
	lb $t4, vertex						#X0
	sub $t4, $t4, $t6					#DeltaX [X - X0]
	mult $t4, $t1
	mflo $t1						#DeltaX*a
	lb $t4, vertex+1					#Y0
	sub $t4, $t4, $t7					#DeltaY [Y - Y0]
	mult $t4, $t2
	mflo $t2						#DeltaY*b
	add $t1, $t1, $t2					#DeltaX*a + DeltaY*b
	add $t0, $t0, $t1					#Pc*Zk := Pc*Zk-1 +Pb
	div $t2, $t0, $t3					#Zk := Zk-1 + Pb/Pc
	#=======================================================
	prepare_pixel(width, $t0, $t7, $t1, $t6)
	get_pixel(bmaddr, $t0, $t1)				#Get pixel
	bgt $t2, $t1, chckbr					#Check if Z of current pixel is greater than Z of pixel on bitmap
	draw(color, $t1, $t2, $t0)				#Draw pixel
chckbr:	
	bge $t6, $t8, nexY					#If greater or equal maxX-1
	addiu $t6, $t6, 1					#Iterate in columns
	bar_factor(vertex, 4, 5, 8, 9, $t6, $t7, alfa, nexY)	#Alfa also check alfa coordinate, if wrong then go to label
	bar_factor(vertex, 8, 9, 0, 1, $t6, $t7, beta, nexY)	#Beta also check beta coordinate, if wrong then go to label
	bar_factor(vertex, 0, 1, 4, 5, $t6, $t7, gamma, nexY)	#Gamma also check gamma coordinate, if wrong then go to label
	b baric
nexY:
	lw $t6, minX
	blt $t7, $t9, lfillr					#If iterator is lesser than height, go to lpixeh [Loop]
	lw $t7, minY						#Change iterator to minY
	b nxtrn
# -------------Vertices Modifying --------------------------------------------------------
swap:
	swap_coor($t0, $t3, $t6)				#Swap X coordinates 
	swap_coor($t1, $t4, $t6)				#Swap Y coordinates
	swap_coor($t2, $t5, $t6)				#Swap Z coordinates
	b lines
nextl:								#Which line should be drawn next
	lb $t4, noline
	li $t6, 1
	beq $t4, $t6, second
	li $t6, 2
	beq $t4, $t6, third	
	
# -------------Next Triangle -------------------------------------------------------------
nxtrn:
	lw $t0, nexttr
	li $t1, 0
	beq $t0, $t1, open					#If there is no other triangle to be drawn, save file
	
	#First vertex of second triangle
	get_xcoor(stri, vertex, 0)				#Get x
	get_coor(8, vertex, 0)					#Get y
	get_coor(16, vertex, 0)					#Get z
	
	#Second vertex
	get_xcoor(nvert, vertex, 4)				#Get x
	get_coor(8, vertex, 4)					#Get y
	get_coor(16, vertex, 4)					#Get z
	
	#Third vertex
	get_xcoor(nvert, vertex, 8)				#Get x
	get_coor(8, vertex, 8)					#Get y
	get_coor(16, vertex, 8)					#Get z
	
	li $t1, 0xDD693F
	sw $t1, color						#Change color of this triangle
	
	li $t6, 0
	sb $t6, noline						#Start from drawing first line
	
	li $t1, 0						#False
	sw $t1, nexttr						#So there is no other triangle to be drawn after this
	
	b pplane						#Go preparing plane
# -------------Open File To Save ---------------------------------------------------------
open:
	open_file(filein, 1)
	
# -------------Save File Header ----------------------------------------------------------
	save_bytes(fdesc, id, 2)				#Save ID -> "BM"
	save_bytes(fdesc, fsize, 4)				#Save file size 
	save_bytes(fdesc, appsp, 4)				#Save application specific
	save_bytes(fdesc, offp, 4)				#Save offset
	save_bytes(fdesc, nodib, 4)				#Save number of bytes in DIB header
	save_bytes(fdesc, width, 4)				#Save width
	save_bytes(fdesc, height, 4)				#Save height
	save_bytes(fdesc, noplan, 2)				#Save number of planes
	save_bytes(fdesc, nobpp, 2)				#Save number of bits per pixel
	save_bytes(fdesc, bdcom, 4)				#Save pixel array compression
	save_bytes(fdesc, rawbd, 4)				#Save size of the raw bitmap data
	save_bytes(fdesc, resho, 4)				#Save print resolution of the image /horizontal
	save_bytes(fdesc, resve, 4)				#Save print resolution of the image /vertical
	save_bytes(fdesc, nocol, 4)				#Save number of colors
	save_bytes(fdesc, imcol, 4)				#Save number of important colors
	
# -------------Save Pixels ---------------------------------------------------------------
	lw $t0, width						#Load width in pixels
	lw $t1, height						#Load height in pixels
	li $t2, 0						#Iterator defining column
	li $t3, 0						#Iterator defining row
	lw $t6, bmaddr						#Load address of bitmap
spixeh:	
	addiu $t3, $t3, 1					#Iterate in rows
spixew:
	addiu $t2, $t2, 1					#Iterate in columns
	lw $t4, ($t6)
	sw $t4, pixel
	save_bytes(fdesc, pixel, 3)				#Save pixel
	addiu $t6, $t6, 4					#Go to next address of bitmap
	blt $t2, $t0, spixew					#If iterator is lesser than width, go to spixew [Loop]
	li $t2, 0						#Change iterator to 0
	
	and $t4, $t0, 0x3					#Mod 4 -> Get to know what size padding is
	li $v0, 15						#Save width padding
	lw $a0, fdesc
	la $a1, padd
	la $a2, ($t4)						#How many bytes
	syscall
	
	blt $t3, $t1, spixeh					#If iterator is lesser than height, go to spixeh [Loop]
	li $t3, 0						#Change iterator to 0
	
	li $v0, 15						#Save end padding
	lw $a0, fdesc
	la $a1, padd
	li $a2, 2						#How many bytes
	syscall			
	
# -------------Close File ----------------------------------------------------------------
	li $v0, 16
	lw $a0, fdesc
	syscall
	
# -------------The End -------------------------------------------------------------------
	li $v0, 4						#Print string
	la $a0, fin						#From this
	syscall
	b end							

# -------------Error ---------------------------------------------------------------------
error:
	li $v0, 4
	la $a0, err
	syscall

# -------------Terminate -----------------------------------------------------------------
end: 
	li $v0, 10						#Terminate execution
	syscall
