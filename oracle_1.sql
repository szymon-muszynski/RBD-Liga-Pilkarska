CREATE TABLE Klub (
    id_klubu NUMBER PRIMARY KEY,
    nazwa VARCHAR2(100),
    CONSTRAINT unikalna_nazwa_klubu UNIQUE (nazwa)
);

CREATE SEQUENCE seq_klub START WITH 1 INCREMENT BY 1;

CREATE OR REPLACE TRIGGER trg_klub_bi
BEFORE INSERT ON Klub
FOR EACH ROW
BEGIN
    IF :NEW.id_klubu IS NULL THEN
        SELECT seq_klub.NEXTVAL INTO :NEW.id_klubu FROM dual;
    END IF;
END;

CREATE TABLE Menadzer (
    id_menadzera NUMBER PRIMARY KEY,
    imie VARCHAR2(100),
    nazwisko VARCHAR2(100),
    data_urodzenia DATE,
    id_klubu NUMBER,
    CONSTRAINT fk_menadzer_klub FOREIGN KEY (id_klubu) REFERENCES Klub(id_klubu)
);

CREATE SEQUENCE seq_menadzer START WITH 1 INCREMENT BY 1;

CREATE OR REPLACE TRIGGER trg_menadzer_bi
BEFORE INSERT ON Menadzer
FOR EACH ROW
BEGIN
    IF :NEW.id_menadzera IS NULL THEN
        SELECT seq_menadzer.NEXTVAL INTO :NEW.id_menadzera FROM dual;
    END IF;
END;

CREATE TABLE Zawodnicy (
    id_zawodnika NUMBER PRIMARY KEY,
    imie VARCHAR2(100),
    nazwisko VARCHAR2(100),
    id_klubu NUMBER,
    data_urodzenia DATE,
    CONSTRAINT fk_zawodnik_klub FOREIGN KEY (id_klubu) REFERENCES Klub(id_klubu)
);

CREATE SEQUENCE seq_zawodnik START WITH 1 INCREMENT BY 1;

CREATE OR REPLACE TRIGGER trg_zawodnik_bi
BEFORE INSERT ON Zawodnicy
FOR EACH ROW
BEGIN
    IF :NEW.id_zawodnika IS NULL THEN
        SELECT seq_zawodnik.NEXTVAL INTO :NEW.id_zawodnika FROM dual;
    END IF;
END;

CREATE TABLE Statystyki_zawodnika (
    id_statystyk NUMBER PRIMARY KEY,
    id_zawodnika NUMBER UNIQUE,
    ilosc_goli NUMBER,
    ilosc_asyst NUMBER,
    ilosc_zoltych_kartek NUMBER,
    ilosc_czerwonych_kartek NUMBER,
    ilosc_meczy NUMBER,
    CONSTRAINT fk_statystyki_zawodnika FOREIGN KEY (id_zawodnika) REFERENCES Zawodnicy(id_zawodnika)
);

CREATE SEQUENCE seq_statystyki START WITH 1 INCREMENT BY 1;

CREATE OR REPLACE TRIGGER trg_statystyki_bi
BEFORE INSERT ON Statystyki_zawodnika
FOR EACH ROW
BEGIN
    IF :NEW.id_statystyk IS NULL THEN
        SELECT seq_statystyki.NEXTVAL INTO :NEW.id_statystyk FROM dual;
    END IF;
END;

--triggery

CREATE OR REPLACE TRIGGER trg_auto_statystyki_ai
AFTER INSERT ON Zawodnicy
FOR EACH ROW
BEGIN
    INSERT INTO Statystyki_zawodnika (
        id_statystyk,
        id_zawodnika,
        ilosc_goli,
        ilosc_asyst,
        ilosc_zoltych_kartek,
        ilosc_czerwonych_kartek,
        ilosc_meczy
    ) VALUES (
        seq_statystyki.NEXTVAL,
        :NEW.id_zawodnika,
        0,
        0,
        0,
        0,
        0
    );
END;

CREATE OR REPLACE TRIGGER unikaj_duplikatow_zawodnikow
BEFORE INSERT ON Zawodnicy
FOR EACH ROW
DECLARE
    cnt NUMBER;
BEGIN
    SELECT COUNT(*) INTO cnt FROM Zawodnicy
    WHERE imie = :NEW.imie AND nazwisko = :NEW.nazwisko AND data_urodzenia = :NEW.data_urodzenia;

    IF cnt > 0 THEN
        RAISE_APPLICATION_ERROR(-20003, 'Taki zawodnik już istnieje!');
    END IF;
END;

CREATE OR REPLACE TRIGGER unikaj_duplikatow_menadzerow
BEFORE INSERT ON Menadzer
FOR EACH ROW
DECLARE
    cnt NUMBER;
BEGIN
    SELECT COUNT(*) INTO cnt FROM Menadzer
    WHERE imie = :NEW.imie AND nazwisko = :NEW.nazwisko AND data_urodzenia = :NEW.data_urodzenia;

    IF cnt > 0 THEN
        RAISE_APPLICATION_ERROR(-20003, 'Taki menadzer już istnieje!');
    END IF;
END;

--funkcje

CREATE OR REPLACE FUNCTION detect_id (
    p_imie IN VARCHAR2,
    p_nazwisko IN VARCHAR2,
    p_data_urodzenia IN DATE
) RETURN NUMBER IS
    v_id_zawodnika NUMBER;
BEGIN
    SELECT id_zawodnika INTO v_id_zawodnika
    FROM Zawodnicy
    WHERE LOWER(imie) = LOWER(p_imie)
      AND LOWER(nazwisko) = LOWER(p_nazwisko)
      AND data_urodzenia = p_data_urodzenia;

    RETURN v_id_zawodnika;
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RAISE_APPLICATION_ERROR(-20004, 'Zawodnik nie został znaleziony.');
END;

CREATE OR REPLACE FUNCTION srednia_goli_na_mecz(p_id_zawodnika IN NUMBER)
RETURN NUMBER IS
    v_gole NUMBER;
    v_mecze NUMBER;
BEGIN
    SELECT ilosc_goli, ilosc_meczy
    INTO v_gole, v_mecze
    FROM Statystyki_zawodnika
    WHERE id_zawodnika = p_id_zawodnika;

    IF v_mecze = 0 THEN
        RETURN 0;
    ELSE
        RETURN v_gole / v_mecze;
    END IF;
END;

CREATE OR REPLACE FUNCTION srednia_asyst_na_mecz(p_id_zawodnika IN NUMBER)
RETURN NUMBER IS
    v_asyste NUMBER;
    v_mecze NUMBER;
BEGIN
    SELECT ilosc_asyst, ilosc_meczy
    INTO v_asyste, v_mecze
    FROM Statystyki_zawodnika
    WHERE id_zawodnika = p_id_zawodnika;

    IF v_mecze = 0 THEN
        RETURN 0;
    ELSE
        RETURN v_asyste / v_mecze;
    END IF;
END;

CREATE OR REPLACE FUNCTION srednia_zoltych_kartek_na_mecz(p_id_zawodnika IN NUMBER)
RETURN NUMBER IS
    v_zolte_kartki NUMBER;
    v_mecze NUMBER;
BEGIN
    SELECT ilosc_zoltych_kartek, ilosc_meczy
    INTO v_zolte_kartki, v_mecze
    FROM Statystyki_zawodnika
    WHERE id_zawodnika = p_id_zawodnika;

    IF v_mecze = 0 THEN
        RETURN 0;
    ELSE
        RETURN v_zolte_kartki / v_mecze;
    END IF;
END;

CREATE OR REPLACE FUNCTION srednia_czerwonych_kartek_na_mecz(p_id_zawodnika IN NUMBER)
RETURN NUMBER IS
    v_czerwone_kartki NUMBER;
    v_mecze NUMBER;
BEGIN
    SELECT ilosc_czerwonych_kartek, ilosc_meczy
    INTO v_czerwone_kartki, v_mecze
    FROM Statystyki_zawodnika
    WHERE id_zawodnika = p_id_zawodnika;

    IF v_mecze = 0 THEN
        RETURN 0;
    ELSE
        RETURN v_czerwone_kartki / v_mecze;
    END IF;
END;

--widok

CREATE OR REPLACE VIEW vw_zawodnik_statystyki AS
SELECT 
    z.id_zawodnika,
    z.imie,
    z.nazwisko,
    z.data_urodzenia,
    s.ilosc_goli,
    s.ilosc_asyst,
    s.ilosc_zoltych_kartek,
    s.ilosc_czerwonych_kartek,
    s.ilosc_meczy,
    srednia_goli_na_mecz(z.id_zawodnika) AS srednia_goli_na_mecz,
    srednia_asyst_na_mecz(z.id_zawodnika) AS srednia_asyst_na_mecz,
    srednia_zoltych_kartek_na_mecz(z.id_zawodnika) AS srednia_zoltych_kartek_na_mecz,
    srednia_czerwonych_kartek_na_mecz(z.id_zawodnika) AS srednia_czerwonych_kartek_na_mecz
FROM 
    ZAWODNICY z
    JOIN STATYSTYKI_ZAWODNIKA s ON z.id_zawodnika = s.id_zawodnika;

--procedury

CREATE OR REPLACE PROCEDURE dodaj_klub (
    p_nazwa IN VARCHAR2
) AS
BEGIN
    INSERT INTO Klub (id_klubu, nazwa)
    VALUES (seq_klub.NEXTVAL, p_nazwa);
END;

BEGIN
    dodaj_klub('Real Madrid');
    dodaj_klub('Barcelona');
    dodaj_klub('Bayern');
    dodaj_klub('Arsenal');
    dodaj_klub('Manchester City');
    dodaj_klub('Inter Milan');
END;
SELECT * FROM Klub;

CREATE OR REPLACE PROCEDURE dodaj_menadzera(
    p_imie IN VARCHAR2,
    p_nazwisko IN VARCHAR2,
    p_data_urodzenia IN DATE,
    p_nazwa_klubu IN VARCHAR2
) AS
    v_id_klubu NUMBER;
BEGIN
    SELECT id_klubu INTO v_id_klubu
    FROM Klub
    WHERE LOWER(nazwa) = LOWER(p_nazwa_klubu);

    INSERT INTO Menadzer(id_menadzera, imie, nazwisko, data_urodzenia, id_klubu)
    VALUES (seq_menadzer.NEXTVAL, p_imie, p_nazwisko, p_data_urodzenia, v_id_klubu);
END;

SELECT * FROM Menadzer;

CREATE OR REPLACE PROCEDURE zmien_klub_menadzera(
    p_imie IN VARCHAR2,
    p_nazwisko IN VARCHAR2,
    p_data_urodzenia IN DATE,
    p_nowa_nazwa_klubu IN VARCHAR2
) AS
    v_id_klubu NUMBER;
BEGIN
    SELECT id_klubu INTO v_id_klubu
    FROM Klub
    WHERE LOWER(nazwa) = LOWER(p_nowa_nazwa_klubu);

    UPDATE Menadzer
    SET id_klubu = v_id_klubu
    WHERE LOWER(imie) = LOWER(p_imie)
      AND LOWER(nazwisko) = LOWER(p_nazwisko)
      AND data_urodzenia = p_data_urodzenia;
END;

CREATE OR REPLACE PROCEDURE dodaj_zawodnika (
    p_imie IN VARCHAR2,
    p_nazwisko IN VARCHAR2,
    p_data_ur DATE,
    p_nazwa_klubu IN VARCHAR2
) AS
    v_id_klubu NUMBER;
BEGIN
    SELECT id_klubu INTO v_id_klubu
    FROM Klub
    WHERE LOWER(nazwa) = LOWER(p_nazwa_klubu);

    INSERT INTO Zawodnicy (id_zawodnika, imie, nazwisko, data_urodzenia, id_klubu)
    VALUES (seq_zawodnik.NEXTVAL, p_imie, p_nazwisko, p_data_ur, v_id_klubu);
END;

SELECT z.imie, z.nazwisko, z.data_urodzenia, k.nazwa AS klub
FROM Zawodnicy z
JOIN Klub k ON z.id_klubu = k.id_klubu
WHERE LOWER(k.nazwa) = 'real madrid';

SELECT * FROM Statystyki_zawodnika;

CREATE OR REPLACE PROCEDURE przenies_zawodnika(
    p_imie VARCHAR2,
    p_nazwisko VARCHAR2,
    p_data_ur DATE,
    p_nazwa_klubu VARCHAR2
) IS
    v_id_klubu NUMBER;
BEGIN
    SELECT id_klubu INTO v_id_klubu
    FROM Klub
    WHERE LOWER(nazwa) = LOWER(p_nazwa_klubu);

    UPDATE Zawodnicy
    SET id_klubu = v_id_klubu
    WHERE imie = p_imie AND nazwisko = p_nazwisko AND data_urodzenia = p_data_ur;
END;

CREATE OR REPLACE PROCEDURE aktualizuj_statystyki (
    p_id_zawodnika NUMBER,
    p_gole NUMBER,
    p_asysty NUMBER,
    p_zolte NUMBER,
    p_czerwone NUMBER,
    p_mecze NUMBER
) IS
BEGIN
    UPDATE Statystyki_zawodnika
    SET 
        ilosc_goli = ilosc_goli + p_gole,
        ilosc_asyst = ilosc_asyst + p_asysty,
        ilosc_zoltych_kartek = ilosc_zoltych_kartek + p_zolte,
        ilosc_czerwonych_kartek = ilosc_czerwonych_kartek + p_czerwone,
        ilosc_meczy = ilosc_meczy + p_mecze
    WHERE id_zawodnika = p_id_zawodnika;
END;

CREATE OR REPLACE PROCEDURE pokaz_zawodnika_i_statystyki (
    p_imie           IN ZAWODNICY.imie%TYPE,
    p_nazwisko       IN ZAWODNICY.nazwisko%TYPE,
    p_data_urodzenia IN ZAWODNICY.data_urodzenia%TYPE
) AS
BEGIN
    FOR rec IN (
        SELECT * FROM vw_zawodnik_statystyki
        WHERE imie = p_imie AND nazwisko = p_nazwisko AND data_urodzenia = p_data_urodzenia
    ) LOOP
        DBMS_OUTPUT.PUT_LINE('Zawodnik: ' || rec.imie || ' ' || rec.nazwisko);
        DBMS_OUTPUT.PUT_LINE('Data urodzenia: ' || TO_CHAR(rec.data_urodzenia, 'YYYY-MM-DD'));
        DBMS_OUTPUT.PUT_LINE('Mecze: ' || rec.ilosc_meczy || 
                             ', Gole: ' || rec.ilosc_goli || 
                             ', Asysty: ' || rec.ilosc_asyst);
        DBMS_OUTPUT.PUT_LINE('Żółte kartki: ' || rec.ilosc_zoltych_kartek || 
                             ', Czerwone kartki: ' || rec.ilosc_czerwonych_kartek);
        DBMS_OUTPUT.PUT_LINE('Średnia goli na mecz: ' || rec.srednia_goli_na_mecz);
        DBMS_OUTPUT.PUT_LINE('Średnia asyst na mecz: ' || rec.srednia_asyst_na_mecz);
        DBMS_OUTPUT.PUT_LINE('Średnia żółtych kartek na mecz: ' || rec.srednia_zoltych_kartek_na_mecz);
        DBMS_OUTPUT.PUT_LINE('Średnia czerwonych kartek na mecz: ' || rec.srednia_czerwonych_kartek_na_mecz);
    END LOOP;
END;

BEGIN
    pokaz_zawodnika_i_statystyki('Luka', 'Modric', TO_DATE('1985-09-09', 'YYYY-MM-DD'));
END;

CREATE OR REPLACE PROCEDURE pokaz_zawodnikow_klubu (
    p_nazwa_klubu IN KLUB.nazwa%TYPE
) AS
BEGIN
    DBMS_OUTPUT.PUT_LINE('Klub: ' || p_nazwa_klubu);
    FOR rec IN (
        SELECT z.imie, z.nazwisko, z.data_urodzenia
        FROM ZAWODNICY z
        JOIN KLUB k ON z.id_klubu = k.id_klubu
        WHERE k.nazwa = p_nazwa_klubu
    ) LOOP
        DBMS_OUTPUT.PUT_LINE('Zawodnik: ' || rec.imie || ' ' || rec.nazwisko ||
                             ', Data urodzenia: ' || TO_CHAR(rec.data_urodzenia));
    END LOOP;
END;

BEGIN
    pokaz_zawodnikow_klubu('Barcelona');
END;

CREATE OR REPLACE PROCEDURE pokaz_menadzera_klubu (
    p_nazwa_klubu IN KLUB.nazwa%TYPE
) AS
BEGIN
    FOR rec IN (
        SELECT m.imie, m.nazwisko, m.data_urodzenia, k.nazwa as nazwa_klubu
        FROM MENADZER m
        JOIN KLUB k ON m.id_klubu = k.id_klubu
        WHERE k.nazwa = p_nazwa_klubu
    ) LOOP
        DBMS_OUTPUT.PUT_LINE('Klub: ' || rec.nazwa_klubu || ', Menadżer: ' || rec.imie || ' ' || rec.nazwisko ||
                             ', Data urodzenia: ' || TO_CHAR(rec.data_urodzenia));
    END LOOP;
END;

BEGIN
    pokaz_menadzera_klubu('Barcelona');
END;
