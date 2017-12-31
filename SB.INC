;
; SB.INC - Procedimientos para reproducir sonido por la Tarjeta Sound Blaster
;          Soporta Sonidos de 8bit 11000Hz
;
;       Autor: vhanla@gmail.com
;Sound Blaster
BASEADDR    EQU 220h
IRQ7	    EQU 15
DMAChannel  EQU 1

; PIC MASKS FOR MASK/DEMASK IRQ
PICANDMASK	   EQU 01111111b   ;'AND' PIC mask for clear IRQ7
PICORMASK	   EQU 10000000b   ;'OR' PIC mask for set IRQ7

; DMA CONTROLLER REGISTERS :
WRITEMASK	   EQU 00ah	    ;WRITE MASK REGISTER
WRITEMODE	   EQU 00bh	    ;WRITE MODE REGISTER
CLEARFLIPFLOP	   EQU 00ch
PAGE_CHN	   EQU 083h	    ;PAGE REGISTER FOR DMAchannel 1
BASE_CHN	   EQU 002h	    ;BASEADDRESS REGISTER DMA 1
COUNT_CHN	   EQU 003h	    ;COUNT REGISTER DMAchannel 1

; SAMPLERATE : (if you change it pay attention to maximum samplerate)
TIMECONST	   EQU 165	    ; = 10989 Hz (256-1000000/11000)

; DMA WRITE MODE
WANTEDMODE	   EQU 01001000b    ; singlemode, nonautoinit, readmode

SAMPLEBUFFERLENGTH EQU 9142


; SoundBlaster SETUP
BASEADDR	   EQU 0220h	   ;SoundBlaster base address
IRQ7		   EQU 15	   ;SoundBlaster IRQ
DMAchannel	   EQU 1	   ;SoundBlaster DMA channel

; PIC MASKS FOR MASK/DEMASK IRQ
PICANDMASK	   EQU 01111111b   ;'AND' PIC mask for clear IRQ7
PICORMASK	   EQU 10000000b   ;'OR' PIC mask for set IRQ7

; DMA CONTROLLER REGISTERS :
WRITEMASK	   EQU 00ah	    ;WRITE MASK REGISTER
WRITEMODE	   EQU 00bh	    ;WRITE MODE REGISTER
CLEARFLIPFLOP	   EQU 00ch
PAGE_CHN	   EQU 083h	    ;PAGE REGISTER FOR DMAchannel 1
BASE_CHN	   EQU 002h	    ;BASEADDRESS REGISTER DMA 1
COUNT_CHN	   EQU 003h	    ;COUNT REGISTER DMAchannel 1

; SAMPLERATE : (if you change it pay attention to maximum samplerate)
TIMECONST	   EQU 165	    ; = 10989 Hz (256-1000000/11000)

; DMA WRITE MODE
WANTEDMODE	   EQU 01001000b    ; singlemode, nonautoinit, readmode
SAMPLEBUFFERLENGTH equ 13652


;ÄÄÄ End of Macrodefinitions ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ


format MZ
stack 100h
heap 4096

mov ax,cs
mov ds,ax
mov [misegmento],ax
;mov es,ax
;primero reservamos un segmento para el archivo que vamos a
;utilizar como buffer de sonido

call allocate
mov [soundbuffer],ax

;abrimos el fichero
mov dx,filename
call openfile
mov [manejaficheros],ax

;leemos los datos en el buffer
mov bx,[manejaficheros]
mov cx,32
call readfiletobuffer
;pero como el cabezal no interesa, tonces
;unicamente leemos el contenido
mov cx,65535
mov bx,[manejaficheros]
call readfiletobuffer
mov [length_of_sound],ax
sub [length_of_sound],1000

;debemos cerrar el fichero
mov ah,3eh
mov bx,[manejaficheros]
int 21h

;ahora que tenemos los datos en memoria, podemos
;hacer sonar un poco nuestro parlante
;call procSBInit

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; MAIN LOOP - here we restart the sample later

start:
		mov	si,soundbuffer
		mov	cx,[length_of_sound];SAMPLEBUFFERLENGTH-1

		mov	[ready],0

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; calculate page and offset for DMAcontroller :
;
; segment*16+offset - 20bit memory location -> upper 4 bits  = page
;                                              lower 16 bits = offset
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
	   mov	   si,soundbuffer
	   mov	   cx,[length_of_sound];SAMPLEBUFFERLENGTH-1

	   mov	   ax,[soundbuffer];ds
	   rol	   ax,4 	       ; * 16 - higher 4 bits in al
	   mov	   bl,al
	   and	   bl,00fh	       ; BL - higher 4 bits
	   and	   al,0f0h	       ; clear higher 4bits in AL
	   add	   si,ax	       ; SI = offset
	   adc	   bl,0 	       ; BL = page
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; check for DMApage override :
; ... problem: DMA controller separates memory into 64KB pages, you can only
; transfer data is placed in one page - no page overrides are allowed
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; To solve that :
; creat a DMA buffer with double size you want - if the first part is placed
; on a page border the second part is for sure not
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
	   neg	   si	       ; si = 65536 - si   (bytes left to DMA page border)
	   cmp	   si,cx       ; if si (bytes left to border) > cx (bytes to play)
	   ja	   nooverride  ; then there's no page override

	   ; WE HAVE TO USE SECOND PART
	   neg	   si	       ; si = offset of first part
	   add	   si,cx       ; si = si + length of one part
	   inc	   si	       ; si=si+1 - start of second part
	   inc	   bl	       ; second part is then on the next page
	   neg	   si	       ; look at the next command ;)
			       ; (that is better than a jump ?)
nooverride:
	   neg	   si

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Setup DMA-controller :
;
; 1st  MASK DMA CHANNEL
;
	   mov	   al,DMAchannel
	   add	   al,4
	   out	   WRITEMASK,al
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; 2nd  CLEAR FLIPFLOP
;
	   out	   CLEARFLIPFLOP,al
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; 3rd  WRITE TRANSFER MODE
;
	   mov	   al,WANTEDMODE
	   add	   al,DMAchannel
	   out	   WRITEMODE,al
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; 4th  WRITE PAGE NUMBER
;
	   mov	   al,bl
	   out	   PAGE_CHN,al
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; 5th  WRITE BASEADDRESS
;
	   mov	   ax,si
	   out	   BASE_CHN,al
	   mov	   al,ah
	   out	   BASE_CHN,al
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; 6th  WRITE SAMPLELENGTH-1
;
	   mov	   al,cl
	   out	   COUNT_CHN,al
	   mov	   al,ch
	   out	   COUNT_CHN,al
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; 7th  DEMASK CHANNEL
;
	   mov	   al,DMAchannel
	   out	   WRITEMASK,al

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Setup SoundBlaster :
;
; 1st  SET TIMECONSTANTE
;
	   mov	   dx,BASEADDR+00Ch	       ;DX = DSP Write Data or Command
	   call WAITWRITE
	   mov	   al,040h		       ;AL = Set timeconstant
	   out	   dx,al
	   call WAITWRITE
	   mov	   al,TIMECONST
	   out	   dx,al

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; 2nd  set DMAplay 8bit mono nonautoinit (DSPcommand-014h)
;
	   call WAITWRITE
	   mov	   al,014h		       ;AL = DMA DAC 8bit
	   out	   dx,al
	   mov	   cx,[length_of_sound];SAMPLEBUFFERLENGTH-1
	   call WAITWRITE
	   mov	   al,cl		       ;AL = LOWER PART SAMPLELENGTH
	   out	   dx,al
	   call WAITWRITE
	   mov	   al,ch		       ;AL = HIGHER PART SAMPLELENGTH
	   out	   dx,al

; TRANSFER STARTS ....... NOW ..... :)

waitloop:
	   call horacio
	   cmp [hora],50
	   jne sigueloop
	   mov [hora],0
	   jmp musicamaestro

sigueloop:
	   mov	   ah,01		       ;AH = Check for character function
	   int	   016h 		       ;   Interrupt: Keyboard
	   jz	   waitloop		       ; wait for any key

	   xor	   ah,ah		       ;Read character, flush keypress
	   int	   016h 		       ;   Interrupt: Keyboard
	   cmp	   al,'r'
	   jne	   norestart
	 musicamaestro:
	   ; HERE TERMINATE CURRENT SAMPLE :
	   mov	   dx,BASEADDR+00Ch	       ;DX = DSP Write Data or Command
	   call WAITWRITE
	   mov	   al,0D0h		       ;AL = Halt DMA Operation, 8-bit
	   out	   dx,al		       ;   Output: DSP Write Data or Command
	   call WAITWRITE
	   mov	   al,0DAh		       ;AL = terminate 8-bit DMA Operation
	   out	   dx,al		       ;   Output: DSP Write Data or Command
	   call WAITWRITE
	   mov	   al,0D0h		       ;AL = Halt DMA Operation, 8-bit
	   out	   dx,al		       ;   Output: DSP Write Data or Command

	   jmp	      start
norestart:
	   cmp	   al,'p'
	   jne	   exit
	   cmp	   [ready],1		       ; sample still playing ?
	   je	   waitloop		       ; not ! return to waitloop

	   ; NOW HALT PLAYING :
	   mov	   dx,BASEADDR+0Ch
	   call WAITWRITE
	   mov	   al,0d0h		       ; AL = DSP halt 8bit DMA
	   out	   dx,al

	   ; WAIT FOR ANY KEY :
	   xor	   ah,ah		       ;Read character, flush keypress
	   int	   016h 		       ;   Interrupt: Keyboard

	   ; CONTINUE PLAYING :
	   mov	   dx,BASEADDR+0Ch
	   call WAITWRITE
	   mov	   al,0d4h		       ; AL = DSP continue 8bit DMA
	   out	   dx,al
	   jmp	   waitloop

exit:
	   ; FIRST TERMINATE DMA TRANSFER :
	   cmp	   [ready],1
	   je	   allready_done	       ; nothin to do allready done

	   ; RESET SOUNDBLASTER
	   call RESET_DSP
allready_done:

	   ; RESTORE PIC MASK
	   in	   al,021h
	   or	   al,PICORMASK 	       ;<-- SET REGISTER MASK BITS TO DISABLE
	   out	   021h,al

	   ; RESTORE IRQ :
	   xor	   ax,ax
	   mov	   es,ax		       ; es to page 0 (Interrupt table)
	   mov	   si,IRQ7*4
	   mov	   ax,[OLDInterruptOFS]
	   mov	   [es:si],ax		       ; set old interrupt routine
	   mov	   ax,[OLDInterruptSEG]
	   mov	   [es:si+2],ax

	   ; TERMINATE EXE:
return2dos:
;xor ax,ax
;int 16h
mov ax,[soundbuffer]
call free_screen_buf
mov ah,4ch
int 21h

;:           mov     ax,04c00h
;.           int     21h          ; bye bye

; display information if Soundblaster is not on this baseaddress
RESET_ERROR:
	   mov	   dx,sberror
	   mov	   ah,9
	   int	   21h			       ; text output
	   jmp	   return2dos

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Our own IRQ for detecting end of playing
; It's generated by the SoundBlaster hardware
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
OWN_IRQ:
	   push    ax
	   push    dx
	   push    ds
	   mov	   dx,BASEADDR+00Eh	       ;DX = DSP DATA AVAILABLE (IRQ ACKNOWLEDGE)
	   in	   al,dx
	   mov	   ax,ds;:misegmento];ds;@DATA
	   mov	   ds,ax
	   mov	   [ds:ready],1 		  ; Sample done ...
	   mov	   al,020h
	   out	   020h,al		       ;ACKNOWLEDGE HARDWARE INTERRUPT - PIC1
	   pop	   ds
	   pop	   dx
	   pop	   ax
	   IRET

;datos
misegmento dw ?
length_of_sound dw ?
sberror db 'SB not found!$'
ready db 0
manejaficheros dw ?

;include 'test1.inc'
;include 'test2.inc'
filename db 'space.voc',0
OLDInterruptOFS dw ?
OLDInterruptSEG dw ?
soundbuffer: dw ?;65535 dup(?)
readfiletobuffer: ;bx=buffer destino, cx=cantidad de bytes
		  ;retorna en AX la cantidad de bytes leidos
push ds
mov ax,[soundbuffer]
mov ds,ax
mov ah,3fh
mov dx,0;soundbuffer
int 21h
pop ds
ret

;errorr:
;mov dx,error
;mov ah,9
;int 21h
;mov ah,4ch
;int 21h
;ret
;error db 'No se pudo leer el archivo.$'

openfile:
mov ax,3d00h
int 21h
jc @noabrio
ret
@noabrio:
mov ah,9
mov dx,noabrio
int 21h
mov ah,4ch
int 21h
ret
noabrio db 'Noabrio$'

allocate:  ;retorna en AX el segmento

	mov ah, 4ah
	mov bx, 1000h
	int 21h
	mov ah, 48h
	mov bx, 1000h
	int 21h
	jc  outofmem
	ret
outofmem:
	mov ah,09h
	mov dx, oom_string
	int 21h
	mov ah,4ch
	int 21h
	ret
oom_string db 'No hay memoria suficiente.$'
free_screen_buf:
	push es
	mov es,ax
	mov ah,49h
	int 21h
	pop es
	ret


horacio:
	mov ah,2ch
	int 21h
	cmp [tiempo],dl ;comparamos con el actual
	je siguenomas
	  ;en caso contrario actualizamos
	  mov [tiempo],dl
	  cmp [hora],255
	  je bajalo
	   inc [hora]
	   ret
	  bajalo:
	   mov [hora],0

siguenomas:
ret
tiempo db 0
hora db 0

WAITWRITE:
;          Arguments : DX = Status port (BASEADDR+0Ch)
;          Returns   : n/a
;          Destroys  : AL

			push	cx
			xor	cx,cx		; need that for slow SBs !
@@:		 dec	 cx
			jz	@f
			in	al,dx		; AL = WRITE COMMAND STATUS
			or	al,al
			js	@r	 ; Jump if bit7=1 - writing not allowed
@@:		   pop	   cx
ret

 WAITREAD		 :
;          Arguments : DX = Status port   (normaly BASEADDR+0Eh)
;          Returns   : n/a
;          Destroys  : AL

			push	cx
			xor	cx,cx		; need that for slow SBs !
@@:		  dec	  cx
			jz	@f
			in	al,dx		; AL = DATA AVAILABLE STATUS
			or	al,al
			jns	@r	  ; Jump if bit7=0 - no data available
@@:		   pop	   cx
ret

RESET_DSP		:
;          Arguments : n/a
;          Returns   : n/a
;          Destroys  : DX,AL

			mov	 dx,BASEADDR+06h
			mov	 al,1
			out	 dx,al		; start DSP reset

			in	 al,dx
			in	 al,dx
			in	 al,dx
			in	 al,dx		; wait 3 æsec

			xor	 al,al
			out	 dx,al		; end DSP Reset

			add	 dx,08h 	; dx = DSP DATA AVAILABLE
			call WAITREAD
			sub	 dx,4		; dx = DSP Read Data
			in	 al,dx
			cmp	 al,0aah	; if there is a SB then it returns 0AAh
			je	 @f
;                        jmp      RESET_ERROR    ; No SB - exit program
@@:
ret


procSBInit:
call RESET_DSP
	   ; ENABLE SB SPEAKERS (for all SBs <SB16)
	   mov	   dx,BASEADDR+00Ch	       ;DX = DSP Write Data or Command
	   call WAITWRITE
	   mov	   al,0D1h		       ; AL = Enable speaker
	   out	   dx,al		       ; Output: DSP Write Data or Command

	   ; SETUP IRQ :
	   xor	   ax,ax
	   mov	   es,ax		       ; es to page 0 (Interrupt table)
	   mov	   si,IRQ7*4		       ; si = position in interrupt table

	   ; DISABLE IRQ
	   in	   al,021h
	   and	   al,PICANDMASK	       ; SET MASK REGISTER BIT TO DISABLE INTERRUPT
	   out	   021h,al

	   ; CHANGE POINTER IN INTERRUPT TABLE
	   mov	   ax,[es:si]
	   mov	   [OLDInterruptOFS],ax        ; save offset of old interupt vector for restoring
	   mov	   ax,OWN_IRQ
	   mov	   [es:si],ax		       ; set offset of new interrupt routine
	   mov	   ax,[es:si+2]
	   mov	   [OLDInterruptSEG],ax        ; save segment of old interupt vector for restoring
	   mov	   ax,cs
	   mov	   [es:si+2],ax 	       ; set segment of new interrupt routine

	   ; CHANGE PIC MASK :
	   in	   al,021h
	   and	   al,PICANDMASK   ; CLEAR MASK REGISTER BIT TO ENABLE INTERRUPT
	   out	   021h,al
ret

