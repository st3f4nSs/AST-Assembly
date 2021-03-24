
section .data
    delim: db ' ',10,0

section .bss
    root resd 1

section .text

extern check_atoi
extern print_tree_inorder
extern print_tree_preorder
extern evaluate_tree
extern strtok
extern strlen
extern malloc
extern strcpy
global create_vector
global check_operand
global create_tree
global iocla_atoi
global allocate_string

iocla_atoi: 
    push ebp
    mov ebp, esp
    mov esi, [ebp + 8]
    xor eax, eax                    ; stocam rezultatul in eax
    xor ebx, ebx                    ; stocam contorul prin vector
    xor ecx, ecx                    ; luam caracter cu caracter din sir
    xor edx, edx                    ; e un is_negative: daca sirul incepe cu -, edx = -1
                                    ;   altfel edx = 1
    mov edx, 1                      ; presupunem initial ca numarul este pozitiv
    movzx ecx, BYTE[esi]            ; luam primul caracter din sir
    cmp cl, 45                      ; verificam daca primul caracter e minus
    jne while_iocla_atoi            ; daca nu e atunci incepem constructia numarului
    mov edx, -1                     ; daca e atunci edx = -1
    inc ebx                         ; trecem la urmatorul caracter

while_iocla_atoi:
    movzx ecx, BYTE[esi + ebx]
    cmp cl, 0                       ; cat timp nu am ajuns la finalul sirului
    je exit_iocla_atoi             
    imul eax, 10                    ; inmultim numarul cu 10, si adaugam cifra(s[i] - 48)
    add eax, ecx                    ; adaugam caracterul
    sub eax, 48                     ; scadem 48
    inc ebx                         ; trecem mai departe la urmatorul caracter
    jmp while_iocla_atoi            ; repetam

exit_iocla_atoi:
    imul eax, edx                   ; la final inmultim rezultatul cu edx
    leave
    ret



check_operand:                      ; functie care pentru un string dat verifica daca e operator sau operand
    push ebp                        ; daca este operand returnam 1 altfel 0
    mov ebp, esp
    xor eax, eax
    xor ebx, ebx
    mov eax, [ebp + 8]              ; salvam in eax sirul
    movzx ebx, BYTE[eax]            ; salvam in ebx primul caracter din string

    push eax
    call strlen                     ; apelam functia strlen pe sirul nostru
    add esp, 4                      ; acum in eax va fi lungimea sirului

    cmp eax, 1                      ; verificam daca lungimea sirului este egala cu 1
    ja is_operand                   ; daca este > 1 atunci este sigur operand
    cmp ebx, 48                     ; daca primul caracter din sir >= 48 atunci e o cifra
    jae is_operand
    xor eax, eax                    ; altfel este operator
    jmp exit_check_operand

is_operand:                         ; daca este operand punem in eax 1
    xor eax, eax
    mov eax, 1

exit_check_operand:
    leave
    ret



create_vector:                      ; functie care construieste un vector de pointeri cu fiecare sir(operator/ operand)
    push ebp                        ; vom pune fiecare sir pe stiva
    mov ebp, esp                    ; vom lua pe rand de pe stiva si vom pune pointer cu pointer( sir cu sir) in vector
                                    ; functia are ca argument sirul initial( expresia prefixata)
    xor eax, eax
    xor ebx, ebx
    xor ecx, ecx
    xor edx, edx
    xor edi, edi
    mov ebx, [ebp + 8]

    push delim
    push ebx                        ; apelam functia strtok
    call strtok                     ; in eax se afla un pointer la primul cuvant
    add esp, 8

while:
    cmp eax, 0                      ; verificam daca pointerul e null, caz in care am terminat.
    je print
    add edi, 4                      ; edi va fi numarul de octeti ce trebuie alocati pentru vectorul de pointeri
    push eax                        ; punem pointerul pe stiva
    xor eax, eax

    push delim  
    push 0                          ; apelam strtok(NULL, delim)
    call strtok
    add esp, 8

    jmp while                       ; repetam

print:                              ; cand ajungem la sfarsitul sirului, cand am terminat de adaugat pe stiva
    xor eax, eax                   
    push edi                        ; alocam memorie pentru vectorul de pointeri
    call malloc
    add esp, 4

while_2:
    cmp esp, ebp                    ; cat timp mai evem elemente pe stiva
    je exit
    xor ebx, ebx
    mov ebx, [esp]                  ; in ebx vom lua pe rand din stiva sirurile rezultate din strtok
    mov [eax], ebx                  ; adaugam in vectorul de pointeri
    add eax, 4                      ; incrementam eax-ul, ne ducem la urmatorul element

    add esp, 4
    jmp while_2                     ; repetam

exit:
    sub eax, edi                    ; scadem din eax, edi, pentru a pointa eax-ul catre primul element
    leave
    ret



allocate_string:                     ; primeste un string drept parametru si returneaza un string nou alocat in memorie.
    push ebp                         ; realizeaza un deepcopy
    mov ebp, esp                            
    xor eax, eax

    push DWORD[ebp + 8] 
    call strlen                      ; apelam strlen pentru a calcula dimensiunea
    add esp, 4

    add eax, 1                       ; adaugam 1 la dimensiune( pentru '\0')
    push eax
    call malloc                      ; alocam un numar de octeti egal cu valoarea din eax
    add esp, 4

    push DWORD[ebp + 8]
    push eax                         ; apelam functia strcpy => un pointer catre un sir nou cu acelasi continut ca
    call strcpy                      ;  cel initial
    add esp, 4

    leave
    ret



create_tree:                          ; functie iterativa care construieste arborele de expresie.
    enter 0, 0                        ; parcurgem vectorul de siruri(pointeri)
    sub esp, 4                        ; daca intalnim un operand atunci construim un nod ce are drept valoare
    pusha                             ;   valoarea sirului, cu nod->st = nod->dr = NULL pe care il punem pe stiva 
    xor ecx, ecx                      ; daca intalnim un operator atunci construim un nod ce are drept valoare 
    xor eax, eax                      ;   valoarea sirului, scoatem 2 noduri de pe stiva( vor fi 2 operanzi) si
    xor edi, edi                      ;   nod->st = primul nod de pe stiva, nod->dr = al doilea nod de pe stiva
    mov eax, [ebp + 8]

    push eax
    call create_vector                ; cream vectorul de siruri           
    add esp, 4

    xor ebx, ebx
    xor ecx, ecx
    xor edx, edx

while_tree:
    cmp ebx, edi                      ; cat timp nu am terminat de parcurs vectorul
    je return_root                    ; daca am terminat de parcurs vom avea in stiva nodul root( radacina)
    push ebx                          ; salvam valoarea contorului
    push eax                          ; salvam pe stiva vectorul de pointeri

    push DWORD[eax]
    call check_operand                ; verificam daca e operand
    add esp, 4

    cmp eax, 1                             
    je if_operand                     ; daca e operand          
    xor ebx, ebx    
    xor eax, eax
    pop eax                           ; punem in eax, vectorul de pointer
    pop ebx                           ; punem in ebx contorul
    push eax

    push DWORD[eax]
    call allocate_string              ; apelam functia allocate_string
    add esp, 4                        ; realizam deepcopy-u
    push eax                          ; punem pe stiva
    xor eax, eax

    push 12
    call malloc                       ; alocam memorie pentru un nod
    add esp, 4

    xor ecx, ecx
    xor edx, edx
    pop edx                           ; punem in edx sirul construit de functia allocate_string
    pop ecx                           ; punem in ecx vectorul de pointeri
    mov [eax], edx                    ; punem valoarea in nod
    xor edx, edx                            
    pop edx                           ; scoatem un nod de pe stiva( un operand, o frunza)
    mov [eax + 4], edx                ; nod->st = nod_1_scos_stiva
    xor edx, edx
    pop edx                           ; scaotem al doilea nod de pe stiva( un operand, o frunza)
    mov [eax + 8], edx                ; nod->dr = nod_2_scos_stiva
    push eax                          ; punem nodul rezultat pe stiva
    xor eax, eax
    mov eax, ecx                      ; punem in eax vectorul de pointeri
    add eax, 4                        ; trecem la urmatorul element
    add ebx, 4                        ; adaugam la contor 4
    jmp while_tree                    ; repetam

if_operand:
    xor ebx, ebx
    xor eax, eax
    pop eax                           ; punem in eax vectorul
    pop ebx                           ; punem in ebx contorul
    push eax                          ; salvam eax-ul(vectorul) pe stiva

    push DWORD[eax]                         
    call allocate_string              ; apelam functia allocate_string
    add esp, 4                        ; realizam deepcopy-ul
    push eax                          ; punem pe stiva
    xor eax, eax

    push 12
    call malloc                       ; alocam memorie pentru un nod
    add esp, 4

    xor ecx, ecx
    xor edx, edx
    pop edx                           ; punem in edx sirul construit de functia allocate_string
    pop ecx                           ; punem in ecx vectorul de pointeri
    mov [eax], edx                    ; punem valoarea in nod
    mov DWORD[eax + 4], 0             ; nod->st = NULL
    mov DWORD[eax + 8], 0             ; nod->st = NULL
    push eax                          ; punem nodul creat pe stiva
    xor eax, eax 
    mov eax, ecx                      ; punem in eax vectorul de pointeri
    add eax, 4                        ; trecem la urmatorul element
    add ebx, 4                        ; adaugam 4 la contor
    jmp while_tree                    ; repetam

return_root:
    xor eax, eax
    pop eax                 
    mov [ebp - 4], eax                ; in eax se va afla radacina arborelui
    popa
    mov eax, [ebp - 4]
    leave
    ret