Intructions to get it compiled with MonetDB
===========================================

1. Partial checkout
```
cd <path_to_monetdb_sources/geom>
git clone https://github.com/NLeSC/3D_geospatial_risk_management.git gspatial
cd gspatial/
git config core.sparseCheckout true
echo "apps/gpu/pnpoly/*" > .git/info/sparse-checkout
```
