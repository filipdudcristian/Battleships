.586
.model flat, stdcall
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;includem biblioteci, si declaram ce functii vrem sa importam
includelib msvcrt.lib
extern exit: proc
extern malloc: proc
extern memset: proc
extern fscanf:proc
extern printf:proc
extern fopen: proc
extern fclose: proc
extern rand: proc


includelib canvas.lib
extern BeginDrawing: proc
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;declaram simbolul start ca public - de acolo incepe executia
public start
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;sectiunile programului, date, respectiv cod
.data
;aici declaram date
window_title DB "Vaporase",0
area_width EQU 1280
area_height EQU 900
area DD 0

counter DD 0 ; numara evenimentele de tip timer

arg1 EQU 8
arg2 EQU 12
arg3 EQU 16
arg4 EQU 20


matrix_X EQU 100
matrix_Y EQU 100
matrix_x_final dd 0
matrix_y_final dd 0

casuta_x dd 0
casuta_y dd 0

start_game dd 0
lovitura_legala dd 0
tip_lovitura dd 0

matrix dd 500 dup (0)

backg_matrix_x dd 0
backg_matrix_y dd 0


counter_vapoare_nedescoperite dd 0
counter_lovituri_succes dd 0
counter_ratari dd 0



coloane_ori_4 dd 0


symbol_width EQU 10
symbol_height EQU 20

include digits.inc
include letters.inc


;----------------FORMATE-------------------

format_fscanf db "%d",0
format_printf db "%d\n",0
format_nume_fisier db "date_intrare.txt",0
mode_r db "r",0


;----------------VARIABILE-----------------
coloane dd 0
linii dd 0
inceput_matrice dd 100
p_citire_fisier dd 0
dimensiune_50 dd 50

nr_vapoare dd 0
nr_casute dd 0



.code
; procedura make_text afiseaza o litera sau o cifra la coordonatele date
; arg1 - simbolul de afisat (litera sau cifra)
; arg2 - pointer la vectorul de pixeli
; arg3 - pos_x
; arg4 - pos_y
make_text proc
	push ebp
	mov ebp, esp
	pusha
	
	mov eax, [ebp+arg1] ; citim simbolul de afisat
	cmp eax, 'A'
	jl make_digit
	cmp eax, 'Z'
	jg make_digit
	sub eax, 'A'
	lea esi, letters
	jmp draw_text
make_digit:
	cmp eax, '0'
	jl make_space
	cmp eax, '9'
	jg make_space
	sub eax, '0'
	lea esi, digits
	jmp draw_text
make_space:	
	mov eax, 26 ; de la 0 pana la 25 sunt litere, 26 e space
	lea esi, letters
	
draw_text:
	mov ebx, symbol_width;schimba asta daca vrei sa ai 20/20 perete
	mul ebx
	mov ebx, symbol_height
	mul ebx
	add esi, eax
	mov ecx, symbol_height
bucla_simbol_linii:
	mov edi, [ebp+arg2] ; pointer la matricea de pixeli
	mov eax, [ebp+arg4] ; pointer la coord y
	add eax, symbol_height
	sub eax, ecx
	mov ebx, area_width
	mul ebx
	add eax, [ebp+arg3] ; pointer la coord x
	shl eax, 2 ; inmultim cu 4, avem un DWORD per pixel
	add edi, eax
	push ecx
	mov ecx, symbol_width
bucla_simbol_coloane:
	cmp byte ptr [esi], 0
	je simbol_pixel_alb
	mov dword ptr [edi], 0
	jmp simbol_pixel_next
simbol_pixel_alb:
	mov dword ptr [edi], 0FFFFFFh
simbol_pixel_next:
	inc esi
	add edi, 4
	loop bucla_simbol_coloane
	pop ecx
	loop bucla_simbol_linii
	popa
	mov esp, ebp
	pop ebp
	ret
make_text endp

; un macro ca sa apelam mai usor desenarea simbolului
make_text_macro macro symbol, drawArea, x, y
	push y
	push x
	push drawArea
	push symbol
	call make_text
	add esp, 16
endm




citire_date_intrare proc
	push ebp
	mov ebp, esp
	pusha

	;deschidem fisierul
	push offset mode_r
	push offset format_nume_fisier
	call fopen
	mov p_citire_fisier,eax
	add esp, 8
	
	;citim valoarea lui coloane
	push offset coloane
	push offset format_fscanf
	push p_citire_fisier
	call fscanf
	add esp, 12
	
	;citim valoarea lui linii
	push offset linii
	push offset format_fscanf
	push p_citire_fisier
	call fscanf
	add esp, 12
	
	mov eax, linii
	mul coloane
	mov nr_casute, eax
	
	push p_citire_fisier
	call fclose
	add esp, 4

	popa
	mov esp, ebp
	pop ebp
	ret
citire_date_intrare endp



linie_orizontala proc; x,y,len,color
	push ebp
	mov ebp, esp
	pusha
	
	mov esi, [ebp+arg4]
	
	mov eax, [ebp+arg2]
	mov ebx, area_width
	mul ebx
	add eax, [ebp+arg1]
	shl eax, 2
	add eax, area
	mov ecx, [ebp+arg3]
	bucla_linie:
		mov dword ptr[eax],  esi
		add eax, 4
	loop bucla_linie
	
	popa
	mov esp, ebp
	pop ebp
	ret
linie_orizontala endp


linie_verticala proc; x,y,len,color
	push ebp
	mov ebp, esp
	pusha
	
	mov esi, [ebp+arg4]
	
	mov eax, [ebp+arg2]
	mov ebx, area_width
	mul ebx
	add eax, [ebp+arg1]
	shl eax, 2
	add eax, area
	mov ecx, [ebp+arg3]
	bucla_linie:
		mov dword ptr[eax], esi
		add eax, area_width*4
	loop bucla_linie
		
	popa
	mov esp, ebp
	pop ebp
	ret
linie_verticala endp

; un macro ca sa apelam mai usor desenarea CASUTEI
make_casute_macro proc; x, y;

	push ebp
	mov ebp, esp
	pusha
	
	mov eax, [ebp+arg1];x
	mov ebx, [ebp+arg2];y
	push 0
	push dimensiune_50
	push ebx
	push eax
	call linie_orizontala;creaza linia de sus
	call linie_verticala;creaza linia din stanga
	add esp,4
	add eax,50
	push eax
	call linie_verticala ;creaza linia din dreapta
	add esp,8
	sub eax,50
	add ebx,50
	
	push ebx
	push eax
	call linie_orizontala;creaza linia de jos
	add esp,16
	
	popa
	mov esp, ebp
	pop ebp
	ret
;endm
make_casute_macro endp

create_matrix proc;int m,int coloane
	push ebp
	mov ebp, esp
	pusha
	
	mov edx, [ebp+arg1];punem in edx pe coloane
	mov eax, 100; coordonatele y la care va incepe matricea
	
	new_line:
		mov ecx, [ebp+arg2];punem in ecx pe m
		mov ebx, 100 ;coordonatele x la care va incepe matricea
		draw_randuri:;se scrie un rand de casute
			push ebx
			push eax
			call make_casute_macro ;construieste o casuta
			add esp,8
			add ebx, 50;se trece la o coloana noua
		loop draw_randuri
		
		add eax, 50;se trece la un rand nou de casute
		dec edx ;se decrementeaza M, adica numarul de randuri ramase sa fie afisate
	cmp edx, 0
	jg new_line
	
	popa
	mov esp, ebp
	pop ebp
	ret
create_matrix endp 


create_matrix_macro macro coloane,linii
	push linii
	push coloane
	call create_matrix
	add esp, 8
	
endm

get_box_coordinates proc ;x,y unde s-a dat click in pe ecran

	push ebp
	mov ebp, esp
	pusha
;--------------------------------se verifica daca s-a dat click in matrice------------------------------------------------------	
	mov eax, [ebp+arg1]
	cmp eax, matrix_X
	jl illegal_click
	cmp eax, matrix_x_final
	jg illegal_click
	mov eax, [ebp+arg2]
	cmp eax, matrix_Y
	jl illegal_click
	cmp eax, matrix_y_final
	jg illegal_click
;--------------------------------se determina in ce casuta s-a dat click------------------------------------------------------	
	mov eax, [ebp+arg1]
	mov ecx, 0
	gasire_coordonate_casuta_y:; se determina coordonata y din coltul stanga sus a casutei care e multiplu de 50, prin scaderi repetate de 50 pana cand ramane o val <50
		cmp eax, 50
		jb gasit_coord_y
		sub eax, 50
		add ecx, 50
	jmp gasire_coordonate_casuta_y
	
	gasit_coord_y:
	
	mov casuta_y, ecx;##########################################################
	
	push casuta_y
	push offset format_fscanf
	call printf
	add esp, 8
	
	mov ebx, [ebp+arg2]
	mov ecx, 0
	gasire_coordonate_casuta_x:; se determina coordonata x din coltul stanga sus a casutei care e multiplu de 50, prin scaderi repetate de 50 pana cand ramane o val <50
		cmp ebx, 50
		jb gasit_coord_x
		sub ebx, 50
		add ecx, 50
	jmp gasire_coordonate_casuta_x

	gasit_coord_x:
	mov casuta_x, ecx;##########################################################
	
	push casuta_x
	push offset format_fscanf
	call printf
	add esp, 8
	
	mov lovitura_legala, 1
	jmp get_box_coordinates_end
	
	illegal_click:
		mov lovitura_legala, 0

	get_box_coordinates_end:
	popa
	mov esp, ebp
	pop ebp
	ret

get_box_coordinates endp




colorare_casuta proc ;color
	push ebp
	mov ebp, esp
	pusha

	mov eax, casuta_x
	add eax, 1
	
	mov ecx, casuta_y
	add ecx, 49

		colorare_linie:
			 push [ebp+arg1]
			 push 49
			 push ecx
			 push eax
			 call linie_orizontala 
			 add esp, 16
		dec ecx
		cmp ecx, casuta_y
		ja colorare_linie

	popa
	mov esp, ebp
	pop ebp
	ret

colorare_casuta endp

verificare_lovitura proc

	push ebp
	mov ebp, esp
	pusha
	
	mov ebx, casuta_x
	mov ecx, casuta_y
	
	
	sub ebx, 100
	sub ecx, 100
	
	;int 3
	mov eax, ebx
	mov edx,0
	div dimensiune_50;---------------------------------gasire pozitie exacta pe coordonata x in background matrix-----------------------
	shl eax, 2
	mov ebx, eax
	
	mov backg_matrix_x, ebx
	
	mov eax, ecx
	mov edx,0
	div dimensiune_50;---------------------------------gasire pozitie exacta pe coordonata y in background matrix-----------------------
	mul linii
	shl eax, 2
	mov ecx, eax
	
	mov backg_matrix_y, ecx
	
	cmp matrix[ecx+ebx],1
		jne ratare
		dec counter_vapoare_nedescoperite
		inc counter_lovituri_succes
			add matrix[ecx+ebx],2
		jmp final_verificare_lovitura
	ratare:
		cmp matrix[ecx+ebx],0 
		jne final_verificare_lovitura
			inc counter_ratari
			add matrix[ecx+ebx], 2
	

	final_verificare_lovitura:
	popa
	mov esp, ebp
	pop ebp
	ret

verificare_lovitura endp

random_position_generator proc
	push ebp
	mov ebp, esp
	pusha

	
	
	generate_new_number:
	rdtsc 
	mov edx,0
	div nr_casute;---------------se imparte la nr total de casute si se ia restul ca si o pozitie care va fi verificata daca se poate plasa un vapor-------------------------
	mov eax, edx
	mov ecx, 4
	mul ecx
	
	mov edi, eax
	;-----------------------------verific daca nr e par sau impar pentru a decide daca vaporul va fi plasat orizontal sau vertical--------------------------------------
	
	rdtsc
	add eax, 13
	mov ecx, 2
	mov edx, 0
	div ecx
	
	mov eax, edi
	
	cmp edx, 0
	jne verticala;--------daca val e 0 se plaseaza orizontal, daca e 1 vertical
	;-----------------------------------------------------------se verifica daca trei pozitii consecutive sunt libere-------------------------------------------------
	cmp matrix[eax], 0
	jne other_way_orizontal
		add eax, 4
		cmp matrix[eax],0
		jne other_way_orizontal
			add eax, 4
			cmp matrix[eax],0
			jne other_way_orizontal
				mov matrix[eax], 1
				sub eax, 4
				mov matrix[eax], 1
				sub eax, 4
				mov matrix[eax], 1
				add counter_vapoare_nedescoperite, 3
				jmp final_generare
				
	 other_way_orizontal:;--------se verifica in cealalta directie pe orizontala daca se poate plasa vaporul
	 cmp matrix[eax], 0
	 jne verticala
		 cmp matrix[eax-4],0
		 jne verticala
			 cmp matrix[eax-8],0
			 jne verticala
				 mov matrix[eax], 1
				 mov matrix[eax-4],1
				 mov matrix[eax-8],1
				 add counter_vapoare_nedescoperite, 3
				 jmp final_generare
				 
				 
	verticala:
	
	jmp generate_new_number
	
	mov ecx, eax
	mov eax, 50
	mov ebx, 4
	mul ebx
	mov ebx, eax
	mov coloane_ori_4,ebx
	mov eax, ecx
	
	cmp matrix[eax], 0
	jne other_way_verticala
	
		mov ebx, eax
		add ebx, coloane_ori_4
		
		cmp matrix[ebx],0
		jne other_way_verticala
		
			add ebx, coloane_ori_4
			
				cmp matrix[ebx],0
				jne other_way_verticala 
			
					mov matrix[eax], 1
					mov matrix[ebx],1
					sub ebx, coloane_ori_4
					mov matrix[ebx],1
					add counter_vapoare_nedescoperite, 3
					
				jmp final_generare
				
	other_way_verticala:;--------se verifica in cealalta directie pe verticala daca se poate plasa vaporul
	
	cmp matrix[eax], 0
	jne generate_new_number
	
		mov ebx, eax
		sub ebx, coloane_ori_4
		
		cmp ebx,0
		jb generate_new_number
		
		cmp matrix[ebx],0
		jne generate_new_number
	
			sub ebx, coloane_ori_4
			
			cmp ebx,0
			jb generate_new_number
			
			cmp matrix[ebx],0
			jne generate_new_number
			
				mov matrix[eax], 1
				mov eax, coloane_ori_4
				mov matrix[ebx+eax], 1
				mov matrix[ebx], 1
				add counter_vapoare_nedescoperite, 3
				
	 final_generare:
	
	
	popa
	mov esp, ebp
	pop ebp
	ret
random_position_generator endp

initalize_background_matrix proc ;coloane,linii ;--------------------------------------------initializeaza matricea din background----------------------------------------

	push ebp
	mov ebp, esp
	pusha
	
	;--------------------------------------------------------se afla numarul de vapoare-------------------------------------------------------
	
	mov eax,nr_casute
	mov edx, 0
	mov ecx, 20
	div ecx
	cmp eax, 0 
	jg plasare
		mov nr_vapoare, 1
		
	un_vapor_in_plus:
	cmp edx, 10
	jb plasare
		inc nr_vapoare
	
	plasare:
	add nr_vapoare, eax
	
	
	loop_plasare_vapoare:
	
		call random_position_generator
		dec nr_vapoare
		
	cmp nr_vapoare, 0
	jne loop_plasare_vapoare
	
	
	popa
	mov esp, ebp
	pop ebp
	ret
initalize_background_matrix endp


draw_matrix_colors proc
	push ebp
	mov ebp, esp
	pusha
		
	mov ecx, 0
	mov ebx, 0
	
	
	mov edi, offset matrix
	
	parcrugere_backg_matrix_linii:
		mov ebx, 0
		parcrugere_backg_matrix_coloane:
		;----------------------------se afla coordonata de pe canvas x a casutei unde se coloreaza---------------
			mov eax, ebx
			mul dimensiune_50
			add eax, 100
			mov casuta_x, eax
		;----------------------------se afla coordonata de pe canvas y a casutei unde se coloreaza---------------	
			mov eax, ecx
			mul dimensiune_50
			add eax, 100
			mov casuta_y, eax
		
		
			cmp dword ptr [edi], 2;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			jne colorare_cu_rosu
				push 0269AE1h;------------------------albastru/apa
				call colorare_casuta
				add esp, 4
			colorare_cu_rosu:
			cmp dword ptr[edi], 3;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			jne nu_trebuie_colorat
				push 0DC0E0Eh;------------------------rosu/lovitura
				call colorare_casuta
				add esp, 4
				
			nu_trebuie_colorat:
			
			add edi, 4
		inc ebx
		cmp ebx, linii
		jb parcrugere_backg_matrix_coloane
	
	inc ecx
	cmp ecx, coloane
	jb parcrugere_backg_matrix_linii
		

	popa
	mov esp, ebp
	pop ebp
	ret

draw_matrix_colors endp


; functia de desenare - se apeleaza la fiecare click
; sau la fiecare interval de 200ms in care nu s-a dat click
; arg1 - evt (0 - initializare, 1 - click, 2 - s-a scurs intervalul fara click)
; arg2 - x
; arg3 - y
draw proc
	push ebp
	mov ebp, esp
	pusha
	
	mov eax, [ebp+arg1]
	cmp eax, 1
	jz evt_click
	cmp eax, 2
	;jz evt_timer ; nu s-a efectuat click pe nimic
	;mai jos e codul care intializeaza fereastra cu pixeli albi
	mov eax, area_width
	mov ebx, area_height
	mul ebx
	shl eax, 2
	push eax
	push 255
	push area
	call memset
	add esp, 12
	
	;-------------------------------------se calculeaza capetele matricei----------------------------------------------
	mov eax, coloane
	mul dimensiune_50
	add eax, 100
	mov matrix_x_final, eax
	
	
	mov eax, linii
	mul dimensiune_50
	add eax, 100
	mov matrix_y_final, eax
	
	mov ebx, 10
	mov eax, counter_vapoare_nedescoperite
	;cifra unitatilor
	mov edx, 0
	div ebx
	add edx, '0'
	make_text_macro edx, area, 30, 10
	;cifra zecilor
	mov edx, 0
	div ebx
	add edx, '0'
	make_text_macro edx, area, 20, 10
	;cifra sutelor
	mov edx, 0
	div ebx
	add edx, '0'
	make_text_macro edx, area, 10, 10
	
	mov ebx, 10
	mov eax, counter_lovituri_succes
	;cifra unitatilor
	mov edx, 0
	div ebx
	add edx, '0'
	make_text_macro edx, area, 30, 30
	;cifra zecilor
	mov edx, 0
	div ebx
	add edx, '0'
	make_text_macro edx, area, 20, 30
	;cifra sutelor
	mov edx, 0
	div ebx
	add edx, '0'
	make_text_macro edx, area, 10, 30
	
	
	mov ebx, 10
	mov eax, counter_ratari
	;cifra unitatilor
	mov edx, 0
	div ebx
	add edx, '0'
	make_text_macro edx, area, 30, 50
	;cifra zecilor
	mov edx, 0
	div ebx
	add edx, '0'
	make_text_macro edx, area, 20, 50
	;cifra sutelor
	mov edx, 0
	div ebx
	add edx, '0'
	make_text_macro edx, area, 10, 50
	
;--------------------------------se creaza matricea--------------------------------------------------	
	create_matrix_macro linii,coloane
	
	
	call draw_matrix_colors
	
	jmp final_draw
	
;--------------------------------se coloreaza casutele pe care s-a dat click-----------------------------------------
evt_click:

	
	
	push [ebp+arg2];coordonata x
	push [ebp+arg3];coordonata y
	call get_box_coordinates
	add esp, 8

	cmp lovitura_legala, 1
	jne final_draw
	
	call verificare_lovitura
	call draw_matrix_colors
	
	
	
	lovitura_ratata:


final_draw:
	popa
	mov esp, ebp
	pop ebp
	ret
draw endp

start:
	;alocam memorie pentru zona de desenat
	mov eax, area_width
	mov ebx, area_height
	mul ebx
	shl eax, 2
	push eax
	call malloc
	add esp, 4
	mov area, eax
	call citire_date_intrare
	call initalize_background_matrix; se creaza matricea din background
	;apelam functia de desenare a ferestrei
	; typedef void (*DrawFunc)(int evt, int x, int y);
	; void __cdecl BeginDrawing(const char *title, int width, int height, unsigned int *area, DrawFunc draw);
	push offset draw
	push area
	push area_height
	push area_width
	push offset window_title
	call BeginDrawing
	add esp, 20
	
	;terminarea programului
	push 0
	call exit
end start
