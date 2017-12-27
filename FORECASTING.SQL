CREATE OR REPLACE FUNCTION expForecast(_tbl varchar, n numeric, l int, ll int)
	RETURNS table (X integer, Y numeric) AS
$func$
DECLARE WAT INTEGER;
BEGIN
CREATE TEMPORARY TABLE TT (x integer, y numeric);
INSERT INTO TT SELECT * FROM timeSeriesShow(_tbl);
CREATE TEMPORARY TABLE TTT (x integer, y numeric);
INSERT INTO TTT SELECT * FROM TT;
for r in 2..l LOOP
UPDATE TTT c SET "y"=n*a."y"+(1.0-n)*b."y" FROM TT a, TTT b WHERE (c."x"=r and a."x"=r-1 and b."x"=r-1);
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

CREATE OR REPLACE FUNCTION expTrendForecast(_tbl varchar, alpha numeric, beta numeric, l int, ll int)
	RETURNS table (X integer, Y numeric) AS
$func$
DECLARE WAT numeric;
BEGIN
CREATE TEMPORARY TABLE TT (x integer, y numeric);
INSERT INTO TT SELECT * FROM timeSeriesShow(_tbl);
CREATE TEMPORARY TABLE TTT (x integer, y numeric);
INSERT INTO TTT SELECT * FROM TT;
SELECT (a."y"-b."y")/l INTO WAT from TT a, TT b WHERE (a."x"=l and b."x"=1);
for r in 2..l LOOP
UPDATE TTT c SET "y"=alpha*a."y"+(1.0-alpha)*(b."y"+WAT) FROM TT a, TTT b WHERE (c."x"=r and a."x"=r-1 and b."x"=r-1);
SELECT (a."y"-b."y")*beta+(1.0-beta)*WAT INTO WAT from TTT a, TTT b WHERE (a."x"=r and b."x"=r-1);
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

CREATE OR REPLACE FUNCTION holtWintersForecast(_tbl varchar, alpha numeric, beta numeric, gamma numeric, p int, l int, ll int)
	RETURNS table (X integer, Y numeric) AS
$func$
DECLARE 
WAT numeric;
TP numeric;
BEGIN
CREATE TEMPORARY TABLE TT (x integer, y numeric);
INSERT INTO TT SELECT * FROM timeSeriesShow(_tbl);
CREATE TEMPORARY TABLE TTT (x integer, y numeric);
INSERT INTO TTT SELECT * FROM TT;
CREATE TEMPORARY TABLE TTS (x integer, y numeric);
INSERT INTO TTS SELECT * FROM TT;
WAT:=0;
SELECT AVG(a."y"-b."y") INTO WAT from TT a, TT b WHERE (a."x"=b."x"+p and b."x"<=p);
WAT := WAT/p;
TP:=0;
SELECT AVG(a."y") INTO TP from TT a WHERE (a."x"<=p);
UPDATE TTS a SET "y"=b."y"/TP from TT b WHERE (b."x"=a."x" and a."x"<=p);
for r in 2..p LOOP
UPDATE TTT c SET "y"=alpha*a."y"+(1.0-alpha)*(b."y"+WAT) FROM TT a, TTT b WHERE (c."x"=r and a."x"=r-1 and b."x"=r-1);
SELECT (a."y"-b."y")*beta+(1.0-beta)*WAT INTO WAT from TTT a, TTT b WHERE (a."x"=r and b."x"=r-1);
END LOOP;
for r in p+1..l LOOP
UPDATE TTT c SET "y"=alpha*a."y"/d."y"+(1.0-alpha)*(b."y"+WAT) FROM TT a, TTT b, TTS d WHERE (c."x"=r and d."x"=r-p and a."x"=r-1 and b."x"=r-1);
SELECT (a."y"-b."y")*beta+(1.0-beta)*WAT INTO WAT from TTT a, TTT b WHERE (a."x"=r and b."x"=r-1);
UPDATE TTS c SET "y"=gamma*a."y"/b."y"+(1.0-gamma)*(d."y") FROM TT a, TTT b, TTS d WHERE (c."x"=r and d."x"=r-p and a."x"=r and b."x"=r);
END LOOP;
for r in l+1..l+ll LOOP
UPDATE TTT c SET "y"=(1.0)*(b."y"+WAT) FROM TTT b WHERE (c."x"=r and b."x"=r-1);
UPDATE TTS c SET "y"=d."y" FROM TTS d WHERE (c."x"=r and d."x"=r-p);
END LOOP;
UPDATE TTT c SET "y"=c."y"*b."y" FROM TTS b WHERE (c."x"=b."x"+p);
UPDATE TTT c SET Y=round(c."y",6);
RETURN QUERY SELECT * FROM TTT;
DROP TABLE TT;
DROP TABLE TTT;
DROP TABLE TTS;
END
$func$
LANGUAGE plpgsql;