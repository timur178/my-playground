# consumer_api.py
import json
import threading
import time
import os
from datetime import datetime, timedelta
from flask import Flask, jsonify, request
from kafka import KafkaConsumer
import psycopg2
import psycopg2.extras
import logging
from contextlib import contextmanager

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Configuration
DATABASE_CONFIG = {
    'host': os.getenv('DB_HOST', 'YOUR_DB_HOST'),
    'port': os.getenv('DB_PORT', '5432'),
    'database': os.getenv('DB_NAME', 'postgres'),
    'user': os.getenv('DB_USER', 'postgres'),
    'password': os.getenv('DB_PASSWORD', 'YOUR_DB_PASSWORD'),
    'sslmode': 'require'
}

KAFKA_CONFIG = {
    'bootstrap_servers': ['kafka-cluster-kafka-bootstrap.kafka.svc.cluster.local:9092'],
    'topic': 'sensor-data',
    'group_id': 'sensor-consumer-group'
}

class DatabaseManager:
    def __init__(self, db_config):
        self.db_config = db_config
        self.init_database()
    
    @contextmanager
    def get_db_connection(self):
        """Context manager for database connections"""
        conn = None
        try:
            conn = psycopg2.connect(**self.db_config)
            yield conn
        except Exception as e:
            if conn:
                conn.rollback()
            logger.error(f"Database error: {e}")
            raise
        finally:
            if conn:
                conn.close()
    
    def init_database(self):
        """Initialize database schema"""
        with self.get_db_connection() as conn:
            cursor = conn.cursor()
            
            # Create events table
            cursor.execute("""
                CREATE TABLE IF NOT EXISTS events (
                    id SERIAL PRIMARY KEY,
                    sensor_id VARCHAR(50),
                    temperature FLOAT,
                    humidity FLOAT,
                    location VARCHAR(50),
                    timestamp TIMESTAMP,
                    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
                )
            """)
            
            # Create index for better query performance
            cursor.execute("""
                CREATE INDEX IF NOT EXISTS idx_events_timestamp 
                ON events(timestamp)
            """)
            
            cursor.execute("""
                CREATE INDEX IF NOT EXISTS idx_events_sensor_id 
                ON events(sensor_id)
            """)
            
            conn.commit()
            logger.info("Database schema initialized")
    
    def insert_event(self, event_data):
        """Insert event data into database"""
        with self.get_db_connection() as conn:
            cursor = conn.cursor()
            
            cursor.execute("""
                INSERT INTO events (sensor_id, temperature, humidity, location, timestamp)
                VALUES (%(sensor_id)s, %(temperature)s, %(humidity)s, %(location)s, %(timestamp)s)
            """, event_data)
            
            conn.commit()
    
    def get_latest_events(self, limit=50):
        """Get latest events from database"""
        with self.get_db_connection() as conn:
            cursor = conn.cursor(cursor_factory=psycopg2.extras.RealDictCursor)
            
            cursor.execute("""
                SELECT * FROM events 
                ORDER BY timestamp DESC 
                LIMIT %s
            """, (limit,))
            
            return cursor.fetchall()
    
    def get_stats(self):
        """Get aggregated statistics"""
        with self.get_db_connection() as conn:
            cursor = conn.cursor(cursor_factory=psycopg2.extras.RealDictCursor)
            
            # Overall stats
            cursor.execute("""
                SELECT 
                    COUNT(*) as total_events,
                    AVG(temperature) as avg_temperature,
                    AVG(humidity) as avg_humidity,
                    MIN(timestamp) as first_event,
                    MAX(timestamp) as last_event
                FROM events
            """)
            
            overall_stats = cursor.fetchone()
            
            # Stats by sensor
            cursor.execute("""
                SELECT 
                    sensor_id,
                    COUNT(*) as event_count,
                    AVG(temperature) as avg_temperature,
                    AVG(humidity) as avg_humidity
                FROM events 
                GROUP BY sensor_id
                ORDER BY event_count DESC
            """)
            
            sensor_stats = cursor.fetchall()
            
            # Recent hourly data for charts
            cursor.execute("""
                SELECT 
                    DATE_TRUNC('hour', timestamp) as hour,
                    AVG(temperature) as avg_temperature,
                    AVG(humidity) as avg_humidity,
                    COUNT(*) as event_count
                FROM events 
                WHERE timestamp >= NOW() - INTERVAL '24 hours'
                GROUP BY DATE_TRUNC('hour', timestamp)
                ORDER BY hour
            """)
            
            hourly_stats = cursor.fetchall()
            
            return {
                'overall': overall_stats,
                'by_sensor': sensor_stats,
                'hourly': hourly_stats
            }

class KafkaEventConsumer:
    def __init__(self, kafka_config, db_manager):
        self.kafka_config = kafka_config
        self.db_manager = db_manager
        self.consumer = None
        self.running = False
    
    def start_consuming(self):
        """Start consuming messages from Kafka"""
        self.consumer = KafkaConsumer(
            self.kafka_config['topic'],
            bootstrap_servers=self.kafka_config['bootstrap_servers'],
            group_id=self.kafka_config['group_id'],
            value_deserializer=lambda m: json.loads(m.decode('utf-8')),
            auto_offset_reset='latest'
        )
        
        self.running = True
        logger.info(f"Started consuming from topic: {self.kafka_config['topic']}")
        
        try:
            for message in self.consumer:
                if not self.running:
                    break
                    
                event_data = message.value
                logger.info(f"Consumed message: {event_data}")
                
                # Convert timestamp string to datetime
                event_data['timestamp'] = datetime.fromisoformat(event_data['timestamp'].replace('Z', '+00:00'))
                
                # Insert into database
                self.db_manager.insert_event(event_data)
                logger.info("Event stored in database")
                
        except Exception as e:
            logger.error(f"Error consuming messages: {e}")
        finally:
            if self.consumer:
                self.consumer.close()
    
    def stop_consuming(self):
        """Stop consuming messages"""
        self.running = False

# Flask Application
app = Flask(__name__)
db_manager = DatabaseManager(DATABASE_CONFIG)
kafka_consumer = KafkaEventConsumer(KAFKA_CONFIG, db_manager)

@app.route('/health')
def health():
    """Health check endpoint"""
    return jsonify({'status': 'healthy', 'timestamp': datetime.utcnow().isoformat()})

@app.route('/data/latest')
def get_latest_data():
    """Get latest events"""
    try:
        limit = request.args.get('limit', 50, type=int)
        events = db_manager.get_latest_events(limit)
        
        # Convert datetime objects to strings for JSON serialization
        for event in events:
            event['timestamp'] = event['timestamp'].isoformat()
            event['created_at'] = event['created_at'].isoformat()
        
        return jsonify({
            'status': 'success',
            'count': len(events),
            'data': events
        })
    except Exception as e:
        logger.error(f"Error fetching latest data: {e}")
        return jsonify({'status': 'error', 'message': str(e)}), 500

@app.route('/data/stats')
def get_stats():
    """Get aggregated statistics"""
    try:
        stats = db_manager.get_stats()
        
        # Convert datetime objects to strings for JSON serialization
        def convert_datetime(obj):
            if isinstance(obj, dict):
                for key, value in obj.items():
                    if isinstance(value, datetime):
                        obj[key] = value.isoformat()
                    elif isinstance(value, list):
                        obj[key] = [convert_datetime(item) if isinstance(item, dict) else item for item in value]
            return obj
        
        stats = convert_datetime(stats)
        
        return jsonify({
            'status': 'success',
            'data': stats
        })
    except Exception as e:
        logger.error(f"Error fetching stats: {e}")
        return jsonify({'status': 'error', 'message': str(e)}), 500

if __name__ == '__main__':
    # Start Kafka consumer in background thread
    consumer_thread = threading.Thread(target=kafka_consumer.start_consuming)
    consumer_thread.daemon = True
    consumer_thread.start()
    
    # Start Flask app
    app.run(host='0.0.0.0', port=8080, debug=False)