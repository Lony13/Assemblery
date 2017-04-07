;*****************************************	
;******************ZADANIE_1**************
;*****************************************
dane1 segment
	argBuf		db 200 dup(?)	;bufor na argumenty z linii polecen
	licznik 	dw 0			;licznik uzywany w petlach programowych
	iloscArg 	db 0			;ilosc argumentow
	szachownica	db 153 dup (0)	;szachownica 17 na 9
	miejsceKonca	dw 1		;polozenie gonca na koniec skokow
	binary		db 17 dup (?)	;tablica zawierajaca zapis binarny klucza, jedno miejsce na dolar na koncu
	nowaLinia	db 10,13,'$'	;nowa linia	

	arg1 db 30 dup ('$')		;tablica na pierwszy argument
	arg2 db 30 dup ('$')		;tablica na drugi argument

	errBrakArg	db "Blad! Brak argumentow!",10,13,'$'
	errZlaIlosc	db "Blad! Bledna ilosc argumentow",10,13,'$'
	errArg1		db "Blad! Pierwszy argument musi byc 0 lub 1",10,13,'$'
	errDlugosc	db "Blad! Drugi argument musi byc 32-znakowy",10,13,'$'
	errHeksa	db "Blad! Drugi argument musi byc podany w systemie szestnastkowym",10,13,'$'
	znaki		db		' ','.', 'o', '+', '=', '*', 'B', 'O', 'X', '@', '%', '&', '#', '/','^' ;znaki potrzebne do tablicy wynikowej
	goraRamki	db '+--[ RSA 1024]----+',10,13,'$'
	dolRamki	db '+-----------------+',10,13,'$'
	
dane1 ends


code1 segment
	assume cs:code1, ds:dane1	;dyrektywa assume informuje kompilator, z którego rejestru segmentowego ma korzystac przy odwolaniu sie do etykiet podanego segmentu
	start1:
	mov ax,seg wStosu		;za pomoca AX przenosimy adres
	mov ss,ax				;SS jest poczatkiem segmentu przeznaczonego na stos
	mov sp,offset wStosu	;SP to wskaznik stosu

	call daneInit			;inicjalizacja segmentu danych
	call wczytajArgumenty	;odczytanie argumentow
	call zmianaNaBinary		;zamiana klucza na postac binarna
	callBack:
	call move				;funkcja wywolujaca ruch gonca
	moveBack:	
	call zamienNaZnaki		;funkcja zamieniajaca ilosc ruchow na znak ASCII-Art
	call rysuj				;funkcja rysujaca tablice

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
	je bialeNaPoczatku				;instrukcja jest potrzebna gdy pojawia sie wiecej spacji przed pierwszym argumentem
	
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
	xor ax,ax					;czyscimy AX
	call wczytajArg				;wywolujemy funkcje wczytujaca argumenty do etykiet
	call sprawdzPoprawnosc		;sprawdzamy poprawnosc podanych argumentow wzgledem wytycznych w zadaniu
	pop si						;pobieramy ze stosu wszystkie wartosci ktore odlozylismy na
	pop di						;poczatku funkcji
	pop dx
	pop cx
	pop bx
	pop ax
ret

;-------------------------------
bialeNaPoczatku:			;wywolujemy jesli przed pierwszym argumentem pojawia sie wiecej spacji
	dec si					;dekrementujemy wtedy SI by nie przeskoczylo nam miejsce w buforze argumentow gdyz spowodowalo
	call pominieto			;by to nie nadpisanie niczym pierwszego miejsca i wywolalo bledne dzialanie programu
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

	mov si,0				;zerujemy SI na potrzeby wczytywania drugiego argumentu do drugiej etykiety
	xor ax,ax				;czyscimy AX
	wczytajArg2:				;petla wczytujaca drugi argument do etykiety
		mov al,ds:[argBuf+di]	;pobieramy z bufora znak zaczynajac od pierwszego znaku po dolarze
		mov ds:[arg2+si],al		;wpisujemy go do etykiety
		inc si					;inkrementujemy SI przechodzac do kolejnego znaku
		inc di					;inkrementujemy DI przechodzac do kolejnego miejsca w etykiecie
		cmp al,'$'				;jesli bedzie dolar to wychodzimy z petli konczac wczytywanie argumentu
		jne wczytajArg2			;jesli nie byl dolar to znaczy ze argument sie jeszcze nie skonczyl
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
;------------------------------------------------
;###Funkcja sprawdzajaca poprawnosc argumentow###
;------------------------------------------------
sprawdzPoprawnosc:
	call sprawdzDlugoscPierwszego		;wywolanie sprawdzenia dlugosci pierwszego argumentu
	call sprawdzPoprawnoscPierwszego	;sprawdzenie poprawnosci pierwszego argumentu
	call sprawdzDlugoscDrugiego			;wywolanie sprawdzenia dlugosci drugiego argumentu
	call sprawdzPoprawnoscDrugiego		;sprawdzenie poprawnosci drugiego argumentu
ret
	
	
;------------------------------------------------
sprawdzDlugoscPierwszego:
	mov si,offset arg1		;przenosimy do SI offset etykiety z argumentem pierwszym
	mov licznik,0			;zerujemy licznik ktory bedzie uzywany w petli	
liczDlugosc:				;petla liczaca dlugosc pierwszego argumentu
	lodsb					;ladujemy do AL pierwszy bajt
	cmp al,'$'				;sprawdzamy czy jest $, jesli jest to koniec argumentu
	je porownaj				;jesli byl dolar to mozemy sprawdzic czy dlugosc sie zgadza
	inc licznik				;jesli nie bylo dolara to inkrementujemy licznik
	call liczDlugosc		;wywolanie sprawdzenia nastepnego znaku w etykiecie
porownaj:
	cmp licznik,1			;sprawdzamy czy dlugosc argumentu to 1
	jne bladPierwszyArg		;jesli nie to wypisujemy odpowiedni blad
ret

;-------------------------------------------------
sprawdzDlugoscDrugiego:		
	mov si,offset arg2		;przenosimy do SI offset etykiety z argumentem drugim
	mov licznik,0			;zerujemy licznik ktory bedzie uzywany w petli
	
drugiDlugosc:				;petla liczaca dlugosc pierwszego argumentu
	lodsb					;ladujemy do AL pierwszy bajt
	cmp al,'$'				;sprawdzamy czy jest $, jesli jest to koniec argumentu
	je porownaj2			;jesli byl dolar to mozemy sprawdzic czy dlugosc sie zgadza
	inc licznik				;jesli nie bylo dolara to inkrementujemy licznik
	call drugiDlugosc		;wywolanie sprawdzenia nastepnego znaku w etykiecie
porownaj2:
	cmp licznik,32			;sprawdzamy czy dlugosc argumentu to 32
	jne zlaDlugoscArg		;jesli nie to wypisujemy odpowiedni blad
ret

;--------------------------------------------------
sprawdzPoprawnoscPierwszego:
	mov si,offset arg1		;przenosimy do SI offset etykiety z argumentem pierwszym
	lodsb					;ladujemy do AL pierwszy bajt
	cmp al,'0'				;sprawdzamy czy AL jest '0'
	je arg1ok				;jesli jest to argument jest poprawnie podany
	cmp al,'1'				;sprawdzamy czy AL jest '1'
	je arg1ok				;jesli jest to argument jest poprawnie podany
	call bladPierwszyArg	;jesli nie byl '0' ani '1' to wypisujemy odpowiedni blad
arg1ok:
ret

;---------------------------------------------------
sprawdzPoprawnoscDrugiego:
	push di					;odkladamy na stos uzywane rejestry
	push cx
	mov di,0				;zerujemy DI
	dec di					;dekrementujemy DI poniewaz bedziemy go inkrementowac na poczatku petli
alfabet:					;petla sprawdzajaca poprawnosc i zmieniajaca na system binarny drugi argument	
	inc cx						;inkrementujemy CX ktory sprawdza czy juz koniec argumentu	
	inc di						;inkrementujemy DI by przejsc do nastepnego znaku w argumencie
	mov al,byte ptr ds:[arg2+di];ladujemy do Al znak z etykiety z drugim argumentem
	cmp al,'0'					;sprawdzamy czy jest mniejszy niz '0', jesli jest to na pewno
	jb zlySystemArg				;argument nie jest w systemie 16-kowym
	cmp al,'9'					;sprawdzamy czy jest mniejsze lub rowne '9', jesli jest to
	jbe liczba					;musi zawierac sie w przedziale zamknietym 0-9
	cmp al,'a'					;sprawdzamy czy jest mniejsze niz 'a', jesli tak to na pewno												
	jb zlySystemArg				;jest znakiem pomiedzy F-a wiec nie jest w systemie 16-kowym												
	cmp al,'f'					;sprawdzamy czy jest powyzej 'f', jesli tak to nie jest											
	ja zlySystemArg				;w systemie 16-kowym

	litera:								;jesli przeszlo przez wszystko to jest miedzy a-f				
		mov al,87						;wtedy aby zmienic znak na liczbe trzeba odjac 87
		sub byte ptr ds:[arg2+di],al	;odejmujemy od naszego znaku 87 ktore jest w AL co 
		jmp pomin						;zmienia nam znak na odpowiednia liczbe
	liczba:								;wywolane gdy nasz znak 0-9
		mov al,48						;odejmujemy 48 ktory zmienia nam
		sub byte ptr ds:[arg2+di],al	;znak na odpowiednia liczbe
	pomin:
	cmp cx,32							;sprawdzamy czy sprawdzilismy juz wzystkie 32 znaki
	jb alfabet							;jesli nie to sprawdzamy nastepny
	
	pop cx						;pobieramy ze stosu to co odlozylismy na poczatku
	pop di
ret
	

;---------------------------------------------------------------------------------------------------------------------------------------------------------------------
;--------------------------------------------###Funkcja zmieniajaca klucz w systemie szestnastkowym na postac binarna###----------------------------------------------
;---------------------------------------------------------------------------------------------------------------------------------------------------------------------
zmianaNaBinary:
	push ax					;odkladamy na stos wszystko co moze byc uzyte
	push bx					;podczas wykonywania sie funkcji
	push cx
	push dx
	push di
	push si
	mov si,offset arg2		;ladujemy do SI offset drugiego argumentu
	mov di,offset binary	;ladujemy do DI offset tablicy w ktorej bedzie zapis binarny klucza
	mov cx,16				;petla wykonuje sie 16 razy poniewaz bierzemy po dwie
	naBinarny:
		push cx					;odkladamy na stos by nie zgubic
		mov al,byte ptr ds:[si]	;ladujemy do AL pierwszy znak
		mov cl,4				;do CL wpisujemy 4, uzyjemy go do przesuniecia
		shl al,cl				;przesuwamy o 4 bity w lewo, shl powoduje przesuniecei bitow w argumencie o zadana liczbe pozycji w lewo
		mov dl,al				;przenosimy z AL do DL
		inc si					;inkrementujemy DI by przejsc na nastepny znak
		mov al,byte ptr ds:[si]	;pobieramy drugi znak
		add dl,al				;sumujemy oba argumenty otrzymujac tym samym jeden bajt, mozna uzyc or czyli suma logiczna oraz xor
		mov byte ptr ds:[di],dl	;wynik dodawania przenosimy do tablicy w ktorej mamy binarny zapis klucza
		inc si					;przechodzimy na nastepny element
		inc di					;przenosimy sie na nastepne miejsce w tablicy binarnej
		pop cx					;zdejmujemy CX ze stosu
		loop naBinarny
	mov byte ptr ds:[di],'$'	;na koncu dodajemy dolara
	pop si						;zdejmujemy wszystkie odlozone rejesty ze stosu
	pop di
	pop dx
	pop cx
	pop bx
	pop ax
	call callBack
ret


;---------------------------------------------------------------------------------------------------------------------------------------------------------------------
;-------------------------------------------------------###FUNKCJE WYWOLUJACE RUCH GONCA PO TABLICY###----------------------------------------------------------------
;---------------------------------------------------------------------------------------------------------------------------------------------------------------------
move:
	push ax						;odkladamy na stos rejestry by ich nie zgubic
	push bx
	push cx
	push dx
	push si
	push di
	mov di,offset binary		;do DI przekazujemy offset tablicy z kluczem w wersji binarnej
	mov licznik,17d				;poniewaz mamy 16 bajtow do analizy, jeden wiecej z racji struktury petli jaka stworzylem
	mov si,76d					;srodek tablicy czyli miejsce z ktorego zaczyna goniec
	
	analizujBajt:				
	mov bl,byte ptr ds:[di]	;do BL dajemy bajt ktory bedziemy teraz analizowac
	inc di					;inkrementujemy DI
	mov cx,4				;w kazdym bajcie mamy 4 pary bitow
	call czyModyfikacja		;sprawdzamy czy program zostal uruchomiony z modyfikacja
	cmp ax,1				;sprawdzamy czy zwrocono w AX, 1, jesli tak to jest modyfikacja
	je paryBitowMod
	
	paryBitow:				;wersja ruchow bez modyfikacji
		ruchJeden:				;zaczynamy od ruchu w prawo badz lewo
		shr bl,1				;mlodszy bit w parze
		jc prawo				;jesli 1 to ruch w prawo
		jmp lewo				;jesli 0 to ruch w lewo
		
		ruchDwa:				;nastepnie wykonujemy ruch w gore badz w dol
		shr bl,1				;starszy bit w parze
		jc dol					;jesli 1 to ruch w dol
		jmp gora				;jesli 0 to ruch w gore
	
		ruchTablica:			;wywolanie funkcji ktora symuluje ruch w tablicy
		call zapiszRuch
	
		loop paryBitow
		jmp czyKoniec		;skok by nie wykonac instrukcji dla zmodyfikowanej wersji
		
	paryBitowMod:			;wersja ruchow zmodyfikowana
		ruchJedenMod:
		shr bl,1			;mlodszy bit w parze
		jc prawoMod			;jesli 1 to ruch w prawo
		jmp lewoMod			;jesli 0 to ruch w lewo
		
		ruchDwaMod:
		shr bl,1			;starszy bit w parze
		jc dolMod			;jesli 1 to ruch w dol
		jmp goraMod			;jesli 0 to ruch w gore
		
		ruchTablicaMod:		;wywolanie funkcji ktora symuluje ruch w tablicy
		call zapiszRuch
		
		loop paryBitowMod
	czyKoniec:					;tutaj skaczemy gdy wykonywalismy skoki bez modyfikacji
	dec licznik					;dekrementujemy licznik
	mov cx,licznik				;przenosimy go do CX by petla nie byla nieskonczona
	loop analizujBajt			
	
	mov miejsceKonca,si					;zapisanie miejsca w ktorym goniec skonczyl ostatni ruch
	pop di								;zdejmujemy ze stosu poprzednio odlozone rejestry
	pop si
	pop dx
	pop cx
	pop bx
	pop ax
	call moveBack
ret

;----------------------------------------------------
;--------------###Ruch Gora Normalny###--------------
;----------------------------------------------------
gora:
	cmp si,16		;sprawdzamy czy goniec nie jest przy gornej krawedzi
	jbe	nieGora		;jezeli tak to nie mozemy wykonac ruchu w gore
	sub si,17		;jesli mozna wykonac ruch to przenosimy gonca o jeden w gore
	nieGora:
	call ruchTablica

;----------------------------------------------------
;---------------###Ruch Dol Normalny###--------------
;----------------------------------------------------
dol:
	cmp si,136		;sprawdzamy czy goniec nie jest przy dolnej krawedzi
	jae nieDol		;jesli jest na dole to nie mozemy wykonac ruchu w dol
	add si,17		;jesli mozna wykonac ruch to przesuwamy gonca o jeden w dol
	nieDol:
	call ruchTablica

;----------------------------------------------------
;--------------###Ruch Prawo Normalny###-------------
;----------------------------------------------------
prawo:
	push ax
	push dx			;odkladamy DX bo bedzie uzywany w funkcji
	mov ax,si		;przenosimy do AX, SI w ktorym jest zapisane polozenie naszego gonca
	mov dl,17		;dajemy do DL 17 gdyz szerokosc naszej tablicy wynosi 17
	div dl			;dzielimy AX przez DL, reszta z dzielenia bedzie w AH
	cmp ah,16		;sprawdzamy czy reszta jest rowna 16
	je niePrawo		;jesli jest rowna 16 to nie mozemy wykonac ruchu w prawo
	inc si			;inkrementujemy SI by wykonac ruch w prawo
	niePrawo:		
	pop dx			;zdejmujemy DX ze stosu
	pop ax
	call ruchDwa

;----------------------------------------------------
;--------------###Ruch Lewo Normalny###--------------
;----------------------------------------------------
lewo:
	push ax
	push dx			;odkladamy DX bo bedzie uzywany w funkcji
	mov ax,si		;przenosimy do AX, SI w ktorym jest zapisane polozenie naszego gonca
	mov dl,17		;dajemy do DL 17 gdyz szerokosc naszej tablicy wynosi 17
	div dl			;dzielimy AX przez DL, reszta z dzielenia bedzie w AH
	cmp ah,0		;sprawdzamy czy reszta jest rowna 0
	je nieLewo		;jesli jest rowna 0 to nie mozemy wykonac ruchu w lewo
	dec si			;dekrementujemy SI by wykonac ruch w lewo
	nieLewo:
	pop dx			;zdejmujemy DX ze stosu
	pop ax
	call ruchDwa
	
;----------------------------------------------------
;--------------###Ruch Gora Zmodyfikowany###---------
;----------------------------------------------------
goraMod:
	cmp si,16			;sprawdzamy czy SI czyli miejsce w ktorym znajduje sie goniec jest mniejsze-rowne 16, jesli tak to jest w gornym rzedzie
	jbe goraPrzezSciane	;wiec musimy wywolac skok przez sciane
	sub si,17			;jesli nie byl na gorze to po prostu wykonujemy przeskok o jedno pole w gore
	jmp goraByl			;i pomijamy instrukcje ktore wykonuja sie gdy goniec jest w gornym rzedzie
	goraPrzezSciane:	;jesli goniec jest na gorze
	add si,136			;to dodajac 136 do miejsca gonca przeniesiemy go na odpowiednie pole na dole tablicy
	goraByl:
	call ruchTablicaMod

;----------------------------------------------------
;--------------###Ruch Dol Zmodyfikowany###----------
;----------------------------------------------------
dolMod:
	cmp si,136			;sprawdzamy czy SI czyli miejsce w ktorym znajduje sie goniec jest wieksze-rowne 136, jesli tak to jest w dolnym rzedzie
	jae dolPrzezSciane	;wiec musimy wywolac skok przez sciane
	add si,17			;jesli jest normalny skok to po prostu odejmujac 17 przemieszczamy gonca o jedno pole w dol
	jmp dolByl			;i pomijamy instrukcje ktore wykonuja sie gdy mamy skok przez sciane
	dolPrzezSciane:		;jesli goniec jest w dolnym rzedzie
	sub si,136			;to odejmujemy 136 co spowoduje przeniesienie gonca na odpowiednie pole na gorze tablicy
	dolByl:
	call ruchTablicaMod

;----------------------------------------------------
;--------------###Ruch Prawo Zmodyfikowany###--------
;----------------------------------------------------
prawoMod:
	push ax				;odkladamy na stos uzywane rejestry
	push dx
	mov ax,si			;przenosimy SI do AX by nie zgubic polozenia naszego gonca podczas dzielenia
	mov dl,17			;do DL wkladamy 17 potrzebne do sprawdzania reszty z dzielenia
	div dl				;dzielimy AX przez DL (17) co da nam w AH reszte z dzielenia
	cmp ah,16			;jesli reszta jest rowna 16 to oznacza ze goniec jest przy prawej krawedzi szachownicy
	je prawoPrzezSciane	;wiec wywolujemy skok przez sciane
	inc si				;jesli nie ma skoku przez sciane to po prostu inkrementujemy SI
	jmp prawoByl		;pomijamy instrukcje wykonujace sie podczas skoku przez sciane
	prawoPrzezSciane:	;jesli mamy skok przez sciane 
	sub si,16			;to odejmujemy od SI, 16 co przeniesie gonca z konca wiersza na jego poczatek
	prawoByl:			
	pop dx				;zdejmujemy ze stosu wczesniej odlozone rejestry
	pop ax
	call ruchDwaMod

;----------------------------------------------------
;--------------###Ruch Lewo Zmodyfikowany###---------
;----------------------------------------------------
lewoMod:
	push ax				;odkladamy na stos uzywane rejestry
	push dx
	mov ax,si			;przenosimy SI do AX by nie zgubic polozenia naszego gonca podczas dzielenia
	mov dl,17			;do DL wkladamy 17 potrzebne do sprawdzania reszty z dzielenia
	div dl				;dzielimy AX przez DL (17) co da nam w AH reszte z dzielenia
	cmp ah,0			;jesli reszta jest rowna 0 to oznacza ze goniec jest przy lewej krawedzi szachownicy
	je lewoPrzezSciane	;wiec wywolujemy skok przez sciane
	dec si				;jesli nie ma skoku przez sciane to po prostu dekrementujemy SI
	jmp lewoByl			;pomijamy instrukcje wykonujace sie podczas skoku przez sciane
	lewoPrzezSciane:	;jesli mamy skok przez sciane 
	add si,16			;to dodajemy od SI, 16 co przeniesie gonca z poczatku wiersza na jego koniec
	lewoByl:
	pop dx				;zdejmujemy ze stosu wczesniej odlozone rejestry
	pop ax
	call ruchDwaMod
	
;-------------------------------------------
;------------###Ruch W Tablicy###-----------
;-------------------------------------------
zapiszRuch:
	push ax						;odkladamy na stos rejestry ktore bedziemy uzywac w funkcji
	push di
	mov di,offset szachownica	;do DI przekazujemy offset tablicy
	add di,si					;dodajemy do DI, SI czyli obecne polozenie gonca
	mov al,1					;dajemy do AL jedynke
	add byte ptr ds:[di],al		;powiekszamy odpowiednie miejsce o 1 ruch
	pop di						;zdejmujemy ze stosu poprzednio odlozone rejestry
	pop ax
ret

;----------------------------------------------------
;------------###Sprawdzanie modyfikacji###-----------
;----------------------------------------------------
czyModyfikacja:
	push si					;odkladamy na stos uzywane rejestry
	mov ax,0				;jesli zostanie 0 to bez modyfikacji
	mov si,offset arg1		;do SI wkladamy offset pierwszego argumentu
	lodsb					;ladujemy pierwszy znak do AL
	cmp al,'1'				;porownujemy go by sprawdzic czy wystapila modyfikacja
	jne nieModyfikuj		;jesli tak to wywolujemy funkcje ruchu z modyfikacja
	mov ax,1				;jest modyfikacja wiec dajemy do AX 1
	nieModyfikuj:
	pop si					;zdejmujemy ze stosu to co zostalo odlozone
ret
	

;---------------------------------------------------------------------------------------------------------------------------------------------------------------------
;--------------------------------------------------------------------###WYPISYWANIE TABLICY###------------------------------------------------------------------------
;---------------------------------------------------------------------------------------------------------------------------------------------------------------------	
;----------------------------------------------------------------------------------
;------###Funkcja zmieniajaca ilosc ruchow w danym polu na znaki ASCII-Art###------
;----------------------------------------------------------------------------------
zamienNaZnaki:
	push ax								;na stos odkladamy rejestry ktorych bedziemy uzywac
	push cx
	push dx
	push si
	push di
	mov di,offset szachownica			;do DI wsadzamy offset szachownicy
	mov cx,153							;petla wykona sie 153 razy
	zamien:
		mov si,offset znaki				;do SI wsadzamy offset znakow
		xor ax,ax						;czyscimy ax
		mov al,byte ptr ds:[di]			;do AL dajemy liczbe odwiedzin danego pola				
		cmp al,14						;sprawdzamy czy jest wiecej niz 14
		jbe mniej						;jesli jest to przyjmujemy ze jest 14
		mov al,14						;jesli bylo wiecej niz 14 to dajmy do AL 14
		mniej:
		add si,ax				;dodajemy do SI w ktorym sa znaki AX by wiedziec ktory znak wpisac do szachownicy
		mov al,byte ptr ds:[si]	;do AL dajemy znak ktory ma byc w tym miejsu
		mov byte ptr ds:[di],al	;i przenosimy go do szachownicy
		inc di					;inkrementacja di
	loop zamien
	mov di,offset szachownica				;do DI przenosimy offset szachownicy
	mov byte ptr ds:[di+76],'S'				;w miejsu startu gonca umieszczamy S
	add di,miejsceKonca						;przenosimy do DI miejsce w ktorym goniec skonczyl skakanie po szachownicy
	mov byte ptr ds:[di],'E'				;w miejsce konca dodajemy E
	pop di									;zdejmujemy wszystko poprzednio odlozone ze stosu
	pop si
	pop dx
	pop cx
	pop ax
	ret

;---------------------------------------------------
;----------###Funkcja rysujaca tablice###-----------
;---------------------------------------------------
rysuj:
	call wyczysc				;bez tego wypisuje na koncu jakies smieci
	push cx						;odkladamy na stos rejestry ktorych bedziemy uzywac
	push dx
	push si
	mov dx,offset goraRamki		;wypisanie gornej czesci ramki
	call print					;wywolanie funkcji drukujacej
	
	mov si, offset szachownica	;do SI dajemy offset szachownicy
	
	wypiszLinie:
		mov ah,2				;wypisanie po jednym znaku
		cmp byte ptr [si],'$'	;sprawdzamy czy koniec szachownicy
		je zakoncz
		mov dl,'|'				;lewy bok ramki
		int 21h					;funkcja wypisania
		
		mov licznik,17				;poniewaz mamy 17 znakow w linii
		wiersz:
			mov dl,byte ptr ds:[si]			;bierzemy nastepny znak
			cmp byte ptr [si],'$'			;sprawdzamy czy koniec szachownicy
			je zakoncz
			int 21h							;funkcja wypisania
			inc si							;inkrementujemy SI
			dec licznik						;dekrementujemy licznik
			cmp licznik,0					;sprawdzamy czy wypisalismy juz cala linie
			jne wiersz						;jesli nie to wypisujemy dalej
			
		mov dl,'|'				;prawa strona ramki
		int 21h					;wypisanie ramki			
		mov dx,offset nowaLinia	;przejscie do nowej linii
		mov ah,9	
		int 21h
	jmp wypiszLinie
	
	zakoncz:				
	mov dx,offset dolRamki		;wypisujemy dol ramki
	call print					;wywolanie funkcji drukujacej na ekran
	pop si						;pobieramy rejestry ze stosu
	pop dx
	pop cx
ret

wyczysc:
	push si						;odkladam na stos rejestr ktory zaraz bede uzywac
	mov si,offset miejsceKonca	;do SI daje offset binary
	mov byte ptr ds:[si],'$'	;na poczatku dodaje dolara
	pop si						;pobieram rejest z powtorem ze stosu
ret

print:
	mov ah,9
	int 21h
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
;***Do zad1 - jesli pierwszy argument jest bledny***
bladPierwszyArg:
	mov ax,offset errArg1
	call errorPrint
;***Do zad1 - jesli drugi argument jest zlej dlugosci***
zlaDlugoscArg:
	mov ax,offset errDlugosc
	call errorPrint
;***Do zad1 - jesli drugi argument nie jest w systemie szesnastkowym***
zlySystemArg:
	mov ax,offset errHeksa
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