# ===== Section donnees =====  
# 		415638972362479185789215364926341758138756429574982631257164893843597216691823547		1 solution
#		120056789690078215587291463352184697416937528978625341831542976269713854745869132		2 solutions
#		120056789690078215587290000350000000006937528978625341831540000269000004745869132		4 solutions
#		120000009690078200580290000350000000006007520008620040031540000269000004705800032		8 solutions
.data
    fichier: .asciiz "grille.txt"     	# /!\ doit être dans le même dossier que Mars OU mettre le chemin absolu
    grille: .space 1024
    zero: .asciiz "_"
    position_square: .byte 0, 3, 6, 27, 30, 33, 54, 57, 60
    offset: .byte 0,1,2,9,10,11,18,19,20
    barre: .asciiz "|"
    barho: .asciiz "------------------"
    finsol: .asciiz "Il n'y a plus de solutions"

# ===== Section code =====  
.text
# ----- Main ----- 

main:

	li $s7 0 			# sera utile dans solve_sudoku
    	jal loadFile
    	jal readFile
    	jal closeFile
	jal transformAsciiValues
	jal displayGrilleSudoc
	jal check_sudoku
	jal addNewLine
	jal addNewLine
	jal solve_sudoku
	j exit

# ----- Fonctions ----- 



# ----- Fonction loadFile -----
# Objectif : Ouvrir le fichier contenant la grille
# Registres utilises : $v0, $a[0-1], $s1
loadFile:
la   $a0, fichier   	#nom du fichier en argument
li   $v0, 13      	#syscall qui permet d'ouvrir un fichier
li   $a1, 0   		#lecture du ficher   
syscall            
move $s1, $v0      	#sauvegarde le filedescriptor (necessaire pour lire et fermer le fichier)
jr $ra

# ----- Fonction readFile -----
# Objectif : Lire le fichier contenant la grille
# Registres utilises : $v0, $a[0-2], $s1
readFile:
li   $v0, 14      	#syscall qui permet de lire un fichier
move $a0, $s1      	#met le filedescriptor dans a0
la   $a1, grille	#endroit qui contiendra la grille
li   $a2, 2024    	#taille de la chaine
syscall   
jr $ra         

# ----- Fonction closeFile -----
# Objectif : Fermer le fichier contenant la grille
# Registres utilises : $v0, $a0, $s1
closeFile:
li   $v0, 16   		#syscall qui permet de fermer le fichier
move $a0, $s1      	#met le filedescriptor dans a0
syscall            
jr $ra






# ----- Fonction addNewLine -----  
# objectif : fait un retour a la ligne a l'ecran
# Registres utilises : $v0, $a0
addNewLine:
    li      $v0, 11
    li      $a0, 10
    syscall
    jr $ra



# ----- Fonction displayGrilleSudoc -----   
# Affiche la grille.
# Registres utilises : $v0, $a0, $t[0-2]
displayGrilleSudoc:  
    la      $t0, grille
    add     $sp, $sp, -4        # Sauvegarde de la reference du dernier jump
    sw      $ra, 0($sp)
    li      $t1, 0
    boucle_displayGrille:
        bge     $t1, 81, end_displayGrille     # Si $t1 est plus grand ou egal a 81 alors branchement a end_displayGrille
        # Vérifier si t1 % 9 = 0 (si fin de ligne ou pas)
        # si = 0 : changer de ligne et jump au début de boucle
        # si =/= 0 : continuer à afficher les chiffres
        
        
            blt $t1 9 bop		    # premi�re ligne (ne passe pas dans le modulo)
            
            move  $a0 $t1		    #prep modulo
            li $a1 9			    # prep modulo
            jal getModulo		    # modulo
            beq $v0 $0 bob 		    # saut de ligne
        
            bop:
            add     $t2, $t0, $t1           # $t0 + $t1 -> $t2 ($t0 l'adresse du tableau et $t1 la position dans le tableau)
            lb      $a0, ($t2)              # load byte at $t2(adress) in $a0
            beq $a0 $0 zeroToSpace
            li      $v0, 1                  # code pour l'affichage d'un entier
            syscall
            
            barre_inc:
            li $v0, 4
            la $a0, barre
            syscall
            
            
            add     $t1, $t1, 1             # $t1 += 1;
        j boucle_displayGrille

end_displayGrille:
    lw      $ra, 0($sp)                 # On recharge la reference 
    add     $sp, $sp, 4                 # du dernier jump
    jr $ra


bob:					# ajoute une nouvelle ligne puis continue le code
    jal addNewLine
     li $v0, 4
     la $a0, barho
     syscall
    jal addNewLine
    j bop




# ----- Fonction zeroToSpace -----   
# Objectif : convertit les 0 (cases vides) de la grille en tiret
# Registre utilisé : $s7 (sera utile dans solve_sudoku), $t8
zeroToSpace:
    addi $s7 $s7 1
    li $v0, 4
    la $t8 zero
    move $a0 $t8
    syscall
    j barre_inc
        



# ----- Fonction transformAsciiValues -----   
# Objectif : transforme la grille de ascii a integer
# Registres utilises : $t[0-3]
transformAsciiValues:  
    add     $sp, $sp, -4
    sw      $ra, 0($sp)
    la      $t3, grille
    li      $t0, 0
    boucle_transformAsciiValues:
        bge     $t0, 81, end_transformAsciiValues
            add     $t1, $t3, $t0
            lb      $t2, ($t1)
            sub     $t2, $t2, 48
            sb      $t2, ($t1)
            add     $t0, $t0, 1
        j boucle_transformAsciiValues
    end_transformAsciiValues:
    lw      $ra, 0($sp)
    add     $sp, $sp, 4
    jr $ra


# ----- Fonction getModulo ----- 
# Objectif : Fait le modulo (a mod b)
#   $a0 represente le nombre a (doit etre positif)
#   $a1 represente le nombre b (doit etre positif)
# Resultat dans : $v0
# Registres utilises : $a0
getModulo: 
    sub     $sp, $sp, 4
    sw      $ra, 0($sp)
    boucle_getModulo:
        blt     $a0, $a1, end_getModulo
            sub     $a0, $a0, $a1
        j boucle_getModulo
    end_getModulo:
    move    $v0, $a0
    lw      $ra, 0($sp)
    add     $sp, $sp, 4
    jr $ra


#################################################
#               A completer !                   #
#                                               #
# Nom et prenom binome 1 : DAUSSE Capucine      #
# Nom et prenom binome 2 : MERAL Elif		#

# Fonction check_n_column                       #
# Objectif : vérifie la validité d'une colonne
# Resultat dans : $v1
# Arguments : $a2 (argument n) 
# Registres utilis�s : $t4 (i), $t5 (j), $t6 (G[9i+n]), $t7 (G[9j+n])
check_n_column:               
	li $v1, 0		# $v1 = 0 si c'est vrai sinon $v1=1
	li $t4, 0 		# $t5=0 compteur i
	pour1_check_n_column:
	bge $t4, 9, Fin_check_n_column		#si i>=9 alors saut vers la fin
	addi $t5, $t4, 1	# $t5 = i+1 (j)
	pour2_check_n_column:
	bge $t5, 9, incrementI_column 		#si j>=9 alors on incr�mente i
		mul $t6, $t4, 9		#$t6 = i*9
		add $t6, $t6, $a2	#$t6 = (9i)+n
		add $t6, $t0, $t6	#$t6 = 9i+n + grille
		lb $t6, 0($t6)		#$t6 = G[9i+n]
		beq $t6, 0, incrementI_column		#si G[9i+n]==0 alors incr�menter I
			mul $t7, $t5, 9		#$t7 = j*9
			add $t7, $t7, $a2	#$t7 = (9j)+n	
			add $t7, $t0, $t7	#$t7 = 9j+n + grille
			lb $t7, 0($t7)		#G[9j+n]
			beq $t6, $t7, Verif_faux_n_column		#si G[9i+n] != G[9j+n]

			addi $t5, $t5, 1 	#j++
			j pour2_check_n_column	#saut vers pour2_check_n_column			
		

incrementI_column: 
addi $t4, $t4, 1 	# i++
j pour1_check_n_column

Verif_faux_n_column:
li $v1, 1	#$v1 = 1 (donc la colonne n'est pas valide)
move $a0 $v1
li $v0, 1
#syscall
jr $ra

Fin_check_n_column: 
move $a0 $v1
li $v0, 1
#syscall
jr $ra



# Fonction check_n_row                       	#
# Objectif : vérifie la validité d'une rangée
# Resultat dans : $v1
# Arguments : $a2 (argument n) 
# Registres utilis�s : $t4 (i), $t5 (j), $t6 (G[9n+i]), $t7 (G[9n+i])
check_n_row:               
	li $v1, 0		# $v1 = 0 si c'est vrai sinon $v1=1
	li $t4, 0 		# $t5=0 compteur i
	pour1_check_n_row:
	bge $t4, 9, Fin_check_n_row		#si i>=9 alors saut vers la fin
	addi $t5, $t4, 1	# $t5 = i+1 (j)
	pour2_check_n_row:
	bge $t5, 9, incrementI_row 		#si j>=9 alors on incr�mente i
		mul $t6, $a2, 9		#$t6 = n*9
		add $t6, $t6, $t4	#$t6 = (9n)+i
		add $t6, $t0, $t6	#$t6 = 9n+i + grille
		lb $t6, 0($t6)		#$t6 = G[9n+i]
		beq $t6, 0, incrementI_row		#si G[9n+i]==0 alors incr�menter I
			mul $t7, $a2, 9		#$t7 = n*9
			add $t7, $t7, $t5	#$t7 = (9n)+j	
			add $t7, $t0, $t7	#$t7 = 9n+j + grille
			lb $t7, 0($t7)		#G[9n+j]
			beq $t6, $t7, Verif_faux_n_row	#si G[9n+i] != G[9n+j]
			
			addi $t5, $t5, 1 	#j++
			j pour2_check_n_row	#saut vers pour2_check_n_row			
		

incrementI_row: 
addi $t4, $t4, 1 	# i++
j pour1_check_n_row

Verif_faux_n_row:
li $v1, 1	#$v1 = 1 donc la rangée n'est pas valide
move $a0 $v1
li $v0, 1
#syscall
jr $ra

Fin_check_n_row: 
move $a0 $v1
li $v0, 1
#syscall
jr $ra


# Fonction check_n_square 			#
# Objectif : vérifie la validité d'un carré
#Registres utilisés : $v0, $a0, $t[0;1;4] adresses, $t[5-9] variables
#Registre arguments : $a2 -> n (utilisé par check_n_columns)
#R�sultat dans $v1

check_n_square:
    li $v1, 0                # Initialisation : 0 = vrai, 1 = faux
    la $t1, position_square  # Adresse de position_square
    add $t5 $t1 $a2
    lb $t5 0($t5)	     # Position du 1er indice du carré
    
    la $t4, offset           # Adresse de offset
    

    li $t8, 0                # Compteur i pour les sous-grilles
    li $t9, 0                # Compteur j pour les �l�ments dans les sous-grilles

    Pour_check_n_square:
    	bge $t8, 9, Fin_check_n_square  # Si i >= 9, sortir de la boucle
    	addi $t9 $t8 1			# j = i + 1
    	
    	add $t6 $t4 $t8		# t6 <- addresse de offset + i
    	lb $t6 0($t6)		# valeur de l'offset en fonction de i
    	
    	add $t6 $t5 $t6		# t6 <- position de i en fonction de t5 (carré à verifier) et de l'offset en cours (position de i dans le carré)
    	add $t6 $t0 $t6		# t6 <- position de i dans la grille
    	lb $t6 0($t6)		# t6 <- chiffre 1 à vérifier
    	beq $t6 0 Increment_square_i
    	
    	pour_check_n_square_j:
    		bgt $t9, 8, Increment_square_i  # Si j > 8, passer au suivant (incrémenter i)
    		
    		add $t7 $t4 $t9		# t7 <- addresse de offset + j
    		lb $t7 0($t7)		# valeur de l'offset en fonction de j
    	
   	 	add $t7 $t5 $t7		# t7 <- position de j en fonction de a2 (carré à verifier) et de l'offset en cours (position de j dans le carré)
   	 	add $t7 $t0 $t7		# t7 <- position de j dans la grille
   	 	lb $t7 0($t7)		# t7 <- chiffre 2 à vérifier
   	 	
   	 	beq $t6 $t7 Faux_square_verif  	# Si les valeurs sont identiques, c'est une erreur
		    				# sinon :
		    addi $t9, $t9, 1        	 # Incrémenter j pour comparer la prochaine case
		    j pour_check_n_square_j  	 # Revenir à l'étape suivante pour comparer
   	 	
    

Increment_square_i:
    addi $t8, $t8, 1         # Incr�menter i pour passer � la sous-grille suivante
    j Pour_check_n_square   # Revenir � l'�tape initiale pour le prochain carr�

Faux_square_verif:
    li $v1, 1                # Faux : v1 = 1 (la sous-grille n'est pas valide)
    j Fin_check_n_square     # Aller � la fin de la fonction

Fin_check_n_square:
    move $a0, $v1            # Retourner le r�sultat dans $a0
    li $v0, 1
#    syscall
    jr $ra                   # Retour � l'appelant


# Fonction check_column          		#
# Objectif : vérifie la validité des colonnes
#Registre arguments : $a2 -> n (utilis� par check_n_columns)
#R�sultat dans $v1
check_columns:
add     $sp, $sp, -4        # Sauvegarde de la reference du dernier jump
sw      $ra, 0($sp)

li $a2 0	#$a2 = 0
pour_check_columns:
bge $a2, 9, fin_check_columns		#$a2 de 0 � 8
	jal check_n_column		#appel la fonction check_n_column
	beq $v1, 1, verif_faux_columns	#si $v1 == 1 alors saut vers verif_faux_columns
	addi $a2 $a2 1			# incr�ment� $a2++
	j pour_check_columns

fin_check_columns:
lw      $ra, 0($sp)                 # On recharge la reference 
add     $sp, $sp, 4                 # du dernier jump
jr $ra

verif_faux_columns:
lw      $ra, 0($sp)                 # On recharge la reference 
add     $sp, $sp, 4                 # du dernier jump
jr $ra


# Fonction check_rows                           #
# Objectif : vérifie la validité des rangées
#Registre arguments : $a2 -> n (utilis� par check_n_row)
#R�sultat dans $v1
check_rows:
add     $sp, $sp, -4      	  	# Sauvegarde de la reference du dernier jump
sw      $ra, 0($sp)

li $a2 0				#$a2=0
pour_check_rows:	
bge $a2, 9, fin_check_rows		#$a2 de 0 � 8 
	jal check_n_row			#appel la fonctions check_n_rows
	beq $v1, 1, verif_faux_rows	#si $v1 == 1 alors verif_faux_rows
	addi $a2 $a2 1			#incr�ment� $a2
	j pour_check_rows

fin_check_rows:
lw      $ra, 0($sp)                 	# On recharge la reference 
add     $sp, $sp, 4                 	# du dernier jump
jr $ra	

verif_faux_rows:
lw      $ra, 0($sp)                 	# On recharge la reference 
add     $sp, $sp, 4                 	# du dernier jump
jr $ra



# Fonction check_squares                        #
# Objectif : vérifie la validité des carrés
#Registre arguments : $a2 -> n (utilis� par check_n_square)
#R�sultat dans $v1
check_squares:
add     $sp, $sp, -4        # Sauvegarde de la reference du dernier jump
sw      $ra, 0($sp)

li $a2 0		#$a2=0
pour_check_squares:	
bge $a2, 9, fin_check_squares	#$a2 de 0 � 8 
	jal check_n_square	#appel la fonctions check_n_square
	beq $v1, 1, verif_faux_squares	#si $v1 == 1 alors verif_faux_squares
	addi $a2 $a2 1			#incr�ment� $a2
	j pour_check_squares

fin_check_squares:
lw      $ra, 0($sp)                 # On recharge la reference 
add     $sp, $sp, 4                 # du dernier jump
jr $ra

verif_faux_squares:
lw      $ra, 0($sp)                 # On recharge la reference 
add     $sp, $sp, 4                 # du dernier jump
jr $ra



#                                               #
#                                               #
#                                               #
# Fonction check_sudoku                         #
# Objectif : tester l'entièreté du sudoku
# Registre argument : $v1
# Résultat dans $s5
check_sudoku:
	li $s5 0				# utile pour solve_sudoku
	
	add     $sp, $sp, -4        		# Sauvegarde de la reference du dernier jump
	sw      $ra, 0($sp)
	
	jal check_columns
	beq $v1 1 false				# si une colonne n'est pas correcte, pas besoin de tester le reste
	
	jal check_rows
	beq $v1 1 false				# si une ligne n'est pas correcte, pas besoin de tester le reste
	
	jal check_squares
	beq $v1 1 false				# si un carré n'est pas correcte, pas besoin de tester le reste
	
	lw      $ra, 0($sp)              	# On recharge la reference 
	add     $sp, $sp, 4              	# du dernier jump
	jr $ra



false:
	li $s5 1				# utile pour solve_sudoku
	lw      $ra, 0($sp)                 	# On recharge la reference 
	add     $sp, $sp, 4                 	# du dernier jump
	jr $ra

#                                               #
#                                               #
#                                               #
# Fonction solve_sudoku                         #
# Objectif : Résoudre le sudoku
# Registre arguments : $s5 (validité de la grille donnée par check_sudoku), $s7 (nombre de 0 donné par zeroToSpace)
# Registres utilisés : $v0, $a0, $s[3-4;6] $t[0-8]
solve_sudoku:
	add     $sp, $sp, -4        		# Sauvegarde de la reference du dernier jump
    	sw      $ra, 0($sp)
    	
    	
	# allocation mémoire dans le tas (ressemble à un tableau)
	beq $s7 0 the_end			# si il n'y a pas de 0 : afficher la grille comme solution
	move $s4 $s7				# sauvegarde s7 dans s4			s4 : nombre de 0
	mul $s7 $s7 2				# pour avoir la valeur et la position dans le tas
	mul $s7 $s7 4				# pour avoir le nombre d'octets
	
	li $v0 9				# syscall pour l'allocation
	move $a0 $s7
	syscall
	move $s6 $v0				# s6 contient maintenant l'adresse du tas
	
	li $t3 0				# position dans le tas


	# cherche les positions des 0 pour les mettre dans le tas
	li $t7 0						# compteur nombre de 0 déjà stockés dans le tas
	li $t8 0					# compteur i (position dans la grille)
	boucle_solve_nbr0:
	bge $t8 81 recursion				# tant que le compteur t8 n'est pas à 81
	bge $t7 $s4 recursion				# tant qu'il y a encore des 0
		add $t1, $t0, $t8          		# $t0 + $t8 -> $t1 ($t0 l'adresse du tas et $t8 la position dans le tas)
            	lb $t2, ($t1)             		# load byte at $t1(adress) in $t2
            	beq $t2 0 increment_0			# si le chiffre n'est pas un 0
            		addi $t8 $t8 1			# augmente le compteur
            		j boucle_solve_nbr0


increment_0:				# si le chiffre est un 0
	addu $t4 $s6 $t3		# prend la position pour stocker la valeur (0) dans le tas
	sw $t2 ($t4)			# stock la valeur dans le tas
	addi $t3 $t3 4			# incrémente la position dans le tas (de 4 car il faut 4 octets pour un entier)
	addu $t4 $s6 $t3		# prend la position pour stocker la position du nième 0 dans le tas
	sw $t8 ($t4)			# stock la position du nième 0 dans le tas à l'emplacement donné par t1
	addi $t3 $t3 4			# incrémente la position dans le tas
	addi $t7 $t7 1			# compteur de 0
	addi $t8 $t8 1			# compteur i += 1 (sinon loop)
	j boucle_solve_nbr0		# retourne dans la fonction
	
	

recursion:			# t0 adresse grille; s6 adresse tas; s7 nbr octets; t9 nbr de 0; s5 vérif grille (0 ok, 1 pas ok)
	li $t3 0		# compteur du chiffre à changer
	li $s3 0		# compteur qui sert à mettre le bon chiffre dans le tas et la grille
	
	plusieurs_solu:				

	bge $t3 $s4 the_end			# si tous les 0 ont été changés, afficher la grille comme solution
		mul $t2 $t3 8			# position de la valeur en cours		j
		li $s5 1			# initialisation de la vérification de grille à non-valide
		
		bcl:				# loop tant que la grille n'est pas valide
		beq $s5 0 chiffre_valide	# si la grille est valide, passe au chiffre suivant
		bge $s3 9 pas_valide		# si la grille ne peut pas être valide
		
			addu $t1 $s6 $t2	# t1 : position de la valeur à changer dans le tas
			lb $s3 ($t1)		# charge la valeur du chiffre à changer dans s3
			addi $s3 $s3 1		# lui ajoute 1
			sb $s3 ($t1)		# modifie la valeur dans le tas
			
			addi $t2 $t2 4		# augmente j pour avoir la position
			
			addu $t1 $s6 $t2	# t1 : position dans le tas de la position de la valeur à changer dans la grille
			lb $t1 ($t1)		# t1 : position de la valeur à changer dans la grille
			
			addi $t2 $t2 -4		# diminue j pour avoir la valeur
			
			add $t5 $t0 $t1		# t5 : position de la valeur à changer
			sb $s3 ($t5)		# midifie la grille à la position voulue
			
			jal check_sudoku	# teste la validité de la grille
			j bcl			# retourne au début de la boucle
			
	
	chiffre_valide:				# si le chiffre est valide
		add $t3 $t3 1			# passe au suivant
		li $s3 0			# remet s3 à 0
		j plusieurs_solu
		
	
	pas_valide:
		addu $t1 $s6 $t2	# t1 : position de la valeur à changer
		li $s3 0		# remet la valeur à 0
		sb $s3 ($t1)

		addi $t2 $t2 4		# augmente j pour avoir la position
			
		addu $t1 $s6 $t2	# t1 : position dans le tas de la position de la valeur à changer dans la grille
		lb $t1 ($t1)		# t1 : position de la valeur à changer dans la grille
			
		addi $t2 $t2 -4		# diminue j pour avoir la valeur
		
		add $t5 $t0 $t1		# t5 : position de la valeur à changer
		sb $s3 ($t5)		# midifie la grille à la position voulue
		
		add $t3 $t3 -1		# retourne au chiffre précédent
		beq $t3 -1 fin_solu	# si t3 = -1, il n'y a plus de solutions possible (tous les chiffres sont à 9)
		
		# évite les boucles infinies et que la valeur passe au dessus de 9
		mul $t2 $t3 8		# prend la position de la valeur suivante
		addu $t1 $s6 $t2	# t1 : position de la valeur
		lb $s3 ($t1)		# charge la valeur dans s3
		
		j plusieurs_solu	
		
	
	

# affichage des solutions
the_end:
    la      $t0, grille
    li      $t1, 0
    displayGrille:
        bge     $t1, 81, endd_displayGrille     # Si $t1 est plus grand ou egal a 81 alors branchement a end_displayGrille
            add     $t2, $t0, $t1           	# $t0 + $t1 -> $t2 ($t0 l'adresse du tableau et $t1 la position dans le tableau)
            lb      $a0, ($t2)              	# load byte at $t2(adress) in $a0
            li      $v0, 1                  	# code pour l'affichage d'un entier
            syscall	
            add     $t1, $t1, 1             	# $t1 += 1;
        j displayGrille
    endd_displayGrille:
    	jal addNewLine				# saute une ligne entre chaque solution
    	
    	beq $s7 0 exit				# si il n'y a pas de 0 : va vers exit
    	
    	addi $t3 $t3 -1				# retourne au chiffre en cours pour chercher une possile solution suivante
    	j plusieurs_solu			# retourne chercher une possible solution suivante
    	
    	
# quand il n'y a plus de solutions possibles
fin_solu:
	li $v0, 4
     	la $a0, finsol			    # affiche qu'il n'y a plus de solutions
     	syscall
     	lw      $ra, 0($sp)                 # On recharge la reference 
	add     $sp, $sp, 4                 # du dernier jump
	jr $ra				    # retour dans le main (passage à exit)
          
#                                               #
#                                               #
#                                               #
#                                               #
# Autres fonctions que nous avons ajoute :      #
#                                               #
# Fonction ???                                  #   
#                                               #
#                                               #
#                                               #
#                                               #
# Fonction !!!                                  #  
#                                               #
#                                               #
#                                               #
################################################# 





exit: 
    li $v0, 10
    syscall
