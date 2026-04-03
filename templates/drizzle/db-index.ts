import { drizzle } from 'drizzle-orm/planetscale-serverless'
import { Client } from '@planetscale/database'
import * as schema from './schema'

function createDb() {
  const client = new Client({ url: process.env.DATABASE_URL! })
  return drizzle(client, { schema })
}

let _db: ReturnType<typeof createDb> | null = null

export function getDb() {
  if (!_db) _db = createDb()
  return _db
}
