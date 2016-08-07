sed -i '/^declare/d' data/bgt_*.sql
sed -i '/^set/d' data/bgt_*.sql
node --max-old-space-size=8192 monetdb_service.js
