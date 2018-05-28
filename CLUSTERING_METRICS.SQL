CREATE OR REPLACE FUNCTION anfun.DavidBoulduin(_data varchar, p numeric default 2.0)
RETURNS numeric as
$func$
	DECLARE 
    S numeric;
	BEGIN
		S:=0;
		CREATE TEMPORARY TABLE TT (id integer, x numeric, y numeric, c integer);
		INSERT INTO TT SELECT * FROM anfun.dots2DimClusteredShow(_data);
        CREATE TEMPORARY TABLE TTT (c integer, x numeric, y numeric);
        INSERT INTO TTT SELECT TT."c", AVG(TT."x") as x, AVG(TT."y") as y FROM TT GROUP BY TT."c";
        CREATE TEMPORARY TABLE TTTT (c integer, d numeric, x numeric, y numeric);
        
        INSERT INTO TTTT SELECT b."c", POWER(AVG(POWER(anfun.dist(a."x",a."y",b."x",b."y",p),p)),1.0/p) as d, b."x", b."y" 
        FROM TT a join TTT b on (a."c"=b."c") GROUP BY b."c",b."x",b."y";
        SELECT SUM(a."m") INTO S FROM
        (SELECT MAX((a."d"+b."d")/anfun.dist(a."x",a."y",b."x",b."y",p)) as m 
        FROM TTTT a join TTTT b on (a."c"<>b."c") GROUP BY a."c") a;
        
		DROP TABLE TT;
        DROP TABLE TTT;
        DROP TABLE TTTT;
		RETURN S;
	END
$func$
LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION anfun.Dunno(_data varchar, p numeric default 2.0)
RETURNS numeric as
$func$
	DECLARE 
    S numeric;
	BEGIN
		S:=0;
		CREATE TEMPORARY TABLE TT (id integer, x numeric, y numeric, c integer);
		INSERT INTO TT SELECT * FROM anfun.dots2DimClusteredShow(_data);
        
		SELECT AVG(a."d") INTO S FROM (
        SELECT CASE a."d" WHEN 0 THEN 0 ELSE b."d"/a."d" END as d FROM (
		SELECT a."id",MAX(anfun.dist(a."x",a."y",b."x",b."y",p)) as d
		FROM TT a JOIN TT b on (a."c"=b."c") GROUP BY a."id") a JOIN (
        SELECT a."id", MIN(anfun.dist(a."x",a."y",b."x",b."y",p)) as d
		FROM TT a JOIN TT b on (a."c"!=b."c") GROUP BY a."id") b
       	ON (a."id"=b."id")) a;
        
		DROP TABLE TT;
		RETURN S;
	END
$func$
LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION anfun.Sillhuette(_data varchar, p numeric default 2.0)
RETURNS numeric as
$func$
	DECLARE 
    S numeric;
	BEGIN
		S:=0;
		CREATE TEMPORARY TABLE TT (id integer, x numeric, y numeric, c integer);
		INSERT INTO TT SELECT * FROM anfun.dots2DimClusteredShow(_data);
        
        SELECT AVG(a."d") INTO S FROM (
		SELECT CASE a."cnt" WHEN 1 THEN 0 ELSE (b."d"-a."d")/anfun.MAXI(b."d",a."d") END as d FROM (
		SELECT a."id", COUNT(b."id") as cnt, AVG(anfun.dist(a."x",a."y",b."x",b."y",p)) as d
		FROM TT a JOIN TT b on (a."c"=b."c") GROUP BY a."id") a JOIN (
		SELECT a."id", MIN(a."d") as d FROM (
        SELECT a."id", AVG(anfun.dist(a."x",a."y",b."x",b."y",p)) as d
		FROM TT a JOIN TT b on (a."c"!=b."c") GROUP BY a."id",b."c") a 
        GROUP BY  a."id") b on (a."id"=b."id")) a;
		DROP TABLE TT;
		RETURN S;		
	END
$func$
LANGUAGE plpgsql;

