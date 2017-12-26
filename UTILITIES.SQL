CREATE OR REPLACE FUNCTION dots2DimShow(_tbl varchar)
  RETURNS table(id int, X numeric, Y numeric) AS
$func$
BEGIN
RETURN QUERY EXECUTE 'SELECT * FROM ' || _tbl;
END
$func$  
LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION timeSeriesShow(_tbl varchar)
  RETURNS table(X integer, Y numeric) AS
$func$
BEGIN
RETURN QUERY EXECUTE 'SELECT * FROM ' || _tbl;
END
$func$  
LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION dots2DimClusteredShow(_tbl varchar)
  RETURNS table(id integer, X numeric, Y numeric, C integer) AS
$func$
BEGIN
RETURN QUERY EXECUTE 'SELECT * FROM ' || _tbl;
END
$func$  
LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION initClusters(_tbl varchar)
	RETURNS table(id int, X numeric, Y numeric, C int) AS
$func$
BEGIN
	RETURN QUERY EXECUTE 'SELECT s."id", s."x", s."y", s."id" as "c" FROM shw('''||_tbl||''') s';
END
$func$
LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION maxi(a numeric, b numeric)
	RETURNS NUMERIC AS
$func$
BEGIN 
	IF a>b THEN RETURN a; ELSE RETURN b; END IF;
END
$func$
LANGUAGE plpgsql;