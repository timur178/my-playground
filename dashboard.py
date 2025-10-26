from flask import Flask, render_template, jsonify
import requests
import json
from datetime import datetime

app = Flask(__name__)

# Configuration
API_BASE_URL = "http://kafka-consumer-api-service.kafka.svc.cluster.local"  # Internal k8s service
# For local testing: API_BASE_URL = "http://localhost:8080"

@app.route('/')
def dashboard():
    """Main dashboard page"""
    return render_template('dashboard.html')

@app.route('/api/data')
def get_dashboard_data():
    """Proxy API calls to consumer service"""
    try:
        # Get latest data
        latest_response = requests.get(f"{API_BASE_URL}/data/latest?limit=100")
        latest_data = latest_response.json() if latest_response.status_code == 200 else {"data": []}
        
        # Get stats
        stats_response = requests.get(f"{API_BASE_URL}/data/stats")
        stats_data = stats_response.json() if stats_response.status_code == 200 else {"data": {}}
        
        return jsonify({
            "latest": latest_data,
            "stats": stats_data
        })
    
    except Exception as e:
        return jsonify({"error": str(e)}), 500

@app.route('/health')
def health():
    """Health check endpoint"""
    return jsonify({'status': 'healthy', 'service': 'visualization-dashboard'})

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=3000, debug=True)