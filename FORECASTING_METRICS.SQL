CREATE OR REPLACE FUNCTION anfun.MAE(_tbl1 varchar, _tbl2 varchar)
RETURNS numeric as
$func$
	DECLARE 
    	S numeric;
	BEGIN
		CREATE TEMPORARY TABLE anfun.anfun.TT1 (x integer, y numeric);
		INSERT INTO anfun.TT1 SELECT * FROM anfun.timeSeriesShow(_tbl1);
		CREATE TEMPORARY TABLE anfun.TT2 (x integer, y numeric);
		INSERT INTO anfun.TT2 SELECT * FROM anfun.timeSeriesShow(_tbl2);
		select AVG(abs(a."y"-b."y")) INTO S FROM anfun.TT2 a join anfun.TT1 b on (a."x"=b."x");
		DROP TABLE anfun.TT1;
		DROP TABLE anfun.TT2;
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
		CREATE TEMPORARY TABLE anfun.TT1 (x integer, y numeric);
		INSERT INTO anfun.TT1 SELECT * FROM anfun.timeSeriesShow(_tbl1);
		CREATE TEMPORARY TABLE anfun.TT2 (x integer, y numeric);
		INSERT INTO anfun.TT2 SELECT * FROM anfun.timeSeriesShow(_tbl2);
		select sqrt(AVG((a."y"-b."y")*(a."y"-b."y"))) INTO S FROM anfun.TT2 a join anfun.TT1 b on (a."x"=b."x");
		DROP TABLE anfun.TT1;
		DROP TABLE anfun.TT2;
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
		CREATE TEMPORARY TABLE anfun.TT1 (x integer, y numeric);
		INSERT INTO anfun.TT1 SELECT * FROM anfun.timeSeriesShow(_tbl1);
		CREATE TEMPORARY TABLE anfun.TT2 (x integer, y numeric);
		INSERT INTO anfun.TT2 SELECT * FROM anfun.timeSeriesShow(_tbl2);
		select 100*AVG((b."y"-a."y")/b."y") INTO S FROM anfun.TT2 a join anfun.TT1 b on (a."x"=b."x");
		DROP TABLE anfun.TT1;
		DROP TABLE anfun.TT2;
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
		CREATE TEMPORARY TABLE anfun.TT1 (x integer, y numeric);
		INSERT INTO anfun.TT1 SELECT * FROM anfun.timeSeriesShow(_tbl1);
		CREATE TEMPORARY TABLE anfun.TT2 (x integer, y numeric);
		INSERT INTO anfun.TT2 SELECT * FROM anfun.timeSeriesShow(_tbl2);
		select 100*AVG(abs(b."y"-a."y")/b."y") INTO S FROM anfun.TT2 a join anfun.TT1 b on (a."x"=b."x");
		DROP TABLE anfun.TT1;
		DROP TABLE anfun.TT2;
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
		CREATE TEMPORARY TABLE anfun.TT1 (x integer, y numeric);
		INSERT INTO anfun.TT1 SELECT * FROM anfun.timeSeriesShow(_tbl1);
		CREATE TEMPORARY TABLE anfun.TT2 (x integer, y numeric);
		INSERT INTO anfun.TT2 SELECT * FROM anfun.timeSeriesShow(_tbl2);
		select SUM(abs(b."y"-a."y")) INTO S FROM anfun.TT2 a join anfun.TT1 b on (a."x"=b."x");
		DROP TABLE anfun.TT1;
		DROP TABLE anfun.TT2;
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
		CREATE TEMPORARY TABLE anfun.TT1 (x integer, y numeric);
		INSERT INTO anfun.TT1 SELECT * FROM anfun.timeSeriesShow(_tbl1);
		CREATE TEMPORARY TABLE anfun.TT2 (x integer, y numeric);
		INSERT INTO anfun.TT2 SELECT * FROM anfun.timeSeriesShow(_tbl2);
		select AVG(abs(b."y"-a."y")) INTO S FROM anfun.TT2 a join anfun.TT1 b on (a."x"=b."x");
		DROP TABLE anfun.TT1;
		DROP TABLE anfun.TT2;
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
		CREATE TEMPORARY TABLE anfun.TT1 (x integer, y numeric);
		INSERT INTO anfun.TT1 SELECT * FROM anfun.timeSeriesShow(_tbl1);
		CREATE TEMPORARY TABLE anfun.TT2 (x integer, y numeric);
		INSERT INTO anfun.TT2 SELECT * FROM anfun.timeSeriesShow(_tbl2);
		SELECT 1-"dt"/"dr" INTO S FROM
		(select SUM((a."y"-b."y")*(a."y"-b."y")) dt FROM anfun.TT2 a join anfun.TT1 b on (a."x"=b."x")) a,
		(select SUM((a."y"-b."y")*(a."y"-b."y")) dr FROM (select AVG("y") as y FROM anfun.TT1) a, anfun.TT1 b) b;
		DROP TABLE anfun.TT1;
		DROP TABLE anfun.TT2;
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
		CREATE TEMPORARY TABLE anfun.TT1 (x integer, y numeric);
		INSERT INTO anfun.TT1 SELECT * FROM anfun.timeSeriesShow(_tbl1);
		CREATE TEMPORARY TABLE anfun.TT2 (x integer, y numeric);
		INSERT INTO anfun.TT2 SELECT * FROM anfun.timeSeriesShow(_tbl2);
		select sqrt(SUM((b."y"-a."y")*(b."y"-a."y"))/SUM(b."y"*b."y"+a."y"*a."y")) INTO S FROM anfun.TT2 a join anfun.TT1 b on (a."x"=b."x");
		DROP TABLE anfun.TT1;
		DROP TABLE anfun.TT2;
		RETURN S;
	END
$func$
LANGUAGE plpgsql;