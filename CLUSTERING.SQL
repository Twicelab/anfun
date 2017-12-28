CREATE OR REPLACE FUNCTION anfun.DBSCAN(_tbl varchar, n integer, e numeric, p numeric default 2.0)
RETURNS table (id integer, X numeric, Y numeric, C integer) AS
$func$
	DECLARE 
    	WAT integer;
	BEGIN
		CREATE TEMPORARY TABLE anfun.TT (id integer, x numeric, y numeric, c integer);
		INSERT INTO anfun.TT SELECT * FROM anfun.initClusters(_tbl);
		CREATE TEMPORARY TABLE anfun.TTT (id integer, NN integer);
		INSERT INTO anfun.TTT SELECT a."id", COUNT(*)-1 as NN FROM anfun.TT a
		JOIN anfun.TT b on (dist(a."x",a."y",b."x",b."y",p)<e)
		GROUP BY a."id",a."x",a."y";
		UPDATE anfun.TT SET C=-1 FROM anfun.TTT WHERE anfun.TTT."nn"<n and (anfun.TT."id"=anfun.TTT."id");
		LOOP
			CREATE TEMPORARY TABLE anfun.TTTT (id integer, CC integer);
			INSERT INTO anfun.TTTT SELECT b."id", min(a."c") as CC FROM anfun.TT a
			JOIN anfun.TT b on (dist(a."x",a."y",b."x",b."y",p)<e)
			WHERE a."c">-1
			GROUP BY b."id";
			SELECT COUNT(*) INTO WAT FROM anfun.TT join anfun.TTTT on 
            (anfun.TT."id"=anfun.TTTT."id") and (anfun.TT."c"!=anfun.TTTT."cc");
			IF WAT>0 THEN
				UPDATE anfun.TT SET C=CC FROM anfun.TTTT WHERE (anfun.TT."id"=anfun.TTTT."id");
			ELSE 
            	EXIT;
			END IF;
			DROP TABLE anfun.TTTT;
		END LOOP;
		RETURN QUERY SELECT * FROM anfun.TT;
		DROP TABLE anfun.TT;
		DROP TABLE anfun.TTT;
		DROP TABLE anfun.TTTT;
	END
$func$
LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION anfun.KMeans(_tbl varchar, k integer, p numeric default 2.0)
RETURNS table (id integer, X numeric, Y numeric, C integer) AS
$func$
	DECLARE 
    	WAT integer;
	BEGIN
		CREATE TEMPORARY TABLE anfun.TT (id integer, x numeric, y numeric, c integer);
		INSERT INTO anfun.TT SELECT * FROM anfun.initClusters(_tbl);
		CREATE TEMPORARY TABLE anfun.TTT (id integer, x numeric, y numeric, nx numeric, ny numeric);
		SELECT COUNT(*) INTO WAT FROM anfun.TT;
		FOR r in 1..k LOOP
			INSERT INTO anfun.TTT SELECT r,a."x",a."y",a."x",a."y" FROM anfun.TT a WHERE (a."id")=round(WAT/k*r);
		END LOOP;
		CREATE TEMPORARY TABLE anfun.TTTT (id integer, c integer, d integer);
		INSERT INTO anfun.TTTT
		SELECT a."id", a."c" FROM 
        (
        SELECT anfun.TT."id" as id, anfun.TTT."id" as c, 
		rank() OVER (PARTITION BY anfun.TT."id" 
                	 ORDER BY anfun.dist(anfun.TT."x",anfun.TT."y",anfun.TTT."x",anfun.TTT."y",p) ASC) as d 
		FROM anfun.TT,anfun.TTT 
        ) 
        a WHERE a."d"=1;
		UPDATE anfun.TT a SET "c"=b."c" FROM anfun.TTTT b WHERE (b."id"=a."id");
		DROP TABLE anfun.TTTT;
		LOOP
			UPDATE anfun.TTT SET "x"="nx", "y"="ny";
			CREATE TEMPORARY TABLE anfun.TTTT (c integer, x numeric, y numeric);
			INSERT INTO anfun.TTTT SELECT anfun.TT."c", 
            AVG(anfun.TT."x") as x, AVG(anfun.TT."y") as y FROM 
            anfun.TT GROUP BY anfun.TT."c";
			UPDATE anfun.TTT a SET "nx"=b."x", "ny"=b."y" FROM 
            anfun.TTTT b WHERE (b."c"=a."id");
			DROP TABLE anfun.TTTT;
			SELECT SUM(anfun.dist(anfun.TTT."x",anfun.TTT."y",anfun.TTT."nx",anfun.TTT."ny",p)) 
            INTO WAT FROM anfun.TTT;
			EXIT WHEN WAT=0;
			CREATE TEMPORARY TABLE anfun.TTTT (id integer, c integer, d integer);
			INSERT INTO anfun.TTTT
			SELECT a."id", a."c" FROM (SELECT anfun.TT."id" as id, anfun.TTT."id" as c, 
			rank() OVER (PARTITION BY anfun.TT."id" 
                         ORDER BY dist(anfun.TT."x",anfun.TT."y",anfun.TTT."x",anfun.TTT."y",2) ASC) as d 
			FROM anfun.TT,anfun.TTT) a WHERE a."d"=1;
			UPDATE anfun.TT a SET "c"=b."c" FROM 
            anfun.TTTT b WHERE (b."id"=a."id");
			DROP TABLE anfun.TTTT;
		END LOOP;
		RETURN QUERY SELECT * FROM anfun.TT;
		DROP TABLE anfun.TT;
		DROP TABLE anfun.TTT;
	END
$func$
LANGUAGE plpgsql;