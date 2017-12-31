include 'fondo.inc'
;---------------------- GRAFICOS
CORAZON db 00,244,00,244,00
	db 244,244,244,244,244
	db 00,244,244,244,00
	db 00,00,244,00,00
include 'alien.inc'

Alfabeto:
A db 1,1,1
  db 1,0,1
  db 1,1,1
  db 1,0,1
  db 1,0,1
B db 1,1,1
  db 1,0,1
  db 1,1,0
  db 1,0,1
  db 1,1,1
C db 1,1,1
  db 1,0,0
  db 1,0,0
  db 1,0,0
  db 1,1,1
D db 1,1,0
  db 1,0,1
  db 1,0,1
  db 1,0,1
  db 1,1,0
E db 1,1,1
  db 1,0,0
  db 1,1,1
  db 1,0,0
  db 1,1,1
F db 1,1,1
  db 1,0,0
  db 1,1,1
  db 1,0,0
  db 1,0,0
G db 1,1,1
  db 1,0,0
  db 1,1,1
  db 1,0,1
  db 1,1,1
H db 1,0,1
  db 1,0,1
  db 1,1,1
  db 1,0,1
  db 1,0,1
I db 0,1,0
  db 0,1,0
  db 0,1,0
  db 0,1,0
  db 0,1,0
J db 0,0,1
  db 0,0,1
  db 0,0,1
  db 1,0,1
  db 0,1,0
K db 1,0,1
  db 1,0,1
  db 1,1,0
  db 1,0,1
  db 1,0,1
L db 1,0,0
  db 1,0,0
  db 1,0,0
  db 1,0,0
  db 1,1,1
M db 1,0,1
  db 1,1,1
  db 1,1,1
  db 1,0,1
  db 1,0,1
N db 1,0,1
  db 1,1,1
  db 1,1,1
  db 1,1,1
  db 1,0,1
O db 0,1,0
  db 1,0,1
  db 1,0,1
  db 1,0,1
  db 0,1,0
P db 1,1,1
  db 1,0,1
  db 1,1,1
  db 1,0,0
  db 1,0,0
Q db 0,1,0
  db 1,0,1
  db 1,0,1
  db 1,1,1
  db 0,1,1
R db 1,1,1
  db 1,0,1
  db 1,1,0
  db 1,0,1
  db 1,0,1
S db 1,1,1
  db 1,0,0
  db 1,1,1
  db 0,0,1
  db 1,1,1
T db 1,1,1
  db 0,1,0
  db 0,1,0
  db 0,1,0
  db 0,1,0
U db 1,0,1
  db 1,0,1
  db 1,0,1
  db 1,0,1
  db 1,1,1
V db 1,0,1
  db 1,0,1
  db 1,0,1
  db 1,0,1
  db 0,1,0
W db 1,0,1
  db 1,0,1
  db 1,1,1
  db 1,1,1
  db 1,0,1
X db 1,0,1
  db 1,0,1
  db 0,1,0
  db 1,0,1
  db 1,0,1
Y db 1,0,1
  db 1,0,1
  db 0,1,0
  db 0,1,0
  db 0,1,0
Z db 1,1,1
  db 0,0,1
  db 0,1,0
  db 1,0,0
  db 1,1,1
SIGNOS:
_SLASH:
    DB 0,0,1
    DB 0,1,0
    DB 0,1,0
    DB 0,1,0
    DB 1,0,0
_PUNTO:
    DB 0,0,0
    DB 0,0,0
    DB 0,0,0
    DB 0,0,0
    DB 0,1,0
_DOSPTS:
    DB 0,0,0
    DB 0,1,0
    DB 0,0,0
    DB 0,1,0
    DB 0,0,0
; NUMEROS
NUM:
_0: DB 0,1,0
    DB 1,0,1
    DB 1,0,1
    DB 1,0,1
    DB 0,1,0
_1: DB 0,1,0
    DB 1,1,0
    DB 0,1,0
    DB 0,1,0
    DB 0,1,0
_2: DB 1,1,1
    DB 0,0,1
    DB 1,1,1
    DB 1,0,0
    DB 1,1,1
_3: DB 1,1,1
    DB 0,0,1
    DB 1,1,0
    DB 0,0,1
    DB 1,1,1
_4: DB 1,0,1
    DB 1,0,1
    DB 1,1,1
    DB 0,0,1
    DB 0,0,1
_5: DB 1,1,1
    DB 1,0,0
    DB 1,1,1
    DB 0,0,1
    DB 1,1,1
_6: DB 0,1,1
    DB 1,0,0
    DB 1,1,1
    DB 1,0,1
    DB 1,1,1
_7: DB 1,1,1
    DB 0,0,1
    DB 0,0,1
    DB 0,1,0
    DB 0,1,0
_8: DB 1,1,1
    DB 1,0,1
    DB 1,1,1
    DB 1,0,1
    DB 1,1,1
_9: DB 1,1,1
    DB 1,0,1
    DB 1,1,1
    DB 0,0,1
    DB 0,1,0
