# Rozproszone Bazy Danych - Liga Piłkarska

Projekt z przedmiotu RBD (Rozproszone Bazy Danych) realizujący system zarządzania ligą piłkarską. 

**Autorzy:** Szymon Muszyński, Anton Pryhkodzka.

## Architektura Systemu
<p align="center">
  <img width="650" height="650" alt="image" src="https://github.com/user-attachments/assets/58bb52f4-642b-428c-800f-04d2e1408782" />
</p>

System oparto na mechanizmach Linked Server w środowisku SQL Server. Umożliwia to wykonywanie zapytań i procedur na połączonych, zdalnych instancjach bazodanowych. Wymiana danych realizowana jest poprzez zapytania `OPENQUERY`, wywołania funkcji w środowisku docelowym oraz wyzwalacze (triggery).

Projekt składa się z trzech współpracujących ze sobą węzłów:

* **Lokalny SQL Server:** Przechowuje dane o stadionach (`Stadiony`), rozegranych spotkaniach (`Mecze`) i konkretnych wydarzeniach na boisku (`WydarzeniaMeczowe`). Dba o integralność procesów za pomocą triggerów (np. walidujących wprowadzane mecze).
* **Oracle Database (`ORACLE_LINK`):** Pełni rolę serwera zdalnego przechowującego informacje o klubach, menadżerach i zawodnikach. Baza ta zawiera tabele `Klub`, `Menadzer`, `Zawodnicy` i `Statystyki_zawodnika`.
* **Zdalny SQL Server w Dockerze (`DOCKER_SQL`):** Wydzielony serwer zajmujący się wyłącznie obsługą arbitrów. Zawiera tabele `Sedziowie` oraz tabelę łącznikową `MeczeSedziowie`. Obsługa przypisywania sędziów do spotkań odbywa się poprzez procedury z poziomu serwera lokalnego.

## Główne funkcjonalności

* **Synchronizacja statystyk w czasie rzeczywistym:** Dodanie wydarzenia meczowego (np. zdobycie gola) na lokalnym SQL Serverze automatycznie wywołuje procedurę `aktualizuj_statystyki` w bazie Oracle. 
* **Automatyczny eksport do Excela:** Procedura wstawiająca nowy mecz (`DodajMeczPoNazwach`) posiada zaimplementowany mechanizm eksportu dodanego rekordu bezpośrednio do arkusza kalkulacyjnego wykorzystując `OPENROWSET`. W przypadku błędu eksportu system poinformuje o tym komunikatem, ale sam mecz pozostanie w bazie danych.
* **Agregacja danych rozproszonych:** Procedura `PokazSzczegolyMeczuRozproszone` kompiluje dane z trzech niezależnych baz – informacje o klubach pobiera z bazy Oracle, przebieg spotkania z lokalnego SQL Servera, a obsadę sędziowską z serwera w środowisku Docker.
* **Automatyzacja i ograniczenia integralności:** System używa dedykowanych triggerów na wszystkich instancjach, m.in. automatycznie inicjując zera w statystykach po dodaniu nowego zawodnika w Oracle, wymuszając unikalność nazw nowo dodawanych stadionów oraz blokując dublowanie sędziów.

## Zawartość repozytorium

* `server.txt` - Skrypty DDL, triggery oraz procedury składowane dla lokalnego serwera SQL.
* `server_zdalny` - Skrypt tworzący struktury tabel sędziowskich na serwerze rezydującym w Dockerze.
* `oracle_1.sql` - Skrypty z tabelami, widokami, sekwencjami oraz procedurami na docelową bazę Oracle.
* `Sprawozdanie_RBD_245883_248662.pdf` - Oficjalna dokumentacja projektu oraz zrzuty architektoniczne i schematy UML.
