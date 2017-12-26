CREATE OR REPLACE FUNCTION R2(_tbl1 varchar, _tbl2 varchar)
returns numeric as
$func$
DECLARE S numeric;
BEGIN
CREATE TEMPORARY TABLE TT1 (x integer, y numeric);
INSERT INTO TT1 SELECT * FROM timeSeriesShow(_tbl1);
CREATE TEMPORARY TABLE TT2 (x integer, y numeric);
INSERT INTO TT2 SELECT * FROM timeSeriesShow(_tbl2);
SELECT 1-"dt"/"dr" INTO S FROM
(select SUM((a."y"-b."y")*(a."y"-b."y")) dt FROM TT2 a join TT1 b on (a."x"=b."x")) a,
(select SUM((a."y"-b."y")*(a."y"-b."y")) dr FROM (select AVG("y") as y FROM TT1) a, TT1 b) b;
DROP TABLE TT1;
DROP TABLE TT2;
RETURN S;
END
$func$
LANGUAGE plpgsql;