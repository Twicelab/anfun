CREATE SCHEMA AnFun;

CREATE TABLE TEA (X integer, Y numeric);
CREATE TABLE SP500 (X integer, Y numeric);
CREATE TABLE POPULATION (X integer, Y numeric);
CREATE TABLE SPB_STOPS (ID integer, LATITUDE numeric, LONGITUDE numeric);

COPY TEA FROM 'С:\anfun-master\anfun-master\TEA.csv' DELIMITER ';' CSV HEADER;
COPY SP500 FROM 'С:\anfun-master\anfun-master\SP500.csv' DELIMITER ';' CSV HEADER;
COPY POPULATION FROM 'С:\anfun-master\anfun-master\POPULATION.csv' DELIMITER ';' CSV HEADER;
COPY SPB_STOPS FROM 'С:\anfun-master\anfun-master\SPB_STOPS.csv' DELIMITER ';' CSV HEADER;

CREATE OR REPLACE FUNCTION anfun.dist(x1 numeric,y1 numeric,x2 numeric,y2 numeric, p numeric default 2.0)
RETURNS numeric AS
$func$
	DECLARE 
		S numeric;
	BEGIN
    	IF p=2.0 THEN S:=SQRT((x1-x2)*(x1-x2)+(y1-y2)*(y1-y2));
        ELSEIF p=1.0 THEN S:=ABS(x1-x2)+ABS(y1-y2);
        ELSE S:=POWER(POWER(ABS(x1-x2),p)+POWER(ABS(y1-y2),p),1.0/p); END IF;
		RETURN S;
	END
$func$
LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION anfun.dots2DimShow(_tbl varchar)
RETURNS table(id int, X numeric, Y numeric) AS
$func$
	BEGIN
		RETURN QUERY EXECUTE 'SELECT * FROM ' || _tbl;
	END
$func$  
LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION anfun.timeSeriesShow(_tbl varchar)
RETURNS table(X integer, Y numeric) AS
$func$
	BEGIN
		RETURN QUERY EXECUTE 'SELECT * FROM ' || _tbl;
	END
$func$  
LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION anfun.dots2DimClusteredShow(_tbl varchar)
RETURNS table(id integer, X numeric, Y numeric, C integer) AS
$func$
	BEGIN
		RETURN QUERY EXECUTE 'SELECT * FROM ' || _tbl;
	END
$func$  
LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION anfun.initClusters(_tbl varchar)
RETURNS table(id int, X numeric, Y numeric, C int) AS
$func$
	BEGIN
		RETURN QUERY EXECUTE 'SELECT s."id", s."x", s."y", s."id" as "c" FROM anfun.dots2DimShow('''||_tbl||''') s';
	END
$func$
LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION anfun.maxi(a numeric, b numeric)
RETURNS NUMERIC AS
$func$
	BEGIN 
		IF a>b THEN RETURN a; ELSE RETURN b; END IF;
	END
$func$
LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION anfun.mini(a numeric, b numeric)
RETURNS NUMERIC AS
$func$
	BEGIN 
		IF a<b THEN RETURN a; ELSE RETURN b; END IF;
	END
$func$
LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION anfun.random2DimDotsCircles(k integer, h integer,w numeric)
RETURNS table(id int, X numeric, Y numeric) AS
$func$
	DECLARE
		ox numeric;
		lx numeric;
		ly numeric;
	BEGIN
		FOR f in 1..h LOOP
			ox:=f; 
			FOR r in 1..k LOOP
    			id:=r+(f-1)*k; 
        		lx:=(random()-0.5);
        		ly:=(random()-0.5);
        		X:=sin(2*3.141593*ly)*(ox+lx*lx*lx*w); 
        		Y:=cos(2*3.141593*ly)*(ox+lx*lx*lx*w);
        		RETURN NEXT;     
			END LOOP;
		END LOOP;
	END
$func$
LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION anfun.random2DimDotsBlobs(k integer, h integer, w numeric)
RETURNS table(id int, X numeric, Y numeric) AS
$func$
	DECLARE 
		ox numeric; 
		oy numeric; 
		lx numeric; 
		ly numeric; 
	BEGIN 
		FOR f in 1..h LOOP 
			ox:=random(); 
			oy:=random(); 
			FOR r in 1..k LOOP 
				id:=r+(f-1)*k; 
				lx:=(random()-0.5); 
				ly:=random(); 
				X:=ox+sin(2*3.141592*lx)*ly*ly*ly/h/h*w; 
				Y:=oy+cos(2*3.141592*lx)*ly*ly*ly/h/h*w; 
				RETURN NEXT; 
			END LOOP; 
		END LOOP; 
	END
$func$
LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION anfun.randomTimeSeries(k integer, o numeric, l numeric)
RETURNS table(X integer, Y numeric) AS
$func$
	DECLARE 
    	d numeric;
	BEGIN 
		d:=0;
		FOR r in 1..k LOOP
        	X:=r; 
        	d:=d+sin(2.0*pi()/k*o*r)+l*(random()-0.5)*(random()-0.5);
        	Y:=d;
        	RETURN NEXT;     
		END LOOP;
	END
$func$
LANGUAGE plpgsql;

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


CREATE OR REPLACE FUNCTION anfun.expForecast(_tbl varchar, n numeric, l int DEFAULT 0, ll int DEFAULT 0)
RETURNS table (X integer, Y numeric) AS
$func$
	DECLARE 
    	WAT INTEGER;
		NUM INTEGER;
	BEGIN
		CREATE TEMPORARY TABLE TT (x integer, y numeric);
		INSERT INTO TT SELECT * FROM anfun.timeSeriesShow(_tbl);
		IF l=0 THEN
			SELECT COUNT(*) INTO l FROM TT;
		END IF;
		SELECT COUNT(*) INTO NUM FROM TT;
		IF l>NUM THEN
			ll:=ll+(l-NUM);
			SELECT COUNT(*) INTO l FROM TT;
		END IF;
		CREATE TEMPORARY TABLE TTT (x integer, y numeric);
		INSERT INTO TTT SELECT * FROM TT;
		for r in 2..l LOOP
			UPDATE TTT c SET "y"=n*a."y"+(1.0-n)*b."y" FROM 
            TT a, TTT b WHERE (c."x"=r and a."x"=r and b."x"=r-1);
		END LOOP;
		IF (l+ll)>NUM THEN
			IF l=NUM THEN 
				FOR r IN l+1..l+ll LOOP
					INSERT INTO TTT(X) VALUES (r);
					UPDATE TTT c SET "y"=b."y" FROM TTT b WHERE (c."x"=r and b."x"=r-1);
				END LOOP;
			ELSE 
				FOR r IN l+1..NUM LOOP
					UPDATE TTT c SET "y"=b."y" FROM TTT b WHERE (c."x"=r and b."x"=r-1);
				END LOOP;
				FOR r IN NUM..l+ll LOOP
					INSERT INTO TTT(X) VALUES (r);
					UPDATE TTT c SET "y"=b."y" FROM TTT b WHERE (c."x"=r and b."x"=r-1);
				END LOOP;
			END IF;
		ELSE
			FOR r IN l+1..l+ll LOOP
				UPDATE TTT c SET "y"=b."y" FROM TTT b WHERE (c."x"=r and b."x"=r-1);
			END LOOP;
			IF (l+ll)<NUM THEN
				FOR r IN l+ll+1..NUM LOOP
					DELETE FROM TTT c WHERE c.x=r;
				END LOOP;
			END IF;
		END IF;
		UPDATE TTT c SET Y=round(c."y",6);
		RETURN QUERY SELECT * FROM TTT ORDER BY x;
		DROP TABLE TT;
		DROP TABLE TTT;
	END
$func$
LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION anfun.expTrendForecast(_tbl varchar, alpha numeric, beta numeric, l int DEFAULT 0, ll int DEFAULT 0)
RETURNS table (X integer, Y numeric) AS
$func$
	DECLARE 
    	WAT numeric;
		NUM INTEGER;
	BEGIN
		CREATE TEMPORARY TABLE TT (x integer, y numeric);
		INSERT INTO TT SELECT * FROM anfun.timeSeriesShow(_tbl);
		IF l=0 THEN
			SELECT COUNT(*) INTO l FROM TT;
		END IF;
		SELECT COUNT(*) INTO NUM FROM TT;
		IF l>NUM THEN
			ll:=ll+(l-NUM);
			SELECT COUNT(*) INTO l FROM TT;
		END IF;
		CREATE TEMPORARY TABLE TTT (x integer, y numeric);
		INSERT INTO TTT SELECT * FROM TT;
		SELECT (a."y"-b."y")/(l-1) INTO WAT from TT a, TT b WHERE (a."x"=l and b."x"=1);
		for r in 2..l LOOP
			UPDATE TTT c SET "y"=alpha*a."y"+(1.0-alpha)*(b."y"+WAT) FROM 
            TT a, TTT b WHERE (c."x"=r and a."x"=r and b."x"=r-1);
			SELECT (a."y"-b."y")*beta+(1.0-beta)*WAT INTO WAT from 
            TT a, TT b WHERE (a."x"=r and b."x"=r-1);
		END LOOP;
		IF (l+ll)>NUM THEN
			IF l=NUM THEN 
				FOR r IN l+1..l+ll LOOP
					INSERT INTO TTT(X) VALUES (r);
					UPDATE TTT c SET "y"=b."y"+WAT FROM TTT b WHERE (c."x"=r and b."x"=r-1);
				END LOOP;
			ELSE 
				FOR r IN l+1..NUM LOOP
					UPDATE TTT c SET "y"=b."y"+WAT FROM TTT b WHERE (c."x"=r and b."x"=r-1);
				END LOOP;
				FOR r IN NUM..l+ll LOOP
					INSERT INTO TTT(X) VALUES (r);
					UPDATE TTT c SET "y"=b."y"+WAT FROM TTT b WHERE (c."x"=r and b."x"=r-1);
				END LOOP;
			END IF;
		ELSE
			FOR r IN l+1..l+ll LOOP
				UPDATE TTT c SET "y"=b."y"+WAT FROM TTT b WHERE (c."x"=r and b."x"=r-1);
			END LOOP;
			IF (l+ll)<NUM THEN
				FOR r IN l+ll+1..NUM LOOP
					DELETE FROM TTT c WHERE c.x=r;
				END LOOP;
			END IF;
		END IF;
		UPDATE TTT c SET Y=round(c."y",6);
		RETURN QUERY SELECT * FROM TTT ORDER BY x;
		DROP TABLE TT;
		DROP TABLE TTT;
	END
$func$
LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION anfun.holtWintersForecast(_tbl varchar, alpha numeric, beta numeric, gamma numeric, p int, l int DEFAULT 0, ll int DEFAULT 0)
RETURNS table (X integer, Y numeric) AS
$func$
	DECLARE 
		WAT numeric;
		TP numeric;
		NUM INTEGER;
	BEGIN
		CREATE TEMPORARY TABLE TT (x integer, y numeric);
		INSERT INTO TT SELECT * FROM anfun.timeSeriesShow(_tbl);
		IF l=0 THEN
			SELECT COUNT(*) INTO l FROM TT;
		END IF;
		SELECT COUNT(*) INTO NUM FROM TT;
		IF l>NUM THEN
			ll:=ll+(l-NUM);
			SELECT COUNT(*) INTO l FROM TT;
		END IF;
		CREATE TEMPORARY TABLE TTT (x integer, y numeric);
		INSERT INTO TTT SELECT * FROM TT;
		CREATE TEMPORARY TABLE TTS (x integer, y numeric);
		INSERT INTO TTS SELECT * FROM TT;
		WAT:=0;
		SELECT AVG(a."y"-b."y") INTO WAT from TT a, TT b WHERE (a."x"=b."x"+p and b."x"<=p);
		WAT := WAT/p;
		TP:=0;
		SELECT SUM(a."y")/p INTO TP from TT a WHERE (a."x"<=p);
		UPDATE TTT a SET "y"=TP WHERE (a."x"=1);
		UPDATE TTS a SET "y"=b."y"-TP from TT b WHERE (b."x"=1 and a."x"=1);
		for r in 2..p+1 LOOP
			UPDATE TTT c SET "y"=b."y"+WAT FROM TTT b WHERE (c."x"=r and b."x"=r-1);
			SELECT (a."y"-b."y")*beta+(1.0-beta)*WAT INTO WAT from TTT a, TTT b WHERE (a."x"=r and b."x"=r-1);
			UPDATE TTS a SET "y"=b."y"-TP from TT b WHERE (b."x"=r and a."x"=r);
		END LOOP;
		IF (l=NUM) THEN
			INSERT INTO TTT(X) VALUES (l+1);
			INSERT INTO TTS(X) VALUES (l+1);
		END IF;
		for r in p+1..l+1 LOOP
			UPDATE TTT c SET "y"=alpha*(a."y"-d."y")+(1.0-alpha)*(b."y"+WAT) FROM TT a, TTT b, TTS d WHERE (c."x"=r and d."x"=r-p and a."x"=r-1 and b."x"=r-1);
			SELECT (a."y"-b."y")*beta+(1.0-beta)*WAT INTO WAT from TTT a, TTT b WHERE (a."x"=r and b."x"=r-1);
			UPDATE TTS c SET "y"=gamma*(a."y"-(b."y"+WAT))+(1.0-gamma)*(d."y") FROM TT a, TTT b, TTS d WHERE (c."x"=r and d."x"=r-p and a."x"=r and b."x"=r-1);
		END LOOP;
		IF (l=NUM) THEN
			DELETE FROM TTT c WHERE c.x=l+1;
			DELETE FROM TTS c WHERE c.x=l+1;
		END IF;
		IF (l+ll)>NUM THEN
			IF l=NUM THEN 
				FOR r IN l+1..l+ll+1 LOOP
					INSERT INTO TTT(X) VALUES (r);
					INSERT INTO TTS(X) VALUES (r);
					UPDATE TTT c SET "y"=b."y"+WAT FROM TTT b WHERE (c."x"=r and b."x"=r-1);
					UPDATE TTS c SET "y"=d."y" FROM TTS d WHERE (c."x"=r and d."x"=r-p);
				END LOOP;
				DELETE FROM TTT c WHERE c.x=l+ll+1;
				DELETE FROM TTS c WHERE c.x=l+ll+1;
			ELSE 
				FOR r IN l+1..NUM+1 LOOP
					UPDATE TTT c SET "y"=b."y"+WAT FROM TTT b WHERE (c."x"=r and b."x"=r-1);
					UPDATE TTS c SET "y"=d."y" FROM TTS d WHERE (c."x"=r and d."x"=r-p);
				END LOOP;
				FOR r IN NUM..l+ll+1 LOOP
					INSERT INTO TTT(X) VALUES (r);
					INSERT INTO TTS(X) VALUES (r);
					UPDATE TTT c SET "y"=b."y"+WAT FROM TTT b WHERE (c."x"=r and b."x"=r-1);
					UPDATE TTS c SET "y"=d."y" FROM TTS d WHERE (c."x"=r and d."x"=r-p);
				END LOOP;
				DELETE FROM TTT c WHERE c.x=l+ll+1;
				DELETE FROM TTS c WHERE c.x=l+ll+1;
			END IF;
		ELSE
			FOR r IN l+1..l+ll+1 LOOP
				UPDATE TTT c SET "y"=b."y"+WAT FROM TTT b WHERE (c."x"=r and b."x"=r-1);
				UPDATE TTS c SET "y"=d."y" FROM TTS d WHERE (c."x"=r and d."x"=r-p);
			END LOOP;
			IF (l+ll)<NUM THEN
				DELETE FROM TTT c WHERE c.x>l+ll;
				DELETE FROM TTS c WHERE c.x>l+ll;
			END IF;
		END IF;
		UPDATE TTT c SET "y"=c."y"+b."y" FROM TTS b WHERE (c."x"=b."x"+p);
		UPDATE TTT c SET "y"=c."y"+b."y" FROM TTS b WHERE (c."x"=b."x" and c."x"<=p);
		UPDATE TTT c SET Y=round(c."y",6);
		RETURN QUERY SELECT * FROM TTT ORDER BY x;
		DROP TABLE TT;
		DROP TABLE TTT;
		DROP TABLE TTS;
	END
$func$
LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION anfun.MAE(_tbl1 varchar, _tbl2 varchar)
RETURNS numeric as
$func$
	DECLARE 
    	S numeric;
	BEGIN
		CREATE TEMPORARY TABLE TT1 (x integer, y numeric);
		INSERT INTO TT1 SELECT * FROM anfun.timeSeriesShow(_tbl1);
		CREATE TEMPORARY TABLE TT2 (x integer, y numeric);
		INSERT INTO TT2 SELECT * FROM anfun.timeSeriesShow(_tbl2);
		select AVG(abs(a."y"-b."y")) INTO S FROM TT2 a join TT1 b on (a."x"=b."x");
		DROP TABLE TT1;
		DROP TABLE TT2;
		RETURN S;
	END
$func$
LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION anfun.RMSE(_tbl1 varchar, _tbl2 varchar)
RETURNS numeric as
$func$
	DECLARE 
    	S numeric;
	BEGIN
		CREATE TEMPORARY TABLE TT1 (x integer, y numeric);
		INSERT INTO TT1 SELECT * FROM anfun.timeSeriesShow(_tbl1);
		CREATE TEMPORARY TABLE TT2 (x integer, y numeric);
		INSERT INTO TT2 SELECT * FROM anfun.timeSeriesShow(_tbl2);
		select sqrt(AVG((a."y"-b."y")*(a."y"-b."y"))) INTO S FROM TT2 a join TT1 b on (a."x"=b."x");
		DROP TABLE TT1;
		DROP TABLE TT2;
		RETURN S;
	END
$func$
LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION anfun.MPE(_tbl1 varchar, _tbl2 varchar)
RETURNS numeric as
$func$
	DECLARE 
    	S numeric;
	BEGIN
		CREATE TEMPORARY TABLE TT1 (x integer, y numeric);
		INSERT INTO TT1 SELECT * FROM anfun.timeSeriesShow(_tbl1);
		CREATE TEMPORARY TABLE TT2 (x integer, y numeric);
		INSERT INTO TT2 SELECT * FROM anfun.timeSeriesShow(_tbl2);
		select 100*AVG((b."y"-a."y")/b."y") INTO S FROM TT2 a join TT1 b on (a."x"=b."x");
		DROP TABLE TT1;
		DROP TABLE TT2;
		RETURN S;
	END
$func$
LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION anfun.MAPE(_tbl1 varchar, _tbl2 varchar)
RETURNS numeric as
$func$
	DECLARE 
    	S numeric;
	BEGIN
		CREATE TEMPORARY TABLE TT1 (x integer, y numeric);
		INSERT INTO TT1 SELECT * FROM anfun.timeSeriesShow(_tbl1);
		CREATE TEMPORARY TABLE TT2 (x integer, y numeric);
		INSERT INTO TT2 SELECT * FROM anfun.timeSeriesShow(_tbl2);
		select 100*AVG(abs(b."y"-a."y")/b."y") INTO S FROM TT2 a join TT1 b on (a."x"=b."x");
		DROP TABLE TT1;
		DROP TABLE TT2;
		RETURN S;
	END
$func$
LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION anfun.AD(_tbl1 varchar, _tbl2 varchar)
RETURNS numeric as
$func$
	DECLARE 
    	S numeric;
	BEGIN
		CREATE TEMPORARY TABLE TT1 (x integer, y numeric);
		INSERT INTO TT1 SELECT * FROM anfun.timeSeriesShow(_tbl1);
		CREATE TEMPORARY TABLE TT2 (x integer, y numeric);
		INSERT INTO TT2 SELECT * FROM anfun.timeSeriesShow(_tbl2);
		select SUM(abs(b."y"-a."y")) INTO S FROM TT2 b, (select AVG("y") as y FROM TT1) a;
		DROP TABLE TT1;
		DROP TABLE TT2;
		RETURN S;
	END
$func$
LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION anfun.MAD(_tbl1 varchar, _tbl2 varchar)
RETURNS numeric as
$func$
	DECLARE 
    	S numeric;
	BEGIN
		CREATE TEMPORARY TABLE TT1 (x integer, y numeric);
		INSERT INTO TT1 SELECT * FROM anfun.timeSeriesShow(_tbl1);
		CREATE TEMPORARY TABLE TT2 (x integer, y numeric);
		INSERT INTO TT2 SELECT * FROM anfun.timeSeriesShow(_tbl2);
		select AVG(abs(b."y"-a."y")) INTO S FROM TT2 b, (select AVG("y") as y FROM TT1) a;
		DROP TABLE TT1;
		DROP TABLE TT2;
		RETURN S;
	END
$func$
LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION anfun.R2(_tbl1 varchar, _tbl2 varchar)
RETURNS numeric as
$func$
	DECLARE 
    	S numeric;
	BEGIN
		CREATE TEMPORARY TABLE TT1 (x integer, y numeric);
		INSERT INTO TT1 SELECT * FROM anfun.timeSeriesShow(_tbl1);
		CREATE TEMPORARY TABLE TT2 (x integer, y numeric);
		INSERT INTO TT2 SELECT * FROM anfun.timeSeriesShow(_tbl2);
		SELECT regr_r2(a.Y, b.Y) INTO S FROM TT1 a JOIN TT2 b ON (a."x"=b."x");
		DROP TABLE TT1;
		DROP TABLE TT2;
		RETURN S;
	END
$func$
LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION anfun.THEIL(_tbl1 varchar, _tbl2 varchar)
RETURNS numeric as
$func$
	DECLARE 
		S numeric;
	BEGIN
		CREATE TEMPORARY TABLE TT1 (x integer, y numeric);
		INSERT INTO TT1 SELECT * FROM anfun.timeSeriesShow(_tbl1);
		CREATE TEMPORARY TABLE TT2 (x integer, y numeric);
		INSERT INTO TT2 SELECT * FROM anfun.timeSeriesShow(_tbl2);
		select sqrt(SUM((b."y"-a."y")*(b."y"-a."y"))/SUM(b."y"*b."y"+a."y"*a."y")) INTO S FROM TT2 a join TT1 b on (a."x"=b."x");
		DROP TABLE TT1;
		DROP TABLE TT2;
		RETURN S;
	END
$func$
LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION anfun.Pearson(_tbl1 varchar, _tbl2 varchar)
RETURNS numeric as
$func$
	DECLARE 
		S numeric;
		AVG_y1 numeric;
		AVG_y2 numeric;
	BEGIN
		CREATE TEMPORARY TABLE TT1 (x integer, y numeric);
		INSERT INTO TT1 SELECT * FROM anfun.timeSeriesShow(_tbl1);
		CREATE TEMPORARY TABLE TT2 (x integer, y numeric);
		INSERT INTO TT2 SELECT * FROM anfun.timeSeriesShow(_tbl2);
		SELECT AVG(y) INTO AVG_y1 FROM TT1;
		SELECT AVG(y) INTO AVG_y2 FROM TT2;
		SELECT (SUM((a."y"-AVG_y1)*(b."y"-AVG_y2))/SQRT(SUM((a."y"-AVG_y1)*(a."y"-AVG_y1))*SUM((b."y"-AVG_y2)*(b."y"-AVG_y2)))) INTO S FROM TT1 a join TT2 b on (a."x"=b."x");
		DROP TABLE TT1;
		DROP TABLE TT2;
		RETURN S;
	END
$func$
LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION anfun.linearRegression(_tbl varchar, l int DEFAULT 0, ll int DEFAULT 0)
RETURNS table (X integer, Y numeric) AS
$func$
	DECLARE
    	AK numeric;
		BK numeric;
		NUM integer;
		D numeric;
	BEGIN
		CREATE TEMPORARY TABLE TT (x integer, y numeric);
		INSERT INTO TT SELECT * FROM anfun.timeSeriesShow(_tbl);
		IF l=0 THEN
			SELECT COUNT(*) INTO l FROM TT;
		END IF;
		SELECT COUNT(*) INTO NUM FROM TT;
		IF l>NUM THEN
			ll:=ll+(l-NUM);
			SELECT COUNT(*) INTO l FROM TT;
		END IF;
		CREATE TEMPORARY TABLE TTT (x integer, y numeric);
		INSERT INTO TTT SELECT * FROM TT;
		SELECT regr_intercept(a.Y, a.X) INTO BK FROM TT a;
		SELECT regr_slope(a.Y, a.X) INTO AK FROM TT a;
		SELECT (MAX(a.x)-MIN(a.x))/NUM INTO D FROM TT a;
		IF (l+ll)>NUM THEN
			IF l=NUM THEN 
				FOR r IN l+1..l+ll LOOP
					INSERT INTO TTT(x) VALUES(r);
				END LOOP;
			ELSE
				FOR r IN NUM+1..l+ll LOOP
					INSERT INTO TTT(x) VALUES(r);
				END LOOP;
			END IF;
		END IF;
		UPDATE TTT c SET "y"=(AK*c."x")+BK;
		UPDATE TTT c SET X=round(c."x",6);
		UPDATE TTT c SET Y=round(c."y",6);
		RETURN QUERY SELECT * FROM TTT ORDER BY x;
		DROP TABLE TT;
		DROP TABLE TTT;
	END
$func$
LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION anfun.Determinant(sys numeric[][])
RETURNS numeric AS
$func$
	DECLARE
    	B numeric;
		Q numeric[][];
		n integer;
		detQ numeric;
	BEGIN
		B:=0;
		detQ:=1;
		SELECT array_length(sys, 1) INTO n;
		Q:=array_fill(0, ARRAY[n-1, n-1]);
		IF n=1 THEN
			B:=sys[1][1];
		ELSIF n=2 THEN
			B:=sys[1][1]*sys[2][2]-sys[1][2]*sys[2][1];
		ELSE 
			FOR r IN 1..n LOOP
				FOR i IN 1..n-1 LOOP
					FOR j IN 1..n LOOP
						IF j<r THEN
							Q[i][j]:=sys[i+1][j];
						ELSIF j>r THEN
							Q[i][j-1]:=sys[i+1][j];
						END IF;
					END LOOP;						
				END LOOP;
				detQ:=anfun.Determinant(Q);
				B:=B+((-1)^(r+1))*sys[1][r]*detQ;
			END LOOP;
		END IF;
		RETURN B;
	END
$func$
LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION anfun.Cramer(sys numeric[][], r numeric[])
RETURNS numeric[] AS
$func$
	DECLARE
    	Det numeric;
		Det_i numeric;
		num integer;
		M_i numeric[][];
		Ans numeric[];
	BEGIN
		Det:=anfun.Determinant(sys);
		SELECT array_length(r, 1) INTO num;
		M_i:=sys;
		Ans:=r;
		FOR i IN 1..num LOOP
			FOR j IN 1..num LOOP
				M_i[j][i]:=r[j];
			END LOOP;
			Det_i:=anfun.Determinant(M_i);
			Ans[i]:=Det_i/Det;
			M_i:=sys;
		END LOOP;
		RETURN Ans;
	END
$func$
LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION anfun.TransposeMatrix(sys numeric[][])
RETURNS numeric[][] AS
$func$
	DECLARE
		AT numeric[][];
		m integer;
		n integer;
	BEGIN
		SELECT array_length(sys, 1) INTO m;
		SELECT array_length(sys, 2) INTO n;
		AT:=array_fill(0, ARRAY[n, m]);
		FOR i IN 1..n LOOP
			FOR j IN 1..m LOOP
				AT[i][j]:=sys[j][i];
			END LOOP;
		END LOOP;
		RETURN AT;
	END
$func$
LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION anfun.InvertMatrix(sys numeric[][])
RETURNS numeric[][] AS
$func$
	DECLARE
    	Det numeric;
		AComp numeric[][];
		n integer;
		sys_s numeric[][];
		AI numeric[][];
	BEGIN
		Det:=anfun.Determinant(sys);
		SELECT array_length(sys, 1) INTO n;
		AComp:=array_fill(0, ARRAY[n, n]);
		AI:=array_fill(0, ARRAY[n, n]);
		sys_s:=array_fill(0, ARRAY[n-1, n-1]);
		FOR i IN 1..n LOOP
			FOR j IN 1..n LOOP
				FOR i_s IN 1..n LOOP
					FOR j_s IN 1..n LOOP
						IF i_s<i THEN
							IF j_s<j THEN
								sys_s[i_s][j_s]:=sys[i_s][j_s];
							ELSIF j_s>j THEN
								sys_s[i_s][j_s-1]:=sys[i_s][j_s];
							END IF;
						ELSIF i_s>i THEN
							IF j_s<j THEN
								sys_s[i_s-1][j_s]:=sys[i_s][j_s];
							ELSIF j_s>j THEN
								sys_s[i_s-1][j_s-1]:=sys[i_s][j_s];
							END IF;
						END IF;
					END LOOP;
				END LOOP;
				AComp[i][j]:=((-1)^(i+j))*anfun.Determinant(sys_s);
			END LOOP;
		END LOOP;
		AComp:=anfun.TransposeMatrix(AComp);
		FOR i IN 1..n LOOP
			FOR j IN 1..n LOOP
				AI[i][j]:=(1/Det)*AComp[j][i];
			END LOOP;
		END LOOP;
		AI:=anfun.TransposeMatrix(AI);
		RETURN AI;
	END
$func$
LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION anfun.MultMatrix(G numeric[][], H numeric[][])
RETURNS numeric[][] AS
$func$
	DECLARE
    	R numeric[][];
		a integer;
		b integer;
		c integer;
	BEGIN
		SELECT array_length(G, 1) INTO a;
		SELECT array_length(G, 2) INTO b;
		SELECT array_length(H, 2) INTO c;
		R:=array_fill(0, ARRAY[a, c]);
		FOR i IN 1..a LOOP
			FOR j IN 1..c LOOP
				FOR k IN 1..b LOOP
					R[i][j]:=R[i][j]+G[i][k]*H[k][j];
				END LOOP;
			END LOOP;
		END LOOP;
		RETURN R;
	END
$func$
LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION anfun.OLS(A numeric[][], b numeric[])
RETURNS numeric[] AS
$func$
	DECLARE
		b_mx numeric[][];
		bt numeric[][];
		At numeric[][];
		prom numeric[][];
		m integer;
		n integer;
		Ans numeric[];
	BEGIN
		SELECT array_length(A, 1) INTO m;
		SELECT array_length(A, 2) INTO n;
		At:=array_fill(0, ARRAY[n, m]);
		bt:=array_fill(0, ARRAY[m, 1]);
		b_mx:=array_fill(0, ARRAY[1, m]);
		prom:=array_fill(0, ARRAY[n, n]);
		Ans:=array_fill(0, ARRAY[n]);
		FOR i IN 1..m LOOP
			b_mx[1][i]:=b[i];
		END LOOP;
		At:=anfun.TransposeMatrix(A);
		bt:=anfun.TransposeMatrix(b_mx);
		prom:=anfun.MultMatrix(At, A);
		prom:=anfun.InvertMatrix(prom);
		prom:=anfun.MultMatrix(prom, At);
		prom:=anfun.MultMatrix(prom, bt);
		FOR i IN 1..n LOOP
			Ans[i]:=prom[i][1];
		END LOOP;
		RETURN Ans;
	END
$func$
LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION anfun.AR(_tbl varchar, p integer, k integer, l int DEFAULT 0, ll int DEFAULT 0) 
/* p<(l-1)/2 */ 
RETURNS table (X integer, Y numeric) AS
$func$
	DECLARE
    	k_a numeric[];
		z_mx numeric[][];
		z_r numeric[];
		z_f numeric[];
		y_n numeric;
		num integer;
		prom numeric;
	BEGIN
		CREATE TEMPORARY TABLE TT (x integer, y numeric);
		INSERT INTO TT SELECT * FROM anfun.timeSeriesShow(_tbl);
		CREATE TEMPORARY TABLE TTT (x integer, y numeric);
		INSERT INTO TTT SELECT * FROM TT;
		IF l=0 THEN
			SELECT COUNT(*) INTO l FROM TT;
		END IF;
		SELECT COUNT(*) INTO num FROM TT;
		IF l>num THEN
			ll:=ll+(l-num);
			SELECT COUNT(*) INTO l FROM TT;
		END IF;
		z_mx:=array_fill(0, ARRAY[p+1, p+1]);
		z_r:=array_fill(0, ARRAY[p+1]);
		k_a:=array_fill(0, ARRAY[p+1]);
		z_f:=array_fill(0, ARRAY[p+1]);
		y_n:=0;
		FOR i IN 0..p LOOP
			SELECT a.Y FROM TT a INTO prom WHERE (a."x"=l-i);
			z_r[i+1]:=prom;
		END LOOP;
		FOR j IN 1..p+1 LOOP
			z_mx[j][1]:=1;
		END LOOP;
		FOR i IN 1..p+1 LOOP
			FOR j IN 2..p+1 LOOP
				SELECT a.Y FROM TT a INTO prom WHERE (a."x"=l-j-i+2);
				z_mx[i][j]:=prom;
			END LOOP;
		END LOOP;
		k_a:=anfun.OLS(z_mx, z_r);
		IF (l+ll)>num THEN
			IF l=num THEN 
				FOR r IN l+1..l+ll LOOP
					z_f[1]:=1;
					FOR i IN 0..p-1 LOOP
						SELECT a.Y FROM TT a INTO prom WHERE (a."x"=r-1-i);
						z_f[i+2]:=prom;
					END LOOP;
					FOR i IN 1..p+1 LOOP
						y_n:=y_n+k_a[i]*z_f[i];
					END LOOP;
					INSERT INTO TTT VALUES (r, y_n);
					INSERT INTO TT VALUES (r, y_n);
					z_f:=array_fill(0, ARRAY[p+1]);
					y_n:=0;
				END LOOP;
			ELSE 
				FOR r IN l+1..num LOOP
					z_f[1]:=1;
					FOR i IN 0..p-1 LOOP
						SELECT a.Y FROM TT a INTO prom WHERE (a."x"=r-1-i);
						z_f[i+2]:=prom;
					END LOOP;
					FOR i IN 1..p+1 LOOP
						y_n:=y_n+k_a[i]*z_f[i];
					END LOOP;
					UPDATE TTT a SET "y"=y_n WHERE (a."x"=r);
					UPDATE TT a SET "y"=y_n WHERE (a."x"=r);
					z_f:=array_fill(0, ARRAY[p+1]);
					y_n:=0;
				END LOOP;
				FOR r IN num..l+ll LOOP
					z_f[1]:=1;
					FOR i IN 0..p-1 LOOP
						SELECT a.Y FROM TT a INTO prom WHERE (a."x"=r-1-i);
						z_f[i+2]:=prom;
					END LOOP;
					FOR i IN 1..p+1 LOOP
						y_n:=y_n+k_a[i]*z_f[i];
					END LOOP;
					INSERT INTO TTT VALUES (r, y_n);
					INSERT INTO TT VALUES (r, y_n);
					z_f:=array_fill(0, ARRAY[p+1]);
					y_n:=0;
				END LOOP;
			END IF;
		ELSE
			FOR r IN l+1..l+ll LOOP
				z_f[1]:=1;
				FOR i IN 0..p-1 LOOP
					SELECT a.Y FROM TT a INTO prom WHERE (a."x"=r-1-i);
					z_f[i+2]:=prom;
				END LOOP;
				FOR i IN 1..p+1 LOOP
					y_n:=y_n+k_a[i]*z_f[i];
				END LOOP;
				UPDATE TTT a SET "y"=y_n WHERE (a."x"=r);
				UPDATE TT a SET "y"=y_n WHERE (a."x"=r);
				z_f:=array_fill(0, ARRAY[p+1]);
				y_n:=0;
			END LOOP;
		END IF;
		UPDATE TTT c SET X=round(c."x",6);
		UPDATE TTT c SET Y=round(c."y",6);
		RETURN QUERY SELECT * FROM TTT ORDER BY x;
		DROP TABLE TT;
		DROP TABLE TTT;
	END
$func$
LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION anfun.I(_tbl varchar) 
RETURNS table (X integer, Y numeric) AS
$func$
	DECLARE
		num integer;
		prom numeric;
		d numeric[];
		d2 numeric[];
	BEGIN
		CREATE TEMPORARY TABLE TT (x integer, y numeric);
		INSERT INTO TT SELECT * FROM anfun.timeSeriesShow(_tbl);
		CREATE TEMPORARY TABLE TTD (x integer, y numeric);
		SELECT COUNT(*) INTO num FROM TT;
		d:=array_fill(0, ARRAY[num]);
		d2:=array_fill(0, ARRAY[num]);
		d[1]:=0;
		FOR i IN 2..num LOOP
			SELECT b.y-a.y INTO prom FROM TT a JOIN TT b ON (a."x"=i-1 AND b."x"=i);
			d[i]:=prom;
		END LOOP;
		d2[1]:=0;
		FOR i IN 2..num LOOP
			d2[i]:=d[i]-d[i-1];
		END LOOP;
		FOR i IN 1..num LOOP
			INSERT INTO TTD VALUES (i, d2[i]);
		END LOOP;
		UPDATE TTD c SET X=round(c."x",6);
		UPDATE TTD c SET Y=round(c."y",6);
		RETURN QUERY SELECT * FROM TTD ORDER BY x;
		DROP TABLE TT;
		DROP TABLE TTD;
	END
$func$
LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION anfun.MA(_tbl varchar, q integer)
RETURNS table(X integer, Y numeric) AS
$func$
	DECLARE
		num integer;
		prom numeric;
		p_y numeric;
	BEGIN
		CREATE TEMPORARY TABLE TT (x integer, y numeric);
		INSERT INTO TT SELECT * FROM anfun.timeSeriesShow(_tbl);
		CREATE TEMPORARY TABLE TTT (x integer, y numeric);
		INSERT INTO TTT SELECT * FROM TT;
		SELECT COUNT(*) INTO num FROM TT;
		prom:=0;
		FOR i IN 2..num LOOP
			IF (i<q) THEN
				FOR k IN 1..i LOOP
					SELECT c.Y INTO p_y FROM TT c WHERE (c."x"=i-k+1);
					prom:=prom+p_y;
				END LOOP;
				prom:=prom/i;
				UPDATE TTT c SET Y=prom WHERE (c."x"=i);
				prom:=0;
			ELSE
				FOR k IN 1..q LOOP
					SELECT c.Y INTO p_y FROM TT c WHERE (c."x"=i-k+1);
					prom:=prom+p_y;
				END LOOP;
				prom:=prom/q;
				UPDATE TTT c SET Y=prom WHERE (c."x"=i);
				prom:=0;
			END IF;
		END LOOP;
		UPDATE TTT c SET X=round(c."x",6);
		UPDATE TTT c SET Y=round(c."y",6);
		RETURN QUERY EXECUTE 'SELECT * FROM TTT ORDER BY x';
		DROP TABLE TT;
		DROP TABLE TTT;
	END
$func$
LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION anfun.ARIMA(_tbl varchar, p integer, k integer, q integer, l int DEFAULT 0, ll int DEFAULT 0)
RETURNS table(X integer, Y numeric) AS
$func$
	DECLARE
		num integer;
		num_A integer;
		prom numeric;
		d numeric[];
		d2 numeric[];
	BEGIN
		CREATE TEMPORARY TABLE TTA (x integer, y numeric);
		INSERT INTO TTA SELECT * FROM anfun.timeSeriesShow(_tbl);
		CREATE TEMPORARY TABLE TTA2 (x integer, y numeric);
		INSERT INTO TTA2 SELECT * FROM anfun.MA('TTA', q);
		CREATE TEMPORARY TABLE TTA3 (x integer, y numeric);
		SELECT COUNT(*) INTO num FROM TTA;
		d:=array_fill(0, ARRAY[num]);
		d2:=array_fill(0, ARRAY[num]);
		d[1]:=0;
		FOR i IN 2..num LOOP
			SELECT b.y-a.y INTO prom FROM TTA a JOIN TTA b ON (a."x"=i-1 AND b."x"=i);
			d[i]:=prom;
		END LOOP;
		d2[1]:=0;
		FOR i IN 2..num LOOP
			d2[i]:=d[i]-d[i-1];
		END LOOP;
		FOR i IN 1..num LOOP
			INSERT INTO TTA3 VALUES (i, d2[i]);
		END LOOP;
		CREATE TEMPORARY TABLE TTA4 (x integer, y numeric);
		INSERT INTO TTA4 SELECT * FROM anfun.AR('TTA3', p, k, l, ll);
		CREATE TEMPORARY TABLE Answer (x integer, y numeric);
		INSERT INTO Answer SELECT * FROM anfun.timeSeriesShow(_tbl);		
		FOR i IN l+1..l+ll LOOP
			SELECT a.Y INTO prom FROM TTA4 a WHERE (a."x"=i);
			d2[i]:=prom;
		END LOOP;
		IF (l+ll)>num THEN
			IF l=num THEN 
				FOR r IN l+1..l+ll LOOP
					INSERT INTO Answer(X) VALUES (r);
					UPDATE Answer a SET "y"=b.y+d[r-1]+d2[r] FROM Answer b WHERE (a."x"=r AND b."x"=r-1);
					d[r]:=d[r-1]+d2[r];
				END LOOP;
			ELSE 
				FOR r IN l+1..num LOOP
					UPDATE Answer a SET "y"=b.y+d[r-1]+d2[r] FROM Answer b WHERE (a."x"=r AND b."x"=r-1);
					d[r]:=d[r-1]+d2[r];
				END LOOP;
				FOR r IN num..l+ll LOOP
					INSERT INTO Answer(X) VALUES (r);
					UPDATE Answer a SET "y"=b.y+d[r-1]+d2[r] FROM Answer b WHERE (a."x"=r AND b."x"=r-1);
					d[r]:=d[r-1]+d2[r];
				END LOOP;
			END IF;
		ELSE
			FOR r IN l+1..l+ll LOOP
				UPDATE Answer a SET "y"=b.y+d[r-1]+d2[r] FROM Answer b WHERE (a."x"=r AND b."x"=r-1);
				d[r]:=d[r-1]+d2[r];
			END LOOP;
		END IF;
		UPDATE Answer c SET X=round(c."x",6);
		UPDATE Answer c SET Y=round(c."y",6);
		RETURN QUERY SELECT * FROM Answer ORDER BY x;
		DROP TABLE TTA;
		DROP TABLE TTA2;
		DROP TABLE TTA3;
		DROP TABLE TTA4;
		DROP TABLE Answer;
	END
$func$
LANGUAGE plpgsql;
