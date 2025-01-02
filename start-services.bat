@echo off
echo Starting API Gateway...
docker-compose up -d api-gateway
timeout /t 10 /nobreak > nul

echo Starting Route Optimization Service...
docker-compose up -d route-service
timeout /t 10 /nobreak > nul

echo Starting Hospital Management Service...
docker-compose up -d hospital-service
timeout /t 10 /nobreak > nul

echo Starting Ambulance Service...
docker-compose up -d ambulance-service
timeout /t 10 /nobreak > nul

echo Starting Dispatch Service...
docker-compose up -d dispatch-service
timeout /t 10 /nobreak > nul

echo Starting Eureka Server...
docker-compose up -d eureka-server

echo All services have been started!

echo Showing logs from all services...
docker-compose logs -f
