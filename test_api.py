"""
Test script to verify backend API endpoints
"""
import requests
import json

BASE_URL = "http://localhost:8000"

def test_register():
    print("\n=== Testing Registration ===")
    payload = {
        "username": "testuser123",
        "email": "testuser123@test.com",
        "password": "password123"
    }
    response = requests.post(f"{BASE_URL}/auth/register", json=payload)
    print(f"Status: {response.status_code}")
    print(f"Response: {json.dumps(response.json(), indent=2)}")
    return response.json() if response.status_code == 200 else None

def test_login(email, password):
    print("\n=== Testing Login ===")
    payload = {
        "email": email,
        "password": password
    }
    response = requests.post(f"{BASE_URL}/auth/login", json=payload)
    print(f"Status: {response.status_code}")
    print(f"Response: {json.dumps(response.json(), indent=2)}")
    return response.json() if response.status_code == 200 else None

def test_lobbies():
    print("\n=== Testing Get Lobbies ===")
    response = requests.get(f"{BASE_URL}/lobbies/")
    print(f"Status: {response.status_code}")
    print(f"Response: {json.dumps(response.json(), indent=2) if response.status_code == 200 else response.text}")

def test_health():
    print("\n=== Testing Health ===")
    response = requests.get(f"{BASE_URL}/health")
    print(f"Status: {response.status_code}")
    print(f"Response: {json.dumps(response.json(), indent=2)}")

if __name__ == "__main__":
    test_health()
    
    # Test register
    reg_result = test_register()
    
    # Test login
    if reg_result:
        test_login("testuser123@test.com", "password123")
    
    test_lobbies()
