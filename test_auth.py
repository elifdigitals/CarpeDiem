"""
Quick test script to verify auth flow
"""
import asyncio
import bcrypt
from sqlalchemy import select
from database import AsyncSessionLocal, engine, Base
import models

async def test_auth():
    # Create tables
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)
    
    # Test password hashing
    password = "test_password_123"
    hashed = bcrypt.hashpw(password.encode('utf-8'), bcrypt.gensalt()).decode('utf-8')
    print(f"Original: {password}")
    print(f"Hashed: {hashed}")
    
    # Test verification
    is_correct = bcrypt.checkpw(password.encode('utf-8'), hashed.encode('utf-8'))
    print(f"Verification: {is_correct}")
    
    # Test with user in DB
    async with AsyncSessionLocal() as session:
        # Create test user
        test_user = models.User(
            username="testuser",
            email="test@test.com",
            hashed_pw=hashed
        )
        session.add(test_user)
        await session.commit()
        print(f"✅ Test user created: {test_user.id}")
        
        # Retrieve and verify
        result = await session.execute(select(models.User).where(models.User.email == "test@test.com"))
        user = result.scalar_one_or_none()
        if user:
            print(f"✅ User found: {user.username}")
            verify = bcrypt.checkpw(password.encode('utf-8'), user.hashed_pw.encode('utf-8'))
            print(f"✅ Password verified: {verify}")
        else:
            print("❌ User not found")

if __name__ == "__main__":
    asyncio.run(test_auth())
