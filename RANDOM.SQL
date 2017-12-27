CREATE OR REPLACE FUNCTION random2DimDots(k integer, h integer)
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
        ly:=(random()-0.5);
        X:=ox+lx*(lx*lx+ly*ly)/sqrt(h); 
        Y:=oy+ly*(lx*lx+ly*ly)/sqrt(h);
        RETURN NEXT;     
	END LOOP;
END LOOP;
END
$func$
LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION randomTimeSeries(k integer, o numeric, l numeric)
	RETURNS table(X integer, Y numeric) AS
$func$
DECLARE d numeric;
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