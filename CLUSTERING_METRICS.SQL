CREATE OR REPLACE FUNCTION Sillhuette(_data varchar, p numeric default 2.0) -- на вход подается таблица полученная в результате кластеризации
returns numeric as -- выход - число, значение метрики силуэт
$func$
DECLARE S numeric;
BEGIN
CREATE TEMPORARY TABLE TT (id integer, x numeric, y numeric, c integer);
INSERT INTO TT SELECT * FROM dots2DimClusteredShow(_data);
SELECT AVG("d")INTO S FROM (
SELECT "c",AVG("d") as d FROM (
SELECT a."id",a."c",(b."d"-a."d")/MAXI(b."d",a."d") as dist FROM (
SELECT a."id",a."c",AVG(dist(a."x",a."y",b."x",b."y",p)) as d
FROM TT a JOIN TT b on (a."c"=b."c") GROUP BY a."id",a."c") a JOIN (
SELECT a."id",a."c",AVG(dist(a."x",a."y",b."x",b."y",p)) as d
FROM TT a JOIN TT b on (a."c"!=b."c") GROUP BY a."id",a."c") b on (a."id"=b."id") )x GROUP BY "c") x;
DROP TABLE TT;
RETURN S;
END
$func$
LANGUAGE plpgsql;
