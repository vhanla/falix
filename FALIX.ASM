;
; Alix - Version 2.0
;
; Version Flatassembler
;
; Autor: vhanla
;

DO_FADE_IN EQU 1
PUNTOS EQU 10 ;PUNTOS POR ALIEN
HERTZ  EQU 20
TIEMPOAGONIZANTE EQU 60 ;TIEMPO DE ANIMACION EN MICROSecs
VELOCIDAD EQU 1 ;Velocidad de Avance
TRUE EQU 1
FALSE EQU 0

;Sound Blaster
BASEADDR    EQU 220h
IRQ7	    EQU 15
DMAChannel  EQU 1
MUSICDELAY  EQU 24
MUSICDELAY2 EQU 14

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



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;   code segment                      ;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
format MZ

entry codigo:start

segment codigo use16
stack 200h
heap 4096

paleta db 768 dup(0)
mpaleta db 768 dup(0)
tiempo db 0
tempo db 0
hora db 0

ALINESX dw 250 dup(?)
ALINESY DW 250 dup(?)
ALINESS DW 250 dup(1); 0=muerto,1=vivo,2=agonizando
; ---------------------------------
BOMBAS	DW 3  ; tres bomas como maximo
BALAS	DW 25 ; numero de balas por nivel
PUNTAJE DW 0  ; AQUI ALMACENAMOS LOS PUNTOS OBTENIDOS
TITULO	   DB 'SUPER RESISTENCIA$'   ; EL TITULO DEL JUEGO QUE SE MOSTRARA EN LA PARTE SUPERIOR
jugador    db 9,0,'         ',36
strJUGADOR DB 'JUGADOR$'
strPUNTAJE DB 'PUNTAJE$'
strVIDAS   DB 'VIDAS$'
strTEMPO   DB 'TIEMPO$'
strBOMBAS  DB 'BOMBAS$'
strBALAS   Db 'BALAS$'
strBOOM    db 'BOOM$'
strNIVEL   DB 'NIVEL $'
NIVELES    DB 10,20,30,40,50,60,70,80,90,100,110,120,130,140,150,160,170,180,190,200
	   DB 210,220,230,240,250 ;total 25 niveles, mas+++ seria aburrido, ademas < 260 (un byte)
NIVEL	   DW 1
;------------------------------------------
unidades dw 1,10,100,1000,10000

include 'images.inc'

VIDAS db 5  ; asignamos 5 vidas para terminar el juego
TEMPO dw 1  ; cronometro de duracion
X_MIRA DW 160 ; MANTIENE LA POSICION DE LA MIRA
Y_MIRA DW 100 ;     ||         ||
LEFT_MOUSE_STATE DB 1; Estado del boton izquierdo del raton 0/1 : libre/presionado
;RIGHT_MOUSE_STATE DB 1;
P_X DW 0
P_Y DW 10
SOUNDMODE dw 0 ; 0 = break it , 1 = wait until finish
COL DB 15  ; ESTE VALOR SE USARA PARA REEMPLAZAR AL COLOR 1 QUE ES LA QUE USAMOS PARA
	    ; DIBUJAR LETRAS

;-----------------
;controlamos la posicion descendiente de los aliens con estos datos
anima db 0 ; usada para comparar cambios de tiempo
anim1 db 0 ;

segundo db 0
LeftToggle		DB	0
RightToggle		DB	0
UpToggle		DB	0
DownToggle		DB	0
FireToggle		DB	0
ExitToggle		DB	0
SoundToggle		DB	0
EnterToggle		DB	0
KeyPress		DB	0

x_spr		dw 10 ; ancho del sprite
y_spr		dw 10 ; alto del sprite
sprite_addr	dw 0 ; posicion del sprite en memoria
OLD9ADDR	Dd ?; B 0,0,0,0
StoreAX 	dw 0

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
puntos_handle dw 0
bufpuntajes:
db 0,0,0,0,0,0,0,0,'$',0,0,0,0
db 0,0,0,0,0,0,0,0,'$',0,0,0,0
db 0,0,0,0,0,0,0,0,'$',0,0,0,0
db 0,0,0,0,0,0,0,0,'$',0,0,0,0
db 0,0,0,0,0,0,0,0,'$',0,0,0,0
db 0,0,0,0,0,0,0,0,'$',0,0,0,0
db 0,0,0,0,0,0,0,0,'$',0,0,0,0
db 0,0,0,0,0,0,0,0,'$',0,0,0,0
db 0,0,0,0,0,0,0,0,'$',0,0,0,0
db 0,0,0,0,0,0,0,0,'$',0,0,0,0
db 0,0,0,0,0,0,0,0,'$',0,0,0,0
db 0,0,0,0,0,0,0,0,'$',0,0,0,0
db 0,0,0,0,0,0,0,0,'$',0,0,0,0
db 0,0,0,0,0,0,0,0,'$',0,0,0,0
db 0,0,0,0,0,0,0,0,'$',0,0,0,0
db 0,0,0,0,0,0,0,0,'$',0,0,0,0
db 0,0,0,0,0,0,0,0,'$',0,0,0,0
db 0,0,0,0,0,0,0,0,'$',0,0,0,0
db 0,0,0,0,0,0,0,0,'$',0,0,0,0
db 0,0,0,0,0,0,0,0,'$',0,0,0,0
scores db 'PUNTOS.DAT',0
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

fMenuFile db 'MENUA.TGA',0
fAlienM db 'ALIMENU.TGA',0
fCreditos db 'CREDITOS.TGA',0
fPuntajes db 'SALON.TGA',0
fAlienigena db 'ALI.TGA',0
fAISystem   db 'AIS.TGA',0
fControls db 'TECLADO.TGA',0
fFondo db 'fondo.tga',0
fGameOver db 'gameover.dat',0
fSoundFile db 'space.voc',0
fMsgSound01 db 'msg01.voc',0
fMsgSound02 db 'msg02.voc',0
fMsgSound03 db 'msg03.voc',0
fMsgSound04 db 'msg04.voc',0
fMenuSound  db 'menu.voc',0
fMenuSound2 db 'menu2.voc',0
fBoomSound db 'boom.voc',0
fOverSound db 'gameover.voc',0
fMenuHandler dw ?
fMenuCounter db 0 ; contador de los frames, sirve para relocalizar
fMenuAnimHandler dw ?
;---------------
;Pruebas
adition dw 0

start:
mov ax,codigo
mov ds,ax
mov dx,fSoundFile
mov [SOUNDMODE],0
call ChangeSound
GOON:
;RUTINA PRINCIPAL - MENU DEL JUEGO [PANTALLA PRINCIPAL]
	mov	ax,13h
	int	10h
	lea	dx,[fAlienM]
	mov	ax,DO_FADE_IN
	call	procLoadTGA

	mov	ah,2 ;gotoxy
	mov	bh,0
	mov	dh,14
	mov	dl,4
	int	10h

	mov	ah,0ah
	mov	dx,jugador
	int	21h
;        call    InstallNewInt9
	mov [P_X],114
	mov [P_Y],58
	call	procFadeOut

	call   sprocMENUIMG
MAIN:
main:
;        call loopmusic;a
	call   procNextFile
;        push    [P_X]
;        mov     ax,[P_Y]
;        mov [COL],49
;        mov [P_X],100
;        call    procWriteNumber
;        pop     [P_X]

	mov [x_spr],14
	mov [y_spr],8

	mov	[sprite_addr],ALINE
	call	procSprite
	call	procVolcarVideoRAM
	mov cx,5
	call	sProcDelay
	call procReadKey
;       TECLAS:
	cmp [DownToggle],1;50h;tecla para abajo
	 jne lblMainTeclaArriba
	 mov [DownToggle],0
	 cmp [P_Y],163-19-10;si ya no hay mas
	 jna lblMenuTecla01
	  mov [P_Y],58-19
	 lblMenuTecla01:
	 add [P_Y],19
	 mov [DownToggle],0
		call  procMenuSound
       lblMainTeclaArriba:
	cmp [UpToggle],1;48h;tecla para arriba
	jne lblMainTeclaEnter
	mov [UpToggle],0
	cmp [P_Y],58+19;si ya no hay mas
	jnb lblMenuTecla02
	 mov [P_Y],163+19-10
	lblMenuTecla02:
	sub [P_Y],19
	mov [UpToggle],0
	       call  procMenuSound
       lblMainTeclaEnter:
	cmp [EnterToggle],1;1ch;al,13
	je CONTINUA_MAIN ; todo esto es
	jmp main;MAIN         ; jne main
       CONTINUA_MAIN:
	push dx
	mov dx,fMenuSound2
	mov [SOUNDMODE],1 ;means to wait until finish the sound
	call ChangeSound
	pop dx
	call procMusic
	mov [EnterToggle],0 ;desactivamos despues de presionar
;       Ahora escogemos el destino de la opcion
	cmp [P_Y],58	 ; JUGAR
	jne opIntro
	 call procMusic
	 call procJUGAR
	 jmp MAIN
       opIntro:
	cmp [P_Y],58+19  ; INTRO
	jne opControles
	 call procINTRO
	 jmp MAIN
       opControles:
	cmp [P_Y],58+19+19 ; CONTROLES
	jne opCreditos
	 call procCONTROLES
	 jmp MAIN
       opCreditos:
	cmp [P_Y],58+19+19+19	 ; CREDITOS
	jne opPuntajes
	 call procCREDITOS
	 jmp MAIN
       opPuntajes:
	cmp [P_Y],58+19+19+19+19    ; PUNTAJES
	jne opSalir
	 call procPUNTAJES
	 jmp MAIN
       opSalir:
	cmp [P_Y],58+19+19+19+19+19    ; SALIR
	je FIN_MENU
	 jmp main;MAIN
;   ---------------------------------------------
    FIN_MENU:
	call procFadeOut
	call sprocCloseMenuIMG
;        call    RemoveNewInt9
	;liberemos el bloque de memoria reservado
;        mov ax,[soundbuffer]
;        mov es,ax
;        mov ah,49h
;        int 21h
	call exit
	mov ax,3
	int 10h
	MOV	AH,4CH
	INT	21H
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
procMenuSound:
	push dx
	mov dx,fMenuSound
	mov [SOUNDMODE],1 ;means to wait until finish the sound
	call ChangeSound
	pop dx
	call procMusic
ret

horacio:
pusha
	mov ah,2ch
	int 21h
	cmp [tempo],dl ;comparamos con el actual
	je siguenomas
	  ;en caso contrario actualizamos
	  mov [tempo],dl
	  cmp [hora],255
	  je bajalo
	   inc [hora]
	   popa
	   ret
	  bajalo:
	   mov [hora],0

siguenomas:
popa
ret

ChangeSound: ;DX=fName
pusha
; primero debemos esperar un tiempo si no ha terminado
cmp [SOUNDMODE],1
jnz normal
cmp [ready],1
jz notyet
normal:
;abrimos el fichero
;mov dx,AX;fSoundFile
mov ax,3d00h
int 21h
jc @noabro
jmp goon
@noabro:
mov ah,4ch
int 21h
goon:
mov [fMenuHandler],ax

mov bx,ax
mov cx,32
mov ah,3fh
mov dx,FreeArea;SoundBuffer
int 21h
;pero como el cabezal no interesa, tonces
;unicamente leemos el contenido
mov cx,15011-32;64000
mov bx,[fMenuHandler]
mov ah,3fh
;push ds
;mov ax,segsound;[soundbuffer]
;mov ds,ax
mov dx,FreeArea
;xor dx,dx ;Directo al comienzo del segmento
int 21h
;pop ds

mov [length_of_sound],ax ; SI ahora funka bien
sub [length_of_sound],10;18000 ; esto es para eliminar el clic del final de sonido
;debemos cerrar el fichero
mov ah,3eh
mov bx,[fMenuHandler]
int 21h
notyet:
popa
ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
procReadKey:
	push ax
	mov [ExitToggle],0
	mov [EnterToggle],0
	mov [UpToggle],0
	mov [DownToggle],0
	mov ah,1
	int 16h
	jz donread
	xor ax,ax
	int 16h
	cmp al,27 ;escape
	jnz @f
	mov [ExitToggle],1
       @@:
	cmp al,13 ;enter
	jnz @f
	mov [EnterToggle],1
       @@:
	cmp ah,48h ;down
	jnz @f
	mov [UpToggle],1
       @@:
	cmp ah,50h ;up
	jnz @f
	mov [DownToggle],1

donread:
	pop ax
ret
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; in: ax=1 : con fadein, ax=0 : sin fadein
procLoadTGA:
   push ax
	call procAbrirArchivo
	mov [fMenuHandler],ax

	mov ax,datos
	xor dx,dx
	mov bx,[fMenuHandler]
	mov cx,18
	call procLeerArchivo
      push ds
	mov ax,codigo;data
	xor dx,dx
	mov bx,[fMenuHandler]
	mov cx,768
	call procLeerArchivo
      pop ds

	mov ax,datos
	xor dx,dx
	mov bx,[fMenuHandler]
	mov cx,64000
	call procLeerArchivo
	mov bx,[fMenuHandler]
	call procCerrarArchivo
 pop ax
      cmp ax,1 ; hay FADEIN o No!!!
      jne nohayfadein
	call procDarkenDAC
	mov ax,datos
	mov bx,0A000h
	mov cx,64000
	xor di,di
	mov si,0
	call procVolcarRAM
	call procFadeIn
      ret
     nohayfadein:
      push ds
	mov ax,codigo;data
	mov ds,ax
	call procRetrazo
	xor ax,ax
	call procCambiarPaleta
      pop  ds

	mov ax,datos
	mov bx,0A000h
	mov cx,64000
	xor di,di
	mov si,0
	call procVolcarRAM

ret

procVolcarVideoRAM:
	mov ax,datos
	mov bx,0A000h
	mov cx,64000
	xor di,di
	xor si,si
	call procVolcarRAM
ret
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
procPUNTAJES:
	push [P_X]
	push [P_Y]
	call procLeePuntajes
	lea dx,[fPuntajes]
	mov ax,DO_FADE_IN
	call procLoadTGA
	call procShowScores
	call procVolcarVideoRAM
	call sprocEnter
	call procFadeOut
	pop  [P_Y]
	pop  [P_X]
ret

procCREDITOS:
	push [P_X]
	push [P_Y]
	lea dx,[fCreditos]
	mov ax,DO_FADE_IN
	call procLoadTGA

	mov [P_X],15
	mov [P_Y],130
	mov [COL],3
	lea ax,[MSG_CRED]
       MOV CX,10
      CRED_TEXT:
       PUSH CX
       PUSH AX
	call procWriteString
	mov cx,20;TIEMPO DE RETARDO
	call sProcDelay
	mov [P_X],15
	ADD [P_Y],5
       POP AX
       POP CX
	ADD ax,74;strAIS11
       LOOP CRED_TEXT
	call sprocEnter
	call procFadeOut
	pop  [P_Y]
	pop  [P_X]
ret
MSG_CRED:
db '        +              +    +  +++++++++++++++++++++++++++++++++++++++++ $'
db '   +    +      +++++    +  +   ++                                     ++ $'
db '  + +   +        +       ++    ++   ALIX] LA GRAN DEFENSA VERSION II  ++ $'
db ' +   +  +        +       ++    ++                                     ++ $'
db ' +++++  +        +      +  +   ++      DESARROLLADO POR VHANLA        ++ $'
db '+     + ++++++   +     +    +  ++                                     ++ $'
db '+     +        +++++           ++   JUNTO A MIS AMIGOS BETO Y DENIS   ++ $'
db '                               ++                                     ++ $'
db '    HTTP][[VHANLA\UP\MD[       ++                                     ++ $'
db '                               +++++++++++++++++++++++++++++++++++++++++ $'


procCONTROLES:
	push [P_X]
	push [P_Y]
	lea dx,[fControls]
	mov ax,DO_FADE_IN
	call procLoadTGA
	call procVolcarVideoRAM
	call sprocEnter
	call procFadeOut
	pop  [P_Y]
	pop  [P_X]
ret

procINTRO:
	push [P_X]
	push [P_Y]
	lea dx,[fAISystem]
	mov ax,DO_FADE_IN
	call procLoadTGA
	mov [P_X],15
	mov [P_Y],130
	mov [COL],69
	lea ax,[strAIS01]
	call procWriteString
	mov cx,HERTZ

	push dx
	mov dx,fMsgSound01
	mov [SOUNDMODE],1 ;means to wait until finish the sound
	call ChangeSound
	pop dx
	call procMusic

	call sProcDelay
	mov [P_X],15
	mov [P_Y],140
	lea ax,[strAIS02]
	call procWriteString

	mov cx,HERTZ
	call sProcDelay
	mov [P_X],15
	mov [P_Y],150
	lea ax,[strAIS03]
	call procWriteString
	mov cx,HERTZ
	call sProcDelay
	mov [P_X],15
	mov [P_Y],160
	lea ax,[strAIS04]
	call procWriteString
	mov cx,HERTZ
	call sProcDelay
	mov [P_X],15
	mov [P_Y],170
	lea ax,[strAIS05]
	call procWriteString

	push dx
	mov dx,fMsgSound02
	mov [SOUNDMODE],1 ;means to wait until finish the sound
	call ChangeSound
	pop dx
	call procMusic

	mov cx,HERTZ
	call sProcDelay
	mov [P_X],15
	mov [P_Y],180
	lea ax,[strAIS06]
	call procWriteString
	mov cx,HERTZ
	call sProcDelay
	;esperamos un poco mas de lo necesario
	call sprocEnter
	call procFadeOut
	lea dx,[fAlienigena]
	mov ax,DO_FADE_IN
	call procLoadTGA
	mov [P_X],15
	mov [P_Y],130
	mov [COL],54
	lea ax,[strAIS07]
	call procWriteString

	push dx
	mov dx,fMsgSound03
	mov [SOUNDMODE],1 ;means to wait until finish the sound
	call ChangeSound
	pop dx
	call procMusic

	mov cx,HERTZ
	call sProcDelay
	mov [P_X],15
	mov [P_Y],140
	lea ax,[strAIS08]
	call procWriteString
	mov cx,HERTZ
	call sProcDelay
	mov [P_X],15
	mov [P_Y],150
	lea ax,[strAIS09]
	call procWriteString
	mov cx,HERTZ
	call sProcDelay
	mov [P_X],15
	mov [P_Y],160
	lea ax,[strAIS0A]
	call procWriteString
	mov cx,HERTZ
	call sProcDelay
	mov [P_X],15
	mov [P_Y],170
	lea ax,[strAIS0B]
	call procWriteString

	push dx
	mov dx,fMsgSound04
	mov [SOUNDMODE],1 ;means to wait until finish the sound
	call ChangeSound
	pop dx
	call procMusic

	mov cx,HERTZ
	call sProcDelay
	mov [P_X],15
	mov [P_Y],180
	lea ax,[strAIS0C]
	call procWriteString
	mov cx,HERTZ
	call sProcDelay

	call sprocEnter
	call procFadeOut
	pop  [P_Y]
	pop  [P_X]
ret
; Datos para la introduccion
strAIS01 db 'AISystem]$'
strAIS02 db 'Se detecto presencia de una horda de aliens cerca del planeta TIERRA$'
strAIS03 db 'segun los analisis de patrones de comportamiento se sospecha que se$'
strAIS04 db 'dirigen hacia aqui con intenciones belicas y se sospecha que son muchos$'
strAIS05 db 'Tu mision es destruir todas las naves que se acerquen a la Universidad$'
strAIS06 db 'para ello cuentas con las municiones necesarias para destruirlos$'

strAIS07 db 'Este es RisBOX DorRoe un criminal intergalactico buscado por muchas$'
strAIS08 db 'organizaciones de inteligencia interespaciales se dice que es muy astuto$'
strAIS09 db 'pero no te preocupes tenemos el armamento necesario para destruir sus$'
strAIS0A db 'naves ya que el equipo de Ingenieria de Sistemas de La UNAP Puno ha$'
strAIS0B db 'desarrollado un algoritmo para evadir las defensas de sus naves por tanto$'
strAIS0C db 'podremos derrotarlos gracias a este equipo$'
; la parte principal del programa
procJUGAR:
	push dx
	mov dx,fSoundFile
	mov [SOUNDMODE],0 ;means to wait until finish the sound
	call ChangeSound
	pop dx

	push [P_Y]
	push [P_X]
	call procLeePuntajes
	lea dx,[fFondo];Puntajes
	mov ax,DO_FADE_IN+1
	call procLoadTGA
	mov ax,datos
	xor di,di
	call procCLS
	call procVolcarVideoRAM

	mov [VIDAS],3
	mov [PUNTAJE],0
	mov [tiempo],0
	mov [BOMBAS],3
	mov [NIVEL],1
	mov bx,35
	call procInicializar
	mov [ExitToggle],0
;-----------------------------------------------------------------------------------------------
    PRINCIPAL:;<----------------------------
	CALL procActualizaSegundos	   ;
	mov  ax,datos
	xor  di,di
	CALL procCLS			   ;
;        CALL procFONDITO                   ;
	lea si,[FONDO]
	mov ax,datos
	mov es,ax
	mov di,48000
	mov cx,8000
	rep movsw
;       FONDITO
; ---------------------------------        ;
;| empezamos a dibujar los sprites |       ;
; ---------------------------------        ;
	call XRATON
	CALL procDibujarAliens		   ;
	;el procedimiento anterior devuelve en AX si se termino en nivel
	cmp ax,1
	jnz CONTINUAR
	  ;procedemos al siguiente nivel
	  ADD [BOMBAS],3 ;mov [BOMBAS],3 ; PA QUE SEA MAS FACIL LO CAMBIE
	  inc [NIVEL]
	  mov bx,35
	  sub bx,[NIVEL]
	  call procInicializar
	  ;pero antes mostramos un mensaje
	  mov [P_X],130
	  mov [P_Y],100
	  mov ax,strNIVEL
	  call procWriteString
	  add [P_X],6
	  mov ax,[NIVEL]
	  call procWriteNumber
	  CALL procVolcarVRam
	  call sprocEnter
	  jmp PRINCIPAL
	CONTINUAR:
	CALL procTeclas 		   ;
	CALL procMainGameText		   ;
					   ;
;---------------------                     ;
; Teclado                                  ;
;---------------------                     ;
       mov [P_X],100
       mov [P_Y],90
       cmp [VIDAS],0
       jne SIGUEJUEGO
	mov [COL],252
	call procGameOver
       SIGUEJUEGO:
	call procRetrazo		   ;
	CALL procVolcarVRam		   ;

	cmp [VIDAS],0
	je FIN
	;musica maestro
;        push dx
;        mov dx,fSoundFile
;        mov [SOUNDMODE],1 ;means to wait until finish the sound
;        call ChangeSound
;        pop dx
	call loopmusic
	call procReadKey		   ;
	cmp [ExitToggle],0		   ;
					   ;
	jnz FIN2
	jmp PRINCIPAL ;-------------------->;
FIN:
	call procReadKey		   ;
	cmp [ExitToggle],0
	jz FIN
FIN2:
	call procOrdenaPosicionPuntos
	call procSaveScores
	mov [EnterToggle],0
	call procFadeOut
	pop  [P_X]
	pop  [P_Y]
ret


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

sprocMENUIMG: ; primero abrimos el fichero de animacion del menu
	mov dx,fMenuFile
	call procAbrirArchivo

	mov [fMenuAnimHandler],ax

	mov ax,datos
	xor dx,dx
	mov bx,[fMenuHandler]
	mov cx,18
	call procLeerArchivo
	mov ax,codigo;data
	mov dx,768;xor dx,dx
	mov bx,[fMenuAnimHandler]
	mov cx,768
	call procLeerArchivo
	mov [fMenuCounter],0
;y lo unico que hacemos es leer la paleta
ret
procNextFile:
	cmp [fMenuCounter],9 ;esperamos a que termine la animacion para poder regresar
       jb nextF
	;en caso de que hayamos rebazado el limite, regresamos a la posicion 18+768
	mov ax,4200h
	mov bx,[fMenuAnimHandler]
	xor cx,cx
	mov dx,18+768
	int 21h
	mov [fMenuCounter],0
       nextF:
	mov ax,datos
	xor dx,dx
	mov bx,[fMenuAnimHandler]
	mov cx,64000
	call procLeerArchivo

	mov ax,datos
	mov bx,0A000h
	mov cx,64000
	xor di,di
	mov si,0
	call procVolcarRAM

	mov ax,768
	call procCambiarPaleta

	inc [fMenuCounter]
ret

sprocCloseMenuIMG:
	mov bx,[fMenuAnimHandler]
	call procCerrarArchivo
ret
;Delay basado en retrazado vertical
;si 60hz = 60veces por segundo
; usada para actualizar la pantalla por
; tiempo determinado
;;;;;mov cx,HERTZ ;tiempo de espera, estandarizado por la pantalla
sProcDelay:
       delay:
	call procRetrazo
	loop delay
	call procVolcarVideoRAM
ret

sprocEnter: ;un loop hasta que se presione la tecla enter
	espera1:
	mov [EnterToggle],0
	call procReadKey
	cmp [EnterToggle],1
	jne espera1
	mov [EnterToggle],0
ret

;Procedimiento que lee el archivo "gameover.dat" para mostrar la
;animacion de GAME OVER
procGameOver:
	     push dx
	     mov dx,fOverSound
	     mov [SOUNDMODE],0 ;0=break
	     call ChangeSound
	     pop dx
	     call waitloop

	mov dx,fGameOver
	call procAbrirArchivo
	mov [fMenuHandler],ax

	mov ax,datos
	xor dx,dx
	mov bx,[fMenuHandler]
	mov cx,18
	call procLeerArchivo
	mov ax,codigo;data
	xor dx,dx
	mov bx,[fMenuHandler]
	mov cx,768
	call procLeerArchivo
	xor ax,ax ; mov ax,offset [paleta]; que su posicion es inicial (0x0000) en .CODE
	call procCambiarPaleta

	mov cx,20;frames del video
       framing:
	push cx
	mov ax,datos
	xor dx,dx
	mov bx,[fMenuHandler]
	mov cx,64000
	call procLeerArchivo

	mov ax,datos
	mov bx,0A000h
	mov cx,64000
	xor di,di
	mov si,0
	call procVolcarRAM
	mov cx,3
	call sProcDelay
	pop cx
       loop framing

	mov bx,[fMenuHandler]
	call procCerrarArchivo
ret
; Procedimiento que hace un fundido a oscuro FADEOUT de la paleta
procFadeOut:
	mov cx,32;64
      bucleFadeOut:
       push cx
	 mov cx,768
	 xor di,di
	bucleFadePalette:
	  mov al,[paleta+di]
	  shr al,2
	  cmp al,1
	 jbe nextFading
	   dec al
	   dec al
	   shl al,2
	   mov [paleta+di],al
	 nextFading:
	   inc di
	loop bucleFadePalette
	 call procRetrazo
	 mov ax,paleta
	 call procCambiarPaleta
       pop  cx
      loop bucleFadeOut
ret
;procedimiento que oscurece toda la paleta DAC
procDarkenDAC:
       ;primero oscurecemos toda la paleta en el DAC mismo
	mov cx,256
       bucleDarkeningDAC:
	mov dx,03c8h
	mov al,cl
	neg al
	out dx,al
	inc dx
	xor al,al
	out dx,al
	out dx,al
	out dx,al
       loop bucleDarkeningDAC
ret
; Procedimiento que hace un fundido de oscuro a la imagen -> FADEIN
procFadeIn:
       mov cx,64
      bucleFADE_IN:
       push cx
	 mov cx,256
	 xor di,di
	bucleFadeIn:
	 mov dx,03c7h ;leeremos desde la dac
	 mov al,cl
	 neg al
	 out dx,al
	 mov dx,03c9h ;rgb
	 in al,dx ;RED
	 mov ah,al ;guardamos RED
	 in al,dx ;GREEN
	 mov bh,al ;guardamos GREEN
	 in al,dx ;BLUE
	 mov bl,al ;guardamos BLUE

	 mov dx,03c8h ;escribiremos al DAC palette
	 mov al,cl
	 neg al
	 out dx,al
	 inc dx
	 mov al,[paleta+di+2]
	 shr al,2
	 cmp ah,al ;comparamos RED Dac con Red Paleta
	 je nextGreen
	  inc ah
	 nextGreen:
	  mov al,ah
	  out dx,al ; ponemos el nuevo valor en el DAC
	 mov al,[paleta+di+1] ;green
	 shr al,2
	 cmp bh,al ;comparamos GREEN DAC con GREEN Paleta
	 je nextBlue
	  inc bh
	 nextBlue:
	  mov al,bh
	  out dx,al ; ponemos el nuevo valor en el DAC
	 mov al,[paleta+di] ; blue
	 shr al,2
	 cmp bl,al
	 je nextDac
	  inc bl
	 nextDac:
	  mov al,bl
	  out dx,al ; ponemos el nuevo valor en el DAC
	 add di,3
	loop bucleFadeIn
	 call procRetrazo ;hacemos una pequeña demora
       pop cx
       loop bucleFADE_IN
ret

; ALGORITMOS.INC vhl

;:;;;:;:;:;:;:;:
; mis algoritmos
;:;:;:;:;:;:;;:;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

procActualizaSegundos:
	MOV	AH, 2CH
	INT	21H
	MOV	[anima], DL

;actualizamos el cronometro
	mov	ah,dh
	cmp	ah,[segundo]
	jz	noActualizarElTiempo ;----------------->;
	 inc	[TEMPO]; contar segundos                ;
	 mov	 [segundo],ah				;
       noActualizarElTiempo:;<--------------------------;

ret

; Primero inicilializamos la posicion de los sprites alien
; en BX=el espacio de alien en alien; limitamos a un espacio maximo de 100 pixels
; por razones de comodidad, y tb evitar el que se sobre pase el limite de 2 bytes con signo
procInicializar:
	;evitamos que sea mayor de 100 pixels el espacio maximo entre aliens en Y
	cmp bx,100
	jb InicializaR
	;si es mayor, lo bajamos al maximo permitido
	 mov bx,100
       InicializaR:
	mov cx,250 ;aliens a inicializar
	xor di,di
	xor ax,ax
       InicializaX:
	;128,64,32,16,8,4,2,1
	push ax
	call procRandom ;obtenemos en DX el valor aleatorio
	pop ax ;puesto que el procedimiento Aleatorio modifica AX
	;unicamente utilizamos DL para el area de la pantalla en X
	add dx,100
	mov byte [ALINESX+di],DL ;ponemos un byte en la parte LITTLE
	mov word [ALINESY+di],AX
	push bx
	push di
	mov di,[NIVEL] ;averiguamos el nivel en el que estamos
	dec di ;pero como el primero debe apuntar a 0 en el offset, decrementamos
	xor bx,bx;ponemos bh=0
	mov bl,byte [NIVELES+di] ;obtenemos el numero de aliens para este nivel
      push ax
	mov ax,bx
       push cx
	mov cl,4
	div cl;la cuarta parte es el 25 por ciento, retorna el cociente en al
	;ahora ponemos el numero de balas
	mov [BALAS],bx
	and AX,00FFH ;convertimos AH en ceros
	add [BALAS],AX
       pop cx
      pop ax
	pop di
	shl bx,1;multiplicamos bx por 2 para compararlo con di
	cmp di,bx;vemos que no sea el alien mayor de lo deseado
	jae noqueremos
	mov word [ALINESS+Di],1;estos participan
	jmp queremos
	noqueremos:
	mov word [ALINESS+DI],0;no participan
	queremos:
	pop bx
	add di,2
	sub AX,BX ; restamos el espacio requerido
       loop InicializaX

ret
; MOVIMIENTO ALEATORIO EN X
procMoverAlienX:
RET;deshabiltado
;        call procRandom ;utilizamos el procedimiento Random para poder
;                        ;decidir el movimiento aleatorio en X
;        test dx,1 ;vemos si es par o impar, y nos basamos en eso para
;                  ;mover a la derecha o izquierda
;        jz MoverImpar ;nos movemos a la izquierda si es impar
;         ;sino a la derecha
;         ;pero antes debemos evitar que el alien desaparezca a los lados
;         cmp word ptr[ALINESX+di],304 ;319-14(ancho del alien)-1
;         jg NoMoverXDer
;          add word ptr[ALINESX+di],2
;         NoMoverXDer:
;        MoverImpar:
;         cmp word ptr[ALINESX+di],1 ;el primer pixel a la izquierda de la pantalla
;         jl NoMoverXIzq
;          dec word ptr[ALINEsX+Di]
;         NoMoverXIzq:
;ret
; DESCENSO DEL ALIEN
procBajarAlien:
	mov cx,250
	xor di,di
       BajandoX:
	push cx
	 mov cx,[NIVEL]
	 add word [ALINESY+di],cx;VELOCIDAD
	 add di,2
	pop cx
       loop BajandoX
ret

; BOMBARDEO
procBombardear:
 ; primero bajamos el numero de bombas
	cmp [BOMBAS],0
	JA MATADERO
	 ret
       MATADERO:
	dec [BOMBAS]
	mov cx,250
	xor di,di
       BombasAPantalla:
	cmp [ALINESY+DI],200
	Jg NOMATAR
	 cmp [ALINESY+DI],-8
	 jl NOMATAR
	 cmp [ALINESS+DI],1 ;matamos si esta vivo, obviamente
	 jnz NOMATAR
	  add [PUNTAJE],PUNTOS
	  mov [ALINESS+DI],TIEMPOAGONIZANTE ;estado agonizante
	NOMATAR:
	add di,2
       loop BombasAPantalla
ret
;-----------------------------------------------------------------------------------------------
procAnimacionSprite:
	cmp	[anima],60
	jb next ;------------>;
;        mov     [anima],0   ;
	next:;<----------------

	cmp	[anima],50
	jb	next1 ;-------------------------->;
	  MOV	  [sprite_addr],ALINE		  ;
	  jmp	  ANIMAEND ;----------------------+----->;
	next1:;<----------------------------------;      ;
	cmp	[anima],30			       ;
	jb  next2 ;------------------------------>;      ;
	  mov	  [sprite_addr],ALINE2		  ;      ;
	  jmp	  ANIMAEND ;----------------------+----->;
	next2:;<----------------------------------;      ;
	cmp	[anima],0			       ;
	jb ANIMAEND;----------------------------->;      ;
	  mov	  [sprite_addr],ALINE3		  ;      ;
	ANIMAEND:;<--------------------------------------;
RET
procAnimacionSpriteMuriendo:
	cmp	[anima],60
	jb dnext ;------------>;
;        mov     [anima],0   ;
	dnext:;<----------------

	cmp	[anima],50
	jb	dnext1 ;-------------------------->;
	  MOV	  [sprite_addr],ALINE4		   ;
	  jmp	 dANIMAEND ;----------------------+----->;
	dnext1:;<---------------------------------;      ;
	cmp	[anima],30			       ;
	jb  dnext2 ;----------------------------->;      ;
	  mov	  [sprite_addr],ALINE5		  ;      ;
	  jmp	 dANIMAEND ;----------------------+----->;
	dnext2:;<---------------------------------;      ;
	cmp	[anima],0			       ;
	jb dANIMAEND;---------------------------->;      ;
	  mov	  [sprite_addr],ALINE6		  ;      ;
	dANIMAEND:;<-------------------------------------;
RET

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
procDibujarAliens:
	mov	ah,[anima]
	cmp	ah,[anim1]
	jz	nobajar ;----------------->;
	 call procBajarAlien
	 mov	 [anim1],ah		   ;
       nobajar:;<--------------------------;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	mov cx,250 ;aliens
	xor di,di
	xor ax,ax ;en ax veremos si todos los aliens han muerto
	DRAWIT:
	 add ax,[ALINESS+di] ;sumamos los estados de los aliens
	 push ax
	;.................................                ;+     ;+
	; ANTES DE DIBUJAR DEBEMOS VERIFICAR SI EL        ;+     ;+
	; SPRITE NO FUE ELIMINADO                         ;+     ;+
	;:::::::::::::::::::::::::::::::::::::::::::      ;+     ;+
	CALL procFueEliminado;+                           ;+     ;+
	pop ax
	add di,2
	LOOP DRAWIT
	;ahora veremos si terminamos el nivel al comprobar ax=0, cuando todos han muerto
	cmp ax,0 ;retornamos la respuesta en ax
	jne NivelNoCompletado
	mov ax,1 ;verdad
	ret
	NivelNoCompletado:
	xor ax,ax
ret
;--------------------------
procFueEliminado:
	CMP word [ALINESS+di],0 ; SI ES IGUAL A 0 QUIERE DECIR QUE YA MURIO
	JNZ VIVOONO ;----------------------------------------------->;
	  ret							    ;
	VIVOONO:
	CMP word [ALINESS+di],1 ;ver si esta vivo todavia
	JZ NOMURIO
	  ;en caso de haber estado en estado de moribundo, pasar al estado de muerto
	  cmp word [ALINESS+DI],2 ;vemos si termino su tiempo de agonizar
	  JZ HORADEMORIR
	   dec word [ALINESS+DI]
	   JMP DIBUJAR_ALIEN_XY
	  HORADEMORIR:

	push dx
	mov dx,fSoundFile
	mov [SOUNDMODE],1 ;means to wait until finish the sound
	call ChangeSound
	pop dx

	  MOV [ALINESS+DI],0
	  ret
	NOMURIO:;<--------------------------------------------------;
	; SI ES CERO(esta muerto) NO DIBUJAMOS
	cmp [ALINESY+di],200-8 ; vemos que no se haya pasado de la tierra  ;
	jl noATERRIZO ;---------------------------------;
	CMP [VIDAS],0					;
	JL GAMEOVER ;---------->;                       ;
	DEC [VIDAS]		;                       ;
	JMP LIVING ;------------+----------;            ;
	GAMEOVER: ;<------------;          ;            ;
	MOV [VIDAS],0			   ;            ;
	LIVING: ;<-------------------------;            ;
	MOV [ALINESS+Di],0				;
	noATERRIZO:;<-----------------------------------;

  ;vemos que estemos disparando
	cmp [FireToggle],0
	jz nofire  ;---------------------------------------->;
     ;si esta presionado                                     ;
	mov ax,[X_MIRA] 				     ;
	add ax,5
	mov bx,[ALINESX+DI]
	cmp ax,bx					     ;
	jb fueradealcance ;------------------------>;        ;
	add bx,14
	cmp ax,bx				    ;        ;
	ja fueradealcance ;------------------------>;        ;
	mov ax,[Y_MIRA] 				     ;
;        add ax,10
	 mov bx,[ALINESY+DI]
	 cmp ax,bx				    ;        ;
	 jb fueradealcance ;----------------------->;        ;
	   add bx,8
	   cmp ax,bx				    ;        ;
	   ja fueradealcance ;--------------------->;        ;
	     CMP [BALAS],0
	     JE fueradealcance
	     push dx
	     mov dx,fBoomSound
	     mov [SOUNDMODE],1 ;0=break
	     call ChangeSound
	     pop dx
	     call waitloop
	     ;si esta en el area matamos el alien   ;        ;
	     MOV [ALINESS+DI],TIEMPOAGONIZANTE	    ;        ;
	     ADD [PUNTAJE],PUNTOS		    ;        ;
	fueradealcance: ;<--------------------------;        ;
   nofire: ;<------------------------------------------------;
   DIBUJAR_ALIEN_XY:
	mov ax,[ALINESX+DI]
	mov [P_X],ax
	mov ax,[ALINESY+DI]
	mov [P_Y],ax
	mov [x_spr],14
	mov [y_spr],8
	push cx
	push di
	call procMoverAlienX
	cmp [ALINESS+DI],1
	jne VIVEAUN
	call procAnimacionSprite
	jmp QUIENSABE
	VIVEAUN:
	 sub [P_Y],8
	 push [P_X]
	 mov ax,strBOOM
	 call procWriteString
	 pop [P_X]
	 add [P_Y],8
	 call procAnimacionSpriteMuriendo
	QUIENSABE:
	CALL procSprite
	pop di
	pop cx
ret

;-----------------------------------------------------------------------------------------------

procVerVidas:
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;DIBUJAMOS LAS VIDAS
   xor cx,cx
   MOV CL,[VIDAS]
   MOV [x_spr],5
   MOV [y_spr],4

   JCXZ VIDA
  VIDASs:
    MOV [sprite_addr],CORAZON
    CALL procSprite
    ADD [P_X],6
    LOOP VIDASs
  VIDA:

ret

procTeclas:

	MOV	AX,[X_MIRA]
	mov [P_X],ax
	sub [P_X],4
	mov	ax,[Y_MIRA]
	mov [P_Y],ax
	sub [P_Y],7
       cmp [FireToggle],0
       jz disparo
	mov	[sprite_addr],MIRA_ON
	 cmp	 [BALAS],0
	 JE NoQUITARBalas
	  dec	  [BALAS]
	 NoQUITARBalas:
	jmp noshot
       disparo:
	mov	[sprite_addr],MIRA
       noshot:
	mov	[FireToggle],0
	mov	[x_spr],10
	MOV	[y_spr],8
       right:
	cmp [RightToggle],0
	jz left
	cmp [X_MIRA],315
	ja left
	inc [X_MIRA]
       left:
	cmp [LeftToggle],0
	jz down
	cmp [X_MIRA],7
	jb down
	dec [X_MIRA]
       down:
	cmp [DownToggle],0
	jz up
	cmp [Y_MIRA],194
	ja up
	inc [Y_MIRA]
       up:
	 cmp [UpToggle],0
	 jz enterkey
	 cmp [Y_MIRA],4
	 jb enterkey
	 dec [Y_MIRA]
       enterkey:
	 cmp [EnterToggle],0
	 jz nokeys
	 mov [EnterToggle],0
	 call procBombardear
       nokeys:
;---------------------
	CALL	procSprite
	;debemos desactivar el disparo
ret


procMainGameText:
	MOV [P_X],120
	MOV [P_Y],2
	LEA  AX, [TITULO]
	MOV  [COL],249
	CALL procWriteString

	MOV [P_X],10
	MOV [P_Y],8
	LEA AX,[strJUGADOR]
	MOV  [COL],246
	CALL procWriteString
	LEA AX,[jugador]
	ADD AX,2
	ADD [P_X],6
	CALL procWriteString

	MOV [P_X],100
	LEA AX,[strPUNTAJE]
	CALL procWriteString
	ADD [P_X],6
	mov ax,[PUNTAJE]
	call procWriteNumber

	MOV [P_X],150
	LEA AX,[strTEMPO]
	CALL procWriteString
	add [P_X],5
	mov ax,[TEMPO]
	call procWriteNumber

	MOV [P_X],250
	LEA AX,[strVIDAS]
	CALL procWriteString

	CALL procVerVidas
; parte de abajo
	MOV [P_Y],200-8
	MOV [P_X],10
	LEA AX,[strBOMBAS]
	CALL procWriteString
	ADD [P_X],6
	mov ax,[BOMBAS]
	call procWriteNumber

	MOV [P_X],100
	LEA AX,[strBALAS]
	CALL procWriteString
	ADD [P_X],6
	mov ax,[BALAS]
	call procWriteNumber

	MOV [P_X],250
	LEA AX,[strNIVEL]
	CALL procWriteString
	ADD [P_X],6
	mov ax,[NIVEL]
	call procWriteNumber


RET



;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°

procVolcarVRam:
	PUSH	DS ;+;+;+;+;+;+;+;+;+;+;+;+;+;+;+;+;+;+;+;+
	MOV AX,datos;@data;word ptr [VideoBuffer];@data;CS     ;+
	MOV DS,AX					 ;+
	LEA SI,[VideoBuffer]				 ;+
;xor si,si                                               ;+
							 ;+
	MOV	AX,0A000H				 ;+
	MOV	ES,AX					 ;+
	XOR	DI,DI					 ;+
	MOV	CX,32000				 ;+
	REP	MOVSW					 ;+
	POP	DS ;+;+;+;+;+;+;+;+;+;+;+;+;+;+;+;+;+;+;+;+
	RET

;
; DISC.INC - procedimientos para abrir ficheros
;
;
;
; Procedimientos:
; - procAbrirArchivo
; - procCerrarArchivo
; - procLeerArchivo

;IN DX=offset del nombre del archivo, formato 8.3 terminando en byte 0
;OUT: retorna en AX el manejador y el BX retorna el valor booleano
procAbrirArchivo:
	mov	ax, 3d00h ;solo lectura
	int	21h
	jc	lblNoAbrio
	mov	bx, TRUE
	ret
 lblNoAbrio:
	mov	bx, FALSE
ret

; nota: siempre debemos cerrar el fichero abierto para no ver
;       resultados indeseados
; IN BX=handle (manejador)
procCerrarArchivo:
	mov	ah, 3eh
	int	21h

ret

;IN: AX=segmento; DS:DX puntero de buffer
;    BX=manejador, CX=cantidad de bytes a leer
;OUT: AX cantidad de bytes leidos
procLeerArchivo:
	push	ds
	mov	ds, ax
	mov	ah, 3fh
	int	21h
	pop	ds
ret



;-----------------------------------------------------------------------------------------------
; AVERIGUA LAS COORDENADAS DEL MOUSE EN X_MOUSE e Y_MOUSE /2
XRATON:

		MOV	AX,3
		INT	33H	;ACTIVA EL MOUSE
		SHR	CX,1 ; MUEVE UN BIT A LA DERECHA (DIVIDE A CX ENTRE 2)

		MOV  [X_MIRA],CX
		MOV  [Y_MIRA],DX

		TEST	 BX,1 ; AVERIGUAMOS SI SE PRESIONA EL BOTON IZQUIERDO
		JZ @XRATON ;------------------------------>
		; primero debemos ver que el boton no haya estado presionado
		cmp [LEFT_MOUSE_STATE],1 ; si el boton esta presionado
		jz @XNOLEFT
		mov [LEFT_MOUSE_STATE],1
		mov [FireToggle],1			  ;
;                call waitloop
		@XNOLEFT:
		RET					  ;
	       @XRATON:;<---------------------------------;
		mov [LEFT_MOUSE_STATE],0
		mov  [FireToggle],0
		RET

;-----------------------------------------------------------------------------------------------
; SB - Procedimiento de Sonido
;-----------------------------------------------------------------------------------------------
procMusic:
	pusha
	mov	[ready],0
;------------------------------------------------------------------------------
; calculate page and offset for DMAcontroller :
;
; segment*16+offset - 20bit memory location -> upper 4 bits  = page
;                                              lower 16 bits = offset
;------------------------------------------------------------------------------
	   mov	   si,FreeArea
;           xor     si,si
	   mov	   cx,[length_of_sound];SAMPLEBUFFERLENGTH-1

	   mov	   ax,ds;segsound;[SoundBuffer];ds
	   rol	   ax,4 	       ; * 16 - higher 4 bits in al
	   mov	   bl,al
	   and	   bl,00fh	       ; BL - higher 4 bits
	   and	   al,0f0h	       ; clear higher 4bits in AL
	   add	   si,ax	       ; SI = offset
	   adc	   bl,0 	       ; BL = page
;------------------------------------------------------------------------------
; check for DMApage override :
; ... problem: DMA controller separates memory into 64KB pages, you can only
; transfer data is placed in one page - no page overrides are allowed
;------------------------------------------------------------------------------
; To solve that :
; creat a DMA buffer with double size you want - if the first part is placed
; on a page border the second part is for sure not
;------------------------------------------------------------------------------
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
popa
ret

loopmusic:
	call horacio
	cmp [hora],MUSICDELAY
	jne ffff
	 call waitloop
	 mov [hora],0
  ffff:
ret
;loopmusica:
;        call horacio
;        cmp [hora],MUSICDELAY2
;        jne fff
;         call waitloop
;         mov [hora],0
;  fff:
;ret


waitloop:
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
	call procMusic

	   cmp	   [ready],1		       ; sample still playing ?
	   jz	   waitloop		       ; not ! return to waitloop

	   ; NOW HALT PLAYING :
	   mov	   dx,BASEADDR+0Ch
	   call WAITWRITE
	   mov	   al,0d0h		       ; AL = DSP halt 8bit DMA
	   out	   dx,al

	   ; CONTINUE PLAYING :
	   mov	   dx,BASEADDR+0Ch
	   call WAITWRITE
	   mov	   al,0d4h		       ; AL = DSP continue 8bit DMA
	   out	   dx,al
ret

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
procRestoreIRQ:
	   ; RESTORE IRQ :
	   xor	   ax,ax
	   mov	   es,ax		       ; es to page 0 (Interrupt table)
	   mov	   si,IRQ7*4
	   mov	   ax,[OLDInterruptOFS]
	   mov	   [es:si],ax		       ; set old interrupt routine
	   mov	   ax,[OLDInterruptSEG]
	   mov	   [es:si+2],ax
ret

OWN_IRQ:
	push ax
	push dx
	push ds
	mov dx,BASEADDR+00Eh
	in  al,dx
	mov ax,ds
	mov ds,ax
	mov [ds:ready],1
	mov al,020h
	out 020h,al
	pop  ds
	pop  ds
	pop  ax
IRET

ready db 0
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
length_of_sound dw ?
OLDInterruptOFS dw ?
OLDInterruptSEG dw ?
;
; Biblioteca de Procedimientos para el manejo de memoria
;
;
; ------------------------------------------------------
; Procedimientos:
procVolcarRAM:
	push	ds
	mov	ds, ax
	mov	es, bx
	rep	movsb
	pop	ds
ret

;::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
; HIGH SCORES . Puntajes mas altos
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

procLeePuntajes:
;abrimos el archivo usando un manejador
	mov	ax, 3d00h
	lea	dx, [scores]
	int	21h
	jc	noabrio
	mov	[puntos_handle], ax
;leemos los datos en el buffer puntos
	mov	cx, 10
	mov	si, 13 ;posicion inicial de lectura
     intercala:
	push	cx
	mov	ah, 3fh
	mov	bx, [puntos_handle]
	mov	dx, bufpuntajes
	mov	cx, 13
	add	dx, si
	int	21h
	add	si, 13+13;saltamos una linea
	pop	cx
	loop	intercala
; ahora debemos cerrar el fichero
	mov	ah, 3eh
	mov	bx, [puntos_handle]
	int	21h
     noabrio:
ret

;-----------------------------------------------------------------------------------------------
procShowScores: ;muestra los puntajes

	MOV	CX, 10 ;10 famosos por defecto
	MOV	[P_Y], 50 ;posicion Y inicial
	MOV	[COL], 255 ;color para el texto
	push	si
	mov	si, 13
       MOSTRAT_PUNTOS:
	cmp	word [bufpuntajes+si],0 ;comparamos si existe
	jne	continuemoastradas
	;caso contrario terminamos
	pop	si
	ret
     continuemoastradas:
	push	cx
	MOV	[P_X], 100
	LEA	AX, [bufpuntajes+si];jugador
	push	si
	CALL	procWriteString
	pop	si
	MOV	[P_X], 140+10
	mov	ax, word [bufpuntajes+si+9]
	call	procWriteNumber
	MOV	[P_X], 185+20
	mov	ax, word [bufpuntajes+si+11]
	call	procWriteNumber
	add	si, 26;saltando una linea de 13
	add	[P_Y], 10
	pop	cx
	LOOP	MOSTRAT_PUNTOS
	pop	si

RET


procRandom:
	 mov ax,123h;2006
	 mov dx,ax
	 not dx
	 shl dx,2
	 add ax,dx
	 shr dx,1
	 add ax,dx
	 rol ax,5
	 mov word [procRandom+1],ax ; reemplazamos mov ax,123h por otro mov ax,[otro]
	 mov dx,ax
	 ret

;----------------------------------------------------------------------------------------------+
; Con esta funcion se dibujan las letras _(5x5)_                                               |
;----------------------------------------------------------------------------------------------+
; EL OFFSET DE LA CADENA SE LE PASA A AX ANTES DE LLAMAR A ESTE PROCEDIMIENTO
; P_X Y P_Y DEBEN TENER LA COORDENADA TB - POR AHORA SOLO ACEPTA MAYUSCULAS 64-90 (A - Z)
procWriteString:
	push [x_spr]
	push [y_spr]

	MOV [x_spr],3
	MOV [y_spr],5
	MOV SI,AX
       READ:
	LODSB ; AL = DS:SI
	CMP AL,'$' ; VEMOS QUE NO SEA FIN DE CADENA
	JZ WRITE_NOT
	CMP AL,' ' ; VER SI HEMOS PUESTO UN ESPACIO
	JNZ NO_HAY_ESPACIO
	 ADD [P_X],4 ; NOS MOVEMOS 4 PIXELES A LA DERECHA
	 JMP READ  ; PASAMOS A LEER EL SIGUIENTE CARACTER
	NO_HAY_ESPACIO:

	CMP AL,13 ; VER SI HEMOS PUESTO UN ENTER
	JNZ NO_HAY_ENTER
	 ADD [P_X],4 ; NOS MOVEMOS 4 PIXELES A LA DERECHA
	 JMP READ  ; PASAMOS A LEER EL SIGUIENTE CARACTER
	NO_HAY_ENTER:

	; SINO EMPEZAMOS A DIBUJAR - OJO NO HAY PREVENSION DE QUE SEA MENOR DE 64 Y 90
	; PUES NO LO NECESITAMOS
	XOR CX,CX
	MOV CL,AL ; COPIAMOS EL VALOR DEL CARACTER ASCII
       cmp cl,96
       jb minuscula
	SUB CL,32 ;le restamos 33+64 = 97
       minuscula:
	SUB CL,64 ; RETROCEDEMOS 64 PUESTO QUE CONSIDERAREMOS LETRAS:0 COMO A Y :1 COMO B ...
 ; EN AQUI ESTAN LAS IMAGENES QUE USAREMOS, EL PRIMERO ES A
	MOV [sprite_addr],Alfabeto;bx
       SEEK:
	ADD [sprite_addr],15
	LOOP SEEK
	SUB [sprite_addr],15
	PUSH CX ;+;+;+;;+
	CALL procSprite;+
	POP CX	;+;+;+;;+
	ADD [P_X],4
	jmp READ
       WRITE_NOT:
	pop [y_spr]
	pop [x_spr]
	RET
;----------------------------------------------------------------------------------------------+
; Con esta funcion se convierte numero a texto y luego se imprime                              |
;----------------------------------------------------------------------------------------------+
; SE PASA EL VALOR A IMPRIMIR EN AX OJO: NO ACEPTA NUMEROS NEGATIVOS POR AHORA
; PARA 2 BYTES
procWriteNumber:
	mov cx,4
	cmp ax,10
	jb  PRINT_NOW
dibuja_num:  ;<===================================================================;;
	mov di,cx								  ;;
	shl di,1								  ;;
	CMP AX,word [unidades+di]					       ;;
	JB next_num  ;--------------------------------------------------------->; ;;
	  MOV BX,word [unidades+di]					     ; ;;
	  push cx  ;+;+;+;+;+;+;+;+;+;+;+;+;+;+                                 ; ;;
	  mov dx,cx ;contador de digitos     ;+                                 ; ;;
	    CALL CUENTA_DIGITOS 	     ;+                                 ; ;;
	  pop cx ;+;+;+;+;+;+;+;+;+;+;+;+;+;+;+                                 ; ;;
	    cmp ax,0 ; nos aseguramos de que si quedan ceros (1000) u otro      ; ;;
	    jne next_num;MILLARES ;por tanto ;--------------------------------->; ;;
	    printceros: 							; ;;
	      push cx  ;+;+;+;+;+;+;+;+;+;+;+;+;+;+;+;+;+;+;+;+;+;+             ; ;;
		mov cx,0 ; cx=0                                  ;+             ; ;;
		call PRINT_NUM ; modifica y_spr,x_spr,P_X        ;+             ; ;;
	      pop cx ;+;+;+;+;+;+;+;+;+;+;+;+;+;+;+;+;+;+;+;+;+;+;+             ; ;;
	    loop printceros							; ;;
	  ret									; ;;
	next_num: ;<------------------------------------------------------------- ;;
	  cmp cx,2;ax,10 ; vemos que si el valor encontrado es menor a 10         ;;
	  jb PRINT_NOW	 ;----------------------;                                 ;;
	  cmp ax,10				;                                 ;;
	  jae continua ;------------>;          ;                                 ;;
	   push cx  ;+;+;+;+;+       ;          ;                                 ;;
	   mov cx,0	    ;+       ;          ;                                 ;;
	   call PRINT_NUM   ;+       ;          ;                                 ;;
	   pop cx ;+;+;+;+;+;+       ;          ;                                 ;;
	  continua: ;<---------------;          ;                                 ;;
	  loop dibuja_num ;======================================================>;;
	  ret					;
						;
       PRINT_NOW: ;<----------------------------;
	mov cx,ax
	call PRINT_NUM
	RET

CUENTA_DIGITOS:
	XOR CX,CX ; CONTADOR IGUAL A CERO
       looper: ;<-------------------------------------------------;
	INC CX							  ;
	SUB AX,BX ; RESTAMOS                                      ;
	CMP AX,BX ; VEMOS QUE NO BAJE EL NUMERO DE DIGITOS        ;
	JAE looper ;volvemos a restar si es mayor o igual ;------>;
	call PRINT_NUM
	ret
PRINT_NUM:
       mov [x_spr],3
       mov [y_spr],5
	mov [sprite_addr],NUM; vamos a dibujar el numero
	jcxz notpu ; si el contador es CERO, tonces no pasamos al siguiente digito ;
       sig_digito:								   ;
	add [sprite_addr],15 ; el siguiente digito                                 ;
       loop sig_digito								   ;
       notpu:  ;<------------------------------------------------------------------;
	push ax ; +;+;+;+;+;+;+;+;+
	PUSH CX ; +;+;+;+        ;+
	call procSprite;+        ;+
	POP CX	; +;+;+;+        ;+
	pop ax	; +;+;+;+;+;+;+;+;+
	add [P_X],5
	ret

;----------------------------------------------------------------------------------------------+
; Con esta funcion se dibuja un sprite                                                         |
; se necesita poner el offset en "sprite_addr"                                                 |
; P_X,P_Y,x_spr y y_spr son X,Y,ancho y alto respectivamente;                                  |
; usamos COL para poner el color que reemplazara al valor 1                                    |
;----------------------------------------------------------------------------------------------+
procSprite:
	PUSH	CX
	PUSH	BX
	PUSH	[P_Y] ; guardamos la coordenada Y inicial
	XOR	BX,BX ; offset del sprite

	MOV	CX,[y_spr]; 8 VECES
      @J:
	PUSH	CX
	PUSH	[P_X]
	INC	[P_Y]

	MOV	CX,[x_spr]; 8 VECES

      @I:
	INC	[P_X]
	PUSH	BX ;+;+;+;+;+;+;+;+;+;+;+;+;+
					   ;+
	push	di ;+;+;+;+;+;+;+;+;+      ;+
	mov	di,bx		   ;+      ;+
	mov	bx,[sprite_addr]   ;+      ;+
				   ;+      ;+
	MOV	AH,[BX+DI]	   ;+      ;+
	pop	di ;+;+;+;+;+;+;+;+;+      ;+
					   ;+
	MOV	DL,AH			   ;+
	CMP	DL,0			   ;+
	JZ NODIBUJA ;--------------->;     ;+
	CMP	DL,1		     ;     ;+
	JNZ PUNTEA ;------>;         ;     ;+
	MOV	AH,[COL]   ;         ;     ;+
	MOV	DL,AH	   ;         ;     ;+
       PUNTEA: ;<----------;         ;     ;+
	CALL	procPunto	     ;     ;+
       NODIBUJA: ;<------------------;     ;+
					   ;+
	POP	BX ;+;+;+;+;+;+;+;+;+;+;+;+;+
	INC	BX
	LOOP	@I

	POP	[P_X]
	POP	CX
	LOOP	@J

	POP	[P_Y] ; recuperamos el valor inicial de la posicion vertical
	POP	BX
	POP	CX
	RET



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
procSaveScores: ;guardamos los puntajes, incluyendo el obtenido,
	     ;si es que supera a los otros, colocandolo en la
	     ;posicion que deseada
push di
mov ah,3ch
xor cx,cx    ;cx=0 modo de escritura, si existe el archivo lo
	     ;eliminamos y lo vuelve a crear(vaciar)
mov dx,scores ;guardamos en el archivo DATOS.DAT
int 21h
jc @err
mov [puntos_handle],ax
;tenemos que guardar 10 datos (nombre+puntaje+tiempo)
mov cx,20 ;veinte comparaciones, pues el bufer es de esa cantidad
xor di,di ;puntero a los datos
xor ax,ax ;contamos 10 veces, solo queremos los 10 primeros
guardarscores:
 cmp word [bufpuntajes+di],0 ;vemos que haya algo escrito ahi
 je siguientedato
  ;entonces, podemos ahora guardar 13 bytes en el disco "puntos.dat"
  push cx
  mov cx,13;13 (bytes)
   push ax
   mov ah,40h ;escribir al fichero
   mov bx,[puntos_handle]
   lea dx,[bufpuntajes+di];posicion actual
   int 21h
   pop ax
   inc ax;contamos
  pop cx
 siguientedato:
 add di,13 ;siguiente estructura de datos
 cmp ax,10 ;si llegamos a los 10 datos, entonces terminamos de guardar
 je cerrararchivos
loop guardarscores
;cerramos el archivo, antes de terminar
cerrararchivos:
mov ah,3eh
mov bx,[puntos_handle]
int 21h
@err:
pop di
ret


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
procOrdenaPosicionPuntos: ;colocamos los nuevos puntajes
push di
xor di,di ;indice de busqueda , de 13 en 13, donde se
	  ;encuentra el valor del puntaje actual, pero
	  ;antes debemos ver si en esa posicion hay un valor
	  ;de puntaje con el que se deba comparar
mov cx,10 ;hacemos diez comparaciones por defecto
coparar:
 ;es decir los primeros 13=0,luego +9=22
 ;es donde si hay un valor

 ;si hay un valor, por tanto comparamos
 mov ax,[PUNTAJE] ;usamos ax
 cmp ax,word [bufpuntajes+di+22]
 jb nextcomparison ;comparamos con el siguiente
   ;si es igual o mayor, entonces colocamos los datos en el bufer actual DI
   ;pero antes debemos ver que si es igual el puntaje, entonces el tiempo debe
   ;ser minimo para considerarlo superior
    jne noesigualpunto
    mov bx,[TEMPO]
    cmp bx,word [bufpuntajes+di+24];comparamos los tiempos
    ja nextcomparison
    noesigualpunto:
    mov word [bufpuntajes+di+9],ax ;ponemos los puntos actuales
    mov byte [bufpuntajes+di+8],'$'
    mov ax,[TEMPO];guardamos tambien el tiempo
    mov word [bufpuntajes+di+11],ax
    push si
    xor si,si
    mov cx,8 ;8 letras por jugador+$
    copianombre:
     mov bl,byte [jugador+si+2];copiamos las letras del nombre
     push si
     add si,di
     mov byte [bufpuntajes+si],bl
     pop si
     inc si
    loop copianombre
    pop si
    ;notese que ya no es necesario comparar con los otros datos, asi que salimos
    pop di
    ret
nextcomparison:
add di,26;siguiente bufer salteando uno de 13
loop coparar
pop di
ret

;
; VGA.INC - Manejo de imagenes en el modo MCGA 320x200x256
;
;
; --------------------------------------------------------

procCambiarPaleta: ;ax=paleta
	mov	cx, 256
;        lea     bx, ax;Paleta
	mov	bx, ax
	xor	di, di
	xor	ax, ax
lbl_VGA_Cargar:
	mov	dx, 03c8h
	out	dx, al

	inc	dx

	push	ax

	mov	al, [bx+di+2]
	shr	al, 2 ;solo 6 bits
	out	dx, al
	mov	al, [bx+di+1]
	shr	al, 2
	out	dx, al
	mov	al, [bx+di]
	shr	al, 2
	out	dx, al

	pop	ax

	add	di, 3

	inc	ax
	loop	lbl_VGA_Cargar

ret

; IN AX=destino;DI=offset
procCLS:
	mov	es, ax
	mov	cx, 32000
	mov	ax, 0
	rep	stosw
ret

; Retrazado vertical - Esperar a que termine
procRetrazo:
	mov	dx, 03dah
       lbl1:
	in	al, dx
	test	al, 1000b
	jnz	lbl1
       lbl2:
	in	al, dx
	test	al, 1000b
	jz	lbl2
ret

;Punto
; IN AX=segmento ;Di=offset;BX=X; CX=Y DL=color
procPunto:
	cmp	[P_X],320
	jb seg1
	ret
       seg1:
	cmp	[P_Y],200
	jb seg2
	ret
       seg2:
	MOV	AX,[P_Y]
	MOV	BX,[P_Y]
	SHL	AX,8
	SHL	BX,6
	ADD	AX,BX
	ADD	AX,[P_X]
	MOV	BX,AX

	MOV	AX,datos;@data;word ptr[VideoBuffer];@data;CS
	MOV	ES,AX
	MOV	DI,VideoBuffer

	ADD	DI,BX
	MOV	AL,DL
	MOV	[ES:DI],AL

ret
BufferArea: times 18175 db ? ; no se porque, pero si no hay esto, no funka el sound
FreeArea: times 65536-FreeArea db ?
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;   data segment                      ;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;segment segsound use16
;SoundFile db 'space.voc',0,'$'
;FileHandler dw ?
;SoundBuffer db 64000 dup(?)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;   buffer segment                    ;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
segment datos use16
VideoBuffer db 65536 dup(?)
