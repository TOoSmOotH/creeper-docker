#!/bin/sh

cp /etc/creeper/mining.conf $CREEP_MINER_DATADIR/mining.conf

echo "Replacing some stuff"
echo $MADDRESS
echo $PORT

sed -i -e "s/MININGPOOLADDRESS/$MADDRESS/g" $CREEP_MINER_DATADIR/mining.conf
sed -i -e "s/MPORT/$PORT/g" $CREEP_MINER_DATADIR/mining.conf
cat $CREEP_MINER_DATADIR/mining.conf

./creepMiner $CREEP_MINER_DATADIR/mining.conf
