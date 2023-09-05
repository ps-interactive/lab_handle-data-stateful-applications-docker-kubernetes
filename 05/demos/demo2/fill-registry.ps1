
$env:REGISTRY='wiredbrainprod.azurecr.io'

for ($i=18; $i -le 40; $i++)
{
    $env:BUILD_NUMBER=$i
    
    Add-Content -Value "//" -Path ../src/wiredbrain/web/src/WiredBrain.Web/Startup.cs
    docker-compose -f ../src/wiredbrain/docker-compose.yml build web-tagged
    
    Add-Content -Value "#" -Path ../src/wiredbrain/db/init-products-db.sh
    docker-compose -f ../src/wiredbrain/docker-compose.yml build products-db
    
    Add-Content -Value "//" -Path ../src/wiredbrain/products-api/src/main/java/com/wiredbrain/Application.java
    docker-compose -f ../src/wiredbrain/docker-compose.yml build products-api
    
    Add-Content -Value "//" -Path ../src/wiredbrain/stock-api/src/main.go
    docker-compose -f ../src/wiredbrain/docker-compose.yml build stock-api
}

docker tag wiredbrainprod.azurecr.io/wiredbrain/web:22.05-m5-1 wiredbrainprod.azurecr.io/wiredbrain/web:latest
docker tag wiredbrainprod.azurecr.io/wiredbrain/products-db:22.05-m5-1 wiredbrainprod.azurecr.io/wiredbrain/products-db:latest
docker tag wiredbrainprod.azurecr.io/wiredbrain/products-api:22.05-m5-1 wiredbrainprod.azurecr.io/wiredbrain/products-api:latest
docker tag wiredbrainprod.azurecr.io/wiredbrain/stock-api:22.05-m5-1 wiredbrainprod.azurecr.io/wiredbrain/stock-api:latest

az acr login -n wiredbrainprod

docker image push --all-tags wiredbrainprod.azurecr.io/wiredbrain/web
docker image push --all-tags wiredbrainprod.azurecr.io/wiredbrain/products-db
docker image push --all-tags wiredbrainprod.azurecr.io/wiredbrain/products-api
docker image push --all-tags wiredbrainprod.azurecr.io/wiredbrain/stock-api