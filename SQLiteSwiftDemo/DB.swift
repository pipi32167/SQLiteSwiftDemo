//
//  DB.swift
//  SQLiteSwiftDemo
//
//  Created by Trillion Young on 2023/6/26.
//

import Foundation
import SQLite
import sqlite3


struct TextRow: Hashable {
    let id: Int
    let text: String
}

class TextTable {
    static let tableName = "texts"
    let table = Table(tableName)
    
    let id = Expression<Int>("id")
    let text = Expression<String>("text")
}

class FTSTextTable {
    static let tableName = "fts_\(TextTable.tableName)"
    let table = VirtualTable(tableName)
    
    let id = Expression<Int>("id")
    let text = Expression<String>("text")
}


class DB {
    
    static public let shared = DB()
    private let conn: Connection
    private let textTable = TextTable()
    private let ftsTextTable = FTSTextTable()
    
    init() {
        
        do {
            
            FTSService.registerFTS()
            let path = NSSearchPathForDirectoriesInDomains(
                .documentDirectory, .userDomainMask, true
            ).first!
            let dbPath = "\(path)/demo.db"
            conn = try Connection(dbPath)
#if DEBUG
            conn.trace { print($0) }
#endif
            try createTables()
            
            let kJiebaPath = Bundle.main.path(forResource: "JIEBA", ofType: "bundle")
            try conn.run("select jieba_dict('\(kJiebaPath!)')")
        } catch {
            fatalError("Error initializing database: \(error)")
        }
    }
    
    func close() {
        
        if sqlite3_close(conn.handle) != SQLITE_OK {
            print("error closing database")
        }
    }
    
    func createTables() throws {
        
        try conn.run(textTable.table.create(ifNotExists: true) { t in
            t.column(textTable.id, primaryKey: .autoincrement)
            t.column(textTable.text)
        })
        
        let config = FTS5Config()
            .contentRowId(textTable.id)
            .externalContent(textTable.table)
            .column(textTable.text)
            .tokenizer(.Simple)
        try conn.run(ftsTextTable.table.create(.FTS5(config), ifNotExists: true))
        let tableName = TextTable.tableName
        let ftsTableName = FTSTextTable.tableName
        try conn.run("""
        -- Triggers to keep the FTS index up to date.
        CREATE TRIGGER IF NOT EXISTS \(tableName)_ai AFTER INSERT ON \(tableName) BEGIN
          INSERT INTO \(ftsTableName)(rowid, text) VALUES (new.id, new.text);
        END;
        CREATE TRIGGER IF NOT EXISTS \(tableName)_ad AFTER DELETE ON \(tableName) BEGIN
          INSERT INTO \(ftsTableName)(\(ftsTableName), rowid, text) VALUES('delete', old.id, old.text);
        END;
        CREATE TRIGGER IF NOT EXISTS \(tableName)_au AFTER UPDATE ON \(tableName) BEGIN
          INSERT INTO \(ftsTableName)(\(ftsTableName), rowid, text) VALUES('delete', old.id, old.text);
          INSERT INTO \(ftsTableName)(rowid, text) VALUES (new.id, new.text);
        END;
        """)
        
        if try isEmpty() {
            try insertTestRows()
        }
        
    }
    
    func dropTables() throws {
        try conn.run(textTable.table.drop(ifExists: true))
        try conn.run(ftsTextTable.table.drop(ifExists: true))
    }
    
    func insertOne(text: String) throws {
        
        try conn.run(textTable.table.insert(textTable.text <- text))
    }
    
    func removeOne(id: Int) throws {
        try conn.run(textTable.table.filter(textTable.id == id).delete())
    }
    
    func insertTestRows() throws {
        
        try self.insertOne(text: "周杰伦")
        try self.insertOne(text: "中华人民共和国国歌")
    }
    
    func query(text: String, usingJieba: Bool, usingHighlight: Bool) throws -> [String] {
        
        var whereClause: Expression<Bool>
        if usingJieba {
            whereClause = Expression(literal: "\(ftsTextTable.text) match jieba_query('\(text)')")
        } else {
            whereClause = Expression(literal: "\(ftsTextTable.text) match simple_query('\(text)')")
        }
        var selectClause: [Expressible] = []
        if usingHighlight {
            selectClause.append(Expression<String>(literal: "simple_highlight(\(FTSTextTable.tableName), 0, '[', ']') as text"))
        } else {
            selectClause.append(ftsTextTable.text)
        }
        var results: [String] = []
        for row in try conn.prepare(ftsTextTable.table.where(whereClause).select(selectClause)) {
            
            results.append(try row.get(selectClause[0] as! Expression<String>))
        
        }
        return results
    }
    
    func queryAll() throws -> [String] {
        var results: [String] = []
        for row in try conn.prepare(textTable.table.select([textTable.text])) {
            results.append(try row.get(textTable.text))
        }
        return results
    }
    
    func count() throws -> Int {
        return try conn.scalar(textTable.table.count)
    }
    
    func isEmpty() throws -> Bool {
        return try self.count() == 0
    }
}
