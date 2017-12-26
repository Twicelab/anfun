CREATE OR REPLACE FUNCTION Sillhuette(_tbl varchar)
returns numeric as
$func$
DECLARE S numeric;
BEGIN
CREATE TEMPORARY TABLE TT (id integer, x numeric, y numeric, c integer);
INSERT INTO TT SELECT * FROM dots2DimClusteredShow(_tbl);
SELECT AVG("dist")INTO S FROM (
SELECT "c",AVG("dist") as dist FROM (
SELECT a."id",a."c",(b."dist"-a."dist")/MAXI(b."dist",a."dist") as dist FROM (
SELECT a."id",a."c",AVG(sqrt((a."x"-b."x")*(a."x"-b."x")+(a."y"-b."y")*(a."y"-b."y"))) as dist
FROM TT a JOIN TT b on (a."c"=b."c") GROUP BY a."id",a."c") a JOIN (
SELECT a."id",a."c",AVG(sqrt((a."x"-b."x")*(a."x"-b."x")+(a."y"-b."y")*(a."y"-b."y"))) as dist
FROM TT a JOIN TT b on (a."c"!=b."c") GROUP BY a."id",a."c") b on (a."id"=b."id") )x GROUP BY "c") x;
DROP TABLE TT;
RETURN S;
END
$func$
LANGUAGE plpgsql;