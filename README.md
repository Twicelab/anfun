PostegreSQL have no included analytical functions. Therefore we present you...

# PostgreSQL Analytical Package
*Well it is not... like... ready yet. But soon, very soon ;)*

## Including
* Random Datasets Generators
  * __Time Series__ - with seasonal variance
  * __Dots Clusters__ - circles and blobs right now
* Clustering Functions
  * __DBSCAN__ - cool and comfy
  * __K-MEANS__ - some easy algorithm, is to be enchanced
* Clustering Evaluation Metrics
  * __Sillhuette__ - clusters to numbers
* Forecasting Functions
  * __Exponential__ - with or without trend
  * __Holt-n-Winters__ - some cool forecasting for seasonal time series
* Forecasting Evaluation Metrics
  * __MAE__,__RMSE__,__MPE__,__MAPE__,__AD__,__MAD__,__R2__,__Theil Coefficient__ - for all your needs

## Instalation

In order to use Functions from AnFun you have to download file __anfun_install.sql__ and run it in Data Base Managment System PostegreSQL. After that you can reach desired functions using namespace (schema, in fact) __anfun__.
Example: _SELECT * FROM anfun.DBSCAN('anfun.random2DimDotsCircles(50,2,1)',3,0.5)_
