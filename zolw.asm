;*****************************************	
;******************ZADANIE_3**************
;*****************************************
.387							;wlacz asemblerowanie rozkazow koprocesora 80387 lub jednostki zmiennoprzecinkowej w procesorach 80486 oraz Pentium.

dane1 segment
	argBuf		db 128 dup(?)	;bufor na argumenty z linii polecen
	licznik 	dw 0			;licznik uzywany w petlach programowych
	licznik2	dw 0			;licznik przy buforze z pliku
	ileLiczb	dw 0			;licznik do konwersji liczby ASCII
	wczytana	dw 0			;liczba wczytana z pliku
	iloscArg 	db 0			;ilosc argumentow
	wskIn		dw	?			;wskaznik na plik wejscia
	linia		db 10,13,'$'	;nowa linia	
	ileRuch		dw 0			;o ile pikseli ma wykonac ruch zolwik
	pioro		db 0			;flaga piora, 0 - pioro podniesione, 1 - pioro opuszczone
	flaga		db 0			;flaga przy wykonywaniu ruchu oznacza czy ruszamy sie w gore/dol dla y badz prawo/lewo dla x
	
	l180	dt 180.0		;180.0 do zamiany ze stopni na radiany
	kat		dt 0.0			;kat, declare tenbyte, 80-bitowa liczba zmiennopozycyjna
	x1		dw 160			;poczatkowy x
	y1		dw 100			;poczatkowy y
	x2		dw 0			;koncowy x
	y2		dw 0			;koncowy y
	a		dt 0.0			;wsp a funkcji liniowej
	b		dt 0.0			;wsp b funkcji liniowej

	arg1 db 30 dup ('$')		;tablica na pierwszy argument

	bufor			db 512d dup(0)		;bufor do wczytywania z pliku	
	wczytanaLiczba	db 30 dup('$')		;zmienna do zapisywania liczby z pliku
	wczytaneZnaki	dw 0				;licznik wczytanych znakow
	ileZnakow		dw 0				;licznik wczytanych znakow w jednej porcji

	errBrakArg	db "Brak argumentow",10,13,'$'					;gdy brak argumentow
	errZlaIlosc	db "Blad! Bledna ilosc argumentow",10,13,'$'	;gdy niewlasciwa ilosc argumentow
	errPlik		db "Blad w czasie obslugi pliku",10,13,'$'						;blad gdy byla zla komenda
	errArg		db "Blad Argumentow",10,13,'$'					;blad podanych argumentow w linii polecen

dane1 ends

code1 segment
	assume cs:code1, ds:dane1	;dyrektywa assume informuje kompilator, z którego rejestru segmentowego ma korzystac przy odwolaniu sie do etykiet podanego segmentu
	start1:
	mov ax,seg wStosu		;za pomoca AX przenosimy adres
	mov ss,ax				;SS jest poczatkiem segmentu przeznaczonego na stos
	mov sp,offset wStosu	;SP to wskaznik stosu

	call daneInit			;inicjalizacja segmentu danych
	
	finit					;inicjalizacja stosu FPU (Floating Point Unit), koprocesora, 8 rejestrów, po 80 bitów każdy.
	
	call wczytajArgumenty	;odczytanie argumentow
	call vgaInit			;wywolanie trybu graficznego
	
	call obslugaPliku		;obsluga pliku dla wersji pierwszej
	call zaladujBufor
	
	mov ax,0				;oczekiwanie na klawisz
	int 16h
	mov ah,00h				;powrot do trybu tekstowego
	mov ax,03h				;z trybu graficznego
	int 10h
	
	call zakonczProgram		;wywolanie funkcji konczacej program
	
	
;*********************************************	
;******************PROCEDURY******************
;*********************************************
;-----------------------------------
;### Funkcja czytajaca argumenty ###
;-----------------------------------
wczytajArgumenty:
	push bx						;odkladamy BX na stos by go nie zgubic
	xor bx,bx					;szybkie zerowanie BX, przed uzyciem BL
	mov bl,byte ptr es:[080h]	;pod adresem 080h znajduje sie ilosc znakow argumentow, wkladamy je do BL, struktura PSP
	cmp bx,0					;sprawdzenie czy ilosc znakow nie jest rowna 0, czyli brak argumentow
	je brakArgumentow			;jesli brak argumentow to bledne wywolanie wiec zakoncz program
	call zaladujArg				;wywolanie sprawdzenie poprawnosci argumentow
	pop bx						;pobranie z stosu BX z powtotem
ret

;---------------------------------------------------------------------------------------------------------------------------------------------------------------------
;------------------------------------------------------------###FUNKCJE LADUJACE ARGUMENTY###-------------------------------------------------------------------------
;---------------------------------------------------------------------------------------------------------------------------------------------------------------------
;------------------------------------
;###Funkcja ladujaca argumenty###
;------------------------------------
zaladujArg:
	push ax						;odlozenie na stos wszystkich zmiennych
	push bx						;ktore beda uzywane w obrebie funkcji
	push cx						;aby nie zgubic wartosci w nich zawartych
	push dx
	push di
	push si
	mov si,offset argBuf		;wczytanie do SI offsetu bufora argumentow
	xor di,di					;szybkie zerowanie DI, ES:DI - adres logiczny argumentow z linii komend
	mov cx,bx					;w CX jest ilosc znakow wczytanych z linii polecen
	dec cx						;pomijamy pierwszy znak ponieważ jest spacja
	xor bx,bx					;czyscimy BX
	mov ax,cx					;do AX przenosimy warosc z CX
	
	
	mov iloscArg,1d					;zaczynamy ustawiajac ilosc argumentow na 1 poniewaz zaczynamy wczytywanie od pierwszego
pSprawdzajaca:						;sprawdzanie wszystkich znakow
	mov al, byte ptr es:[082h+di]	;zaczynamy od drugiego bajtu argumentow
	
	call sprawdzZnak				;sprawdzamy czy bialy znak
	cmp ax,1						;jesli w AX jest 1 to jest bialy znak
	jne nieBialy					;jesli nie byl bialy to przeskakujemy dalej i nie dodajemy dolara
	
	cmp si,0						;jesli SI jest 0 to znaczy ze jeszcze nic nie wpisalismy do bufora wiec nie mozemy dac dolara
	jne nieBialeNaPoczatku			;instrukcja jest potrzebna gdy pojawia sie wiecej spacji przed pierwszym argumentem
	dec si
	jmp pominieto
	
	nieBialeNaPoczatku:
	mov byte ptr ds:[argBuf+si],36d	;dodajemy dolara jesli bialy znak
	inc iloscArg					;powiekszamy ilosc argumentow
	jmp nastepny					;przechodzimy dalej by nie inkrementowac DI poniewaz inkrementowalismy DI
									;SI inkrementujemy gdzyz w miejsce spacji wstawilismy dolara								
nieBialy:
	mov byte ptr ds:[argBuf+si],al	;dodaj do bufora kolejny znak
	inc di							;zwiekszamy DI by przesunac sie po wczytanych z linii komend znakach
	nastepny:						
	pominieto:						;pomijamy do tego miejsca jesli byly spacje przed pierwszym argumentem
	inc si							;inkrementujemy SI by przesunac sie na kolejne miejsce w buforze na argumenty
	loop pSprawdzajaca				;powtarzamy dopoki nie skoncza sie wszystkie znaki podane w linii polecen
	
	cmp byte ptr ds:[argBuf+si-1],36d	;sprawdzamy czy na koncu jest dolar, jesli jest znaczy ze na koncu byl bialy znak
										;-1 bo inkrementowalismy SI po dodaniu dolara
	jne bezDolara 						;jesli nie ma dolara przechodzimy dalej
	dec iloscArg						;jesli byl trzeba obnizyc ilosc argumentow
	jmp bylDolar						;jesli byl to nie dodajemy dolara
	bezDolara:
	mov byte ptr ds:[argBuf+si],36d		;wstawianie dolara	
	bylDolar:
	cmp iloscArg,1				;jesli argumenty sa 2 to przechodzimy dalej
	jne blednaIloscArg			;jesli niewlasciwa ilosc argumentow to wypisujemy blad
	xor ax,ax					;czyscimy AX
	call wczytajArg				;wywolujemy funkcje wczytujaca argumenty do etykiet
	sprawdzono:
	pop si						;pobieramy ze stosu wszystkie wartosci ktore odlozylismy na
	pop di						;poczatku funkcji
	pop dx
	pop cx
	pop bx
	pop ax
ret
	
;---------------------------------------------------------------------------
;###Funkcja wczytujaca argumenty do etykiet i sprawdzajaca ich poprawnosc###
;---------------------------------------------------------------------------
wczytajArg:
	push dx					;odlozenie na stos wszystkich wartosci w rejestrach
	push bx					;ktore bedziemy uzywac w trakcie funkcji
	push si
	push di
	mov di,0				;zaczynamy od 0
	mov si,0				;zaczynamy od 0
	xor ax,ax				;zerujemy AX
	wczytajArg1:				;petla wczytujaca pierwszy argument do etykiety
		mov al,ds:[argBuf+di]	;pobieramy z bufora pierwszy znak
		mov ds:[arg1+si],al		;wpisujemy go do etykiet
		inc si					;inkrementyjac SI przechodzimy do kolejnego znaku
		inc di					;tak samo jak wyzej
		cmp al,'$'				;jesli bedzie dolar to wychodzimy z petli konczac wczytywanie argumentu
		jne wczytajArg1			;jesli nie byl dolar to znaczy ze argument sie jeszcze nie skonczyl
	mov al,0					;dopisywanie NULL na koncu by moc otworzyc plik
	mov ds:[arg1+si-1],al
	pop di					;pobieramy z powrotem wartosci ze stosu
	pop si
	pop bx
	pop dx
ret

;---------------------------------------------------------------------------------------------------------------------------------------------------------------------
;-----------------------------------------------------------###FUNKCJE OBSLUGUJACE BIALE ZNAKI###---------------------------------------------------------------------
;---------------------------------------------------------------------------------------------------------------------------------------------------------------------
;----------------------------------------------------------------
;###Funkcja sprawdzajaca czy przekazywany a AX znak jest bialy###
;----------------------------------------------------------------
sprawdzZnak:
	push dx				;odlozenie na stos rejestrow uzywanych w funkcji
	push bx
	call czyZnak		;wywolujemy funkcje sprawdzajaca czy bialy znak
	cmp ax,1			;jesli jest bialy znak to AX bedzie mialo wartosc 1
	jne powrot			;w przypadku braku bialego znaku wychodzimy
	call pominZnak		;jesli jest to wywolujemy funkcje pomijajaca bialy znak
powrot:
	pop bx				;pobranie rejestrow z stosu
	pop dx
ret

;---------------------------------------------------------
;###Funkcja sprawdzająca czy znak jest spacja lub tabem###
;---------------------------------------------------------
czyZnak:
	push dx			;odlozenie na stos
	push bx
	cmp al,32d		;porownanie AL do spacji
	je jestZnak		;jesli jest to wywolujemy procedure jestZnak
	cmp al,09d		;porownanie AL do tab
	je jestZnak		;jesli jest to wywolujemy procedure jestZnak
	jmp brakZnaku	;jesli nie bylo znaku to w AX zostanie 0
jestZnak:
	mov ax,1		;jesli jest bialy znak to zwracamy 1
brakZnaku:
	pop bx			;pobieranie ze stosu
	pop dx
ret

;-------------------------------------------------------
;###Funkcja pomijajaca znak jesli jest bialym znakiem###
;-------------------------------------------------------
pominZnak:
	push dx							;odlozenie na stos
	push bx
	jmp sprawdz						;pomijamy dekrementowanie CX poniewaz
sprawdzPonownie:					;jesli bedzie jedna spacja nie bedzie to potrzebne
	dec cx							;dekrementacja CX jesli pojawila sie kolejna spacja
sprawdz:
	inc di							;zwiekszamy DI by sprawdzic nastepny bajt
	mov al,byte ptr es:[082h+di]	;wsadzamy do AL kolejny bajt do sprawdzenia
	call czyZnak					;i wywolujemy sprawdzenie czy jest bialym znakiem
	cmp ax,1						;jesli byl bialy to w AX bedzie 1
	je sprawdzPonownie				;jesli byl to sprawdzamy nastepny
	mov ax,1						;zwracamy 1 bo przynajmniej jeden bialy znak byl
	pop bx							;pobieranie ze stosu
	pop dx
ret

;---------------------------------------------------------------------------------------------------------------------------------------------------------------------
;-----------------------------------------------------------###OBSLUGA PLIKOW DO WERSJI PIERWSZEJ###------------------------------------------------------------------
;---------------------------------------------------------------------------------------------------------------------------------------------------------------------
;------------------------------------------------
;----###Funkcja otwierajaca plik wejsciowy###----
;------------------------------------------------
obslugaPliku:
	;Plik Wejscia - otwarcie pliku
	push ax						;odkladamy na stos wszystko co bedziemy uzywac
	push bx
	push dx
	mov dx, offset arg1			;otwieramy plik do odczytu z arg2
	mov al,0					;ustawiamy tylko do odczytu, 0 - read only, 1 - zapis, 2 - to i to
	mov ah,03dh					;funkcja 03dh
	int 21h						;przerwanie 21h (otwiera plik)
	jc bladPlik					;flaga CF (carry flag) jest ustawiona jesli wystapi blad
	mov word ptr wskIn,ax		;nie ma bledu, wiec w AX znajduje sie wskaznik do pliku (uchwyt), zapisujemy go
	pop dx						;zdejmujemy wszystko ze stosu
	pop bx
	pop ax
ret

;------------------------------------------------
;------##Funkcja ladujaca bufor z pliku###-------
;------------------------------------------------
zaladujBufor:
	push dx
	push bx
	push cx
	push ax
	mov bx,wskIn		;przenosimy do BX wskaznik na plik
	mov cx,512d			;przenosimy do CX ile bajtow pomiesci bufor
	czyKoniec:			;czytamy petle az nie skonczy sie plik
		lea dx,bufor	;do DX wsadzamy offset bufora
		xor ax,ax		;zerujemy AX
		mov bx,wskIn	;do BX ladujemy wskaznik pliku wejsciowego
		mov ah,3fh		;fukncja 3fh, laduje bufor w DX z pliku BX,CX bajtami
		int 21h			;przerwanie
		add wczytaneZnaki,ax	;powiekszamy zasob wczytanych znakow o AX, w AX zapisuje sie ile bajtow wczytano
		mov ileZnakow,ax		;potrzebne by wiedziec ile razy wykonac petle
		call sprawdzKomende	
		cmp ax,512d				;sprawdzamy czy AX jest rowne rozmiarowi bufora, jezeli jest to znaczy ze musimy kontynuowac wczytywanie	
		je czyKoniec
	pop ax
	pop cx
	pop bx
	pop dx
	call zamknieciePliku		;zamykamy plik
ret

;-------------------------------------------------------
;-------##Funkcja sprawdzajaca kolejne komendy###-------
;-------------------------------------------------------
sprawdzKomende:
	push bx
	push cx
	push dx
	mov licznik2,ax						;petla wykona sie tyle razy ile zaladowalo sie znakow
	push ax								;teraz odkladamy AX na stos by go nie zgubic
	xor di,di							;czyscimy DI gdzyz przy jego pomocy bedziemy sie przesuwac
	sprawdzam:
		mov al,byte ptr ds:[bufor+di]	;do AL wkladamy obecny znak do sprawdzenia
		jmp sprawdzZnaki				;skaczemy do funkcji sprawdzajacych znak
		poSprawdzeniu:					;po sprawdzeniu
		inc di							;inkrementujemy DI by przejsc do nastepnego znaki
		dec licznik2						;dekrementujemy licznik znakow do sprawdzenia
		cmp licznik2,0					;jesli 0 to sprawdzilismy wszystko i wracamy
		jne sprawdzam					;jesli nie to sprawdzamy dalej
	jmp sprawdzonoPartie				;jesli sprawdzono wszystko to wracamy do ladowania koleinych znakow o ile sa
		
sprawdzZnaki:
	cmp al,'r'
	je sprawdzR
	cmp al,'m'
	je sprawdzM
	cmp al,'u'
	je sprawdzU
	cmp al,'d'
	je sprawdzD
	cmp al,' '
	je poSprawdzeniu
	cmp al,10
	je poSprawdzeniu
	cmp al,13
	je poSprawdzeniu
	jmp bladPlik
	
sprawdzR:
	mov al,byte ptr ds:[bufor+di+1]		;sprawdzamy czy nastepny znak jest spacja
	cmp al,' '							;jesli nie jest to mamy blad
	jne bladPlik						;wiec go wypisujemy i konczymy program
	call wczytajLiczbe
	call odwrocZolwia
	
	jmp poSprawdzeniu
	
sprawdzM:
	mov al,byte ptr ds:[bufor+di+1]		;sprawdzamy czy nastepny znak jest spacja
	cmp al,' '							;jesli nie jest to mamy blad
	jne bladPlik						;wiec go wypisujemy i konczymy program
	call wczytajLiczbe
	call policzPunktKonc
	call wykonajRuch
	
	jmp poSprawdzeniu

sprawdzU:
	push bx
	xor bx,bx
	mov al,byte ptr ds:[bufor+di+1]		;sprawdzamy czy nastepny znak jest spacja
	cmp al,' '							;jesli jest to wszystko ok
	je jestOkU
	cmp al,10							;jesli nie to sprawdzamy 10,13 i NULL
	je jestOkU							;jesli jest ktorys z nich to ok ale jesli
	cmp al,13							;nie ma to wyrzucamy blad w pliku
	je jestOkU
	cmp al,0
	je jestOkU
	jmp bladPlik
	jestOkU:
	mov bl,0					
	mov pioro,bl						;ustawiamy flage na 0 czyli podniesione pioro
	pop bx
	jmp poSprawdzeniu

sprawdzD:
	push bx
	xor bx,bx
	mov al,byte ptr ds:[bufor+di+1]
	cmp al,' '
	je jestOkD
	cmp al,10
	je jestOkD
	cmp al,13
	je jestOkD
	cmp al,0
	je jestOkD
	jmp bladPlik
	jestOkD:
	mov bl,1							;ustawiamy flage na 1 czyli opuszczone pioro
	mov pioro,bl
	pop bx
	jmp poSprawdzeniu
	
	sprawdzonoPartie:
	pop ax
	pop dx
	pop cx
	pop bx
ret

;------------------------------------------------
;----###Funkcja wczytujaca liczbe z pliku###-----
;------------------------------------------------
wczytajLiczbe:
	push ax
	push bx
	push cx
	mov ileLiczb,0				;licznik zliczajacy jak duza liczba zostala podana
	add di,2					;zaczynamy od znaku po spacji
	iloLiczbowa:
		mov al,byte ptr ds:[bufor+di]			;do AL wkladamy kolejny wczytany znak
		cmp al,' '								;jesli to spacja to koniec liczby
		je koniecLiczby
		cmp al,10
		je koniecLiczby
		cmp al,13
		je koniecLiczby
		cmp al,0
		je koniecLiczby
		
		cmp al,'0'								;nastepnie sprawdzamy czy na pewno podano liczbe
		jb bladPlik								;jesli nie to wyrzucamy blad
		cmp al,'9'
		ja bladPlik
		inc di						
		inc ileLiczb
		jmp iloLiczbowa
	koniecLiczby:
	cmp ileLiczb,0				;jesli nie bylo liczby to znaczy ze blednie podano komendy w pliku
	je bladPlik
	sub di,ileLiczb				;wracamy do pierwszej cyfry
	xor ax,ax
	mov cx,ileliczb
	mov licznik,cx
	xor cx,cx
	zmieniajInt:
		mov cl,byte ptr ds:[bufor+di]
		sub cl,48		;rzutowanie z ASCII do formy komputerowej
		add ax,cx
		dec licznik
		cmp licznik,0
		je koniecWczytywania
		mov bl,10
		mul bl			;AX = AX * BL
		inc di
		jmp zmieniajInt
	koniecWczytywania:
	xor bx,bx
	mov bx,ileLiczb
	sub licznik2,bx			;musimy zmniejszyc licznik2 od bufora o tyle ile pominelismy wczytujac liczbe
	sub licznik2,1		
	mov wczytana,ax
	pop cx
	pop bx
	pop ax
ret

;------------------------------------------------------
;----###Funkcja odwracajaca wirtualnego zolwika###-----
;------------------------------------------------------
odwrocZolwia:				; 8 rejestrów, po 80 bitów każdy.
	fild wczytana			;wczytana calkowita					st(0) = wczytana
	fld l180				;ladujemy 180.0 na stos,rzeczywista st(0) = 180.0, st(1) = wczytana
	fdiv st(1),st(0)		;st(1) = st(1)/st(0)				st(0) = 180.0, st(1) = wczytana/180.0
	fstp st(0)				;zdejmujemy st(0)					st(0) = wczytana/180.0
	fldpi					;wkladamy na stos liczbe PI			st(0) = PI, st(1) = wczytana/180.0
	fmul st(1),st(0)		;st(1) = st(1) * st(0)				st(0) = PI, st(1) = (wczytana/180.0)*PI
	fstp st(0)				;zdejmujemy st(0)					st(0) = (wczytana/180.0)*PI
	
	fld kat					;ladujemy "kat" na stos				st(0) = kat, st(1) = (wczytana/180.0)*PI
	fadd st(0),st(1)		;st(0) = st(0) + st(1)				st(0) = kat + (wczytana/180)*PI, st(1) = (wczytana/180.0)*PI
	fstp kat				;zdejmujemy st(0) i dajemy do kat	st(0) = (wczytana/180.0)*PI
	fstp st(0)				;czyscimy stos
ret

;--------------------------------------------------------
;----###Funkcja licz wspolrzedne punktu koncowego###-----
;--------------------------------------------------------
policzPunktKonc:		; 8 rejestrów, po 80 bitów każdy.
	fild wczytana									;st(0) = wczytana
	fld kat											;st(0) = kat, st(1) = wczytana
	fsin				;sinus kata st(0)			 st(0) = sin(kat), st(1) = wczytana

	fmul st(0),st(1)								;st(0) = sin(kat)*wczytana, st(1) = wczytana
	fild x1											;st(0) = x1, st(1) = sin(kat)*wczytana, st(2) = wczytana
	fadd st(0),st(1)								;st(0) = x1 + sin(kat)*wczytana, st(1) = sin(kat)*wczytana, st(2) = wczytana
	fistp x2	;obcieta do calkowitej zdejmij		 st(0) = sin(kat)*wczytana, st(1) = wczytana
	fstp st(0)	;zdejmujemy st(0)					 st(0) = wczytana
	
	fld kat											;st(0) = kat, st(1) = wczytana
	fcos				;cosinus kata st(0)			 st(0) = cos(kat), st(1) = wczytana
	fmul st(0),st(1)								;st(0) = cos(kat)*wczytana, st(1) = wczytana
	fild y1											;st(0) = y1, st(1) = cos(kat)*wczytana, st(2) = wczytana
	fsub st(0),st(1)								;st(0) = y1-cos(kat)*wczytana, st(1) = cos(kat)*wczytana, st(2) = wczytana
	fistp y2	;zdejmuj obcieta do calkowitej		;st(0) = cos(kat)*wczytana, st(1) = wczytana
	
	fstp st(0)	;czyszczenie stosu
	fstp st(0)
ret

;------------------------------------------------------
;----###Funkcja wykonujaca ruch zolwia po ekranie###---
;------------------------------------------------------
wykonajRuch:		;w zmiennej "wczytana" jest dlugosc jaka mamy narysowac, w zmiennej "kat" kat pod jakim mamy rysowac
	push ax
	push bx
	push cx
	push dx
	
	push di
	xor di,di	
	cmp pioro,0		;na poczatku sprawdzamy flage czy w ogole trzeba cos rysowac czy moze
	je nieRysuj		;pioro jest podniesione

	;Sprawdzenie jakie mamy rysowanie pionowe, poziome czy ukosne
	mov ax,x2		;na poczatku porownojemy x1 i x1
	cmp ax,x1		;jesli sa rozne to znaczy ze mamy rysowanie pionowe
	je rowne		;jesli nie to znaczy ze bedziemy rysowac pionowo
	cmp ax,x1		
	jb mniejsze		
	
	mov flaga,0		;jesli sa rozne to musimy wiedziec czy w petli
	jmp dalej		;bedziemy inkrementowac x1 (x1<x2) czy dekrementowac x1 (x1>x2)
	
	mniejsze:
	mov flaga,1
	
	;------------------------------------------------
	;Rysowanie gdy idziemy po skosie
	dalej:
	mov ax,y2
	cmp ax,y1
	je poziome			;sprawdzmy czy przypadkiem y1 nie jest rowne y2, bo jesli tak to mamy rysowanie poziome
	
	finit				; 8 rejestrów, po 80 bitów każdy.
	fild x2				;st(0) = x2
	fild x1				;st(0) = x1, st(1) = x2
	fsub st(0),st(1)	;st(0) = x1 - x2, st(1) = x2
	fild y1				;st(0) = y1, st(1) = x1 - x2, st(2) = x2
	fild y2				;st(0) = y2, st(1) = y1, st(2) = x1 - x2, st(3) = x2
	fsub st(1),st(0)	;st(0) = y2, st(1) = y1 - y2, st(2) = x1 - x2, st(3) = x2
	fstp st(0)			;st(0) = y1 - y2, st(1) = x1 - x2, st(2) = x2
	fdiv st(0),st(1)	;st(0) = (y1 - y2)/(x1 - x2), st(1) = x1 - x2, st(2) = x2
	fstp a				;st(0) = x1 - x2, st(1) = x2
	fstp st(0)			;st(0) = x2
	fstp st(0)			;czysty stos
	
	fild x1				;st(0) = x1
	fld a				;st(0) = a, st(1) = x1
	fmul st(0),st(1)	;st(0) = a*x1, st(1) = x1
	fild y1				;st(0) = y1, st(1) = a*x1, st(2) = x1
	fsub st(0),st(1)	;st(0) = y1 - a*x1, st(1) = a*x1, st(2) = x1
	fstp b				;st(0) = a*x1, st(1) = x1
	fstp st(0)			;st(0) = x1
	fstp st(0)			;czysty stos

	rysujFunkcje:
		fld a				;st(0) = a
		fild x1				;st(0) = x1, st(1) = a
		fmul st(0),st(1)	;st(0) = x1*a, st(1) = a
		fld b				;st(0) = b, st(1) = x1*a, st(2) = a
		fadd st(0),st(1)	;st(0) = a*x1 + b, st(1) = x1*a, st(2) = a
		fistp y1			;st(0) = x1*a, st(1) = a
		jmp punkt
		narysowanoPunkt:
		
		cmp flaga,0			;zwiekszanie badz zmiejszaanie x1 w zaleznosci od
		jne mniejszyX2		;stosunku x1 do x2
		
		inc x1
		jmp zwiekszonoX1
		
		mniejszyX2:
		dec x1
		
		zwiekszonoX1:
		mov ax,x2
		cmp ax,x1
		jne rysujFunkcje
	jmp narysowane
		
	punkt:
	mov ax,y1
	mov bx,320
	mul bx			;AX = BX*AX = 320*y1
	mov bx,ax		;BX = AX = 320*y1
	mov ax,x1		;AX = x1
	add bx,ax		;BX = BX + AX = 320*y1 + x1
	mov al,15		;kolor
	mov byte ptr es:[bx],al
	jmp narysowanoPunkt
	;------------------------------------------------
	;Rysowanie gdy idziemy pionowo
	rowne:
	mov ax,y2		;trzeba sprawdzic czy rysujemy pionowo w gore czy w dol
	cmp ax,y1		;jesli w gore to musimy inkrementowac y1
	jb mniejszyY	;jesli w dol to musimy dekrementowac y1
	
	mov flaga,0
	jmp dalejY
	
	mniejszyY:
	mov flaga,1
	
	dalejY:

	punktPion:
	mov ax,y1
	mov bx,320
	mul bx
	mov bx,ax
	mov ax,x1
	add bx,ax
	mov al,15
	mov byte ptr es:[bx],al
	
	cmp flaga,0
	jne mniejszyY2
	
	inc y1
	jmp zwiekszonoY1
	
	mniejszyY2:
	dec y1
	
	zwiekszonoY1:
	mov ax,y2
	cmp ax,y1
	jne punktPion
jmp narysowane
	;------------------------------------------------
	;Rysowanie gdy idziemy poziomo
	poziome:
	mov ax,x2		;sprawdzamy czy rysujemy pionowo w prawo czy w lewo
	cmp ax,x1		;jesli w prawo to musimy inkrementowac x1
	jb xMniejsze	;jesli w lewo to dekrementowac
	
	mov flaga,0
	jmp ustawiono
	
	xMniejsze:
	mov flaga,1
	
	ustawiono:
	rysujPoziomo:
	mov ax,y1
	mov bx,320
	mul bx
	mov bx,ax
	mov ax,x1
	add bx,ax
	mov al,15
	mov byte ptr es:[bx],al
	
	cmp flaga,0
	jne zmniejsz
	inc x1
	jmp nieZmniejszaj
	zmniejsz:
	dec x1
	nieZmniejszaj:
	mov ax,x2
	cmp ax,x1
	jne rysujPoziomo
jmp narysowane

	jmp narysowane
	nieRysuj:					;jesli nie rysujemy to zmieniamy punkty poczatkowe na obecne punty koncowe
	mov ax,x2
	mov x1,ax
	mov ax,y2
	mov y1,ax
	
	narysowane:
	pop di
	pop dx
	pop cx
	pop bx
	pop ax
ret	

;------------------------------------------------
;----###Funkcja zamykajaca plik wejsciowy###-----
;------------------------------------------------
zamknieciePliku:
	push ax
	push bx
	xor ax,ax					;czyscimy AX
	mov bx, word ptr wskIn		;przekazujemy do BX wskaznik pliku
	mov ah,03Eh					;funkcja 03Eh
	int 21h						;przerwanie 21h (zamyka plik)
	jc bladPlik					;flaga CF ustawiona, gdy blad zamkniecia pliku
	pop bx
	pop ax
ret

;------------------------------------------------------
;###INICJALIZACJA TRYBU KARTY GRAFICZNEJ VGA 320x200###
;------------------------------------------------------
vgaInit:
    mov ah,00			;numer funkcji do inicjacji standardowych trybów
	mov al,13h			;numer trybu
	int 10h
	mov ax,0A000h 		;obszar pamieci sluzacy do wyswietlania obrazu zaczyna sie od adresu 0A000:0000h, a konczy na 0A000:0F9FFh
	mov es,ax			;dlatego tworzac adres logiczny pikseli, do rejestru segmentowego wrzucamy stala wartosc 0A000h
ret


;---------------------------------------------------------------------------------------------------------------------------------------------------------------------
;----------------------------------------------------------------------###OBSLUGA BLEDOW###---------------------------------------------------------------------------
;---------------------------------------------------------------------------------------------------------------------------------------------------------------------
;-------------------------------------------
;###Funkcje wywolywane gdy wystapia bledy###
;-------------------------------------------
;***Jesli brak argumentow***
brakArgumentow:		
	mov ax,offset errBrakArg	;przeniesienie do AX tekstu do wypisania
	call errorPrint				;wypisanie odpowiedniego komunikatu
;***Jesli bledna ilosc argumentow
blednaIloscArg:
	mov ax,offset errZlaIlosc	
	call errorPrint
;***Jesli inny blad argumentow
bladArg:
	mov ax,offset errArg
	call errorPrint
;***Jesli blad dotyczacy Pliku
bladPlik:
	mov ax,offset errPlik
	call errorPrint
	
;-------------------------------
;### Funkcja wypisujaca z AX ###
;-------------------------------
errorPrint:
	push ax			;odkladamy na stos AX i DX poniewaz beda za chwile uzywane
	push dx
	mov dx,ax		;przenosimy to co mamy wypisac z AX do DX
	xor ax,ax		;czyscimy AX
	mov ah,9		;wypisywanie za pomoca funkcji 9
	int 21h			;przerwanie 21h
	pop dx			;pobranie ze stosu z powrotem DX i AX
	pop ax
	call zakonczProgram			;skok do funkcji konczacej program
ret


;---------------------------------------------------------------------------------------------------------------------------------------------------------------------
;----------------------------------------------------###INICJALIZACJA DANYCH, ZAKONCZENIE PROGRAMU, DEKLARACJA STOSU###-----------------------------------------------
;---------------------------------------------------------------------------------------------------------------------------------------------------------------------
;-----------------------------------
;### Funkcja inicjalizujaca dane ###
;-----------------------------------
daneInit:
	mov ax,seg dane1
	mov ds,ax
ret
	
;--------------------------------
;### Funkcja konczaca program ###
;--------------------------------
zakonczProgram:
	mov ah,4ch		;funkcja 4ch
	int 21h			;przerwanie 21h konczace poprawnie program
	
code1 ends

;--------------------
;### Deklaracja stosu
;--------------------
stos1 segment stack
	dw 200 dup(?)
wStosu dw ?
stos1 ends

end start1