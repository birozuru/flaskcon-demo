# Flask Observability Demo

A comprehensive demonstration of observability patterns for Flask applications using open-source tools. This project showcases monitoring, metrics, logging, and alerting in a simple production-ready setup.

## Architecture

This demo includes a complete observability stack:

- **Flask Application**: Demo web service with custom metrics and logging
- **Prometheus**: Metrics collection and storage
- **Grafana**: Visualization dashboards and alerting
- **Loki**: Log aggregation and storage
- **AlertManager**: Alert routing and notification management
- **Grafana Alloy**: Unified observability data pipeline

## Quick Start

### Prerequisites

- Docker and Docker Compose
- Make (optional, for convenience commands)

### Start the Stack

```bash
# Start all services
make start

# Or manually with docker-compose
docker compose up -d
```

### Access Services

| Service | URL | Credentials |
|---------|-----|-------------|
| Flask App | http://localhost:5002 | N/A |
| Prometheus | http://localhost:9090 | N/A |
| Grafana | http://localhost:3000 | admin/admin |
| AlertManager | http://localhost:9093 | N/A |
| Loki | http://localhost:3100 | N/A |
| Grafana Alloy | http://localhost:12345 | N/A |

## 📊 Demo Scenarios

The Makefile includes various commands to demonstrate different observability scenarios:

### Traffic Generation
```bash
make test-traffic    # Generate normal API traffic
make test-orders     # Create sample orders with metrics
make test-load       # Heavy load testing
```

### Error Scenarios
```bash
make test-errors     # Trigger high error rates (fires alerts)
make test-slow       # Hit slow endpoints (latency spike)
```

### Monitoring
```bash
make health         # Check all service health
make metrics        # View application metrics
make alerts         # Check active alerts
make targets        # View Prometheus scrape targets
```

### Management
```bash
make status         # Show service status
make logs           # Tail all logs
make stop           # Stop all services
make clean          # Clean up all data
```

## Application Endpoints

The Flask demo application provides several endpoints for testing:

| Endpoint | Method | Purpose |
|----------|--------|---------|
| `/` | GET | Home page with app info |
| `/health` | GET | Health check endpoint |
| `/metrics` | GET | Prometheus metrics endpoint |
| `/api/users/<id>` | GET | User lookup with variable latency |
| `/api/orders` | POST | Order creation with success/failure rates |
| `/api/slow` | GET | Intentionally slow endpoint (1-3s) |
| `/api/error` | GET | Random error responses for testing |
| `/api/metrics-demo` | GET | Generate sample metrics |

## Custom Metrics

The application exposes several custom Prometheus metrics:

- `orders_total{status}` - Counter of total orders by status
- `order_value_dollars` - Histogram of order values
- `active_users` - Gauge of currently active users
- `database_query_duration_seconds{query_type}` - Histogram of DB query times
- Standard Flask metrics (requests, duration, etc.)

## Alerting Rules

Pre-configured alerts include:

### Application Alerts
- **HighErrorRate**: >5% error rate for 2+ minutes
- **HighLatency**: 95th percentile >1s for 3+ minutes
- **LowOrderSuccessRate**: <80% order success for 5+ minutes
- **ApplicationDown**: Service unreachable for 1+ minute
- **HighRequestRate**: >100 req/s for 2+ minutes
- **LowActiveUsers**: <5 active users for 5+ minutes

### Infrastructure Alerts
- **HighCPUUsage**: >80% CPU for 5+ minutes
- **HighMemoryUsage**: >85% memory for 5+ minutes
- **DiskSpaceLow**: <20% disk space for 5+ minutes

## Docker Configuration

The stack uses Docker Compose with:

- **Networks**: Isolated `observability` network
- **Volumes**: Persistent storage for metrics, logs, and dashboards
- **Health Checks**: Built-in service health monitoring
- **Logging**: Structured JSON logging with rotation

## Project Structure

```
├── app.py                    # Flask demo application
├── requirements.txt          # Python dependencies
├── Dockerfile               # Flask app container image
├── compose.yml              # Docker Compose configuration
├── Makefile                 # Convenience commands
├── prometheus/
│   ├── prometheus.yml       # Prometheus configuration
│   └── alerts.yml          # Alerting rules
├── grafana/
│   ├── provisioning/       # Datasources and dashboard config
│   └── dashboards/         # Pre-built dashboards
├── loki/
│   └── loki-config.yml     # Loki configuration
├── alertmanager/
│   └── alertmanager.yml    # Alert routing configuration
└── grafana-alloy/
    └── config.alloy        # Alloy pipeline configuration
```

## Configuration

### Environment Variables

- `FLASK_ENV=development` - Flask environment mode
- `GF_SECURITY_ADMIN_USER=admin` - Grafana admin username
- `GF_SECURITY_ADMIN_PASSWORD=admin` - Grafana admin password

### Ports

- `5002` - Flask application
- `9090` - Prometheus
- `3000` - Grafana
- `9093` - AlertManager
- `3100` - Loki
- `12345` - Grafana Alloy

## Grafana Dashboards

The setup includes pre-configured dashboards showing:

- Request rates and response times
- Error rates and status codes
- Custom business metrics (orders, users)
- Infrastructure metrics
- Log analysis and correlation

## Troubleshooting

### Common Issues

1. **Services not starting**: Check Docker daemon and port availability
2. **Metrics not appearing**: Verify Prometheus scrape targets at http://localhost:9090/targets
3. **Grafana connection issues**: Ensure datasources are properly configured
4. **Alerts not firing**: Check AlertManager configuration and webhook URLs

### Debug Commands

```bash
# Check service health
make health

# View service logs
make logs
docker compose logs -f [service-name]

# Check Prometheus targets
make targets

# View current metrics
make metrics
```

## Learning Objectives

This demo demonstrates:

1. **Metrics Collection**: Custom Prometheus metrics in Flask
2. **Observability Patterns**: The three pillars (metrics, logs, traces)
3. **Alerting Strategy**: Meaningful alerts with proper thresholds
4. **Dashboard Design**: Effective visualization of system health
5. **Configuration Management**: Infrastructure as code approach
6. **Docker Orchestration**: Multi-service application deployment

## Contributing

This is a demo project for educational purposes. Feel free to:

- Fork and extend with additional scenarios
- Add more complex alerting rules
- Include additional monitoring tools
- Enhance the Flask application with more features

## Further Reading

- [Prometheus Documentation](https://prometheus.io/docs/)
- [Grafana Documentation](https://grafana.com/docs/)
- [Observability Engineering](https://www.oreilly.com/library/view/observability-engineering/9781492076438/)
