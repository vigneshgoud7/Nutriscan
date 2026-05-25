import asyncio
import asyncpg
import os
from dotenv import load_dotenv

load_dotenv()

async def main():
    db_url = os.getenv("DATABASE_URL")
    if not db_url:
        print("Error: DATABASE_URL not found in .env file.")
        return

    conn = await asyncpg.connect(db_url)
    
    sql = """
    DROP POLICY IF EXISTS "Allow authenticated uploads" ON storage.objects;
    CREATE POLICY "Allow authenticated uploads"
    ON storage.objects
    FOR INSERT
    TO authenticated
    WITH CHECK (bucket_id = 'food-images');
    """
    try:
        await conn.execute(sql)
        print("Policy added successfully!")
    except Exception as e:
        print(f"Error: {e}")
    finally:
        await conn.close()

if __name__ == "__main__":
    asyncio.run(main())
