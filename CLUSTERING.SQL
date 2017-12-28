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

CREATE OR REPLACE FUNCTION KMeans(_tbl varchar, k integer, p numeric default 2.0)
	RETURNS table (id integer, X numeric, Y numeric, C integer) AS
$func$
declare WAT integer;
BEGIN
CREATE TEMPORARY TABLE TT (id integer, x numeric, y numeric, c integer);
INSERT INTO TT SELECT * FROM initClusters(_tbl);
CREATE TEMPORARY TABLE TTT (id integer, x numeric, y numeric, nx numeric, ny numeric);
SELECT COUNT(*) INTO WAT FROM TT;

FOR r in 1..k LOOP
INSERT INTO TTT SELECT r,a."x",a."y",a."x",a."y" FROM TT a WHERE (a."id")=round(WAT/k*r);
END LOOP;


CREATE TEMPORARY TABLE TTTT (id integer, c integer, d integer);
INSERT INTO TTTT
SELECT a."id", a."c" FROM (SELECT TT."id" as id, TTT."id" as c, 
rank() OVER (PARTITION BY TT."id" ORDER BY dist(TT."x",TT."y",TTT."x",TTT."y",p) ASC) as d 
FROM TT,TTT) a WHERE a."d"=1;
UPDATE TT a SET "c"=b."c" FROM TTTT b WHERE (b."id"=a."id");
DROP TABLE TTTT;

LOOP
UPDATE TTT SET "x"="nx", "y"="ny";
CREATE TEMPORARY TABLE TTTT (c integer, x numeric, y numeric);
INSERT INTO TTTT SELECT TT."c", AVG(TT."x") as x, AVG(TT."y") as y FROM TT GROUP BY TT."c";
UPDATE TTT a SET "nx"=b."x", "ny"=b."y" FROM TTTT b WHERE (b."c"=a."id");
DROP TABLE TTTT;
SELECT SUM(dist(TTT."x",TTT."y",TTT."nx",TTT."ny",p)) INTO WAT FROM TTT;
EXIT WHEN WAT=0;
CREATE TEMPORARY TABLE TTTT (id integer, c integer, d integer);
INSERT INTO TTTT
SELECT a."id", a."c" FROM (SELECT TT."id" as id, TTT."id" as c, 
rank() OVER (PARTITION BY TT."id" ORDER BY dist(TT."x",TT."y",TTT."x",TTT."y",2) ASC) as d 
FROM TT,TTT) a WHERE a."d"=1;
UPDATE TT a SET "c"=b."c" FROM TTTT b WHERE (b."id"=a."id");
DROP TABLE TTTT;
END LOOP;

RETURN QUERY SELECT * FROM TT;
DROP TABLE TT;
DROP TABLE TTT;
END
$func$
LANGUAGE plpgsql;