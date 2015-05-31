//
//  NoteManager.m
//  MinimalNote
//
//  Created by Carl Li on 5/4/15.
//  Copyright (c) 2015 Carl Li. All rights reserved.
//

#import "NoteManager.h"
#import "FMDatabase.h"

@implementation NoteManager{
    FMDatabase* mDatabase;
}

+ (instancetype)sharedInstance {
    static id _sharedInstance = nil;
    static dispatch_once_t oncePredicate;
    dispatch_once(&oncePredicate, ^{
        _sharedInstance = [[self alloc] init];
    });
    return _sharedInstance;
}

- (instancetype)init {
    self = [super init];
    NSString* dbDir = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    NSString* dbPath = [dbDir stringByAppendingPathComponent:@"note.db"];
    mDatabase = [FMDatabase databaseWithPath:dbPath];
    if ([mDatabase open]) {
        NSString* noteSql = @"CREATE TABLE Note (id integer PRIMARY KEY AUTOINCREMENT NOT NULL,title text,content text,create_time integer,modify_time integer,tag text);";
        [self excuteUpdate:noteSql];
        
        NSString* tagSql = @"CREATE TABLE Tag (id integer PRIMARY KEY AUTOINCREMENT NOT NULL,name text,color text);";
        [self excuteUpdate:tagSql];
    }else{
        NSLog(@"Could not open db.");
    }

    return self;
}

#pragma mark - Note
- (BOOL)addNote:(Note*) note{
    NSTimeInterval time = [NSDate date].timeIntervalSince1970;
    NSString* sql = [NSString stringWithFormat:@"INSERT INTO Note (title, content, create_time, modify_time) VALUES (\"%@\", \"%@\", %f, %f)", note.title, note.content, time, time];
    return [self excuteUpdate:sql];
}

- (BOOL)updateNote:(Note*) note{
    NSString* sql = [NSString stringWithFormat:@"update Note set title=\"%@\", content=\"%@\", modify_time=%f where id=%ld", note.title, note.content, [NSDate date].timeIntervalSince1970, (long)note.nid];
    return [self excuteUpdate:sql];
}

- (BOOL)deleteNote:(Note*) note{
    NSString* sql = [NSString stringWithFormat:@"delete from Note where id = %ld", (long)note.nid];
    return [self excuteUpdate:sql];
}

- (NSMutableArray*)getAllNotesWithDeleted:(BOOL)all{
    NSString* sql = @"select * from note";
    if (!all) {
        
    }
    sql = [sql stringByAppendingString:@" ORDER BY create_time DESC"];
    FMResultSet* result = [mDatabase executeQuery:sql];
    NSMutableArray* notes = [NSMutableArray new];
    Note* note = nil;
    while ([result next]) {
        note = [Note new];
        note.nid = [result intForColumn:@"id"];
        note.title = [result stringForColumn:@"title"];
        note.content = [result stringForColumn:@"content"];
        note.create_time = [[NSDate alloc] initWithTimeIntervalSince1970:[result doubleForColumn:@"create_time"]];
        note.modify_time = [[NSDate alloc] initWithTimeIntervalSince1970:[result doubleForColumn:@"modify_time"]];
        [notes addObject:note];
    }
    
    return notes;
}

#pragma mark - Tag
- (BOOL)addTag:(Tag*) tag{
    NSString* sql = [NSString stringWithFormat:@"INSERT INTO Tag (name, color) VALUES (\"%@\", \"%@\")", tag.name, tag.color];
    return [self excuteUpdate:sql];
}

- (BOOL)updateTag:(Tag*) tag{
    NSString* sql = [NSString stringWithFormat:@"update Tag set name=\"%@\", color=\"%@\"", tag.name, tag.color];
    return [self excuteUpdate:sql];
}

- (BOOL)deleteTag:(Tag*) tag{
    NSString* sql = [NSString stringWithFormat:@"delete from Tag where id = %ld", (long)tag.nid];
    return [self excuteUpdate:sql];
}

#pragma mark -

- (BOOL)excuteUpdate:(NSString*)sql{
    NSLog(sql,nil);
    return [mDatabase executeUpdate:sql];
}

@end
