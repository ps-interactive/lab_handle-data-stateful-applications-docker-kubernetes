for ($i=1; $i -le 3; $i++)
{
    Add-Content -Value "//" -Path ../src/wiredbrain/web/src/WiredBrain.Web/Startup.cs

    docker-compose -f ../src/wiredbrain/docker-compose.yml build web-slow
}