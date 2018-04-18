CREATE OR REPLACE FUNCTION anfun.Sillhuette(_data varchar, p numeric default 2.0)
RETURNS numeric as
$func$

	DECLARE 
		S numeric;
	BEGIN
		CREATE TEMPORARY TABLE anfun.TT (id integer, x numeric, y numeric, c integer);
		INSERT INTO anfun.TT SELECT * FROM anfun.dots2DimClusteredShow(_data);
		SELECT AVG("d")INTO S FROM (
		SELECT "c",AVG("d") as d FROM (
		SELECT a."id",a."c",(b."d"-a."d")/MAXI(b."d",a."d") as d FROM (
		SELECT a."id",a."c",AVG(anfun.dist(a."x",a."y",b."x",b."y",p)) as d
		FROM anfun.TT a JOIN anfun.TT b on (a."c"=b."c") GROUP BY a."id",a."c") a JOIN (
		SELECT a."id",a."c",AVG(anfun.dist(a."x",a."y",b."x",b."y",p)) as d
		FROM anfun.TT a JOIN anfun.TT b on (a."c"!=b."c") GROUP BY a."id",a."c") b on (a."id"=b."id") 
        )x GROUP BY "c") x;
		DROP TABLE anfun.TT;
		RETURN S;
	END

$func$
LANGUAGE plpgsql;
