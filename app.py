"""
Flask Demo Application for FlaskCon2025 Talk
This app demonstrates various observability patterns using OSS tools.
"""

from flask import Flask, request, jsonify
from prometheus_flask_exporter import PrometheusMetrics
from prometheus_client import Counter, Histogram, Gauge
import logging
import time
import random
from datetime import datetime
import json

app = Flask(__name__)

logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

metrics = PrometheusMetrics(app)
metrics.info('flask_app_info', 'Flask Application Info', version='1.0.0')

# create custom metrics for demo
order_counter = Counter('orders_total', 'Total number of orders', ['status'])
order_value = Histogram('order_value_dollars', 'Order value in dollars')
active_users = Gauge('active_users', 'Number of active users')
database_query_duration = Histogram('database_query_duration_seconds', 
                                    'Database query duration', ['query_type'])

# generate some random active users
_active_users_count = random.randint(10, 50)
active_users.set(_active_users_count)


@app.route('/')
def home():
    """Home endpoint - always healthy"""
    logger.info("Home endpoint accessed", extra={
        'endpoint': '/',
        'user_agent': request.headers.get('User-Agent')
    })
    return jsonify({
        'service': 'Flask Observability Demo',
        'status': 'running',
        'timestamp': datetime.utcnow().isoformat()
    })


@app.route('/health')
def health():
    """Health check endpoint"""
    return jsonify({'status': 'healthy'}), 200


@app.route('/metrics')
def metrics_endpoint():
    """Prometheus metrics endpoint"""
    from prometheus_client import generate_latest, CONTENT_TYPE_LATEST
    from flask import Response
    return Response(generate_latest(), mimetype=CONTENT_TYPE_LATEST)


@app.route('/api/orders', methods=['POST'])
def create_order():
    """Simulate order creation with metrics"""
    order_data = request.get_json()
    
    
    query_start = time.time()
    time.sleep(random.uniform(0.01, 0.1))  
    database_query_duration.labels(query_type='insert').observe(time.time() - query_start)
    
    
    success = random.random() > 0.1  # 90% success rate
    
    if success:
        order_counter.labels(status='success').inc()
        order_value.observe(order_data.get('amount', 0))
        
        logger.info("Order created successfully", extra={
            'order_id': random.randint(1000, 9999),
            'amount': order_data.get('amount', 0),
            'customer': order_data.get('customer', 'unknown')
        })
        
        return jsonify({
            'status': 'success',
            'order_id': random.randint(1000, 9999)
        }), 201
    else:
        order_counter.labels(status='failed').inc()
        
        logger.error("Order creation failed", extra={
            'reason': 'payment_declined',
            'amount': order_data.get('amount', 0)
        })
        
        return jsonify({
            'status': 'error',
            'message': 'Payment declined'
        }), 400


@app.route('/api/users/<user_id>')
def get_user(user_id):
    """Simulate user lookup with variable latency"""
    query_start = time.time()

    time.sleep(random.uniform(0.05, 0.3))
    database_query_duration.labels(query_type='select').observe(time.time() - query_start)
    
    logger.info(f"User lookup", extra={
        'user_id': user_id,
        'query_duration': time.time() - query_start
    })
    
    return jsonify({
        'user_id': user_id,
        'username': f'user_{user_id}',
        'active': True
    })


@app.route('/api/slow')
def slow_endpoint():
    """Intentionally slow endpoint for demo"""
    duration = random.uniform(1, 3)
    logger.warning(f"Slow endpoint accessed - will take {duration:.2f}s", extra={
        'endpoint': '/api/slow',
        'expected_duration': duration
    })
    
    time.sleep(duration)
    
    return jsonify({
        'message': 'This was intentionally slow',
        'duration': duration
    })


@app.route('/api/error')
def error_endpoint():
    """Endpoint that randomly returns errors for demo"""
    error_types = [
        (500, 'Internal Server Error', 'database_connection_failed'),
        (503, 'Service Unavailable', 'downstream_service_timeout'),
        (429, 'Too Many Requests', 'rate_limit_exceeded')
    ]

    status_code, message, reason = random.choice(error_types)

    logger.error("Error endpoint triggered", extra={
        'status_code': status_code,
        'reason': reason
    })

    return jsonify({
        'error': message,
        'reason': reason
    }), status_code


@app.route('/api/metrics-demo')
def metrics_demo():
    """Endpoint that generates interesting metrics"""
    global _active_users_count
 
    increment = random.randint(-5, 10)
    active_users.inc(increment)
    _active_users_count += increment

    for _ in range(random.randint(1, 5)):
        order_counter.labels(status='success').inc()
        order_value.observe(random.uniform(10, 1000))

    return jsonify({
        'message': 'Metrics generated',
        'active_users': _active_users_count
    })


@app.errorhandler(404)
def not_found(_error):
    """Handle 404 errors"""
    logger.warning("404 Not Found", extra={
        'path': request.path,
        'method': request.method
    })
    return jsonify({'error': 'Not found'}), 404


@app.errorhandler(500)
def internal_error(error):
    """Handle 500 errors"""
    logger.error("500 Internal Server Error", extra={
        'path': request.path,
        'error': str(error)
    })
    return jsonify({'error': 'Internal server error'}), 500


if __name__ == '__main__':
    logger.info("Starting Flask Observability Demo App")
    app.run(host='0.0.0.0', port=5002, debug=True)