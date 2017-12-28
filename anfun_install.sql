
--CREATE SCHEMA AnFun;

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
		JOIN TT b on (dist(a."x",a."y",b."x",b."y",p)<e)
		GROUP BY a."id",a."x",a."y";
		UPDATE TT SET C=-1 FROM TTT WHERE TTT."nn"<n and (TT."id"=TTT."id");
		LOOP
			CREATE TEMPORARY TABLE TTTT (id integer, CC integer);
			INSERT INTO TTTT SELECT b."id", min(a."c") as CC FROM TT a
			JOIN TT b on (anfun.dist(a."x",a."y",b."x",b."y",p)<e)
			WHERE a."c">-1
			GROUP BY b."id";
			SELECT COUNT(*) INTO WAT FROM TT join TTTT on 
            (TT."id"=TTTT."id") and (TT."c"!=TTTT."cc");
			IF WAT>0 THEN
				UPDATE TT SET C=CC FROM TTTT WHERE (TT."id"=TTTT."id");
			ELSE 
            	EXIT;
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
                         ORDER BY dist(TT."x",TT."y",TTT."x",TTT."y",2) ASC) as d 
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

CREATE OR REPLACE FUNCTION anfun.Sillhuette(_data varchar, p numeric default 2.0)
RETURNS numeric as
$func$
	DECLARE 
    S numeric;
	BEGIN
		S:=0;
		CREATE TEMPORARY TABLE TT (id integer, x numeric, y numeric, c integer);
		INSERT INTO TT SELECT * FROM anfun.dots2DimClusteredShow(_data);
		SELECT AVG(b."d") INTO S FROM (
		SELECT a."c",AVG(a."d") as d FROM (
		SELECT a."id",a."c",(b."d"-a."d")/anfun.MAXI(b."d",a."d") as d FROM (
		SELECT a."id",a."c",AVG(anfun.dist(a."x",a."y",b."x",b."y",p)) as d
		FROM TT a JOIN TT b on (a."c"=b."c") GROUP BY a."id",a."c") a JOIN (
		SELECT a."id",a."c",AVG(anfun.dist(a."x",a."y",b."x",b."y",p)) as d
		FROM TT a JOIN TT b on (a."c"!=b."c") GROUP BY a."id",a."c") b on (a."id"=b."id") )a GROUP BY a."c") b;
		DROP TABLE TT;
		RETURN S;
	END
$func$
LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION anfun.expForecast(_tbl varchar, n numeric, l int, ll int)
RETURNS table (X integer, Y numeric) AS
$func$
	DECLARE 
    	WAT INTEGER;
	BEGIN
		CREATE TEMPORARY TABLE TT (x integer, y numeric);
		INSERT INTO TT SELECT * FROM anfun.timeSeriesShow(_tbl);
		CREATE TEMPORARY TABLE TTT (x integer, y numeric);
		INSERT INTO TTT SELECT * FROM TT;
		for r in 2..l LOOP
			UPDATE TTT c SET "y"=n*a."y"+(1.0-n)*b."y" FROM 
            TT a, TTT b WHERE (c."x"=r and a."x"=r-1 and b."x"=r-1);
		END LOOP;
		for r in l+1..l+ll LOOP
			UPDATE TTT c SET "y"=b."y" FROM TTT b WHERE (c."x"=r and b."x"=r-1);
		END LOOP;
		UPDATE TTT c SET Y=round(c."y",6);
		RETURN QUERY SELECT * FROM TTT;
		DROP TABLE TT;
		DROP TABLE TTT;
	END
$func$
LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION anfun.expTrendForecast(_tbl varchar, alpha numeric, beta numeric, l int, ll int)
RETURNS table (X integer, Y numeric) AS
$func$
	DECLARE 
    	WAT numeric;
	BEGIN
		CREATE TEMPORARY TABLE TT (x integer, y numeric);
		INSERT INTO TT SELECT * FROM anfun.timeSeriesShow(_tbl);
		CREATE TEMPORARY TABLE TTT (x integer, y numeric);
		INSERT INTO TTT SELECT * FROM TT;
		SELECT (a."y"-b."y")/l INTO WAT from TT a, TT b WHERE (a."x"=l and b."x"=1);
		for r in 2..l LOOP
			UPDATE TTT c SET "y"=alpha*a."y"+(1.0-alpha)*(b."y"+WAT) FROM 
            TT a, TTT b WHERE (c."x"=r and a."x"=r-1 and b."x"=r-1);
			SELECT (a."y"-b."y")*beta+(1.0-beta)*WAT INTO WAT from 
            TT a, TT b WHERE (a."x"=r and b."x"=r-1);
		END LOOP;
		for r in l+1..l+ll LOOP
			UPDATE TTT c SET "y"=b."y"+WAT FROM TTT b WHERE (c."x"=r and b."x"=r-1);
		END LOOP;
		UPDATE TTT c SET Y=round(c."y",6);
		RETURN QUERY SELECT * FROM TTT;
		DROP TABLE TT;
		DROP TABLE TTT;
	END
$func$
LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION anfun.holtWintersForecast(_tbl varchar, alpha numeric, beta numeric, gamma numeric, p int, l int, ll int)
RETURNS table (X integer, Y numeric) AS
$func$
	DECLARE 
		WAT numeric;
		TP numeric;
	BEGIN
		CREATE TEMPORARY TABLE TT (x integer, y numeric);
		INSERT INTO TT SELECT * FROM anfun.timeSeriesShow(_tbl);
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
		for r in p+1..l+1 LOOP
			UPDATE TTT c SET "y"=alpha*(a."y"-d."y")+(1.0-alpha)*(b."y"+WAT) FROM TT a, TTT b, TTS d WHERE (c."x"=r and d."x"=r-p and a."x"=r-1 and b."x"=r-1);
			SELECT (a."y"-b."y")*beta+(1.0-beta)*WAT INTO WAT from TTT a, TTT b WHERE (a."x"=r and b."x"=r-1);
			UPDATE TTS c SET "y"=gamma*(a."y"-(b."y"+WAT))+(1.0-gamma)*(d."y") FROM TT a, TTT b, TTS d WHERE (c."x"=r and d."x"=r-p and a."x"=r and b."x"=r-1);
		END LOOP;
		for r in l+1..l+ll+1 LOOP
			UPDATE TTT c SET "y"=b."y"+WAT FROM TTT b WHERE (c."x"=r and b."x"=r-1);
			UPDATE TTS c SET "y"=d."y" FROM TTS d WHERE (c."x"=r and d."x"=r-p);
		END LOOP;
		UPDATE TTT c SET "y"=c."y"+b."y" FROM TTS b WHERE (c."x"=b."x"+p);
		UPDATE TTT c SET "y"=c."y"+b."y" FROM TTS b WHERE (c."x"=b."x" and c."x"<=p);
		UPDATE TTT c SET Y=round(c."y",6);
		RETURN QUERY SELECT * FROM TTT;
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
		CREATE TEMPORARY TABLE anfun.TT1 (x integer, y numeric);
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
		select SUM(abs(b."y"-a."y")) INTO S FROM TT2 a join TT1 b on (a."x"=b."x");
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
		select AVG(abs(b."y"-a."y")) INTO S FROM TT2 a join TT1 b on (a."x"=b."x");
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
		SELECT 1-"dt"/"dr" INTO S FROM
		(select SUM((a."y"-b."y")*(a."y"-b."y")) dt FROM TT2 a join TT1 b on (a."x"=b."x")) a,
		(select SUM((a."y"-b."y")*(a."y"-b."y")) dr FROM (select AVG("y") as y FROM TT1) a, TT1 b) b;
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