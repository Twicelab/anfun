CREATE OR REPLACE FUNCTION DBSCAN(_tbl varchar, n integer, e numeric, p numeric default 2.0)
	RETURNS table (id integer, X numeric, Y numeric, C integer) AS
$func$
declare WAT integer;
BEGIN
CREATE TEMPORARY TABLE TT (id integer, x numeric, y numeric, c integer);
INSERT INTO TT SELECT * FROM initClusters(_tbl);
CREATE TEMPORARY TABLE TTT (id integer, NN integer);
INSERT INTO TTT SELECT a."id", COUNT(*)-1 as NN FROM TT a
JOIN TT b on (dist(a."x",a."y",b."x",b."y",p)<e)
GROUP BY a."id",a."x",a."y";
UPDATE TT SET C=-1 FROM TTT WHERE TTT."nn"<n and (TT."id"=TTT."id");
LOOP
CREATE TEMPORARY TABLE TTTT (id integer, CC integer);
INSERT INTO TTTT SELECT b."id", min(a."c") as CC FROM TT a
JOIN TT b on (dist(a."x",a."y",b."x",b."y",p)<e)
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

--SELECT * FROM KMeans('random2dimdotsblobs(100,3)',3)

--НИЖЕ НЕ СУЙТЕСЬ
CREATE OR REPLACE FUNCTION KMeans(_tbl varchar, k integer, p numeric default 2.0)
	RETURNS table (id integer, X numeric, Y numeric, C integer) AS
$func$
declare WAT integer;
BEGIN
CREATE TEMPORARY TABLE TT (id integer, x numeric, y numeric, c integer);
INSERT INTO TT SELECT * FROM initClusters('random2dimdotsblobs(100,4,1)');
CREATE TEMPORARY TABLE TTT (id integer, x numeric, y numeric, nx numeric, ny numeric);
SELECT COUNT(*) INTO WAT FROM TT;
FOR r in 1..k LOOP
INSERT INTO TTT SELECT r,a."x",a."y",a."x",a."y" FROM TT a WHERE (a."id")=TRUNC(WAT/k*r);
END LOOP;

INSERT INTO TTT SELECT 1,a."x",a."y",a."x",a."y" FROM TT a WHERE (a."id")=TRUNC(300/4*1);
INSERT INTO TTT SELECT 2,a."x",a."y",a."x",a."y" FROM TT a WHERE (a."id")=TRUNC(300/4*2);
INSERT INTO TTT SELECT 3,a."x",a."y",a."x",a."y" FROM TT a WHERE (a."id")=TRUNC(300/4*3);
INSERT INTO TTT SELECT 4,a."x",a."y",a."x",a."y" FROM TT a WHERE (a."id")=TRUNC(300/4*4);

SELECT * FROM TTT
SELECT * FROM TT

UPDATE TT a SET "c"=b."c" FROM (SELECT "id", "c" FROM (SELECT TT."id" as id, TTT."id" as c, 
rank() OVER (PARTITION BY TT."id" ORDER BY dist(TT."x",TT."y",TTT."x",TTT."y",2) DESC) as d 
FROM TT,TTT) x WHERE d=1) b WHERE (b."id"=a."id");
LOOP
UPDATE TTT a SET "x"=a."nx", "y"=a."ny", "nx"=b."x", "ny"=b."y" FROM 
(SELECT "c", AVG("x"), AVG("y") FROM TT GROUP BY "c") b WHERE (b."c"=a."id") ;
SELECT SUM(dist("x","y","nx","ny",p)) INTO WAT FROM TTT;
IF WAT=0 THEN EXIT;
ELSE
UPDATE TT a SET "c"=b."c" FROM (SELECT "id", "c" FROM (SELECT TT."id" as id, TTT."id" as c, 
rank() OVER (PARTITION BY TT."id" ORDER BY dist(TT."x",TT."y",TTT."x",TTT."y",p) DESC) as d 
FROM TT,TTT) x WHERE d=1) b WHERE (b."id"=a."id");
END IF;
END LOOP;
RETURN QUERY SELECT * FROM TT;
DROP TABLE TT;
DROP TABLE TTT;
END
$func$
LANGUAGE plpgsql;