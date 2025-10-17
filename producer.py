# producer.py
import json
import time
import random
from datetime import datetime
from kafka import KafkaProducer
import logging

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

class SensorDataProducer:
    def __init__(self, bootstrap_servers, topic):
        self.producer = KafkaProducer(
            bootstrap_servers=bootstrap_servers,
            value_serializer=lambda v: json.dumps(v).encode('utf-8'),
            key_serializer=lambda k: str(k).encode('utf-8') if k else None
        )
        self.topic = topic
        
    def generate_sensor_data(self):
        """Generate sample sensor data"""
        return {
            'sensor_id': random.choice(['sensor_001', 'sensor_002', 'sensor_003']),
            'temperature': round(random.uniform(18.0, 35.0), 2),
            'humidity': round(random.uniform(30.0, 80.0), 2),
            'timestamp': datetime.utcnow().isoformat(),
            'location': random.choice(['room_a', 'room_b', 'room_c'])
        }
    
    def produce_messages(self, interval=5, max_messages=None):
        """Produce messages to Kafka topic"""
        message_count = 0
        
        try:
            while True:
                # Generate and send data
                data = self.generate_sensor_data()
                key = data['sensor_id']
                
                future = self.producer.send(
                    self.topic, 
                    key=key, 
                    value=data
                )
                
                # Wait for send to complete
                record_metadata = future.get(timeout=10)
                
                logger.info(f"Sent message {message_count + 1}: {data}")
                logger.info(f"Topic: {record_metadata.topic}, Partition: {record_metadata.partition}, Offset: {record_metadata.offset}")
                
                message_count += 1
                
                # Exit if max_messages reached
                if max_messages and message_count >= max_messages:
                    break
                    
                time.sleep(interval)
                
        except KeyboardInterrupt:
            logger.info("Stopping producer...")
        except Exception as e:
            logger.error(f"Error producing messages: {e}")
        finally:
            self.producer.close()

if __name__ == "__main__":
    # Configuration
    KAFKA_BOOTSTRAP_SERVERS = ['kafka-cluster-kafka-bootstrap.kafka.svc.cluster.local:9092']
    TOPIC_NAME = 'sensor-data'
    
    # Create producer
    producer = SensorDataProducer(KAFKA_BOOTSTRAP_SERVERS, TOPIC_NAME)
    
    # Start producing (send message every 5 seconds)
    producer.produce_messages(interval=5)