CREATE OR REPLACE FUNCTION anfun.expForecast(_tbl varchar, n numeric, l int, ll int)
RETURNS table (X integer, Y numeric) AS
$func$
	DECLARE 
    	WAT INTEGER;
	BEGIN
		CREATE TEMPORARY TABLE anfun.TT (x integer, y numeric);
		INSERT INTO anfun.TT SELECT * FROM anfun.timeSeriesShow(_tbl);
		CREATE TEMPORARY TABLE anfun.TTT (x integer, y numeric);
		INSERT INTO anfun.TTT SELECT * FROM anfun.TT;
		for r in 2..l LOOP
			UPDATE anfun.TTT c SET "y"=n*a."y"+(1.0-n)*b."y" FROM 
            anfun.TT a, anfun.TTT b WHERE (c."x"=r and a."x"=r-1 and b."x"=r-1);
		END LOOP;
		for r in l+1..l+ll LOOP
			UPDATE anfun.TTT c SET "y"=b."y" FROM anfun.TTT b WHERE (c."x"=r and b."x"=r-1);
		END LOOP;
		UPDATE anfun.TTT c SET Y=round(c."y",6);
		RETURN QUERY SELECT * FROM anfun.TTT;
		DROP TABLE anfun.TT;
		DROP TABLE anfun.TTT;
	END
$func$
LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION anfun.expTrendForecast(_tbl varchar, alpha numeric, beta numeric, l int, ll int)
RETURNS table (X integer, Y numeric) AS
$func$
	DECLARE 
    	WAT numeric;
	BEGIN
		CREATE TEMPORARY TABLE anfun.TT (x integer, y numeric);
		INSERT INTO anfun.TT SELECT * FROM anfun.timeSeriesShow(_tbl);
		CREATE TEMPORARY TABLE anfun.TTT (x integer, y numeric);
		INSERT INTO anfun.TTT SELECT * FROM anfun.TT;
		SELECT (a."y"-b."y")/l INTO WAT from anfun.TT a, anfun.TT b WHERE (a."x"=l and b."x"=1);
		for r in 2..l LOOP
			UPDATE anfun.TTT c SET "y"=alpha*a."y"+(1.0-alpha)*(b."y"+WAT) FROM 
            anfun.TT a, anfun.TTT b WHERE (c."x"=r and a."x"=r-1 and b."x"=r-1);
			SELECT (a."y"-b."y")*beta+(1.0-beta)*WAT INTO WAT from 
            anfun.TT a, anfun.TT b WHERE (a."x"=r and b."x"=r-1);
		END LOOP;
		for r in l+1..l+ll LOOP
			UPDATE anfun.TTT c SET "y"=b."y"+WAT FROM anfun.TTT b WHERE (c."x"=r and b."x"=r-1);
		END LOOP;
		UPDATE anfun.TTT c SET Y=round(c."y",6);
		RETURN QUERY SELECT * FROM anfun.TTT;
		DROP TABLE anfun.TT;
		DROP TABLE anfun.TTT;
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
		CREATE TEMPORARY TABLE anfun.TT (x integer, y numeric);
		INSERT INTO anfun.TT SELECT * FROM anfun.anfun.timeSeriesShow(_tbl);
		CREATE TEMPORARY TABLE anfun.TTT (x integer, y numeric);
		INSERT INTO anfun.TTT SELECT * FROM anfun.TT;
		CREATE TEMPORARY TABLE anfun.TTS (x integer, y numeric);
		INSERT INTO anfun.TTS SELECT * FROM anfun.TT;
		WAT:=0;
		SELECT AVG(a."y"-b."y") INTO WAT from anfun.TT a, anfun.TT b WHERE (a."x"=b."x"+p and b."x"<=p);
		WAT := WAT/p;
		TP:=0;
		SELECT SUM(a."y")/p INTO TP from anfun.TT a WHERE (a."x"<=p);
		UPDATE anfun.TTT a SET "y"=TP WHERE (a."x"=1);
		UPDATE anfun.TTS a SET "y"=b."y"-TP from anfun.TT b WHERE (b."x"=1 and a."x"=1);
		for r in 2..p+1 LOOP
			UPDATE anfun.TTT c SET "y"=b."y"+WAT FROM anfun.TTT b WHERE (c."x"=r and b."x"=r-1);
			SELECT (a."y"-b."y")*beta+(1.0-beta)*WAT INTO WAT from anfun.TTT a, anfun.TTT b WHERE (a."x"=r and b."x"=r-1);
			UPDATE anfun.TTS a SET "y"=b."y"-TP from anfun.TT b WHERE (b."x"=r and a."x"=r);
		END LOOP;
		for r in p+1..l+1 LOOP
			UPDATE anfun.TTT c SET "y"=alpha*(a."y"-d."y")+(1.0-alpha)*(b."y"+WAT) FROM anfun.TT a, anfun.TTT b, anfun.TTS d WHERE (c."x"=r and d."x"=r-p and a."x"=r-1 and b."x"=r-1);
			SELECT (a."y"-b."y")*beta+(1.0-beta)*WAT INTO WAT from anfun.TTT a, anfun.TTT b WHERE (a."x"=r and b."x"=r-1);
			UPDATE anfun.TTS c SET "y"=gamma*(a."y"-(b."y"+WAT))+(1.0-gamma)*(d."y") FROM anfun.TT a, anfun.TTT b, anfun.TTS d WHERE (c."x"=r and d."x"=r-p and a."x"=r and b."x"=r-1);
		END LOOP;
		for r in l+1..l+ll+1 LOOP
			UPDATE anfun.TTT c SET "y"=b."y"+WAT FROM anfun.TTT b WHERE (c."x"=r and b."x"=r-1);
			UPDATE anfun.TTS c SET "y"=d."y" FROM anfun.TTS d WHERE (c."x"=r and d."x"=r-p);
		END LOOP;
		UPDATE anfun.TTT c SET "y"=c."y"+b."y" FROM anfun.TTS b WHERE (c."x"=b."x"+p);
		UPDATE anfun.TTT c SET "y"=c."y"+b."y" FROM anfun.TTS b WHERE (c."x"=b."x" and c."x"<=p);
		UPDATE anfun.TTT c SET Y=round(c."y",6);
		RETURN QUERY SELECT * FROM anfun.TTT;
		DROP TABLE anfun.TT;
		DROP TABLE anfun.TTT;
		DROP TABLE anfun.TTS;
	END
$func$
LANGUAGE plpgsql;