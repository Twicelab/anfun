-- DO KMeans ON RandomBlobs AND WRITE INTO kmc
SELECT * INTO KMC FROM anfun.KMEANS('anfun.random2DimDotsBlobs(100,5,0.6)',5);
-- GET Sillhuette SCORE OF kmc CLUSTERISATION-TABLE
SELECT anfun.Sillhuette('KMC');
-- DO DBScan ON RandomCircles
SELECT * FROM anfun.DBSCAN('anfun.random2DimDotsCircles(50,2,1)',3,0.5);
-- WRITE RandomTimeSeries INTO ts
SELECT * INTO TS FROM anfun.randomTimeSeries(1000,10,10);
-- DO HoltWinters ON ts AND WRITE INTO hwf
SELECT * INTO HWF FROM anfun.holtWintersForecast('TS',0.1,0.1,0.1,100,800,200);
-- GET R2 SCORE OF ts-hwf APPROXIMATION
SELECT R2('TS','HWF');

DROP TABLE KMC;
DROP TABLE TS;
DROP TABLE HWF;