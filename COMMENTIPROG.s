.section .rodata                                               // COSTANTI E VARIABILI STATICHE
filename: .asciz "resell.dat"                                  // FILE DA CUI LEGGERE E SU CUI SCRIVERE DATI
read_mode: .asciz "r"                                          //LEGGERE DATI DA RESELL.DAT
write_mode: .asciz "w"                                         //SCRIVERE DATI DA RESELL.DAT
fmt_menu_title:                                                                      //FMT, FORMAT STRING, LEGGERE E STAMPARE DATI
    .ascii "                            ________________________\n"                  //ASCII, ASCIZ (TERMINATORE CIOE METTE UNO ZERO BYTE ALLA FINE), ALLOCARE SPAZIO PER STAMPARE STRING
    .ascii "                                                    \n"
    .ascii "                                The F1rst resell    \n"
    .asciz "                            ________________________\n"
fmt_menu_line:  
    .asciz "--------------------------------------------------------------------\n"
fmt_menu_header:
    .asciz "  # NUMERO     MARCA                MODELLO                   PREZZO\n"
fmt_menu_entry:
    .asciz "%3d %-10s %-20s %-20s %8d\n"
fmt_menu_options:
    .ascii "1: Aggiungi scarpa\n" 
    .ascii "2: Elimina scarpa\n"
    .ascii "3: Calcola prezzo massimo\n"
    .ascii "4: Calcola prezzo medio\n"
    .ascii "5: Prezzo maggiore di...\n"
    .ascii "6: Numero maggiore di...\n"
    .asciz "0: Exit\n"
fmt_prezzo_massimo: .asciz "\nPrezzo massimo: %d\n\n"                               
fmt_prezzo_medio: .asciz "\nPrezzo medio: %.2f\n\n"
fmt_fail_save_data: .asciz "\nImpossibile salvare i dati.\n\n"
fmt_fail_aggiungi_scarpa: .asciz "\nCarrello pieno. Elimina una scarpa.\n\n"
fmt_fail_calcola_prezzo_medio: .asciz "\nNessuna scarpa presente.\n\n"              
fmt_scan_int: .asciz "%d"                         //VIENE LETTO UN INTERO
fmt_scan_str: .asciz "%127s"                     //VIENE LETTA UNA STRINGA
fmt_prompt_menu: .asciz "? "                     //STAMPARE
fmt_prompt_numero: .asciz "Numero: "
fmt_prompt_marca: .asciz "Marca: "
fmt_prompt_modello: .asciz "Modello: "
fmt_prompt_prezzo: .asciz "Prezzo: "
fmt_prompt_numbam: .asciz "Inserisci prezzo: "
fmt_prompt_numero_maggiore: .asciz "Inserisci numero: "
fmt_prompt_index: .asciz "# (9 per annullare): "
.align 2

.data                         //DIRETTIVA PER ALLOCARE DATI
n_scarpa: .word 0                        

.equ max_scarpa, 5                            //ALLOCARE SPAZIO IN MEMORIA DEFINENDO IL NUMERO DI BIT OCCUPATI
.equ size_scarpa_numero, 10
.equ size_scarpa_marca, 20
.equ size_scarpa_modello, 20
.equ size_scarpa_prezzo, 4
.equ offset_scarpa_numero, 0
.equ offset_scarpa_marca, offset_scarpa_numero + size_scarpa_numero           //ACCEDERE ALL'ELEMENTO DELL'"ARRAY" CHE CI SERVE
.equ offset_scarpa_modello, offset_scarpa_marca + size_scarpa_marca
.equ offset_scarpa_prezzo, offset_scarpa_modello + size_scarpa_modello
.equ scarpa_size_aligned, 64                                                               //NUMERO DI BIT TOTALI

.bss                                  //BETTER TO SAVE SPACE PERCHÈ IL FILE OGGETTO DEVE MEMORIZZARE SOLO LA DIMENSIONE DELLA VARIABILE, VARIABILI GLOBALI INIZIALIZZATE A ZERO
tmp_str: .skip 128                        //TEMPORARY STRING    
tmp_int: .skip 8
scarpa: .skip scarpa_size_aligned * max_scarpa


.macro read_int prompt                    //MACRO PER LEGGERE INTERI DA INPUT
    adr x0, \prompt
    bl printf

    adr x0, fmt_scan_int
    adr x1, tmp_int
    bl scanf

    ldr x0, tmp_int
.endm

.macro read_str prompt                    //MACRO PER LEGGERE STRINGHE DA INPUT
    adr x0, \prompt
    bl printf

    adr x0, fmt_scan_str
    adr x1, tmp_str
    bl scanf
.endm

.macro save_to item, offset, size                     
    add x0, \item, \offset                  //SALVA GLI OFFSET DI MARCA,MODELLO,NUMERO
    ldr x1, =tmp_str
    mov x2, \size
    bl strncpy

    add x0, \item, \offset + \size - 1
    strb wzr, [x0]                          //STORE DEL BYTE MENO SIGNIFICATIVO DI X0 MESSO ALL'INTERNO DEL REGISTRO 31(ZERO REGISTER)
.endm


.text                                   //ISTRUZIONI ESEGUIBILI
.type main, %function
.global main                           //VARIABILE GLOBALE VISIBILE AD ALTRI LINKER ESTERNI
main:
    stp x29, x30, [sp, #-16]!           //LOAD E STORE DI DUE REGISTRI, IN QUESTO CASO DEL FRAME POINTER E DEL LINK REGISTER. E POI TOGLIE 16 BIT ALLO STACK POINTER

    bl load_data                         //BRANCH AND LINK

    main_loop:                           //LOOP INCONDIZIONALE
        bl print_menu
        read_int fmt_prompt_menu
        
        cmp x0, #0                        //COMPARE CON UN NUMERO INTERO LETTO DA INPUT PER CHIAMARE LE SINGOLE FUNZIONI
        beq end_main_loop                  //TERMINA IL LOOP QUANDO TROVA #NUMERO/        //BRANCH EQUAL
        
        cmp x0, #1                         //SE NON È UGUALE A #NUMERO NON ESEGUIRE
        bne no_aggiungi_scarpa             //BRANCH NOT EQUAL
        bl aggiungi_scarpa                 //ALTRIMENTI BRANCH AND LINK ED ESEGUE LA FUNZIONE 
        no_aggiungi_scarpa:                //SENNÒ VA AVANTI

        cmp x0, #2
        bne no_elimina_scarpa
        bl elimina_scarpa
        no_elimina_scarpa:

        cmp x0, #3
        bne no_calcola_prezzo_massimo
        bl calcola_prezzo_massimo
        no_calcola_prezzo_massimo:

        cmp x0, #4
        bne no_calcola_prezzo_medio
        bl calcola_prezzo_medio
        no_calcola_prezzo_medio:

        cmp x0, #5
        bne no_numbam
        bl numbam
        no_numbam:
 
        cmp x0, #6
        bne no_numero_maggiore
        adr x0, fmt_prompt_numero_maggiore
        bl printf

        adr x0, fmt_scan_int                 //LEGGE INTERO DA INPUT
        adr x1, tmp_int
        bl scanf
 
        adr x0, fmt_menu_line
        bl printf
        adr x0, fmt_menu_header                 //STAMPA MENÙ
        bl printf
        adr x0, fmt_menu_line
        bl printf
    
        ldr x0, tmp_int 
        mov x1, #0 
        ldr x2, =scarpa
        

        bl numero_maggiore

        adr x0, fmt_menu_line 
        bl printf

        no_numero_maggiore:

        b main_loop     
    end_main_loop:

    mov w0, #0
    ldp x29, x30, [sp], #16
    ret
    .size main, (. - main)


.type load_data, %function                  //FUNZIONE PER CARICARE I DATI NEL FILE RESELL.DAT                 
load_data:
    stp x29, x30, [sp, #-16]!
    str x19, [sp, #-8]!
    
    adr x0, filename
    adr x1, read_mode
    bl fopen                       //FILE OPEN

    cmp x0, #0
    beq end_load_data

    mov x19, x0

    ldr x0, =n_scarpa
    mov x1, #4
    mov x2, #1
    mov x3, x19
    bl fread

    ldr x0, =scarpa
    mov x1, scarpa_size_aligned
    mov x2, max_scarpa
    mov x3, x19
    bl fread

    mov x0, x19
    bl fclose

    end_load_data:

    ldr x19, [sp], #8
    ldp x29, x30, [sp], #16
    ret
    .size load_data, (. - load_data)


.type save_data, %function                             //FUNZIONE PER SALVARE I DATI IN RESELL.DAT
save_data:
    stp x29, x30, [sp, #-16]!
    str x19, [sp, #-8]!
    
    adr x0, filename
    adr x1, write_mode
    bl fopen

    cmp x0, #0
    beq fail_save_data

        mov x19, x0

        ldr x0, =n_scarpa
        mov x1, #4
        mov x2, #1
        mov x3, x19
        bl fwrite

        ldr x0, =scarpa
        mov x1, scarpa_size_aligned
        mov x2, max_scarpa
        mov x3, x19
        bl fwrite

        mov x0, x19
        bl fclose

        b end_save_data

    fail_save_data:
        adr x0, fmt_fail_save_data
        bl printf

    end_save_data:

    ldr x19, [sp], #8
    ldp x29, x30, [sp], #16
    ret
    .size save_data, (. - save_data)


.type print_menu, %function                         //FUNZIONE PER STAMPARE IL MENÙ
print_menu:
    stp x29, x30, [sp, #-16]!
    stp x19, x20, [sp, #-16]!
    stp x21, x22, [sp, #-16]!

    adr x0, fmt_menu_title
    bl printf

    adr x0, fmt_menu_line       
    bl printf
    adr x0, fmt_menu_header
    bl printf
    adr x0, fmt_menu_line
    bl printf

    mov x19, #0
    ldr x20, n_scarpa
    ldr x21, =scarpa
    print_entries_loop:
        cmp x19, x20
        bge end_print_entries_loop

        adr x0, fmt_menu_entry
        add x1, x19, #1
        add x2, x21, offset_scarpa_numero
        add x3, x21, offset_scarpa_marca
        add x4, x21, offset_scarpa_modello
        ldr x5, [x21, offset_scarpa_prezzo]
        bl printf

        add x19, x19, #1
        add x21, x21, scarpa_size_aligned
        b print_entries_loop
    end_print_entries_loop:

    adr x0, fmt_menu_line
    bl printf

    adr x0, fmt_menu_options
    bl printf

    ldp x21, x22, [sp], #16
    ldp x19, x20, [sp], #16
    ldp x29, x30, [sp], #16
    ret
    .size print_menu, (. - print_menu)


.type aggiungi_scarpa, %function
aggiungi_scarpa:
    stp x29, x30, [sp, #-16]!
    stp x19, x20, [sp, #-16]!
    
    ldr x19, n_scarpa
    ldr x20, =scarpa
    mov x0, scarpa_size_aligned
    mul x0, x19, x0
    add x20, x20, x0
    
    cmp x19, max_scarpa
    bge fail_aggiungi_scarpa
        read_str fmt_prompt_numero
        save_to x20, offset_scarpa_numero, size_scarpa_numero

        read_str fmt_prompt_marca
        save_to x20, offset_scarpa_marca, size_scarpa_marca
        
        read_str fmt_prompt_modello
        save_to x20, offset_scarpa_modello, size_scarpa_modello

        read_int fmt_prompt_prezzo
        str w0, [x20, offset_scarpa_prezzo]      

        add x19, x19, #1
        ldr x20, =n_scarpa
        str x19, [x20]

        bl save_data

        b end_aggiungi_scarpa 
    fail_aggiungi_scarpa:
        adr x0, fmt_fail_aggiungi_scarpa
        bl printf
    end_aggiungi_scarpa:
    
    ldp x19, x20, [sp], #16
    ldp x29, x30, [sp], #16
    ret
    .size aggiungi_scarpa, (. - aggiungi_scarpa)


.type elimina_scarpa, %function
elimina_scarpa:
    stp x29, x30, [sp, #-16]!
    
    read_int fmt_prompt_index

    cmp x0, 1
    blt end_elimina_scarpa

    ldr x1, n_scarpa
    cmp x0, x1
    bgt end_elimina_scarpa

    sub x5, x0, 1   // selected index
    ldr x6, n_scarpa
    sub x6, x6, x0  // number of auto after selected index
    mov x7, scarpa_size_aligned
    ldr x0, =scarpa
    mul x1, x5, x7  // offset to dest
    add x0, x0, x1  // dest
    add x1, x0, x7  // source
    mul x2, x6, x7  // bytes to copy
    bl memcpy                              //FUNZIONE LIBRERIA C, COPIA BYTE DI MEMORIA DA UN INDIRIZZO AD UN ALTRO, UTILE PER ELIMINARE ELEMENTI

    ldr x0, =n_scarpa
    ldr x1, [x0]
    sub x1, x1, #1
    str x1, [x0]

    bl save_data

    end_elimina_scarpa:
    
    ldp x29, x30, [sp], #16
    ret
    .size elimina_scarpa, (. - elimina_scarpa)


.type calcola_prezzo_massimo, %function
calcola_prezzo_massimo:
    stp x29, x30, [sp, #-16]!
    
    ldr x0, n_scarpa
    cmp x0, #0
    beq calcola_prezzo_massimo_error

        mov x1, #0
        mov x2, #0
        ldr x3, =scarpa
        add x3, x3, offset_scarpa_prezzo
        calcola_prezzo_massimo_loop:
            ldr x4, [x3]
            cmp x4, x1
            csel x1, x4, x1, gt
            add x3, x3, scarpa_size_aligned
        
            add x2, x2, #1
            cmp x2, x0
            blt calcola_prezzo_massimo_loop              //BRANCH LOWER THAN


        adr x0, fmt_prezzo_massimo
        bl printf

        b end_calcola_prezzo_massimo

    calcola_prezzo_massimo_error:
        adr x0, fmt_fail_calcola_prezzo_medio
        bl printf
    
    end_calcola_prezzo_massimo:

    ldp x29, x30, [sp], #16
    ret                                                              //RETURN
    .size calcola_prezzo_massimo, (. - calcola_prezzo_massimo)


.type calcola_prezzo_medio, %function
calcola_prezzo_medio:
    stp x29, x30, [sp, #-16]!
    
    ldr x0, n_scarpa
    cmp x0, #0
    beq calcola_prezzo_medio_error

        fmov d1, xzr                    //FMOV SPOSTA IL CONTENUTO DELLO ZERO REGISTER(XZR) IN D1(REGISTRO FLOATING POINT(FP))
        mov x2, #0
        ldr x3, =scarpa
        add x3, x3, offset_scarpa_prezzo
        calcola_prezzo_medio_loop:
            ldr x4, [x3]
            ucvtf d4, x4                                  //CONVERSIONE DA REGISTRO INTERO AD FP
            fadd d1, d1, d4
            add x3, x3, scarpa_size_aligned

            add x2, x2, #1
            cmp x2, x0
            blt calcola_prezzo_medio_loop
        
        ucvtf d0, x0                                       //CONVERSIONE DA REGISTRO INTERO AD FP
        fdiv d0, d1, d0
        adr x0, fmt_prezzo_medio
        bl printf

        b end_calcola_prezzo_medio

    calcola_prezzo_medio_error:
        adr x0, fmt_fail_calcola_prezzo_medio
        bl printf
    
    end_calcola_prezzo_medio:

    ldp x29, x30, [sp], #16
    ret
    .size calcola_prezzo_medio, (. - calcola_prezzo_medio)


.type numbam, %function
numbam:
    stp x29, x30, [sp, #-16]!
    stp x19, x20, [sp, #-16]!
    stp x21, x22, [sp, #-16]!

    adr x0, fmt_prompt_numbam
    bl printf

    adr x0, fmt_scan_int
    adr x1, tmp_int
    bl scanf
    ldr x19, tmp_int
    
    adr x0, fmt_menu_line
    bl printf
    adr x0, fmt_menu_header
    bl printf
    adr x0, fmt_menu_line
    bl printf
     
    ldr x20, n_scarpa
    ldr x21, =scarpa
    mov x22, #0
    loop_numbam:
        cmp x22, x20
        bgt endloop_numbam
    
        ldr x5, [x21, offset_scarpa_prezzo]
        cmp x19, x5
        bge endif_numbam
            adr x0, fmt_menu_entry
            mov x1, x22
            add x1, x1, #1
            add x2, x21, offset_scarpa_numero
            add x3, x21, offset_scarpa_marca
            add x4, x21, offset_scarpa_modello

            bl printf
       endif_numbam:

       add x22, x22, #1 
       add x21, x21, scarpa_size_aligned
       b loop_numbam

    endloop_numbam:

     adr x0, fmt_menu_line //Line
    bl printf

    ldp x21, x22, [sp], #16
    ldp x19, x20, [sp], #16
    ldp x29, x30, [sp], #16
    ret
    .size numbam, (. - numbam)


.type numero_maggiore, %function
numero_maggiore:
       stp x29, x30, [sp, #-16]!
       stp x19, x20, [sp, #-16]!
       stp x21, x22, [sp, #-16]!
 
       mov x19, x0                //SPOSTA IL VALORE DI X0 IN X19 //X0 È NUMERO IN INPUT

       ldr x20, n_scarpa            //NUMERO DI SCARPE
       mov x21, x2                  //ARRAY DELLE SCARPE
       mov x22, x1                  //COUNTER
 
       add x0, x21, offset_scarpa_numero       //NUMERO SCARPE
       bl atoi
   
       cmp x19, x0                //SE NUMERO SCARPA > NUMERO IN INPUT PRINT SCARPA
       bge endif_numero_maggiore
           adr x0, fmt_menu_entry
           mov x1, x22
           add x1, x1, #1
           add x2, x21, offset_scarpa_numero            //CASO BASE
           add x3, x21, offset_scarpa_marca
           add x4, x21, offset_scarpa_modello
           ldr x5, [x21, offset_scarpa_prezzo]
           
           
           bl printf
     endif_numero_maggiore:

     add x22, x22, #1                       //AUMENTA DI UNO IL COUNTER
     add x21, x21, scarpa_size_aligned     //PARTE RICORSIVA/ /SCARPA SUCCESSIVA
 
     cmp x22, x20                        //CONFRONTA X22(COUNTER) CON X20(NUMERO SCARPE)
     bgt end_numero_maggiore
   
     mov x0, x19 
     mov x1, x22 
     mov x2, x21 
     bl numero_maggiore

     end_numero_maggiore:
 
     ldp x21, x22, [sp], #16
     ldp x19, x20, [sp], #16
     ldp x29, x30, [sp], #16
     ret
     .size numero_maggiore, (. - numero_maggiore)
