for ($i=1; $i -le 3; $i++)
{
    Add-Content -Value "//" -Path ../src/wiredbrain/web/src/WiredBrain.Web/Startup.cs

    $env:REGISTRY='wiredbrain.azurecr.io'
    $env:BUILD_NUMBER=$i

    docker-compose -f ../src/wiredbrain/docker-compose.yml build web-optimized
}