# Kafka Data Pipeline Application

A production-grade Kafka-based data processing system built for real-time IoT data ingestion, storage, and visualization. This application demonstrates enterprise-level DevOps practices including containerization, event-driven architecture, and cloud-native development.

## 📋 Table of Contents

- [Architecture Overview](#architecture-overview)
- [Use Case Scenarios](#use-case-scenarios)
- [Technology Stack](#technology-stack)
- [Prerequisites](#prerequisites)
- [Application Components](#application-components)
- [Building and Deploying](#building-and-deploying)
- [Configuration](#configuration)

## Architecture Overview

The application implements a complete event-driven architecture:

```
IoT Devices/Sensors → Kafka Producer → Kafka Cluster → Kafka Consumer → PostgreSQL → REST API → Dashboard
```

## Use Case Scenarios

**What are Use Case Scenarios?** These are realistic, industry-specific examples that demonstrate how this Kafka data pipeline application would be deployed in real-world DevOps environments. Each scenario presents a different company context, technical challenges, and business requirements that showcase the versatility and production-readiness of the application architecture. These scenarios help illustrate the practical value and scalability of the system across various domains including healthcare, manufacturing, and environmental monitoring.

### Scenario 1: Medical Device IoT Platform
**Context:** You are a DevOps Engineer at MedTech Solutions, a company that manufactures connected medical devices deployed across 200+ hospitals nationwide.

**Project Background:** The engineering team developed IoT-enabled patient monitoring devices that continuously stream vital signs data (heart rate, blood pressure, oxygen levels) to a cloud backend. Your infrastructure must handle:
- **High-frequency data streams** from 10,000+ devices generating events every 5-10 seconds
- **Regulatory compliance** (HIPAA) requiring encrypted data transmission and audit trails
- **Real-time alerting** for critical health events with sub-second latency
- **Historical analytics** for patient trend analysis and clinical research

**Your Role:** You designed and implemented a scalable Kafka-based data pipeline that ingests device telemetry, processes it through consumer applications, stores it in PostgreSQL, and exposes real-time dashboards for hospital staff. You containerized all application components, created CI/CD pipelines for automated deployments, and implemented secure secrets management for database credentials.

**Technical Challenges Solved:**
- Containerized Python applications with proper health checks and resource limits
- Implemented graceful shutdown handling for Kafka consumers to prevent data loss
- Configured connection pooling and retry logic for database resilience
- Built responsive web dashboards with auto-refresh capabilities

**Business Impact:** Reduced data processing latency by 60%, improved system availability to 99.95%, and enabled real-time clinical decision support for healthcare providers.

---

### Scenario 2: Smart Manufacturing Platform
**Context:** You are a DevOps Engineer at IndustrialEdge, a company providing predictive maintenance solutions for manufacturing plants.

**Project Background:** The company's platform monitors industrial equipment sensors across multiple factory floors, collecting data on temperature, vibration, pressure, and operational metrics. The system must:
- **Handle bursty traffic** during peak production hours (50K+ events/second)
- **Support multi-tenancy** with data isolation between different manufacturing clients
- **Provide near-real-time anomaly detection** to prevent equipment failures
- **Enable historical trend analysis** for maintenance planning

**Your Role:** You developed and containerized a three-tier application stack consisting of Kafka producers for sensor data ingestion, consumer services with REST APIs for data access, and visualization dashboards for operations teams. You implemented proper error handling, logging, and metrics exposure to ensure observability in production environments.

**Technical Challenges Solved:**
- Designed Kafka topic partitioning strategy using sensor IDs as keys for parallel processing
- Implemented database schema with proper indexing for time-series queries
- Built RESTful API with pagination and filtering capabilities
- Created real-time charts using Chart.js with automatic data refresh

**Business Impact:** Achieved 99.9% uptime, reduced infrastructure costs by 35% through efficient resource utilization, and enabled predictive maintenance that prevented $2M in potential equipment downtime.

---

### Scenario 3: Environmental Monitoring Network
**Context:** You are a DevOps Engineer at EcoMetrics, an environmental monitoring company operating 5,000+ weather and air quality sensors across multiple continents.

**Project Background:** Your sensors collect atmospheric data (temperature, humidity, CO2 levels, particulate matter) from remote locations and transmit readings every 5 minutes. The platform requirements include:
- **Handling intermittent connectivity** from remote sensor locations
- **Time-series data storage** with configurable retention policies
- **Public API access** for government agencies and research institutions
- **Interactive dashboards** for real-time environmental monitoring

**Your Role:** You built containerized microservices using Python and Flask, integrating Kafka for reliable message delivery and PostgreSQL for persistent storage. You created Dockerfiles optimized for production use, implemented comprehensive health check endpoints, and designed a responsive web interface for data visualization.

**Technical Challenges Solved:**
- Implemented Kafka consumer with automatic offset management and error recovery
- Designed database schema supporting efficient aggregation queries for statistics
- Built Flask REST API with CORS support and proper error responses
- Created multi-chart dashboard with various visualization types (bar, line, doughnut)

**Business Impact:** Scaled from 1,000 to 5,000 sensors without application redesign, reduced operational overhead by 50% through automation, and provided researchers with 99.99% data availability.

## Technology Stack

**Application:**
- **Python 3.11**: Producer and Consumer services
- **Apache Kafka**: Event streaming
- **Flask**: REST API and web dashboard
- **PostgreSQL**: Relational data storage
- **Chart.js**: Data visualization

**Dependencies:**
- `kafka-python==2.0.2` - Kafka client library
- `flask==2.3.3` - Web framework
- `psycopg2-binary==2.9.9` - PostgreSQL adapter
- `requests==2.31.0` - HTTP client

## Prerequisites

### Infrastructure Requirements
- **Apache Kafka cluster** - Running and accessible
- **PostgreSQL database** - Version 12+
- **Container registry** - For storing Docker images (ECR, Docker Hub, etc.)
- **Kubernetes cluster** - For deployment (optional but recommended)

### Local Development
- **Python 3.11+**
- **Docker** for building container images
- **Git** for version control

## Application Components

### 1. Kafka Producer (`producer.py`)
Simulates IoT sensor data generation:
- Generates temperature, humidity readings every 5 seconds
- Publishes to `sensor-data` Kafka topic
- Supports multiple sensor IDs and locations
- Key-based partitioning for scalability

**Configuration via environment variables:**
- `KAFKA_BOOTSTRAP_SERVERS` - Kafka broker addresses (default: internal service)
- `TOPIC_NAME` - Target topic name (default: `sensor-data`)

### 2. Consumer API (`consumer_api.py`)
Consumes Kafka events and provides REST API:
- **Background Kafka consumer** thread for event processing
- **Database integration** with PostgreSQL connection pooling
- **REST endpoints**:
  - `GET /health` - Health check
  - `GET /data/latest?limit=N` - Retrieve recent events
  - `GET /data/stats` - Aggregated statistics
- **Automatic schema management** with table creation

**Configuration via environment variables:**
- `DB_HOST` - Database hostname
- `DB_PORT` - Database port (default: 5432)
- `DB_NAME` - Database name
- `DB_USER` - Database username
- `DB_PASSWORD` - Database password
- `KAFKA_BOOTSTRAP_SERVERS` - Kafka broker addresses

### 3. Dashboard (`dashboard.py`)
Web-based visualization interface:
- Real-time data refresh every 5 seconds
- Interactive charts using Chart.js:
  - Temperature and humidity by sensor (bar charts)
  - Temperature trend timeline (line chart)
  - Event distribution (doughnut chart)
- Statistics cards showing total events, averages, active sensors
- Responsive table of latest readings

**Configuration via environment variables:**
- `API_BASE_URL` - Consumer API service URL

## Building and Deploying

### Build Docker Images

```bash
# Build producer image
docker build -t kafka-producer:latest -f Dockerfile.producer .

# Build consumer API image
docker build -t kafka-consumer-api:latest -f Dockerfile.consumer .

# Build dashboard image
docker build -t kafka-dashboard:latest -f Dockerfile.dashboard .
```

### Push to Container Registry

**For AWS ECR:**
```bash
# Login to ECR
aws ecr get-login-password --region <REGION> | docker login --username AWS --password-stdin <ACCOUNT_ID>.dkr.ecr.<REGION>.amazonaws.com

# Tag images
docker tag kafka-producer:latest <ACCOUNT_ID>.dkr.ecr.<REGION>.amazonaws.com/kafka-producer:latest
docker tag kafka-consumer-api:latest <ACCOUNT_ID>.dkr.ecr.<REGION>.amazonaws.com/kafka-consumer-api:latest
docker tag kafka-dashboard:latest <ACCOUNT_ID>.dkr.ecr.<REGION>.amazonaws.com/kafka-dashboard:latest

# Push images
docker push <ACCOUNT_ID>.dkr.ecr.<REGION>.amazonaws.com/kafka-producer:latest
docker push <ACCOUNT_ID>.dkr.ecr.<REGION>.amazonaws.com/kafka-consumer-api:latest
docker push <ACCOUNT_ID>.dkr.ecr.<REGION>.amazonaws.com/kafka-dashboard:latest
```

**For Docker Hub:**
```bash
# Login to Docker Hub
docker login

# Tag images
docker tag kafka-producer:latest <USERNAME>/kafka-producer:latest
docker tag kafka-consumer-api:latest <USERNAME>/kafka-consumer-api:latest
docker tag kafka-dashboard:latest <USERNAME>/kafka-dashboard:latest

# Push images
docker push <USERNAME>/kafka-producer:latest
docker push <USERNAME>/kafka-consumer-api:latest
docker push <USERNAME>/kafka-dashboard:latest
```

## Configuration

### Local Testing

**Run Producer:**
```bash
export KAFKA_BOOTSTRAP_SERVERS=localhost:9092
export TOPIC_NAME=sensor-data
python producer.py
```

**Run Consumer API:**
```bash
export DB_HOST=localhost
export DB_PORT=5432
export DB_NAME=postgres
export DB_USER=postgres
export DB_PASSWORD=yourpassword
python consumer_api.py
```

**Run Dashboard:**
```bash
export API_BASE_URL=http://localhost:8080
python dashboard.py
```

Access dashboard at `http://localhost:3000`

## 📊 API Reference

### Consumer API Endpoints

**Health Check**
```
GET /health
Response: {"status": "healthy", "timestamp": "2025-01-15T10:30:00"}
```

**Get Latest Events**
```
GET /data/latest?limit=50
Response: {
  "status": "success",
  "count": 50,
  "data": [...]
}
```

**Get Statistics**
```
GET /data/stats
Response: {
  "status": "success",
  "data": {
    "overall": {...},
    "by_sensor": [...],
    "hourly": [...]
  }
}
```

## 🔍 Monitoring

### Application Health Checks

All services expose `/health` endpoints for readiness and liveness probes:

- Producer: Logs to stdout
- Consumer API: `http://localhost:8080/health`
- Dashboard: `http://localhost:3000/health`

### Logs

View application logs for troubleshooting:
```bash
# Producer logs
kubectl logs -f deployment/kafka-producer -n kafka

# Consumer API logs
kubectl logs -f deployment/kafka-consumer-api -n kafka

# Dashboard logs
kubectl logs -f deployment/kafka-dashboard -n kafka
```

---

**Note:** This application is designed for educational purposes to demonstrate DevOps engineering skills. Deployment configuration and infrastructure provisioning are handled separately through IaC and GitOps workflows.