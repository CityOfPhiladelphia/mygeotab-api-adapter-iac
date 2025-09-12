TIME_SINCE_LAST_UPDATE=$(psql -h $RDS_HOST -d $RDS_DB -U $RDS_USER -c 'SELECT ROUND(GREATEST(0, EXTRACT(EPOCH FROM (now() - max("DateTime"))))) FROM "LogRecords2";' -t --csv)
# 5 minutes
if [ $TIME_SINCE_LAST_UPDATE -gt 300 ]; then
  echo "Restarting due to long time since last update..." | tee -a /var/log/auto_restart_geotab.log
  systemctl restart mygeotabadapter
fi
