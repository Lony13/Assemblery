;*****************************************	
;******************ZADANIE_2**************
;*****************************************
;dopisac przy wszystkich funkcjach z plikami wyrzucenie potencjalnego bledu
dane1 segment
	argBuf		db 128 dup(?)	;bufor na argumenty z linii polecen
	licznik 	dw 0			;licznik uzywany w petlach programowych
	iloscArg 	db 0			;ilosc argumentow
	wskIn		dw	?			;wskaznik na plik wejscia
	wskOut		dw 	?			;wskaznik na plik wyjscia
	dzielnik	dw 10d			;dzielnik do petli przy wpisywaniu liczb do pliku
	liczba 		dw	?			;przy konwersji liczby
	linia		db 10,13,'$'	;nowa linia	
	wersja		db 0			;flaga wersji
	flaga		db 0			;flaga do liczenia linii
	
	arg1 db 30 dup ('$')		;tablica na pierwszy argument
	arg2 db 30 dup ('$')		;tablica na drugi argument

	nadpisac 	db "Plik istnieje. Nadpisac? [t/n]",10,13,'$'	;gdy plik istnieje
	errBrakArg	db "Brak argumentow",10,13,'$'					;gdy brak argumentow
	errZlaIlosc	db "Blad! Bledna ilosc argumentow",10,13,'$'	;gdy niewlasciwa ilosc argumentow
	errPlik		db "Nie udalo sie utworzyc pliku",10,13,'$'		;blad gdy nie utworzono poprawnie pliku
	errArg		db "Blad Argumentow",10,13,'$'					;blad podanych argumentow w linii polecen
	udanyZapis	db "Udalo sie zapisac",10,13,'$'				;gdy udalo sie zapisac poprawnie plik
	poprawny	db "Plik zawiera poprawne znaki",10,13,'$'		;gdy plik sprawdzany zawiera tylko dopuszczalne znaki
	nieAlfa		db "  Plik zawiera bledny znak",10,13,'$'		;gdy plik sprawdzany zawiera znak niedopuszczalny
	nrLinii		db "Blad jest w linii: ",'$'
	znak		db " Znak numer: ",'$'

	bufor			db 512d dup(0)			;bufor do wczytywania z pliku
	wczytaneZnaki	dw 0					;licznik wczytanych znakow, dw 0...65535, db 0...255
	sprawdzoneZnaki	dw 0					;licznik do czesci pierwszej
	sprawdzoneLinie	dw 0					;licnzik sprawdzonych linii w pierwszej czesci zadania
	ileZnakow		dw 0					;licznik wczytanych znakow w jednej porcji
	znakiInterp		db ".!?,:;-(){}[]<>",0	;znaki interpunkcyjne by latwiej bylo je zliczac
	
	litery			dw 0			;licznik liter
	cyfry			dw 0			;licznik cyfr
	bialeZnaki		dw 0			;licznik bialych znakow
	interpunkcyjne	dw 0			;licznik znakow interpunkcyjnych
	wyrazy			dw 0			;licznik wyrazow
	zdania			dw 0			;licznik zdan
	linie			dw 0			;licznik linii
	
	statLitery	dw 13,10,76,105,116,101,114,121,32,45,32					;'Litery -' a-z, A-Z
	statCyfr	dw 13,10,67,121,102,114,121,32,45,32						;'Cyfry - ' cyfry 0-9
	statBiale	dw 13,10,66,105,97,108,101,32,122,110,97,107,105,32,45,32	;'Biale znaki - ' czyli spacje i tabulatory
	statPunkc	dw 13,10,90,110,97,107,105,32,105,110,116,101,114,112,117,110,107,99,121,106,110,101,32,45,32 ;'Znaki interpunkcyjne -' czyli . , : ; ! ? - () {} [] <> ' 
	statWyrazy	dw 13,10,87,121,114,97,122,121,32,45,32						;'Wyrazy -' litery po ktorych nastepuje spacja lub tab
	statZdania	dw 13,10,90,100,97,110,105,97,32,45,32						;'Zdania -' zdania rozdzielane sa . ? !
	statLinie	dw 13,10,76,105,110,105,101,32,45,32						;'Linie -' dane mieszcza sie w przedziale 0 - 65535
	

dane1 ends

code1 segment
	assume cs:code1, ds:dane1	;dyrektywa assume informuje kompilator, z którego rejestru segmentowego ma korzystac przy odwolaniu sie do etykiet podanego segmentu
	start1:					;03ch tworzy nowy, 03dh - otwarcie, 03eh - zamyka plik, 03fh - ladowanie bajtami, 40h - zapis do pliku
	mov ax,seg wStosu		;za pomoca AX przenosimy adres
	mov ss,ax				;SS jest poczatkiem segmentu przeznaczonego na stos
	mov sp,offset wStosu	;SP to wskaznik stosu

	call daneInit			;inicjalizacja segmentu danych
	call wczytajArgumenty	;odczytanie argumentow

	cmp wersja,0			;jesli wersja pierwsza to bedzie 0
	jne drugaOpcja			;jesli nie to wykonujemy wersje z statystykami pliku
	
	call obslugaPliku		;obsluga pliku dla wersji pierwszej
	call zaladujBufor1		;ladowanie bufora i sprawdzanie znakow
	
	drugaOpcja:				;wywolania funkcji dla drugiej wersji
	call obslugaPlikow		;obsluga plikow dla drugiej wersji
	call zaladujBufor		;wywowalnie funkcji liczacych i zapisujacych

	call zakonczProgram		;wywolanie funkcji konczacej program
	
	
;*********************************************	
;******************PROCEDURY******************
;*********************************************
;-----------------------------------
;### Funkcja czytajaca argumenty ###
;-----------------------------------
wczytajArgumenty:
	push bx						;odkladamy BX na stos by go nie zgubic
	xor bx,bx					;szybkie zerowanie BX, przed uzyciem BL, alternatywa wykluczajaca
	mov bl,byte ptr es:[080h]	;pod adresem 080h znajduje sie liczba znakow argumentow, wkladamy je do BL, struktura PSP
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
	xor di,di					;szybkie zerowanie DI, ES:DI - adres logiczny argumentow z linii komend, alternatywa wykluczajaca
	mov cx,bx					;w CX jest ilosc znakow wczytanych z linii polecen
	dec cx						;pomijamy pierwszy znak ponieważ jest spacja
	xor bx,bx					;czyscimy BX,, alternatywa wykluczajaca
	mov ax,cx					;do AX przenosimy warosc z CX
	
	
	mov iloscArg,1d					;zaczynamy ustawiajac ilosc argumentow na 1 poniewaz zaczynamy wczytywanie od pierwszego
pSprawdzajaca:						;sprawdzanie wszystkich znakow
	mov al, byte ptr es:[082h+di]	;zaczynamy od drugiego bajtu argumentow
	
	call sprawdzZnak				;sprawdzamy czy bialy znak
	cmp ax,1						;jesli w AX jest 1 to jest bialy znak
	jne nieBialy					;jesli nie byl bialy to przeskakujemy dalej i nie dodajemy dolara
	
	cmp si,0						;jesli SI jest 0 to znaczy ze jeszcze nic nie wpisalismy do bufora wiec nie mozemy dac dolara
	jne nieBialeNaPoczatku			;instrukcja jest potrzebna gdy pojawia sie wiecej spacji przed pierwszym argumentem
	dec si							;dekrementujemy SI bo inaczej pierwsze miejsce w buforze bedzie wolne co spowoduje 
	jmp pominieto					;bledne dzialanie programu
	
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
	cmp iloscArg,2				;jesli argumenty sa 2 to przechodzimy dalej
	jne blednaIloscArg			;jesli niewlasciwa ilosc argumentow to wypisujemy blad
	xor ax,ax					;czyscimy AX, alternatywa wykluczajaca
	call wczytajArg				;wywolujemy funkcje wczytujaca argumenty do etykiet
	call sprawdzPoprawnosc		;sprawdzamy poprawnosc podanych argumentow wzgledem wytycznych w zadaniu
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
	xor ax,ax				;zerujemy AX, alternatywa wykluczajaca
	wczytajArg1:				;petla wczytujaca pierwszy argument do etykiety
		mov al,ds:[argBuf+di]	;pobieramy z bufora pierwszy znak
		mov ds:[arg1+si],al		;wpisujemy go do etykiet
		inc si					;inkrementyjac SI przechodzimy do kolejnego znaku
		inc di					;tak samo jak wyzej
		cmp al,'$'				;jesli bedzie dolar to wychodzimy z petli konczac wczytywanie argumentu
		jne wczytajArg1			;jesli nie byl dolar to znaczy ze argument sie jeszcze nie skonczyl
	mov al,0					;dopisywanie NULL na koncu by moc otworzyc plik
	mov ds:[arg1+si-1],al
	mov si,0				;zerujemy SI na potrzeby wczytywania drugiego argumentu do drugiej etykiety
	xor ax,ax				;czyscimy AX, alternatywa wykluczajaca
	wczytajArg2:				;petla wczytujaca drugi argument do etykiety
		mov al,ds:[argBuf+di]	;pobieramy z bufora znak zaczynajac od pierwszego znaku po dolarze
		mov ds:[arg2+si],al		;wpisujemy go do etykiety
		inc si					;inkrementujemy SI przechodzac do kolejnego znaku
		inc di					;inkrementujemy DI przechodzac do kolejnego miejsca w etykiecie
		cmp al,'$'				;jesli bedzie dolar to wychodzimy z petli konczac wczytywanie argumentu
		jne wczytajArg2			;jesli nie byl dolar to znaczy ze argument sie jeszcze nie skonczyl
	mov al,0					;dopisywanie NULL na koncu by moc otworzyc plik
	mov ds:[arg2+si-1],al
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
;-----------------------------------------------------------###FUNKCJE SPRAWDZAJACE POPRAWNOSC ARGUMENTOW###----------------------------------------------------------
;---------------------------------------------------------------------------------------------------------------------------------------------------------------------
;----------------------------------------------------------------------
;###Funkcja sprawdzajaca wersje w zaleznosci od pierwszego argumentu###
;----------------------------------------------------------------------
sprawdzPoprawnosc:
	push si				;wrzucamy SI na stos by nie zgubic
	mov wersja,0		;do wersji przypisujemy 0 czyli wersja pierwsza
	mov si,offset arg1	;do SI wsadzamy offset argumentu pierwszego
	lodsb				;ladujemy pierwszy bajt do AL, przeciwne stosb
	cmp al,'-'			;i sprawdzamy czy jest -
	jne wersja2			;jesli nie jest to znaczy ze wersja druga
	lodsb				;jesli byl to ladujemy kolejny bajt
	cmp al,'v'			;i sprawdzamy czy jest v
	jne wersja2			;jesli nie jest to zmieniamy wersje na druga
	lodsb				;jesli byl to ladujemy kolejny bajt
	cmp al,0			;i sprawdzamy czy jest NULL
	je wersja1			;jesli jest to znaczy ze mamy wersje pierwsza
	wersja2:			;jesli jest wersja druga
	mov wersja,1		;to wpisujemy 1 do wersji, nasza flaga 0 - wersja pierwsza, 1 - wersja druga
	wersja1:			;jesli wersja jeden to wychodzimy
	pop si
ret


;---------------------------------------------------------------------------------------------------------------------------------------------------------------------
;-----------------------------------------------------------###OBSLUGA PLIKOW DO WERSJI PIERWSZEJ###------------------------------------------------------------------
;---------------------------------------------------------------------------------------------------------------------------------------------------------------------
;------------------------------------------------
;----###Funkcja otwierajaca plik wejsciowy###----
;------------------------------------------------
obslugaPliku:
	;Plik Wejscia - otwarcie pliku, w DX adres lancucha ASCII zakonczony 0, okreslajacy nazwe i sciezke do pliku
	push ax						;odkladamy na stos wszystko co bedziemy uzywac
	push bx
	push dx
	mov dx, offset arg2			;otwieramy plik do odczytu z arg2, zakonczone zerem
	mov al,0					;ustawiamy tylko do odczytu, 0 - read only, 1 - zapis, 2 - to i to
	mov ah,03dh					;funkcja 03dh, funkcja otwarcia pliku - 03ch tworzy nowy, 03dh - otwarcie, 03eh - zamyka plik, 03fh - ladowanie bajtami, 40h - zapis do pliku
	int 21h						;przerwanie 21h (otwiera plik)
	jc bladPlik					;flaga CF (carry flag) jest ustawiona jesli wystapi blad, 1 - jesli blad, 0 - jesli poprawne
	mov word ptr wskIn,ax		;nie ma bledu, wiec w AX znajduje sie wskaznik do pliku (uchwyt), zapisujemy go
	pop dx						;zdejmujemy wszystko ze stosu
	pop bx
	pop ax
ret

;------------------------------------------------
;------##Funkcja ladujaca bufor z pliku###-------
;------------------------------------------------
zaladujBufor1:
	push dx
	push bx
	push cx
	push ax				;w BX uchwyt pliku, w CX liczba bajtow do przeczytania
	mov bx,wskIn		;przenosimy do BX wskaznik na plik
	mov cx,512d			;przenosimy do CX ile bajtow pomiesci bufor
	czyKoniec:			;czytamy petle az nie skonczy sie plik
		lea dx,bufor	;do DX wsadzamy offset bufora, lea dx,tablica <=> mov dx,offset tablica
		xor ax,ax		;zerujemy AX, xor -> 1 1 -> 0, 0 0 -> 0, 1 0 -> 1, 0 1 -> 1, alternatywa wykluczajaca
		mov bx,wskIn	;do BX ladujemy wskaznik pliku wejsciowego
		mov ah,3fh		;fukncja 3fh, laduje bufor w DX z pliku BX,CX bajtami - 03ch tworzy nowy, 03dh - otwarcie, 03eh - zamyka plik, 03fh - ladowanie bajtami, 40h - zapis do pliku
		int 21h			;przerwanie, w AX znajduje sie liczba wczytanych znakow
		add wczytaneZnaki,ax	;powiekszamy zasob wczytanych znakow o AX, w AX zapisuje sie ile bajtow wczytano
		mov ileZnakow,ax		;potrzebne by wiedziec ile razy wykonac petle
		call alfanumeryczne		;sprawdzamy czy znaki sa prawidlowe
		cmp ax,512d				;sprawdzamy czy AX jest rowne rozmiarowi bufora, jezeli jest to znaczy ze musimy kontynuowac wczytywanie
		je czyKoniec
	pop ax
	pop cx
	pop bx
	pop dx
	call zamknieciePliku		;zamykamy plik
	call poprawnyPlik			;i wypisujemy komunikat o poprawnym pliku
ret

;------------------------------------------------
;###Funkcja sprawdzajaca znaki alfanumeryczne###-
;------------------------------------------------
alfanumeryczne:		;moga wystapis a-z, A-Z, 0-9, znaki interpunkcyjne (. , ; - ? ! : " ( ) [ ] { } ), spacje, tabulatory, znaki nowej linii
	;nie moga wystapic @,#,$,%,^,&,*,<,>,\,/,|,+,=,ą,ę,ż,ź,ł
	push bx
	push cx
	push dx
	mov cx,ax		;sprawdzamy tyle razy ile sie zaladowalo znakow
	push ax			;po wrzuceniu wartosci AX do CX mozemy AX odlozyc na stos by nie zgubic
	xor di,di		;czyscimy DI, alternatywa wykluczajaca
	sprawdzaj:		;petla sprawdzajaca czy znaki sa dopuszczalne
		xor ax,ax							;zerujemy AX, alternatywa wykluczajaca
		mov al, byte ptr ds:[bufor+di]		;ladujemy do AL odpowiedni znak zaladowanych wczesniej do bufora
		cmp al,35		;35 to #			;po kolei sprawdzamy czym jest nasz znak w AL i w zaleznosci od
		jb dobryZnak						;tego czym jest albo sprawdzamy dalej albo wypisujemy odpowiedni
		cmp al,40		;40 to (			;komunikat o bledzie
		jb zlyZnak
		cmp al,42		;42 to *
		jb dobryZnak
		cmp al,44		;44 to ,
		jb zlyZnak
		cmp al,47		;47 to /
		jb dobryZnak
		cmp al,48		;48 to 0
		jb zlyZnak
		cmp al,60		;60 to <
		jb dobryZnak
		cmp al,63		;63 to ?
		jb zlyZnak
		cmp al,64		;64 to @
		jb dobryZnak
		cmp al,65		;65 to A
		jb zlyZnak
		cmp al,92		;92 to \,
		jb dobryZnak
		cmp al,93		;93 to ]
		jb zlyZnak
		cmp al,94		;94 to ^
		jb dobryZnak
		cmp al,97		;97 to a
		jb zlyZnak
		cmp al,124		;124 to |
		jb dobryZnak
		cmp al,125		;125 to }
		jb zlyZnak
		cmp al,126		;126 to ~
		jb dobryZnak
		cmp al,126		;wyzsze numery nie pasuja
		ja zlyZnak
		dobryZnak:
		inc di								;powiekszamy DI by przejsc do nastepnego znaku
		inc word ptr ds:[sprawdzoneZnaki]	;zwiekszamy ilosc sprawdzonych znakow w obecnej linii
		cmp al,13							;jesli AL jest rowne 13 to mozliwe ze napotkalismy enter czyli nowa linie
		jne nieNowaLinia					;jesli nie jest 13 to pomijamy zmiane flagi
		mov flaga,1							;jesli jest to ustawiamy flage na 1 by przy nastepnym sprawdzeniu zobaczyc czy AL bedzie 10
		nieNowaLinia:						
		cmp al,10							;jesli AL jest rozne od 10 to nie mamy nowej linii
		jne nieLinia						;ale jesli jest to musimy sprawdzic flage
		cmp flaga,1							;jesli flaga jest ustawiona na 1 to znaczy ze mamy nowa linie
		jne nieLinia						;jesli nie to po prostu idziemy dalej
		inc word ptr ds:[sprawdzoneLinie]	;inkrementujemy ilosc linii
		mov word ptr ds:[sprawdzoneZnaki],0	;i ustawiamy znaki na 0 gdzyz zaczynamy nowa linie od pierwszego znaku
		mov flaga,0							;flage ustawiamy ponownie na 0
		nieLinia:
	loop sprawdzaj		
	pop ax				;zdejmujemy wszystko ze stosu
	pop dx
	pop cx
	pop bx
ret
	
zlyZnak:					;jesli wystapil zly znak
	push ax					;odkladamy na stos AX
	lea ax,nrLinii			;do AX dajemy napis do wypisania, lea dx,tablica <=> mov dx,offset tablica
	call axPrint			;i wywolujemy funkcje drukujaca na ekran
	
	mov ax,sprawdzoneLinie	;przenosimy do AX ilosc linii ktore sprawdzilismy zanim znalezlismy blad
	add ax,1				;powiekszamy o jeden by sie zgadzalo
	call wypiszLiczbe		;wywolujemy wypisanie liczby na ekran
	
	lea ax,znak				;do AX dajemy napisa do wypisania, lea dx,tablica <=> mov dx,offset tablica
	call axPrint			;i wywolujemy funkcje drukujaca na ekran
	
	mov ax,sprawdzoneZnaki	;przenosimy do AX ilosc znakow ktore sprawdzilismy w obecnej linii przed znalezieniem bledu
	add ax,1				;powiekszamy o 1 by sie zgadzalo
	call wypiszLiczbe		;wywolujemy wypisanie liczby na ekran
	pop ax					;zdejmujemy AX ze stosu
	call zamknieciePliku	;zamykamy plik
	call zakonczProgram		;wywolujemy funkcje konczaca program
ret

;------------------------------------------------
;----###Funkcja wypisujaca liczbe na ekran###----
;------------------------------------------------
wypiszLiczbe:
	push dx
	push bx
	push cx
	mov licznik,0					;licznik cyfr danej liczby
	dziele:
		mov dx,0 					;do DX dajemy 0 gdyz po dzieleniu bedzie tam reszta
		div dzielnik 				;dziele AX:DX przez dzielnik, czyli 10d
		inc licznik 				;+ilosc cyfr
		push dx 					;w DX umieszczona jest reszta z dzielenia, zapisuje ja na stosie
		cmp ax, 0 					;jesli AX jest rozne od zera 
	jne dziele						;dziel dalej
	mov cx, word ptr ds:[licznik] 	;moze byc samo licznik, moze byc samo word ptr, bo word ptr robi konwersje z bajta na word, a ds: daje znak ze to jest z segmentu danych ds
	wypisanieLiczby:
		pop dx						;sciagnij cyfre o najwiekszym znaczeniu ze stosu
		push cx
		add dx,48d 					;dodaj do niej 48, aby zmapowac ja na kod ascii
		mov liczba,dx				;przepisujemy nasza liczbe do etykietki by moc ja zapisac
		mov dx,liczba				;teraz wkladamy miejsce jej zapisu do DX co sprawi ze bedziemy mogli ja zapisac do pliku
		xor ax,ax					;alternatywa wykluczajaca
		mov ah,2h					;funkcja wypisujaca znak na ekran					
		int 21h
		pop cx
	loop wypisanieLiczby
	pop cx
	pop bx
	pop dx
ret

;------------------------------------------------
;----###Funkcja zamykajaca plik wejsciowy###-----
;------------------------------------------------
zamknieciePliku:
	push ax
	push bx
	xor ax,ax					;czyscimy AX, alternatywa wykluczajaca
	mov bx, word ptr wskIn		;przekazujemy do BX wskaznik pliku
	mov ah,03Eh					;funkcja 03Eh, funkcja zamykajaca plik - 03ch tworzy nowy, 03dh - otwarcie, 03eh - zamyka plik, 03fh - ladowanie bajtami, 40h - zapis do pliku
	int 21h						;przerwanie 21h (zamyka plik)
	jc bladPlik					;flaga CF ustawiona, gdy blad zamkniecia pliku
	pop bx
	pop ax
ret
	

;---------------------------------------------------------------------------------------------------------------------------------------------------------------------
;------------------------------------------------------------###OBSLUGA PLIKOW DO WERSJI DRUGIEJ###-------------------------------------------------------------------
;---------------------------------------------------------------------------------------------------------------------------------------------------------------------
;------------------------------------------------
;--------###Funkcja otwierajaca pliki###---------
;------------------------------------------------
obslugaPlikow:
	;Plik Wejscia - otwarcie pliku
	push ax
	push bx
	push dx
	mov dx, offset arg1			;otwieramy plik do odczytu z arg1
	mov al,0					;ustawiamy tylko do odczytu, 0 - read only, 1 - zapis, 2 - to i to
	mov ah,03dh					;funkcja 03dh, funkcja otwarcia pliku - 03ch tworzy nowy, 03dh - otwarcie, 03eh - zamyka plik, 03fh - ladowanie bajtami, 40h - zapis do pliku
	int 21h						;przerwanie 21h (otwiera plik)
	jc bladPlik					;flaga CF (carry flag) jest ustawiona jesli wystapi blad
	mov word ptr wskIn,ax		;nie ma bledu, wiec w AX znajduje sie wskaznik do pliku (uchwyt), zapisujemy go
	;Plikk Wyjscia - otwarcie pliku
	mov dx, offset arg2			;otwieramy plik do zapisu z arg 2
	mov al,1					;ustawiamy do zapisu
	mov ah,03dh					;funkcja 03dh - 03dh - otwarcie, 03fh - ladowanie bajtami, 03eh - zamyka plik, 40h - zapis do pliku, 03ch - nadpisuje
	int 21h						;przerwanie 21h
	jnc nadpisz					;carry flag = 0? brak bledow, czyli plik istnieje, nadpisac ?
	jmp utworzPlik				;jesli plik nie istnieje to tworzymy nowy			
nadpisz:
	jmp nadpisanie				;funkcja nadpisania istniejacego pliku
utworzono:
	mov dx,offset arg2			;otwieramy plik do zapisu z arg2 po tym jak go utworzylismy
	mov al,1					;ustawiamy do zapisu
	mov ah,03dh					;funkcja 03dh - 03ch tworzy nowy, 03dh - otwarcie, 03eh - zamyka plik, 03fh - ladowanie bajtami, 40h - zapis do pliku
	int 21h						;przerwanie 21h
	mov word ptr wskOut,ax		;jesli pomyslnie otwarto, daj wsk do pliku do zmiennej
	pop dx
	pop bx
	pop ax
ret

;------------------------------------------------
;------###Funkcja pytajaca czy nadpisac###-------
;------------------------------------------------
nadpisanie:
	push ax
	push bx
	push cx
	push dx
	lea ax,nadpisac			;adres zapytania, lea dx,tablica <=> mov dx,offset tablica
	call axPrint			;wypisujemy na ekran
oczekiwanie:				;oczekujemy na potwierdzajacy klawisz
	xor ax,ax				;alternatywa wykluczajaca
	mov ah,8				;funkcja 8, wczytuje znak z konsoli
	int 21h					;przerwanie 21h, czeka na wcisniecie klawisza, a nastepnie zapisuje jego kod ascii do AL
	cmp al,'t'				;sprawdzamy czy AL jest rowne t
	je utworzPlikPop		;jesli jest to tworzymy plik
	cmp al,'n'				;jesli nie to sprawdzamy czy wcisnal n
	je zakonczProgram		;jesli tak to konczymy program
	jne oczekiwanie			;jesli wcisnal bledny znak to oczekujemy ponownie na poprawny
	pop dx
	pop cx
	pop bx
	pop ax
ret
	
;------------------------------------------------
;-------------###Wypisanie z AX###---------------
;------------------------------------------------
axPrint:
	push ax
	push dx
	mov dx,ax
	xor ax,ax		;alternatywa wykluczajaca
	mov ah,9		;funkcja 9, czyli wypisz lancuch
	int 21h
	pop dx
	pop ax
ret
	
;------------------------------------------------
;---###Funkcja tworzaca nowy plik do zapisu###---
;------------------------------------------------
utworzPlikPop:			;musimy zdjac ze stosu wszystkie rejestry odlozone 
	pop dx				;w poprzedniej funkcji gdzy nie bedziemy juz do niej wracac
	pop cx				;a jesli tego nie zrobimy to zepsujemy cala kolejnosc
	pop bx				;na stosie co spowoduje nie dzialanie niektorych ret'ow
	pop ax
utworzPlik:
	push ax
	push bx
	push cx
	push dx
	;tworzenie nowego pliku
	xor ax,ax			;czyscimy AX, alternatywa wykluczajaca
	mov ah,03ch			;funkcja 03ch przerwania 21h tworzy, nadpisuje plik - 03ch tworzy nowy, 03dh - otwarcie, 03eh - zamyka plik, 03fh - ladowanie bajtami, 40h - zapis do pliku
	mov cl,0			;atrybuty nadawane plikowi, brak, bit 0 - tylko do odczytu, bit 1 - ukryty, bit 2 - systemowy, bit 5 - archiwalny
	lea dx,arg2			;tworzymy plik o nazwie arg2, lea dx,tablica <=> mov dx,offset tablica
	int 21h				;funkcja przerwania 21h
	jc bladPlik			;jesli CF (carry flag - flaga przeniesienia) jest ustawiona (jej bit jest rowny 1) to mamy blad zapisu
	pop dx
	pop cx
	pop bx
	pop ax
	jmp utworzono
ret

;------------------------------------------------
;---###Funkcja tworzaca nowa linie w pliku###----
;------------------------------------------------
nowaLinia:
	push dx
	push bx
	push cx
	mov bx,word ptr wskOut	;do BX przekazujemy wskaznik na plik wyjscia
	xor ax,ax				;zerujemy AX, alternatywa wykluczajaca
	mov cx,4d				;4 bajty do tego sa potrzebne, w CX jest ilosc bajtow do zapisu do pliku
	mov ah,40h				;40h - funkcja zapisu do pliku - 03ch tworzy nowy, 03dh - otwarcie, 03eh - zamyka plik, 03fh - ladowanie bajtami, 40h - zapis do pliku
	lea dx,linia	 		;adres nowej linii (13,10), lea dx,tablica <=> mov dx,offset tablica
	int 21h
	pop cx
	pop bx
	pop dx
ret

;------------------------------------------------
;---------###Funkcja zamykajaca pliki###---------
;------------------------------------------------
zamknijPliki:
	push ax
	push bx
	xor ax,ax					;alternatywa wykluczajaca
	mov bx,word ptr wskIn		;przekazujemy do BX wskaznik
	mov ah,03Eh					;funkcja 03eh, zamykanie pliku - 03ch tworzy nowy, 03dh - otwarcie, 03eh - zamyka plik, 03fh - ladowanie bajtami, 40h - zapis do pliku
	int 21h						;przerwanie 21h zamyka plik
	jc bladPlik					;flaga CF ustawiona, gdy blad zamkniecia pliku
	mov bx, word ptr wskOut		;przekazujemy do BX wskaznic na drugi plik
	xor ax,ax					;czyscimy AX, alternatywa wykluczajaca
	mov ah,03Eh					;zamykamy drugi plik - 03ch tworzy nowy, 03dh - otwarcie, 03eh - zamyka plik, 03fh - ladowanie bajtami, 40h - zapis do pliku
	int 21h						;przewanie 21h zamyka plik
	jc bladPlik					;jesli flaga ustawiona to wypisujemy blad
	call dobryZapis				;jesli wszystko OK to wypisujemy odpowiedni napis
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
	push ax						;w BX uchwyt pliku, w CX liczba bajtow do przeczytania
	inc word ptr ds:[linie]		;poniewaz zaczynamy sprawdzanie od linii 1 a nie 0
	mov bx,wskIn		;przenosimy do BX wskaznik na plik
	mov cx,512d			;przenosimy do CX ile bajtow pomiesci bufor
	czyKoniecPliku:		;czytamy petle az nie skonczy sie plik
		lea dx,bufor	;do DX wsadzamy offset bufora, lea dx,tablica <=> mov dx,offset tablica
		xor ax,ax		;zerujemy AX, alternatywa wykluczajaca
		mov bx,wskIn	;do BX ladujemy wskaznik pliku wejsciowego
		mov ah,3fh		;fukncja 3fh, laduje bufor w DX z pliku BX,CX bajtami - 03ch tworzy nowy, 03dh - otwarcie, 03eh - zamyka plik, 03fh - ladowanie bajtami, 40h - zapis do pliku
		int 21h			;przerwanie
		add wczytaneZnaki,ax	;powiekszamy zasob wczytanych znakow o AX, w AX zapisuje sie ile bajtow wczytano
		mov ileZnakow,ax		;potrzebne by wiedziec ile razy wykonac petle
		call zliczaj			;wypelniamy tablice odpowiednimi bajtami
		cmp ax,512d				;sprawdzamy czy AX jest rowne rozmiarowi bufora, jezeli jest to znaczy ze musimy kontynuowac wczytywanie
		je czyKoniecPliku
	pop ax
	pop cx
	pop bx
	pop dx
	call zapiszDoPliku		;wywolujemy funkcje zapisu do pliku 
	call zamknijPliki		;nastepnie zamykamy pliki
	call dobryZapis			;i wypisujemy odpowiedni komunikat
ret

;------------------------------------------------
;-------##Funkcja zliczajaca statystyki###-------
;------------------------------------------------
zliczaj:
	push bx
	push cx
	push dx
	mov licznik,ax						;petla wykona sie tyle razy ile zaladowalo sie znakow
	push ax								;teraz odkladamy AX na stos by go nie zgubic
	xor di,di							;czyscimy DI gdzyz przy jego pomocy bedziemy sie przesuwac, alternatywa wykluczajaca
	sprawdzam:
		xor ah,ah						;czyscimy AH gdyz tam bedzie nasza flaga czy znaleziono dany element, alternatywa wykluczajaca		
		mov al,byte ptr ds:[bufor+di]	;do AL wkladamy obecny znak do sprawdzenia
		jmp sprawdzZnaki				;skaczemy do funkcji sprawdzajacych znak
		poSprawdzeniu:					;po sprawdzeniu
		inc di							;inkrementujemy DI by przejsc do nastepnego znaki
		dec licznik						;dekrementujemy licznik znakow do sprawdzenia
		cmp licznik,0					;jesli 0 to sprawdzilismy wszystko i wracamy
		jne sprawdzam					;jesli nie to sprawdzamy dalej
	jmp sprawdzonoPartie				;jesli sprawdzono wszystko to wracamy do ladowania koleinych znakow o ile sa
		
	sprawdzZnaki:
	call czyLitera
		cmp ah,1
		je poSprawdzeniu
	call czyCyfra
		cmp ah,1
		je poSprawdzeniu
	call czyBialy
		cmp ah,1
		je poSprawdzeniu
	call czyInterpunkcyjny
		cmp ah,1
		je poSprawdzeniu
	call czyNowaLinia
		cmp ah,1
		je poSprawdzeniu
	jmp poSprawdzeniu
	
	sprawdzonoPartie:
	pop ax
	pop dx
	pop cx
	pop bx
ret
	
;------------------------------------------------
;------##Funkcja sprawdzajaca czy litera###------
;------------------------------------------------
czyLitera:
	push bx
	push cx
	push dx
	xor ah,ah		;alternatywa wykluczajaca
	cmp al,'A'
	jb nieLitera
	cmp al,91		;pierwszy znak po Z
	jb jestLitera
	cmp al,'a'
	jb nieLitera
	cmp al,'z'
	ja nieLitera
	jestLitera:
	mov ah,1
	inc word ptr ds:[litery]
	nieLitera:
	pop dx
	pop cx
	pop bx
ret

;------------------------------------------------
;-------##Funkcja sprawdzajaca czy cyfra###------
;------------------------------------------------
czyCyfra:
	push bx
	push cx
	push dx
	xor ah,ah		;alternatywa wykluczajaca
	cmp al,'0'
	jb nieCyfra
	cmp al,'9'
	ja nieCyfra
	mov ah,1
	inc word ptr ds:[cyfry]
	nieCyfra:
	pop dx
	pop cx
	pop bx
ret

;------------------------------------------------
;----##Funkcja sprawdzajaca czy bialy znak###----
;------------------------------------------------
czyBialy:
	push dx
	push cx
	xor ah,ah		;zerujemy by moc potem zapisac tu czy byl bialy znak, alternatywa wykluczajaca
	cmp al,9d
	je jestBialy
	cmp al,32d
	je jestBialy
	jmp nieBialyZnak
	jestBialy:
	mov ah,1
	inc word ptr ds:[bialeZnaki]
	call czyKoniecSlowa
	mov ah,1		;jesli nie bylo konca slowa to musimy ponownie dac do AH=1 bo inaczej zwroci sie z 0
	nieBialyZnak:
	pop cx
	pop dx
ret

;-------------------------------------------------
;##Funkcja sprawdzajaca czy znak interpunkcyjny###
;-------------------------------------------------
czyInterpunkcyjny:
	push cx
	push bx
	push si
	xor si,si							;zerujemy SI bo bedziemy nim skakac po tablicy, alternatywa wykluczajaca
	mov bx,offset znakiInterp			;do BX ladujemy offset tablicy ze znakami
	sprawdzCzyInterpunkcyjny:
		cmp al,byte ptr ds:[bx+si]		;element z tablicy porownojemy z AL
		je jestInterpunkcyjny
		inc si							;nastepny element
		cmp byte ptr ds:[bx+si],0		;sprawdzenie czy koniec tablicy
		jne sprawdzCzyInterpunkcyjny
	jmp nieByloInterp
	jestInterpunkcyjny:
	mov ah,1							;jesli byl to nasza flaga = 1	
	inc word ptr ds:[interpunkcyjne]	
	cmp si,2							;jesli SI wieksze od 2 to nie mamy konca znadnia
	ja nieKoniecZdania
	mov al,byte ptr ds:[bufor+di-1]		;jesli byl .!? to sprawdzamy poprzedni znak 
	call czyLitera
	cmp ah,1					
	jne nieKoniecZdania
	inc word ptr ds:[wyrazy]
	inc word ptr ds:[zdania]
	dec word ptr ds:[litery]
	jmp nieByloInterp
	nieKoniecZdania:					;jesli nie bylo .!? to sprawdzmy czy nie koniec slowa
	mov al,byte ptr ds:[bufor+di-1]
	call czyLitera
	cmp ah,1
	jne nieByloSlowa
	inc word ptr ds:[wyrazy]
	dec word ptr ds:[litery]
	nieByloSlowa:
	mov ah,1							;by zwrocic prawidlowe AH
	nieByloInterp:
	pop si
	pop bx
	pop cx
ret
	
	
;------------------------------------------------
;----##Funkcja sprawdzajaca czy nowa linia###----
;------------------------------------------------
czyNowaLinia:
	cmp al,10
	jne	nieNewLine 
	inc word ptr ds:[linie]
	nieNewLine:
ret

;------------------------------------------------
;---##Funkcja sprawdzajaca czy koniec slowa###---
;------------------------------------------------
czyKoniecSlowa:						;wywolujemy w sprawdzeniu bialego znaku
	dec di
	mov al,byte ptr ds:[bufor+di]
	call czyLitera
	inc di
	cmp ah,1
	jne nieKoniecSlowa
	inc word ptr ds:[wyrazy]
	dec word ptr ds:[litery]
	nieKoniecSlowa:
ret

;------------------------------------------------
;--------##Funkcja zapisujaca do pliku##---------
;------------------------------------------------
zapiszDoPliku:
	push ax
	push bx
	push cx
	push dx
	;Litery
	mov bx,offset statLitery	;w BX offset
	mov dx,bx					;przenosimy do DX
	mov cx,22					;ilosc znakow do zapisania
	call zapiszTekst
	mov ax,word ptr ds:[litery]	;teraz do AX liczba do wpisania
	call zapiszLiczbe
	;Cyfry
	mov bx,offset statCyfr
	mov dx,bx
	mov cx,20
	call zapiszTekst
	mov ax,word ptr ds:[cyfry]
	call zapiszLiczbe
	;Biale Znaki
	mov bx,offset statBiale
	mov dx,bx
	mov cx,32
	call zapiszTekst
	mov ax,word ptr ds:[bialeZnaki]
	call zapiszLiczbe
	;Znaki Interpunkcyjne
	mov bx,offset statPunkc
	mov dx,bx
	mov cx,50
	call zapiszTekst
	mov ax,word ptr ds:[interpunkcyjne]
	call zapiszLiczbe
	;Wyrazy
	mov bx,offset statWyrazy
	mov dx,bx
	mov cx,22
	call zapiszTekst
	mov ax,word ptr ds:[wyrazy]
	call zapiszLiczbe
	;Zdania
	mov bx,offset statZdania
	mov dx,bx
	mov cx,22
	call zapiszTekst
	mov ax,word ptr ds:[zdania]
	call zapiszLiczbe
	;Linie		
	mov bx,offset statLinie
	mov dx,bx
	mov cx,20
	call zapiszTekst
	mov ax,word ptr ds:[linie]
	call zapiszLiczbe
	pop dx
	pop cx
	pop bx
	pop ax
ret

;------------------------------------------------
;-----##Funkcja zapisujaca tekst do pliku##------
;------------------------------------------------
zapiszTekst:
	push ax					;w DX mamy poczatek miejsca w pamieci z ktorego zapisujemy
	mov bx,word ptr wskOut	;w CX ilosc bajtow do zapisu a w BX uchwyt pliku
	mov ah,40h				;funkcja 40h zapisujaca do pliku - 03ch tworzy nowy, 03dh - otwarcie, 03eh - zamyka plik, 03fh - ladowanie bajtami, 40h - zapis do pliku
	int 21h
	pop ax
ret

;------------------------------------------------
;-----##Funkcja zapisujaca liczbe do pliku##-----
;------------------------------------------------
zapiszLiczbe:						;w AX mamy liczbe do zapisania
	push dx
	push bx
	push cx
	mov licznik,0					;licznik cyfr danej liczby
	dziel:
		mov dx,0 					;do DX dajemy 0 gdyz po dzieleniu bedzie tam reszta
		div dzielnik 				;dziele AX:DX przez dzielnik, czyli 10d
		inc licznik 				;+ilosc cyfr
		push dx 					;w DX umieszczona jest reszta z dzielenia, zapisuje ja na stosie
		cmp ax, 0 					;jesli ax jest rozne od zera 
	jne dziel						;dziel dalej
	mov cx, word ptr ds:[licznik] 	;moze byc samo licznik, moze byc samo word ptr, bo word ptr robi konwersje z bajta na word, a ds: daje znak ze to jest z segmentu danych ds
	wypisanie:
		pop dx						;sciagnij cyfre o najwiekszym znaczeniu ze stosu
		push cx
		add dx,48d 					;dodaj do niej 48, aby zmapowac ja na kod ascii
		mov liczba,dx				;przepisujemy nasza liczbe do etykietki by moc ja zapisac
		lea dx,liczba				;teraz wkladamy miejsce jej zapisu do DX co sprawi ze bedziemy mogli ja zapisac do pliku
		xor ax,ax					;lea dx,tablica <=> mov dx,offset tablica, alternatywa wykluczajaca
		mov ah,40h					;funkcja wpisujaca do pliku - 03ch tworzy nowy, 03dh - otwarcie, 03eh - zamyka plik, 03fh - ladowanie bajtami, 40h - zapis do pliku
		mov cx,2d					;co dwa sie przesuwac trzeba
		int 21h
		pop cx
	loop wypisanie
	pop cx
	pop bx
	pop dx
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
;***Jesli udany zapis
dobryZapis:
	mov ax,offset udanyZapis
	call errorPrint
;***Jesli poporawny plik	
poprawnyPlik:
	mov ax,offset poprawny
	call errorprint
;***Jesli jest bledny znak
blednyZnak:	
	mov ax,offset nieAlfa
	call errorPrint
	
;-------------------------------
;### Funkcja wypisujaca z AX ###
;-------------------------------
errorPrint:
	push ax			;odkladamy na stos AX i DX poniewaz beda za chwile uzywane
	push dx
	mov dx,ax		;przenosimy to co mamy wypisac z AX do DX
	xor ax,ax		;czyscimy AX, alternatywa wykluczajaca
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