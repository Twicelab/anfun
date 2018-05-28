CREATE OR REPLACE FUNCTION anfun.Aglomerative(_tbl varchar, metric integer default 1, p numeric default 2.0)
RETURNS table (id integer, X numeric, Y numeric, C integer) AS
$func$
	DECLARE 
    	WAT numeric;
    	TWAT numeric;
    	TNUM integer;
    	NUM integer;
	BEGIN
    	Raise Notice 'Start!';
		CREATE TABLE AgloTT (id integer, x numeric, y numeric, c integer);
		INSERT INTO AgloTT SELECT * FROM anfun.initClusters(_tbl);
        IF metric = 1 THEN WAT:=anfun.Sillhuette('AgloTT'); END IF;
        IF metric = 2 THEN WAT:=anfun.Dunno('AgloTT'); END IF;
        SELECT COUNT(*) INTO NUM FROM (SELECT DISTINCT a."c" FROM AgloTT a) x;
    				Raise Notice 'INITIAL: %', WAT;
        CREATE TEMPORARY TABLE AgloTTT (id integer, x numeric, y numeric, c integer);
		INSERT INTO AgloTTT SELECT * FROM AgloTT;
        LOOP
        	SELECT COUNT(*) INTO TNUM FROM (SELECT DISTINCT a."c" FROM AgloTT a) x;
        	IF TNUM < 3 THEN
            	EXIT;
            END IF;        
            
			CREATE TEMPORARY TABLE AgloTTTT (id integer, x numeric, y numeric);
			INSERT INTO AgloTTTT SELECT a."c", avg(a."x"), avg(a."y") FROM AgloTT a GROUP BY a."c";
			
			CREATE TEMPORARY TABLE AgloTTTTT (ida integer, idb integer);
            INSERT INTO AgloTTTTT SELECT PRIM,SECU FROM (
            SELECT a."id" as PRIM,b."id" as SECU,anfun.dist(a."x",a."y",b."x",b."y",p) as DIFF 
            FROM AgloTTTT a join AgloTTTT b on (a."id"<b."id")
            ) a ORDER BY DIFF ASC limit 1;
            
            UPDATE AgloTT SET "c" = AgloTTTTT."ida" FROM AgloTTTTT WHERE AgloTT."c" = AgloTTTTT."idb";    		
            
            DROP TABLE AgloTTTT;
            DROP TABLE AgloTTTTT;
            
        		IF metric = 1 THEN TWAT:=anfun.Sillhuette('AgloTT'); END IF;
        		IF metric = 2 THEN TWAT:=anfun.Dunno('AgloTT'); END IF;
            	IF TWAT > WAT THEN            	
    				Raise Notice '%: % (Update)', TNUM, TWAT;
        			TRUNCATE TABLE AgloTTT;
            		INSERT INTO AgloTTT SELECT * FROM AgloTT;
                	WAT:=TWAT;
                ELSE                	            	
    				Raise Notice '%: % (Skip)', TNUM, TWAT;
            	END IF;
				
        END LOOP;
		RETURN QUERY SELECT * FROM AgloTTT;
		DROP TABLE AgloTT;
		DROP TABLE AgloTTT;
	END
$func$
LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION anfun.FOREL(_tbl varchar, r numeric, p numeric default 2.0)
RETURNS table (id integer, X numeric, Y numeric, C integer) AS
$func$
	DECLARE 
    	oX numeric;
    	oY numeric;
    	nX numeric;
    	nY numeric;
        i integer;
	BEGIN
		CREATE TEMPORARY TABLE TT (id integer, x numeric, y numeric, c integer);
		INSERT INTO TT SELECT * FROM anfun.initClusters(_tbl);
		CREATE TEMPORARY TABLE TTT (id integer, x numeric, y numeric, c integer);
		INSERT INTO TTT SELECT * FROM TT;
        i:=1;
        LOOP
        	IF (SELECT COUNT(*) FROM TTT)=0 THEN
            	EXIT;
            END IF;
        	SELECT TTT."x" into oX FROM TTT LIMIT 1;
        	SELECT TTT."y" into oY FROM TTT LIMIT 1;
            Raise Notice '(%,%)',oX,oY;
        	LOOP            
        		CREATE TEMPORARY TABLE TTTT (id integer, x numeric, y numeric);
				INSERT INTO TTTT SELECT TTT."id", TTT."x", TTT."y" FROM TTT 
                WHERE anfun.dist(TTT."x",TTT."y",oX,oY,p)<r;
                SELECT AVG(TTTT."x") INTO nX FROM TTTT;
                SELECT AVG(TTTT."y") INTO nY FROM TTTT;                
                IF nX=oX and nY=oY THEN            
                	UPDATE TT SET "c" = i WHERE TT."id" IN (SELECT TTTT."id" FROM TTTT);
                    DELETE FROM TTT WHERE TTT."id" IN (SELECT TTTT."id" FROM TTTT);
                    DROP TABLE TTTT;
            		Raise Notice 'Found cluster %, Dots left %',i,(SELECT COUNT(*) FROM TTT);
                    i:=i+1;
                    EXIT;
                ELSE         
                	oX:=nX;
                    oY:=nY;
                    DROP TABLE TTTT;
                END IF;
            END LOOP;           
       END LOOP;
       RETURN QUERY SELECT * FROM TT;
		DROP TABLE TT;
		DROP TABLE TTT;
	END
$func$
LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION anfun.DBSCAN(_tbl varchar, n integer, e numeric, p numeric default 2.0)
RETURNS table (id integer, X numeric, Y numeric, C integer) AS
$func$
	DECLARE 
    	WAT integer;
	BEGIN
		CREATE TEMPORARY TABLE TT (id integer, x numeric, y numeric, c integer);
		INSERT INTO TT SELECT * FROM anfun.initClusters(_tbl);
		CREATE TEMPORARY TABLE TTT (id integer, NN integer);
		INSERT INTO TTT SELECT a."id", COUNT(*)-1 as NN FROM TT a
		JOIN TT b on (anfun.dist(a."x",a."y",b."x",b."y",p)<e)
		GROUP BY a."id",a."x",a."y";
		UPDATE TT SET "c"=-1 FROM TTT WHERE TTT."nn"<n and (TT."id"=TTT."id");

			CREATE TEMPORARY TABLE TTTT (id integer, CC integer);
			INSERT INTO TTTT SELECT b."id", min(a."c") as CC FROM TT a
			JOIN TT b on (anfun.dist(a."x",a."y",b."x",b."y",p)<e)
			WHERE a."c">-1
			GROUP BY b."id";
			UPDATE TT SET "c"=TTTT."cc" FROM TTTT WHERE (TT."id"=TTTT."id");
			

		RETURN QUERY SELECT * FROM TT;
		DROP TABLE TT;
		DROP TABLE TTT;
		DROP TABLE TTTT;
	END
$func$
LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION anfun.KMedians(_tbl varchar, k integer, p numeric default 2.0)
RETURNS table (id integer, X numeric, Y numeric, C integer) AS
$func$
	DECLARE 
    	WAT integer;
	BEGIN
		CREATE TEMPORARY TABLE TT (id integer, x numeric, y numeric, c integer);
		INSERT INTO TT SELECT * FROM anfun.initClusters(_tbl);
		CREATE TEMPORARY TABLE TTT (id integer, x numeric, y numeric, nx numeric, ny numeric);
		SELECT COUNT(*) INTO WAT FROM TT;
		FOR r in 1..k LOOP
			INSERT INTO TTT SELECT r,a."x",a."y",a."x",a."y" FROM TT a WHERE (a."id")=round(WAT/k*r);
		END LOOP;
		CREATE TEMPORARY TABLE TTTT (id integer, c integer, d integer);
		INSERT INTO TTTT
		SELECT a."id", a."c" FROM 
        (
        SELECT TT."id" as id, TTT."id" as c, 
		rank() OVER (PARTITION BY TT."id" 
                	 ORDER BY anfun.dist(TT."x",TT."y",TTT."x",TTT."y",p) ASC) as d 
		FROM TT,TTT 
        ) 
        a WHERE a."d"=1;
		UPDATE TT a SET "c"=b."c" FROM TTTT b WHERE (b."id"=a."id");
		DROP TABLE TTTT;
		LOOP
			UPDATE TTT SET "x"="nx", "y"="ny";
			CREATE TEMPORARY TABLE TTTT (c integer, x numeric, y numeric);

            FOR r in 1..k LOOP
				INSERT INTO TTTT SELECT r,a."x",b."y" FROM
            	(SELECT a."x" FROM (SELECT TT."x" FROM TT WHERE TT."c" = r ORDER BY TT."x" DESC
				LIMIT (SELECT (count(*) / 2) FROM TT)) a 
            	ORDER BY a."x" ASC LIMIT 1) a,
            	(SELECT a."y" FROM (SELECT TT."y" FROM TT WHERE TT."c" = r ORDER BY TT."y" DESC
				LIMIT (SELECT (count(*) / 2) FROM TT)) a 
            	ORDER BY a."y" ASC LIMIT 1) b;
			END LOOP;         
            
            
			UPDATE TTT a SET "nx"=b."x", "ny"=b."y" FROM 
            TTTT b WHERE (b."c"=a."id");
			DROP TABLE TTTT;
			SELECT SUM(anfun.dist(TTT."x",TTT."y",TTT."nx",TTT."ny",p)) 
            INTO WAT FROM TTT;
			EXIT WHEN WAT=0;
			CREATE TEMPORARY TABLE TTTT (id integer, c integer, d integer);
			INSERT INTO TTTT
			SELECT a."id", a."c" FROM (SELECT TT."id" as id, TTT."id" as c, 
			rank() OVER (PARTITION BY TT."id" 
                         ORDER BY anfun.dist(TT."x",TT."y",TTT."x",TTT."y",p) ASC) as d 
			FROM TT,TTT) a WHERE a."d"=1;
			UPDATE TT a SET "c"=b."c" FROM 
            TTTT b WHERE (b."id"=a."id");
			DROP TABLE TTTT;
		END LOOP;
		RETURN QUERY SELECT * FROM TT;
		DROP TABLE TT;
		DROP TABLE TTT;
	END
$func$
LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION anfun.KMeans(_tbl varchar, k integer, p numeric default 2.0)
RETURNS table (id integer, X numeric, Y numeric, C integer) AS
$func$
	DECLARE 
    	WAT integer;
	BEGIN
		CREATE TEMPORARY TABLE TT (id integer, x numeric, y numeric, c integer);
		INSERT INTO TT SELECT * FROM anfun.initClusters(_tbl);
		CREATE TEMPORARY TABLE TTT (id integer, x numeric, y numeric, nx numeric, ny numeric);
		SELECT COUNT(*) INTO WAT FROM TT;
		FOR r in 1..k LOOP
			INSERT INTO TTT SELECT r,a."x",a."y",a."x",a."y" FROM TT a WHERE (a."id")=round(WAT/k*r);
		END LOOP;
		CREATE TEMPORARY TABLE TTTT (id integer, c integer, d integer);
		INSERT INTO TTTT
		SELECT a."id", a."c" FROM 
        (
        SELECT TT."id" as id, TTT."id" as c, 
		rank() OVER (PARTITION BY TT."id" 
                	 ORDER BY anfun.dist(TT."x",TT."y",TTT."x",TTT."y",p) ASC) as d 
		FROM TT,TTT 
        ) 
        a WHERE a."d"=1;
		UPDATE TT a SET "c"=b."c" FROM TTTT b WHERE (b."id"=a."id");
		DROP TABLE TTTT;
		LOOP
			UPDATE TTT SET "x"="nx", "y"="ny";
			CREATE TEMPORARY TABLE TTTT (c integer, x numeric, y numeric);
			INSERT INTO TTTT SELECT TT."c", 
            AVG(TT."x") as x, AVG(TT."y") as y FROM 
            TT GROUP BY TT."c";
			UPDATE TTT a SET "nx"=b."x", "ny"=b."y" FROM 
            TTTT b WHERE (b."c"=a."id");
			DROP TABLE TTTT;
			SELECT SUM(anfun.dist(TTT."x",TTT."y",TTT."nx",TTT."ny",p)) 
            INTO WAT FROM TTT;
			EXIT WHEN WAT=0;
			CREATE TEMPORARY TABLE TTTT (id integer, c integer, d integer);
			INSERT INTO TTTT
			SELECT a."id", a."c" FROM (SELECT TT."id" as id, TTT."id" as c, 
			rank() OVER (PARTITION BY TT."id" 
                         ORDER BY anfun.dist(TT."x",TT."y",TTT."x",TTT."y",p) ASC) as d 
			FROM TT,TTT) a WHERE a."d"=1;
			UPDATE TT a SET "c"=b."c" FROM 
            TTTT b WHERE (b."id"=a."id");
			DROP TABLE TTTT;
		END LOOP;
		RETURN QUERY SELECT * FROM TT;
		DROP TABLE TT;
		DROP TABLE TTT;
	END
$func$
LANGUAGE plpgsql;
