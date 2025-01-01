# Ambulance Tracker System

A comprehensive emergency response system featuring real-time ambulance tracking, built with a microservices architecture, web dashboard, and mobile application. The system optimizes emergency response times and improves coordination between ambulances, hospitals, and dispatch centers.

## System Overview

### Architecture Diagram
```
┌─────────────────┐     ┌─────────────────┐     ┌─────────────────┐
│   Web Frontend  │     │  Mobile App     │     │  Hospital UI    │
│    (Angular)    │     │   (Flutter)     │     │   (Angular)     │
└────────┬────────┘     └────────┬────────┘     └────────┬────────┘
         │                       │                        │
         └───────────┬──────────┴────────────┬──────────┘
                     │                       │
            ┌────────┴────────┐     ┌───────┴────────┐
            │   API Gateway   │     │ WebSocket Server│
            └────────┬────────┘     └───────┬────────┘
                     │                      │
         ┌──────────┴──────────────────────┴──────────┐
         │              Service Discovery             │
         │              (Eureka Server)              │
         └──────────┬──────────────┬───────┬────────┘
                    │              │       │
         ┌──────────┴───┐  ┌──────┴───┐   └───────────┐
         │  Ambulance   │  │ Hospital │   │ Dispatch  │
         │   Service    │  │ Service  │   │ Service   │
         └──────────────┘  └──────────┘   └───────────┘
```

## Project Components

### 1. Backend Services (`Ambulance-tracker/`)

#### Core Services
1. **Ambulance Service** (`Ambulance_Service/`)
   - Real-time ambulance tracking
   - Location updates via WebSocket
   - Status management (Available, On Mission, Out of Service)
   - Route management and navigation

2. **Dispatch Coordination Service** (`dispatch-coordination-service/`)
   - Emergency case management
   - Ambulance assignment algorithms
   - Real-time dispatch coordination
   - Priority queue management

3. **Hospital Management Service** (`hospital-management-service/`)
   - Hospital resource tracking
   - Bed availability management
   - Emergency department status
   - Patient admission coordination

4. **Route Optimization Service** (`route-optimization-service/`)
   - Real-time route calculation
   - Traffic-aware path finding
   - ETA calculations
   - Multi-stop route optimization

#### Infrastructure Services
1. **API Gateway** (`api-gateway/`)
   - Request routing
   - Load balancing
   - Authentication/Authorization
   - Rate limiting
   - Request/Response transformation

2. **Service Discovery** (`eureka-server/`)
   - Service registration
   - Health monitoring
   - Load balancing support
   - Fault tolerance

#### Technical Stack
- Java 17
- Spring Boot 3.1.4
- Spring Cloud
- Spring WebSocket
- Spring Data JPA
- MySQL Database
- Docker & Docker Compose
- Maven

### 2. Web Dashboard (`Ambilance Tracker Frontend/`)

#### Core Features
1. **Real-time Tracking Dashboard**
   - Live ambulance location tracking
   - Interactive Mapbox integration
   - Real-time status updates
   - Custom map markers and overlays

2. **Case Management**
   - Emergency case creation
   - Ambulance assignment
   - Status tracking
   - Historical case data

3. **Hospital Interface**
   - Resource availability management
   - Patient admission tracking
   - Emergency department status
   - Bed management

#### Technical Stack
- Angular 17
- TypeScript 5.2
- RxJS 7.8
- Angular Material
- Mapbox GL JS
- SCSS
- WebSocket (STOMP)

### 3. Mobile Application (`mapbox_flutter_app/`)

#### Core Features
1. **Driver Interface**
   - Turn-by-turn navigation
   - Real-time location tracking
   - Status updates
   - Emergency notifications

2. **Case Management**
   - Case details view
   - Status updates
   - Patient information
   - Hospital navigation

3. **Offline Capabilities**
   - Offline map data
   - Case data caching
   - Background location updates
   - Automatic sync

#### Technical Stack
- Flutter 3.5
- Dart 3.0
- Mapbox Flutter SDK
- Provider State Management
- WebSocket
- SQLite for local storage

## Setup and Installation

### Prerequisites
- JDK 17
- Node.js 18+
- Flutter SDK 3.5+
- Docker & Docker Compose
- MySQL 8.0
- Maven 3.8+

### Backend Setup

1. **Database Setup**
```bash
# Create MySQL database
mysql -u root -p
CREATE DATABASE ambulance_tracker;
```

2. **Start Microservices**
```bash
cd Ambulance-tracker
docker-compose up
```

Services will be available at:
- Eureka Server: http://localhost:8761
- API Gateway: http://localhost:8080
- Ambulance Service: http://localhost:8081
- Hospital Service: http://localhost:8082
- Dispatch Service: http://localhost:8083

### Web Dashboard Setup

```bash
cd "Ambilance Tracker Frontend"
npm install
ng serve
```
Access at http://localhost:4200

### Mobile App Setup

```bash
cd mapbox_flutter_app
flutter pub get
flutter run
```

## Development Guidelines

### Backend Development
1. **Service Creation**
   - Follow microservice patterns
   - Implement circuit breakers
   - Use event-driven architecture
   - Implement proper error handling

2. **API Design**
   - Follow REST principles
   - Use proper HTTP methods
   - Implement versioning
   - Document with OpenAPI

### Frontend Development
1. **Component Structure**
   - Feature-based organization
   - Shared components
   - Lazy loading
   - State management

2. **Style Guide**
   - Follow Angular style guide
   - Use SCSS variables
   - Implement responsive design
   - Follow accessibility guidelines

### Mobile Development
1. **Architecture**
   - Clean architecture
   - Repository pattern
   - Dependency injection
   - Bloc pattern for state

2. **Performance**
   - Optimize battery usage
   - Implement caching
   - Handle offline mode
   - Optimize map rendering

## API Documentation

### REST Endpoints

#### Ambulance Service
```
GET    /api/v1/ambulances
POST   /api/v1/ambulances
GET    /api/v1/ambulances/{id}
PUT    /api/v1/ambulances/{id}/location
PATCH  /api/v1/ambulances/{id}/status
```

#### Hospital Service
```
GET    /api/v1/hospitals
POST   /api/v1/hospitals
GET    /api/v1/hospitals/{id}
PATCH  /api/v1/hospitals/{id}/capacity
```

#### Case Management
```
GET    /api/v1/cases
POST   /api/v1/cases
GET    /api/v1/cases/{id}
PATCH  /api/v1/cases/{id}/status
```

### WebSocket Topics
```
/topic/ambulances                 # All ambulances updates
/topic/ambulance/{id}            # Single ambulance updates
/topic/cases                     # Emergency case updates
/topic/hospitals/{id}/status     # Hospital status updates
```

## Deployment

### Production Setup
1. Configure environment variables
2. Set up SSL certificates
3. Configure database replication
4. Set up monitoring
5. Configure backup system

### Monitoring
- Prometheus for metrics
- Grafana for visualization
- ELK stack for logs
- Uptime monitoring

## Security

### Authentication
- JWT-based authentication
- Role-based access control
- OAuth2 integration
- Secure password storage

### Data Protection
- End-to-end encryption
- HTTPS everywhere
- Data anonymization
- Regular security audits

## Contributing

1. Fork the repository
2. Create feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit changes (`git commit -m 'Add AmazingFeature'`)
4. Push to branch (`git push origin feature/AmazingFeature`)
5. Open Pull Request

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Contact

Project Link: [https://github.com/yourusername/ambulance-tracker](https://github.com/yourusername/ambulance-tracker)

## Acknowledgments

- Mapbox for mapping services
- Spring Framework team
- Angular team
- Flutter team
