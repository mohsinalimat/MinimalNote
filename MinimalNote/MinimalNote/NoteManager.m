//
//  NoteManager.m
//  MinimalNote
//
//  Created by Carl Li on 5/4/15.
//  Copyright (c) 2015 Carl Li. All rights reserved.
//

#import "NoteManager.h"
#import "FMDatabase.h"
#import "Logger.h"

#define CLASS_DEBUG NO

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
        NSString* noteSql = @"CREATE TABLE Note (id integer PRIMARY KEY AUTOINCREMENT NOT NULL,title text,content text,create_time integer,modify_time integer,tag integer, deleted integer(1));";
        [self excuteUpdate:noteSql];
        
        NSString* tagSql = @"CREATE TABLE Tag (id integer PRIMARY KEY AUTOINCREMENT NOT NULL,name text,color text, isdefault integer(1));";
        [self excuteUpdate:tagSql];
        [self initTagData];
    }else{
        [self printLog:@"Could not open db."];
    }

    return self;
}

#pragma mark - Note
- (BOOL)addNote:(Note*) note{
    NSTimeInterval time = [NSDate date].timeIntervalSince1970;
    NSString* sql = [NSString stringWithFormat:@"INSERT INTO Note (title, content, create_time, modify_time, tag, deleted) VALUES (\"%@\", \"%@\", %f, %f, %ld, %d)", note.title, note.content, time, time, (long)note.tag, note.deleted? 1 : 0];
    return [self excuteUpdate:sql];
}

- (BOOL)updateNote:(Note*) note{
    NSString* sql = [NSString stringWithFormat:@"update Note set title=\"%@\", content=\"%@\", modify_time=%f, tag=%ld, deleted=%d where id=%ld", note.title, note.content, [NSDate date].timeIntervalSince1970, (long)note.tag, note.deleted ? 1 : 0, (long)note.nid];
    return [self excuteUpdate:sql];
}

- (BOOL)deleteNote:(Note*) note{
    NSString* sql = [NSString stringWithFormat:@"delete from Note where id = %ld", (long)note.nid];
    return [self excuteUpdate:sql];
}

- (NSMutableArray*)getAllNotesWithDeleted:(BOOL)all{
    NSString* sql = @"select * from note";
    if (!all) {
        sql = [sql stringByAppendingString:@" where deleted=0"];
    }
    sql = [sql stringByAppendingString:@" ORDER BY create_time DESC"];
    FMResultSet* result = [mDatabase executeQuery:sql];
    NSMutableArray* notes = [NSMutableArray new];
    Note* note = nil;
    while ([result next]) {
        note = [self readNoteFromResultSet:result];
        [notes addObject:note];
    }
    return notes;
}

- (NSMutableArray*)getDeletedNotes{
    NSString* sql = @"select * from note where deleted=1";
    sql = [sql stringByAppendingString:@" ORDER BY create_time DESC"];
    FMResultSet* result = [mDatabase executeQuery:sql];
    NSMutableArray* notes = [NSMutableArray new];
    Note* note = nil;
    while ([result next]) {
        note = [self readNoteFromResultSet:result];
        [notes addObject:note];
    }
    return notes;
}


- (NSMutableArray*)getNotesByTagId:(NSInteger)tagId{
    NSString* sql = [NSString stringWithFormat:@"select * from note where tag=%ld and deleted=0", (long)tagId];
    sql = [sql stringByAppendingString:@" ORDER BY create_time DESC"];
    FMResultSet* result = [mDatabase executeQuery:sql];
    NSMutableArray* notes = [NSMutableArray new];
    Note* note = nil;
    while ([result next]) {
        note = [self readNoteFromResultSet:result];
        [notes addObject:note];
    }
    return notes;
}

- (Note*) readNoteFromResultSet:(FMResultSet*) result{
    Note* note = [Note new];
    note.nid = [result intForColumn:@"id"];
    note.title = [result stringForColumn:@"title"];
    note.content = [result stringForColumn:@"content"];
    note.create_time = [[NSDate alloc] initWithTimeIntervalSince1970:[result doubleForColumn:@"create_time"]];
    note.modify_time = [[NSDate alloc] initWithTimeIntervalSince1970:[result doubleForColumn:@"modify_time"]];
    note.tag = [result intForColumn:@"tag"];
    note.deleted = [result intForColumn:@"deleted"] == 1 ? YES : NO;
    return note;
}

#pragma mark - Tag
- (BOOL)addTag:(Tag*) tag{
    NSString* sql = [NSString stringWithFormat:@"INSERT INTO Tag (name, color, isdefault) VALUES (\"%@\", \"%@\", %d)", tag.name, tag.color, tag.isDefault ? 1 : 0];
    return [self excuteUpdate:sql];
}

- (BOOL)updateTag:(Tag*) tag{
    NSString* sql = [NSString stringWithFormat:@"update Tag set name=\"%@\", color=\"%@\", isdefault=%d where id=%ld", tag.name, tag.color, tag.isDefault ? 1 : 0, (long)tag.nid];
    return [self excuteUpdate:sql];
}

- (BOOL)deleteTag:(Tag*) tag{
    NSString* sql = [NSString stringWithFormat:@"delete from Tag where id = %ld", (long)tag.nid];
    return [self excuteUpdate:sql];
}

- (NSMutableArray*)getAllTags{
    NSString* sql = @"select * from Tag";
    FMResultSet* result = [mDatabase executeQuery:sql];
    NSMutableArray* tags = [NSMutableArray new];
    Tag* tag = nil;
    while ([result next]) {
        tag = [Tag new];
        tag.nid = [result intForColumn:@"id"];
        tag.name = [result stringForColumn:@"name"];
        tag.color = [result stringForColumn:@"color"];
        tag.isDefault = [result intForColumn:@"isdefault"] == 1 ? YES : NO;
        [tags addObject:tag];
    }
    return tags;
}

- (Tag*)getTagById:(NSInteger)tagId{
    NSString* sql = [NSString stringWithFormat:@"select * from Tag where id = %ld", (long)tagId];
    
    FMResultSet* result = [mDatabase executeQuery:sql];
    Tag* tag = nil;
    while ([result next]) {
        tag = [Tag new];
        tag.nid = [result intForColumn:@"id"];
        tag.name = [result stringForColumn:@"name"];
        tag.color = [result stringForColumn:@"color"];
        tag.isDefault = [result intForColumn:@"isdefault"] == 1 ? YES : NO;
        break;
    }
    return tag;
}

- (void)initTagData{
    BOOL inited = [[NSUserDefaults standardUserDefaults] boolForKey:@"init_tags"];
    if (!inited) {
        Tag* tag = [Tag new];
        
        tag.name = @"工作";
        tag.color = @"#0099FF";
        tag.isDefault = YES;
        [self addTag:tag];
        
        tag.name = @"生活";
        tag.color = @"#FF6666";
        tag.isDefault = YES;
        [self addTag:tag];
        
        tag.name = @"学习";
        tag.color = @"#99CC33";
        tag.isDefault = YES;
        [self addTag:tag];
        
        tag.name = @"衣";
        tag.color = @"#FFCC00";
        tag.isDefault = NO;
        [self addTag:tag];
        
        tag.name = @"食";
        tag.color = @"#009966";
        tag.isDefault = NO;
        [self addTag:tag];
        
        tag.name = @"住";
        tag.color = @"#99CCFF";
        tag.isDefault = NO;
        [self addTag:tag];
        
        tag.name = @"行";
        tag.color = @"#336699";
        tag.isDefault = NO;
        [self addTag:tag];
        
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"init_tags"];
    }
}

#pragma mark -

- (BOOL)excuteUpdate:(NSString*)sql{
    [self printLog:sql];
    return [mDatabase executeUpdate:sql];
}

- (void)printLog:(NSString*)log{
    if (CLASS_DEBUG) {
        [Logger log:log];
    }
}

@end
