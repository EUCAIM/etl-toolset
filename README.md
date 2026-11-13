## Keeping this branch in sync with Local_Node

Everything this branch shares with the docker-compose distribution (SQL, flows,
Groovy scripts, init.sh, logback.xml, TDC) is developed in Local_Node and in
[etl-mappings](https://github.com/EUCAIM/etl-mappings), and copied here with:
```
git fetch origin && git -C ../etl-mappings fetch
scripts/sync_from_local_node.sh
```
Do not edit those files in this branch: change them in Local_Node and synchronise
again. `shared-files/SOURCE` records the commits they come from. Only `chart/` and
the Dockerfiles of `images/nifi`, `images/postgresql` and `images/desktop` belong
to this branch. After a synchronisation that changes the SQL or TDC, raise the tag
of the image affected, here and in `chart/values.yaml`.

## Steps to install in the platform

Build the images:
```
docker build -t harbor.eucaim-node.i3m.upv.es/library/etl/nifi-etl:2.3.0-1 images/nifi
docker build -t harbor.eucaim-node.i3m.upv.es/library/etl/postgres-etl:15-4 images/postgresql
docker build -t harbor.eucaim-node.i3m.upv.es/library/etl/tdc-app:1.1-slim images/TDC
docker build -t harbor.eucaim-node.i3m.upv.es/library/etl/desktop:1.5 images/desktop
```

Upload the images:
```
docker push harbor.eucaim-node.i3m.upv.es/library/etl/nifi-etl:2.3.0-1
docker push harbor.eucaim-node.i3m.upv.es/library/etl/postgres-etl:15-4
docker push harbor.eucaim-node.i3m.upv.es/library/etl/tdc-app:1.1-slim
docker push harbor.eucaim-node.i3m.upv.es/library/etl/desktop:1.5
```

Package the chart:
```
helm package chart
```
and upload to the apps catalogue.

Finally copy the "shared-files" to "persistent-shared-folder/apps/ETL" in the platform, 
to make them available to any user who deploy this app.

