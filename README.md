## Steps to install in the platform

Build the images:
```
docker build -t harbor.eucaim-node.i3m.upv.es/library/etl/postgres-etl:15-3 images/postgresql
docker build -t harbor.eucaim-node.i3m.upv.es/library/etl/tdc-app:1.0-slim images/TDC
docker build -t harbor.eucaim-node.i3m.upv.es/library/etl/desktop:1.1 images/desktop
```

Upload the images:
```
docker push harbor.eucaim-node.i3m.upv.es/library/etl/postgres-etl:15-3
docker push harbor.eucaim-node.i3m.upv.es/library/etl/tdc-app:1.0-slim
docker push harbor.eucaim-node.i3m.upv.es/library/etl/desktop:1.1
```

Package the chart:
```
helm package chart
```
and upload to the apps catalogue.

Finally copy the "shared-files" to "persistent-shared-folder/apps/ETL" in the platform, 
to make them available to any user who deploy this app.

