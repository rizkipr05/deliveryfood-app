const path = require("path");
const fs = require("fs");
const sqlite3 = require("sqlite3").verbose();

function openDb() {
  const dbPath = process.env.DATABASE_PATH || "./data/app.sqlite";
  const abs = path.isAbsolute(dbPath) ? dbPath : path.join(process.cwd(), "backend", dbPath);

  const dir = path.dirname(abs);
  if (!fs.existsSync(dir)) fs.mkdirSync(dir, { recursive: true });

  const db = new sqlite3.Database(abs);
  db.run("PRAGMA foreign_keys = ON;");
  return db;
}

function run(db, sql, params = []) {
  return new Promise((resolve, reject) => {
    db.run(sql, params, function (err) {
      if (err) return reject(err);
      resolve({ lastID: this.lastID, changes: this.changes });
    });
  });
}

function get(db, sql, params = []) {
  return new Promise((resolve, reject) => {
    db.get(sql, params, (err, row) => {
      if (err) return reject(err);
      resolve(row);
    });
  });
}

function all(db, sql, params = []) {
  return new Promise((resolve, reject) => {
    db.all(sql, params, (err, rows) => {
      if (err) return reject(err);
      resolve(rows);
    });
  });
}

module.exports = { openDb, run, get, all };
