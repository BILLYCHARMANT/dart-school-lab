# Assignment 5 - Offline Posts Manager (SQLite)

## Setup

1. cd assignment-5
2. flutter pub get
3. flutter run

## Goals implemented

- View all posts stored locally (SQLite)
- Read post details
- Add new post
- Edit existing post
- Delete post
- Local database exception handling and UI update

## Dependencies

- sqflite  : native SQLite operations in Flutter
- path_provider: app directory path to store database file

### Why SQLite

SQLite allows offline local persistence, which is needed for this assignment scenario.
It supports structured rows (table), reliability, and query support for CRUD operations.

## Exception handling approach

- Database not initialized
  - `PostsDatabase.instance` throws if accessed before `initDb`.
- Insert/update/delete errors
  - Captured by `DatabaseException` and re-thrown as user-friendly exceptions.
- Invalid/corrupted data
  - `Post.fromMap` validates required fields; malformed data triggers `FormatException` / errors.

## Concept summary

- Database vs Table
  - Database: file-level container (`posts_manager.db`).
  - Table: rows format (`posts` table with `id, title, body`).
- CRUD operations
  - Create: `insert('posts', ...)`
  - Read: `query('posts')`
  - Update: `update('posts', ... where id)`
  - Delete: `delete('posts', ... where id)`
- Async interaction
  - All SQLite API is async and integrated with Flutter using `FutureBuilder` + `setState`.

## How to test

- Add a post via + button
- Select a post to view details
- Use popup menu to edit/delete
- Reopen app to verify data persists offline

