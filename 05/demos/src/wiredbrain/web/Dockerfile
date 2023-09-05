FROM mcr.microsoft.com/dotnet/sdk:6.0-alpine AS builder

WORKDIR /src
COPY src/WiredBrain.Web/WiredBrain.Web.csproj .
RUN dotnet restore

COPY src/WiredBrain.Web/ .
RUN dotnet publish --no-restore -c Release -o /out WiredBrain.Web.csproj

# app image
FROM mcr.microsoft.com/dotnet/aspnet:6.0-alpine

ENV ProductsApi:Url="http://products-api/products" \
    StockApi:Url="http://stock-api/stock" 

ENTRYPOINT ["dotnet", "/app/WiredBrain.Web.dll"]

WORKDIR /app
COPY --from=builder /out/ .