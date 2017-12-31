;
; TGA a DB, conversor de archivos TGA a DB; sin cabecera
; Autor: vhanla
;
; Proposito: Para la creacion de un archivo INClude para el juego ALIX
; Transforma la paleta, y el contenido en DB 0,0,0,.... etc
; Compilado con FASMW

org 100h
mov ax,cs
mov ds,ax
mov es,ax

; Open file using handle

mov ax,3d00h
mov dx,filename
int 21h
jc @@quit
mov [tga_handle],ax
mov ah,09h
mov dx,seabrio
int 21h

mov ah,3fh
mov bx,[tga_handle]
mov cx,18 ; el cabezal
mov dx,buffer
int 21h
jc @@quit
;pero descartamos el cabezal, lo que interesa es la paleta
mov ah,3fh
mov bx,[tga_handle]
mov cx,768 ; el cabezal
mov dx,buffer
int 21h
jc @@quit

;call save_header

mov ah,3fh
mov bx,[tga_handle]
mov cx,320*50 ; el cuerpo de 320x50
mov dx,buffer
int 21h
jc @@quit

call save_body

mov ah,3fh
mov bx,[tga_handle]
mov cx,320*10 ; otros sprites de 320x10
mov dx,buffer
int 21h
jc @@quit

;ahora nos faltan los sprites
mov al,byte[buffer]
mov [color],al
call alien

;y ahora lo cerramos
mov ah,3eh
mov bx,[tga_handle]
int 21h

mov ah,09h
mov dx,completado
int 21h

@@quit:

xor ax,ax
int 16h
mov ah,4ch
int 21h
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
save_header:

mov ah,3ch
mov cx,0
mov dx,outputname2	  ;CAMBIA;
int 21h
jc @err
mov [out_handle],ax
;escribimos el contenido
;primero ponemos PALETA
 mov cx,9
 mov dx,tiPaleta	  ;CAMBIA;
 call fPUT_LABEL
; luego el contenido
mov [veces],48
mov [saltos],0
mov [cols],16
mov [inicio],0
call COPYBYTES
;cerramos el archivo
mov ah,3eh
mov bx,[out_handle]
int 21h

@err:
ret

save_body:

mov ah,3ch
mov cx,0
mov dx,outputname
int 21h
jc @er
mov [out_handle],ax
;escribimos el contenido
;primero ponemos PALETA
 mov cx,9
 mov dx,tiFondo
 call fPUT_LABEL
; luego el contenido
mov [veces],1000
mov [saltos],0
mov [cols],16
mov [inicio],0
call COPYBYTES
;cerramos el archivo
mov ah,3eh
mov bx,[out_handle]
int 21h

@er:
ret

COPYBYTES:
mov di,[inicio]
mov cx,[veces];1000 ;1000x16=16000 320x50
repetir2:
 push cx
  mov ah,40h
  mov cx,5
  mov dx,inc_head
  int 21h

  mov cx,[cols];16
  repp2:
   xor ax,ax
   mov al,byte [buffer+di]; ah contiene el byte a convertir a HEX
   cmp al,[color]; cambiamos el color
   jnz continua
    xor al,al
   continua:
   mov dh,al ;dh contiene otra copia
   shr al,4;el nibble superior en ah
   mov si,ax
   mov dl,[hex_digits+si];copiamos en dl un digito HEXadecimal
   mov [hex_words+1],dl ; copiamos en 0x0h reemplazando x
   mov al,dh
   shl al,4
   shr al,4 ; el nibble inferior en ah
   mov si,ax
   mov dl,[hex_digits+si];copiamos en dl un digito HEXadecimal
   mov [hex_words+2],dl ; copiamos en 0x0h reemplazando x

   mov ah,40h
    push cx
     cmp cx,1
     jz sincoma2
      mov cx,5;6
      jmp concoma2
     sincoma2:
      mov cx,4
     concoma2:
      mov dx,hex_words
      int 21h
    pop cx
   inc di
  loop repp2
 pop cx
  add di,[saltos]
loop repetir2

;y ahora lo cerramos
;mov ah,3eh
;mov bx,[out_handle]
;int 21h

ret


alien:
mov ah,3ch
mov cx,0
mov dx,alien_file
int 21h
jc @rd
mov [out_handle],ax
;escribimos el contenido
;primero ponemos PALETA
 mov cx,9
 mov dx,tiAlien
 call fPUT_LABEL
; luego el contenido
mov [veces],8
mov [saltos],320-14
mov [cols],14
mov [inicio],327;+45
call COPYBYTES
; el siguiente sprite
 mov cx,9
 mov dx,tiAlien2
 call fPUT_LABEL
; y su contenido
add [inicio],15
call COPYBYTES
; el siguiente sprite
 mov cx,9
 mov dx,tiAlien3
 call fPUT_LABEL
; y su contenido
add [inicio],15
call COPYBYTES
 mov cx,9
 mov dx,tiAlien4
 call fPUT_LABEL
add [inicio],15
call COPYBYTES
 mov cx,9
 mov dx,tiAlien5
 call fPUT_LABEL
add [inicio],15
call COPYBYTES
 mov cx,9
 mov dx,tiAlien6
 call fPUT_LABEL
add [inicio],15
call COPYBYTES

; ahora la mira telescopica
 mov cx,7
 mov dx,tiMiraOf
 call fPUT_LABEL
mov [inicio],618
mov [saltos],320-10
mov [cols],10
call COPYBYTES
 mov cx,10
 mov dx,tiMiraOn
 call fPUT_LABEL
mov [inicio],618+10+1
call COPYBYTES
;cerramos el archivo
mov ah,3eh
mov bx,[out_handle]
int 21h
@rd:
ret

fPUT_LABEL: ; escribe la etiqueta pasada en dx, con cx caracteres
 mov bx,[out_handle]
 mov ah,40h
 int 21h
ret
;;;;
;DATOS
inicio dw ? ; punto de inicio dentro del buffer
cols dw ? ;  valores por linea
veces	dw ? ; numero de lineas
saltos	dw ? ; saltos dados antes de cada linea
spr_width db ?
spr_height db ?
color db ? ;lo usaremos para guardar el color violeta asi cambiarlo por otro, en este caso por el 0
	   ; puesto que ese valor lo usamos para que se dibuje la transparencia
tiPaleta db 'PALETA:',13,10
tiFondo  db 'FONDO: ',13,10
inc_head: db 13,10,'db '
hex_words db '000h, ' ;each one is a byte in hex
hex_digits db '0123456789ABCDEF'
seabrio db 'TGA to DB conversor by vhanla',13,10,'2006-2007 ',184,' Hanla Family ',169,13,10,13,10,'Generando los ficheros, espere un momento...$'
completado db 13,10,'Se complet',162,' correctamente!$'
filename: db 'FONDO.TGA',0
outputname db 'FONDO.INC',0
outputname2 db 'PALETA.INC',0
alien_file db 'ALIEN.INC',0
tiAlien db 'ALINE: ',13,10
tiAlien2 db 13,10,'ALINE2:';,13,10
tiAlien3 db 13,10,'ALINE3:';,13,10
tiAlien4 db 13,10,'ALINE4:';,13,10
tiAlien5 db 13,10,'ALINE5:';,13,10
tiAlien6 db 13,10,'ALINE6:';,13,10
tiMiraOf db 13,10,'MIRA:'
tiMiraOn db 13,10,'MIRA_ON:'
tga_handle dw ?
out_handle dw ?
buffer dw ?