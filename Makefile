.PHONY: help start stop restart logs clean status test-traffic test-errors test-slow test-orders health


help:
	@echo "Flask Observability Demo - Available Commands"
	@echo ""
	@echo "Setup & Management:"
	@echo "  make start          - Start all services"
	@echo "  make stop           - Stop all services"
	@echo "  make restart        - Restart all services"
	@echo "  make clean          - Stop and remove all volumes"
	@echo "  make status         - Show status of all services"
	@echo "  make logs           - Tail all logs"
	@echo ""
	@echo "Demo Scenarios:"
	@echo "  make test-traffic   - Generate normal traffic"
	@echo "  make test-errors    - Trigger error rate alert"
	@echo "  make test-slow      - Hit slow endpoints"
	@echo "  make test-orders    - Create sample orders"
	@echo "  make test-load      - Heavy load test"
	@echo "  make health         - Check service health"
	@echo ""
	@echo "Monitoring:"
	@echo "  make metrics        - View Prometheus metrics"
	@echo "  make alerts         - View active alerts"
	@echo "  make targets        - Check Prometheus targets"
	@echo ""
	@echo "Access URLs:"
	@echo "  Flask App:      http://localhost:5002"
	@echo "  Prometheus:     http://localhost:9090"
	@echo "  Grafana:        http://localhost:3000 (admin/admin)"
	@echo "  AlertManager:   http://localhost:9093"


start:
	@echo "Starting full demo stack..."
	docker compose up -d
	@echo "Waiting for services to be ready..."
	@sleep 5
	@echo "Services are running!"
	@echo ""
	@echo "Access services at:"
	@echo "  Flask App:      http://localhost:5002"
	@echo "  Prometheus:     http://localhost:9090"
	@echo "  Grafana:        http://localhost:3000"
	@echo "  AlertManager:   http://localhost:9093"

stop:
	@echo "Stopping all services..."
	docker compose stop
	@echo "All services stopped"

restart:
	@echo "Restarting all services..."
	docker compose restart
	@echo "All services restarted"

clean:
	@echo "Cleaning up..."
	docker compose down -v
	@echo "Cleanup complete"

status:
	@echo "Service Status:"
	@docker compose ps

logs:
	docker compose logs -f

logs-flask:
	docker compose logs -f flask-app

logs-prometheus:
	docker compose logs -f prometheus

logs-grafana:
	docker compose logs -f grafana


test-traffic:
	@echo "Generating normal traffic..."
	@for i in $$(seq 1 50); do \
		curl -s http://localhost:5002/api/users/$$i > /dev/null; \
		echo -n "."; \
		sleep 0.1; \
	done
	@echo ""
	@echo "Traffic generation complete"
	@echo "Check Grafana dashboard for request rate increase"

test-errors:
	@echo "Triggering error endpoints..."
	@for i in $$(seq 1 30); do \
		curl -s http://localhost:5002/api/error > /dev/null; \
		echo -n "."; \
		sleep 0.2; \
	done
	@echo ""
	@echo "Error generation complete"
	@echo "Check AlertManager in ~2 minutes for HighErrorRate alert"
	@echo "http://localhost:9093"

test-slow:
	@echo "Hitting slow endpoints..."
	@for i in $$(seq 1 5); do \
		curl -s http://localhost:5002/api/slow > /dev/null & \
	done
	@echo "Waiting for slow requests to complete..."
	@wait
	@echo "Slow endpoint test complete"
	@echo "Check Grafana for latency spike in p95/p99"


test-orders:
	@echo "Creating sample orders..."
	@for i in $$(seq 1 20); do \
		amount=$$((50 + RANDOM % 450)); \
		curl -s -X POST http://localhost:5002/api/orders \
			-H "Content-Type: application/json" \
			-d "{\"customer\": \"user_$$i\", \"amount\": $$amount}" > /dev/null; \
		echo -n "."; \
		sleep 0.3; \
	done
	@echo ""
	@echo "Order creation complete"
	@echo "Check Grafana for order metrics and success rate"


test-load:
	@echo "Running load test..."
	@echo "Generating 1000 requests with 20 concurrent connections..."
	@if command -v ab > /dev/null; then \
		ab -n 1000 -c 20 -q http://localhost:5002/api/users/123; \
	else \
		echo "Apache Bench (ab) not installed"; \
		echo "Falling back to curl-based load test..."; \
		for i in $$(seq 1 100); do \
			curl -s http://localhost:5002/api/users/$$i > /dev/null & \
			if [ $$((i % 10)) -eq 0 ]; then wait; fi; \
		done; \
		wait; \
	fi
	@echo "Load test complete"
	@echo "Check Grafana for performance under load"

health:
	@echo "Checking service health..."
	@echo ""
	@echo -n "Flask App:      "
	@curl -s http://localhost:5002/health > /dev/null && echo "Healthy" || echo "Down"
	@echo -n "Prometheus:     "
	@curl -s http://localhost:9090/-/healthy > /dev/null && echo "Healthy" || echo "Down"
	@echo -n "Grafana:        "
	@curl -s http://localhost:3000/api/health > /dev/null && echo "Healthy" || echo "Down"
	@echo -n "AlertManager:   "
	@curl -s http://localhost:9093/-/healthy > /dev/null && echo "Healthy" || echo "Down"
	@echo -n "Loki:           "
	@curl -s http://localhost:3100/ready > /dev/null && echo "Healthy" || echo "Down"


metrics:
	@echo "Flask App Metrics:"
	@curl -s http://localhost:5002/metrics | head -20
	@echo ""
	@echo "Full metrics: http://localhost:5002/metrics"
	@echo "Prometheus UI: http://localhost:9090/graph"


alerts:
	@echo "Active Alerts:"
	@curl -s http://localhost:9090/api/v1/alerts | python3 -m json.tool | grep -A 5 "alertname" | head -20
	@echo ""
	@echo "Full alert list: http://localhost:9090/alerts"
	@echo "AlertManager: http://localhost:9093"


targets:
	@echo "Prometheus Scrape Targets:"
	@curl -s http://localhost:9090/api/v1/targets | python3 -m json.tool | grep -E "(job|health|lastError)" | head -30
	@echo ""
	@echo "Full targets: http://localhost:9090/targets"


demo-metrics:
	@echo "Generating various metrics..."
	@curl -s http://localhost:5002/api/metrics-demo
	@echo "Metrics generated"


build:
	@echo "Building services..."
	docker compose build --no-cache
	@echo "Build complete"


demo-full:
	@echo "Running full demo sequence..."
	@echo ""
	@echo "Starting with normal traffic..."
	@make test-traffic
	@sleep 3
	@echo ""
	@echo "Creating some orders..."
	@make test-orders
	@sleep 3
	@echo ""
	@echo "Triggering slow endpoints..."
	@make test-slow
	@sleep 3
	@echo ""
	@echo "Generating errors..."
	@make test-errors
	@echo ""
	@echo "Full demo sequence complete!"
