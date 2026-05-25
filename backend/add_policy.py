import asyncio
import asyncpg

async def main():
    db_url = DATABASE_URL
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
