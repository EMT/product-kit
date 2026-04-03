import {
  mysqlTable,
  serial,
  varchar,
  boolean,
  timestamp,
} from 'drizzle-orm/mysql-core'

export const tasks = mysqlTable('tasks', {
  id: serial('id').primaryKey(),
  text: varchar('text', { length: 256 }).notNull(),
  completed: boolean('completed').notNull().default(false),
  createdAt: timestamp('created_at').notNull().defaultNow(),
})
