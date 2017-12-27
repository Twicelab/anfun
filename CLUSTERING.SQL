CREATE OR REPLACE FUNCTION DBSCAN(_data varchar, _neighbors_num integer, _max_distance numeric) --на вход подается таблица с данными, количество соседей и расстояние до соседа
	RETURNS table (id integer, X numeric, Y numeric, _cluster_num integer) AS --выходные данные - это таблица с дополнительным столбцом, в который храняться номера кластеров
$func$
declare WAT integer;
BEGIN
CREATE TEMPORARY TABLE TT (id integer, x numeric, y numeric, _cluster_num integer);
INSERT INTO TT SELECT * FROM initClusters(_data);
CREATE TEMPORARY TABLE TTT (id integer, NN integer);
INSERT INTO TTT SELECT a."id", COUNT(*)-1 as NN FROM TT a
JOIN TT b on ((a."x"-b."x")*(a."x"-b."x")+(a."y"-b."y")*(a."y"-b."y")<_max_distance*_max_distance)
GROUP BY a."id",a."x",a."y";
UPDATE TT SET _cluster_num=-1 FROM TTT WHERE TTT."nn"<_neighbors_num and (TT."id"=TTT."id");
LOOP
CREATE TEMPORARY TABLE TTTT (id integer, CC integer);
INSERT INTO TTTT SELECT b."id", min(a."c") as CC FROM TT a
JOIN TT b on ((a."x"-b."x")*(a."x"-b."x")+(a."y"-b."y")*(a."y"-b."y")<_max_distance*_max_distance)
WHERE a."c">-1
GROUP BY b."id";
SELECT COUNT(*) INTO WAT FROM TT join TTTT on (TT."id"=TTTT."id") and (TT."c"!=TTTT."cc");
IF WAT>0 THEN
UPDATE TT SET _cluster_num=CC FROM TTTT WHERE (TT."id"=TTTT."id");
ELSE EXIT;
END IF;
DROP TABLE TTTT;
END LOOP;
RETURN QUERY SELECT * FROM TT;
DROP TABLE TT;
DROP TABLE TTT;
DROP TABLE TTTT;
END
$func$
LANGUAGE plpgsql;


--НИЖЕ НЕ СУЙТЕСЬ
CREATE OR REPLACE FUNCTION KMeans(_tbl varchar, k integer)
	RETURNS table (id integer, X numeric, Y numeric, C integer) AS
$func$
declare WAT integer;
BEGIN
CREATE TEMPORARY TABLE TT (id integer, x numeric, y numeric, c integer);
INSERT INTO TT SELECT * FROM initClusters(_tbl);
CREATE TEMPORARY TABLE TTT (id integer, x integer, y integer);
FOR r in 1..k LOOP
INSERT INTO TTT SELECT r,a."x",a."y" FROM TT a WHERE (a."id")

INSERT INTO TTT SELECT a."id", COUNT(*)-1 as NN FROM TT a
JOIN TT b on ((a."x"-b."x")*(a."x"-b."x")+(a."y"-b."y")*(a."y"-b."y")<e*e)
GROUP BY a."id",a."x",a."y";
UPDATE TT SET C=-1 FROM TTT WHERE TTT."nn"<n and (TT."id"=TTT."id");
LOOP
CREATE TEMPORARY TABLE TTTT (id integer, CC integer);
INSERT INTO TTTT SELECT b."id", min(a."c") as CC FROM TT a
JOIN TT b on ((a."x"-b."x")*(a."x"-b."x")+(a."y"-b."y")*(a."y"-b."y")<e*e)
WHERE a."c">-1
GROUP BY b."id";
SELECT COUNT(*) INTO WAT FROM TT join TTTT on (TT."id"=TTTT."id") and (TT."c"!=TTTT."cc");
IF WAT>0 THEN
UPDATE TT SET C=CC FROM TTTT WHERE (TT."id"=TTTT."id");
ELSE EXIT;
END IF;
DROP TABLE TTTT;
END LOOP;
RETURN QUERY SELECT * FROM TT;
DROP TABLE TT;
DROP TABLE TTT;
DROP TABLE TTTT;
END
$func$
LANGUAGE plpgsql;
