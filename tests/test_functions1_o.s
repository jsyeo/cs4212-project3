.data
	
L1:
	.asciz "Square of d larger than sum of squares"
	
L2:
	.asciz "Square of d larger than sum of squares"
	
L3:
	.asciz "\nFactorial of:"
	
L4:
	.asciz "%i"
	
L5:
	.asciz " equal to:"
	
L6:
	.asciz "%i"
	
L7:
	.asciz "\n"
	.text
	.global main
	
Compute_1:
	stmfd sp!,{fp,lr,v1,v2,v3,v4,v5}
	add fp,sp,#24
	sub sp,fp,#28
	add v4,a2,a3
	mov a1,v4
	b .L5exit
	
.L5exit:
	sub sp,fp,#24
	ldmfd sp!,{fp,pc,v1,v2,v3,v4,v5}
	
Compute_2:
	stmfd sp!,{fp,lr,v1,v2,v3,v4,v5}
	add fp,sp,#24
	sub sp,fp,#40
	ldr v3,[a1,#0]
	cmp v3,#0
	beq .5
	ldr a4,[a1,#4]
	mov a1,a4
	b .L4exit
	b .6
	
.5:
	mov a1,#1
	str a1,[a1,#0]
	str a3,[fp,#-32]
	str a2,[fp,#-28]
	mov a1,a1
	ldr a2,[fp,#-28]
	bl Compute_0(PLT)
	mov v4,a1
	mov a1,a1
	ldr a2,[fp,#-32]
	bl Compute_0(PLT)
	mov a3,a1
	str a3,[fp,#-36]
	mov a1,a1
	mov a2,v4
	ldr a3,[fp,#-36]
	bl Compute_1(PLT)
	mov a3,a1
	mov a1,a3
	b .L4exit
	
.6:
	
.L4exit:
	sub sp,fp,#24
	ldmfd sp!,{fp,pc,v1,v2,v3,v4,v5}
	
Compute_0:
	stmfd sp!,{fp,lr,v1,v2,v3,v4,v5}
	add fp,sp,#24
	sub sp,fp,#28
	mul a3,a2,a2
	mov a1,a3
	b .L3exit
	
.L3exit:
	sub sp,fp,#24
	ldmfd sp!,{fp,pc,v1,v2,v3,v4,v5}
	
Compute_3:
	stmfd sp!,{fp,lr,v1,v2,v3,v4,v5}
	add fp,sp,#24
	sub sp,fp,#36
	cmp a2,#1
	movlt a4,#1
	movge a4,#0
	cmp a4,#0
	beq .3
	mov v5,#1
	mov a1,v5
	b .L2exit
	b .4
	
.3:
	sub v5,a2,#1
	str a2,[fp,#-32]
	mov a1,a1
	mov a2,v5
	bl Compute_3(PLT)
	mov a3,a1
	ldr v1,[fp,#-32]
	mul a1,v1,a3
	mov a1,a1
	b .L2exit
	
.4:
	
.L2exit:
	sub sp,fp,#24
	ldmfd sp!,{fp,pc,v1,v2,v3,v4,v5}
	
main:
	stmfd sp!,{fp,lr,v1,v2,v3,v4,v5}
	add fp,sp,#24
	sub sp,fp,#56
	mov v5,#1
	mov v2,#2
	mov a3,#3
	mov v3,#4
	str a3,[fp,#-36]
	mov a1,#8
	bl _Znwj(PLT)
	mov a2,a1
	str a2,[fp,#-52]
	ldr a1,[fp,#-52]
	mov a2,v5
	mov a3,v2
	bl Compute_2(PLT)
	mov v4,a1
	ldr a1,[fp,#-52]
	ldr a2,[fp,#-36]
	bl Compute_0(PLT)
	mov v1,a1
	add a2,v4,v1
	str a2,[fp,#-44]
	ldr a1,[fp,#-52]
	mov a2,v3
	bl Compute_0(PLT)
	mov a2,a1
	ldr a4,[fp,#-44]
	cmp a2,a4
	movgt a3,#1
	movle a3,#0
	cmp a3,#0
	beq .1
	ldr a1,=L1
	bl printf(PLT)
	b .2
	
.1:
	ldr a1,=L2
	bl printf(PLT)
	
.2:
	ldr a1,[fp,#-52]
	mov a2,#4
	bl Compute_3(PLT)
	mov a4,a1
	str a4,[fp,#-44]
	ldr a1,=L3
	bl printf(PLT)
	ldr a1,=L4
	mov a2,#4
	bl printf(PLT)
	ldr a1,=L5
	bl printf(PLT)
	ldr a4,[fp,#-44]
	ldr a1,=L6
	mov a2,a4
	bl printf(PLT)
	ldr a1,=L7
	bl printf(PLT)
	
.L1exit:
	mov a4,#0
	mov a1,a4
	sub sp,fp,#24
	ldmfd sp!,{fp,pc,v1,v2,v3,v4,v5}
