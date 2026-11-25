#!/usr/bin/env bash
# Script para iniciar el cluster de MongoDB en los tres PCs
#Solo se corre en PC1 una vez que se haya hecho el build de los contenedores en los tres PCs

#para que el script se detenga si hay un error (e), si se usa una variable no definida (u) o si un comando en un pipe falla (o)
set -euo pipefail


cd "$(dirname "$0")/../.."      # $0 es la ruta del script, sin importar desde dónde se llame

set -a                          # exporta todas las variables que se lean a continuación
source infra/pc1/.env           # PC1_IP, PC2_IP, PC3_IP, MONGO_ADMIN_PASSWORD
set +a                          # no exporta más variables

# Espera a que un replica set tenga un PRIMARY. Se pasa el nombre del contenedor y el puerto.
esperar_primario() {
  echo "  esperando PRIMARY en $1..."
  until docker exec "$1" mongosh --port "$2" --quiet --eval '!!db.hello().primary' 2>/dev/null | grep -q true; do
    sleep 2
  done
}

echo "== 1/3 rs-config"
docker exec cfg1 mongosh --port 27101 --quiet --eval "
rs.initiate({
  _id: 'rs-config', configsvr: true,
  members: [
    { _id: 0, host: '$PC1_IP:27101' },
    { _id: 1, host: '$PC2_IP:27102' },
    { _id: 2, host: '$PC3_IP:27103' }
  ]
})"
esperar_primario cfg1 27101

echo "== 2/3 rs-shard1"
docker exec shard1-a mongosh --port 27201 --quiet --eval "
rs.initiate({
  _id: 'rs-shard1',
  members: [
    { _id: 0, host: '$PC1_IP:27201' },
    { _id: 1, host: '$PC2_IP:27202' },
    { _id: 2, host: '$PC3_IP:27203' }
  ]
})"
esperar_primario shard1-a 27201

echo "== 3/3 rs-shard2"
docker exec shard2-a mongosh --port 27301 --quiet --eval "
rs.initiate({
  _id: 'rs-shard2',
  members: [
    { _id: 0, host: '$PC1_IP:27301' },
    { _id: 1, host: '$PC2_IP:27302' },
    { _id: 2, host: '$PC3_IP:27303' }
  ]
})"
esperar_primario shard2-a 27301

echo "== Usuario admin"
# El mongos tarda unos segundos en conectarse a rs-config recién elegido: se reintenta.
for intento in {1..15}; do
  if docker exec -e MONGO_ADMIN_PASSWORD mongos1 mongosh --port 27017 --quiet --eval "
    db.getSiblingDB('admin').createUser({
      user: 'admin',
      pwd: process.env.MONGO_ADMIN_PASSWORD,
      roles: [ { role: 'root', db: 'admin' } ]
    })"; then
    break
  fi
  if [ "$intento" -eq 15 ]; then echo "No se pudo crear el usuario admin"; exit 1; fi
  echo "  mongos todavía no está listo, reintentando..."
  sleep 3
done


echo "== Shards, esquema y fragmentación"
docker cp bd/mongo/01_esquema.js mongos1:/tmp/01_esquema.js
docker exec -e MONGO_ADMIN_PASSWORD mongos1 mongosh --port 27017 --quiet --eval "
db.getSiblingDB('admin').auth('admin', process.env.MONGO_ADMIN_PASSWORD);

sh.addShard('rs-shard1/$PC1_IP:27201,$PC2_IP:27202,$PC3_IP:27203');
sh.addShard('rs-shard2/$PC1_IP:27301,$PC2_IP:27302,$PC3_IP:27303');

load('/tmp/01_esquema.js');

sh.enableSharding('hospital');
sh.shardCollection('hospital.expedientes', { paciente_id: 1 }, true);
sh.shardCollection('hospital.notas_consulta', { paciente_id: 'hashed' });
sh.shardCollection('hospital.resultados_laboratorio', { paciente_id: 'hashed' });
sh.shardCollection('hospital.eventos', { paciente_id: 'hashed' });
"

echo "== Cluster listo"