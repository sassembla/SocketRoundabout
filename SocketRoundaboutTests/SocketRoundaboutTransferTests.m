//
//  SocketRoundaboutTransferTests.h
//  SocketRoundabout
//
//  Created by sassembla on 2013/05/03.
//  Copyright (c) 2013年 KISSAKI Inc,. All rights reserved.
//

#import <SenTestingKit/SenTestingKit.h>
#import "KSMessenger.h"

#import "SRTransfer.h"
#import "SRTransferArray.h"

#import "RoundaboutController.h"

#define TEST_MASTER (@"TEST_MASTER_2013/05/03 15:32:06")
#define TEST_WEBSOCKETSERVER   (@"ws://127.0.0.1:8823")

#define TEST_CONNECTIONIDENTITY_3   (@"TEST_CONNECTIONIDENTITY_3_2013/05/03 16:30:38")
#define TEST_CONNECTIONIDENTITY_4   (@"TEST_CONNECTIONIDENTITY_4_2013/05/03 16:30:41")
#define TEST_CONNECTIONIDENTITY_5   (@"TEST_CONNECTIONIDENTITY_5_2013/05/03 18:18:02")
#define TEST_CONNECTIONIDENTITY_6   (@"TEST_CONNECTIONIDENTITY_6_2013/05/03 19:27:00")

#define TEST_MESSAGE    (@"TEST_MESSAGE_2013/05/03 18:05:56")

#define TEST_PREFIX (@"TEST_PREFIX_2013/05/03 18:00:27")
#define TEST_POSTFIX    (@"TEST_POSTFIX_2013/05/03 18:00:50")

#define TEST_PREFIX2 (@"TEST_PREFIX_2013/05/03 18:20:27")
#define TEST_POSTFIX2    (@"TEST_POSTFIX_2013/05/03 18:20:31")


#define TEST_TIMELIMIT  (3)

@interface SocketRoundaboutTransferTests : SenTestCase {
    KSMessenger * messenger;
    RoundaboutController * rCont;
    NSMutableArray * m_connectionIdArray;
}

@end

@implementation SocketRoundaboutTransferTests

- (void) setUp {
    [super setUp];
    
    messenger = [[KSMessenger alloc] initWithBodyID:self withSelector:@selector(receiver:) withName:TEST_MASTER];
    rCont = [[RoundaboutController alloc]initWithMaster:[messenger myNameAndMID]];
    m_connectionIdArray = [[NSMutableArray alloc]init];
}

- (void) tearDown {
    [messenger closeConnection];
    [rCont exit];
    
    [super tearDown];
}

- (void) receiver:(NSNotification * )notif {
    NSDictionary * dict = [messenger tagValueDictionaryFromNotification:notif];
    switch ([messenger execFrom:KS_ROUNDABOUTCONT viaNotification:notif]) {
        case KS_ROUNDABOUTCONT_CONNECT_ESTABLISHED:{
            NSAssert(dict[@"connectionId"], @"connectionId required");
            [m_connectionIdArray addObject:dict[@"connectionId"]];
            break;
        }
        default:
            break;
    }
}

/**
 prefix-postfixに対する値チェック
 */
- (void) testTransferHasValidValue {
    SRTransfer * trans = [[SRTransfer alloc] initWithPrefix:TEST_PREFIX postfix:TEST_POSTFIX];
    
    NSString * expected = [[NSString alloc]initWithFormat:@"%@%@%@", TEST_PREFIX, TEST_MESSAGE, TEST_POSTFIX];
    STAssertTrue([[trans through:TEST_MESSAGE] isEqualToString:expected], @"not match, %@", [trans through:TEST_MESSAGE]);
}

/**
 transferArrayについての、連続変換値チェック
 単体
 */
- (void) testTransferArrayThroughsSingle {
    SRTransfer * trans = [[SRTransfer alloc] initWithPrefix:TEST_PREFIX postfix:TEST_POSTFIX];
    
    SRTransferArray * array = [[SRTransferArray alloc]init];
    [array addTransfer:trans];
    
    NSString * expected = [[NSString alloc]initWithFormat:@"%@%@%@", TEST_PREFIX, TEST_MESSAGE, TEST_POSTFIX];
    STAssertTrue([[array throughs:TEST_MESSAGE] isEqualToString:expected], @"not match, %@", [array throughs:TEST_MESSAGE]);
}


/**
 連続1
 */
- (void) testTransferArrayThroughsMulti {
    SRTransferArray * array = [[SRTransferArray alloc]init];
    
    for (int i = 0; i < 2; i++) {
        SRTransfer * trans = [[SRTransfer alloc] initWithPrefix:TEST_PREFIX postfix:TEST_POSTFIX];
        [array addTransfer:trans];
    }
    
    NSString * expected0 = [[NSString alloc]initWithFormat:@"%@%@%@", TEST_PREFIX, TEST_MESSAGE, TEST_POSTFIX];
    NSString * expected1 = [[NSString alloc]initWithFormat:@"%@%@%@", TEST_PREFIX, expected0, TEST_POSTFIX];
    STAssertTrue([[array throughs:TEST_MESSAGE] isEqualToString:expected1], @"not match, %@", [array throughs:TEST_MESSAGE]);
}

/**
 連続2
 */
- (void) testTransferArrayThroughsMulti2 {
    SRTransferArray * array = [[SRTransferArray alloc]init];
    
    for (int i = 0; i < 3; i++) {
        SRTransfer * trans = [[SRTransfer alloc] initWithPrefix:TEST_PREFIX postfix:TEST_POSTFIX];
        [array addTransfer:trans];
    }
    
    NSString * expected0 = [[NSString alloc]initWithFormat:@"%@%@%@", TEST_PREFIX, TEST_MESSAGE, TEST_POSTFIX];
    NSString * expected1 = [[NSString alloc]initWithFormat:@"%@%@%@", TEST_PREFIX, expected0, TEST_POSTFIX];
    NSString * expected2 = [[NSString alloc]initWithFormat:@"%@%@%@", TEST_PREFIX, expected1, TEST_POSTFIX];
    STAssertTrue([[array throughs:TEST_MESSAGE] isEqualToString:expected2], @"not match, %@", [array throughs:TEST_MESSAGE]);
}



/**
 存在するA,B間に対して、フィルタをセット、設置を確認
 */
- (void) testSetTransferFromAToBCheckTransferSet {
    //1
    [messenger call:KS_ROUNDABOUTCONT withExec:KS_ROUNDABOUTCONT_CONNECT,
     [messenger tag:@"connectionTargetAddr" val:TEST_WEBSOCKETSERVER],
     [messenger tag:@"connectionId" val:TEST_CONNECTIONIDENTITY_3],
     [messenger tag:@"connectionType" val:[NSNumber numberWithInt:KS_ROUNDABOUTCONT_CONNECTION_TYPE_WEBSOCKET]],
     nil];
    
    //2
    [messenger call:KS_ROUNDABOUTCONT withExec:KS_ROUNDABOUTCONT_CONNECT,
     [messenger tag:@"connectionTargetAddr" val:TEST_WEBSOCKETSERVER],
     [messenger tag:@"connectionId" val:TEST_CONNECTIONIDENTITY_4],
     [messenger tag:@"connectionType" val:[NSNumber numberWithInt:KS_ROUNDABOUTCONT_CONNECTION_TYPE_WEBSOCKET]],
     nil];
    
    int i = 0;
    while ([m_connectionIdArray count] < 1) {
        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1.0]];
        i++;
        if (TEST_TIMELIMIT < i) {
            STFail(@"too long wait");
            break;
        }
    }
    
    //connect
    [rCont outFrom:TEST_CONNECTIONIDENTITY_3 into:TEST_CONNECTIONIDENTITY_4];
    
    //transferをセットする
    [rCont setTransferFrom:TEST_CONNECTIONIDENTITY_3 to:TEST_CONNECTIONIDENTITY_4 prefix:TEST_PREFIX postfix:TEST_POSTFIX];
    
    //transferの設置が確認できる
    NSArray * actual = [rCont transfersBetweenOutput:TEST_CONNECTIONIDENTITY_3 toInput:TEST_CONNECTIONIDENTITY_4];
    STAssertTrue([actual count] == 1, @"not match, %d", [actual count]);
}


/**
 存在するA,B間に対して、フィルタをセット、動作を確認、メッセージを投げて、カウントが上がる
 */
- (void) testSetTransferFromAToBCheckTransferWorks {
    //1
    [messenger call:KS_ROUNDABOUTCONT withExec:KS_ROUNDABOUTCONT_CONNECT,
     [messenger tag:@"connectionTargetAddr" val:TEST_WEBSOCKETSERVER],
     [messenger tag:@"connectionId" val:TEST_CONNECTIONIDENTITY_3],
     [messenger tag:@"connectionType" val:[NSNumber numberWithInt:KS_ROUNDABOUTCONT_CONNECTION_TYPE_WEBSOCKET]],
     nil];
    
    //2
    [messenger call:KS_ROUNDABOUTCONT withExec:KS_ROUNDABOUTCONT_CONNECT,
     [messenger tag:@"connectionTargetAddr" val:TEST_WEBSOCKETSERVER],
     [messenger tag:@"connectionId" val:TEST_CONNECTIONIDENTITY_4],
     [messenger tag:@"connectionType" val:[NSNumber numberWithInt:KS_ROUNDABOUTCONT_CONNECTION_TYPE_WEBSOCKET]],
     nil];
    
    int i = 0;
    while ([m_connectionIdArray count] < 1) {
        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1.0]];
        i++;
        if (TEST_TIMELIMIT < i) {
            STFail(@"too long wait");
            break;
        }
    }
    
    //connect
    [rCont outFrom:TEST_CONNECTIONIDENTITY_3 into:TEST_CONNECTIONIDENTITY_4];
    
    //transferをセットする
    [rCont setTransferFrom:TEST_CONNECTIONIDENTITY_3 to:TEST_CONNECTIONIDENTITY_4 prefix:TEST_PREFIX postfix:TEST_POSTFIX];
    
    
    //WebSocketのTEST_CONNECTIONIDENTITY_3へとダミーメッセージ送付
    NSString * message = TEST_MESSAGE;
    [rCont dummyOutput:TEST_CONNECTIONIDENTITY_3 message:message];
    
    //メッセージの移動(通過)が確認できる。ダミーを介してC3からC4にメッセージが届く
    STAssertTrue([rCont transitInputCount:TEST_CONNECTIONIDENTITY_4] == 1, @"not match, %d", [rCont transitInputCount:TEST_CONNECTIONIDENTITY_4]);
}

/**
 存在しないA,C間に対して、トランスファーセット
 */
- (void) testSetTransferFromAToNotExistC {
    //1
    [messenger call:KS_ROUNDABOUTCONT withExec:KS_ROUNDABOUTCONT_CONNECT,
     [messenger tag:@"connectionTargetAddr" val:TEST_WEBSOCKETSERVER],
     [messenger tag:@"connectionId" val:TEST_CONNECTIONIDENTITY_3],
     [messenger tag:@"connectionType" val:[NSNumber numberWithInt:KS_ROUNDABOUTCONT_CONNECTION_TYPE_WEBSOCKET]],
     nil];
    
    //2
    [messenger call:KS_ROUNDABOUTCONT withExec:KS_ROUNDABOUTCONT_CONNECT,
     [messenger tag:@"connectionTargetAddr" val:TEST_WEBSOCKETSERVER],
     [messenger tag:@"connectionId" val:TEST_CONNECTIONIDENTITY_4],
     [messenger tag:@"connectionType" val:[NSNumber numberWithInt:KS_ROUNDABOUTCONT_CONNECTION_TYPE_WEBSOCKET]],
     nil];
    
    int i = 0;
    while ([m_connectionIdArray count] < 1) {
        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1.0]];
        i++;
        if (TEST_TIMELIMIT < i) {
            STFail(@"too long wait");
            break;
        }
    }
    
    //connect
    [rCont outFrom:TEST_CONNECTIONIDENTITY_3 into:TEST_CONNECTIONIDENTITY_4];
    
    @try {
        //存在しないTEST_CONNECTIONIDENTITY_5に対して、transferをセットする
        [rCont setTransferFrom:TEST_CONNECTIONIDENTITY_3 to:TEST_CONNECTIONIDENTITY_5 prefix:TEST_PREFIX postfix:TEST_POSTFIX];
        STFail(@"no error, but failure. error should be occer");
    }
    @catch (NSException *exception) {}
    @finally {}
}


/**
 一つの接続に対して、複数のフィルタをセット
 フィルタは順に動作する。必ず通過(空白文字、空文字)する。->通過カウントが上がる
 */
- (void) testMultiTransferSetInOneTransit {
    //1
    [messenger call:KS_ROUNDABOUTCONT withExec:KS_ROUNDABOUTCONT_CONNECT,
     [messenger tag:@"connectionTargetAddr" val:TEST_WEBSOCKETSERVER],
     [messenger tag:@"connectionId" val:TEST_CONNECTIONIDENTITY_3],
     [messenger tag:@"connectionType" val:[NSNumber numberWithInt:KS_ROUNDABOUTCONT_CONNECTION_TYPE_WEBSOCKET]],
     nil];
    
    //2
    [messenger call:KS_ROUNDABOUTCONT withExec:KS_ROUNDABOUTCONT_CONNECT,
     [messenger tag:@"connectionTargetAddr" val:TEST_WEBSOCKETSERVER],
     [messenger tag:@"connectionId" val:TEST_CONNECTIONIDENTITY_4],
     [messenger tag:@"connectionType" val:[NSNumber numberWithInt:KS_ROUNDABOUTCONT_CONNECTION_TYPE_WEBSOCKET]],
     nil];
    
    int i = 0;
    while ([m_connectionIdArray count] < 1) {
        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1.0]];
        i++;
        if (TEST_TIMELIMIT < i) {
            STFail(@"too long wait");
            break;
        }
    }

    //connect
    [rCont outFrom:TEST_CONNECTIONIDENTITY_3 into:TEST_CONNECTIONIDENTITY_4];
    
    //transfer
    [rCont setTransferFrom:TEST_CONNECTIONIDENTITY_3 to:TEST_CONNECTIONIDENTITY_4 prefix:TEST_PREFIX postfix:TEST_POSTFIX];
    [rCont setTransferFrom:TEST_CONNECTIONIDENTITY_3 to:TEST_CONNECTIONIDENTITY_4 prefix:TEST_PREFIX2 postfix:TEST_POSTFIX2];
    
    //ダミーのoutput
    [rCont dummyOutput:TEST_CONNECTIONIDENTITY_3 message:TEST_MESSAGE];
    
    //メッセージの移動(通過)が確認できる。ダミーを介してC3からC4にメッセージが届く
    STAssertTrue([rCont transitInputCount:TEST_CONNECTIONIDENTITY_4] == 1, @"not match, %d", [rCont transitInputCount:TEST_CONNECTIONIDENTITY_4]);
}

/**
 複数の接続に対して、それぞれにフィルタをセット
 */
- (void) testMultiTransferSetSingleTransit {
    //1
    [messenger call:KS_ROUNDABOUTCONT withExec:KS_ROUNDABOUTCONT_CONNECT,
     [messenger tag:@"connectionTargetAddr" val:TEST_WEBSOCKETSERVER],
     [messenger tag:@"connectionId" val:TEST_CONNECTIONIDENTITY_3],
     [messenger tag:@"connectionType" val:[NSNumber numberWithInt:KS_ROUNDABOUTCONT_CONNECTION_TYPE_WEBSOCKET]],
     nil];
    
    //2
    [messenger call:KS_ROUNDABOUTCONT withExec:KS_ROUNDABOUTCONT_CONNECT,
     [messenger tag:@"connectionTargetAddr" val:TEST_WEBSOCKETSERVER],
     [messenger tag:@"connectionId" val:TEST_CONNECTIONIDENTITY_4],
     [messenger tag:@"connectionType" val:[NSNumber numberWithInt:KS_ROUNDABOUTCONT_CONNECTION_TYPE_WEBSOCKET]],
     nil];
    
    //3
    [messenger call:KS_ROUNDABOUTCONT withExec:KS_ROUNDABOUTCONT_CONNECT,
     [messenger tag:@"connectionTargetAddr" val:TEST_WEBSOCKETSERVER],
     [messenger tag:@"connectionId" val:TEST_CONNECTIONIDENTITY_5],
     [messenger tag:@"connectionType" val:[NSNumber numberWithInt:KS_ROUNDABOUTCONT_CONNECTION_TYPE_WEBSOCKET]],
     nil];
    
    //4
    [messenger call:KS_ROUNDABOUTCONT withExec:KS_ROUNDABOUTCONT_CONNECT,
     [messenger tag:@"connectionTargetAddr" val:TEST_WEBSOCKETSERVER],
     [messenger tag:@"connectionId" val:TEST_CONNECTIONIDENTITY_6],
     [messenger tag:@"connectionType" val:[NSNumber numberWithInt:KS_ROUNDABOUTCONT_CONNECTION_TYPE_WEBSOCKET]],
     nil];
    
    
    int i = 0;
    while ([m_connectionIdArray count] < 2) {
        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1.0]];
        i++;
        if (TEST_TIMELIMIT < i) {
            STFail(@"too long wait");
            break;
        }
    }
    
    //connect
    [rCont outFrom:TEST_CONNECTIONIDENTITY_3 into:TEST_CONNECTIONIDENTITY_4];
    [rCont outFrom:TEST_CONNECTIONIDENTITY_5 into:TEST_CONNECTIONIDENTITY_6];
    

    //transfer
    [rCont setTransferFrom:TEST_CONNECTIONIDENTITY_3 to:TEST_CONNECTIONIDENTITY_4 prefix:TEST_PREFIX postfix:TEST_POSTFIX];
    [rCont setTransferFrom:TEST_CONNECTIONIDENTITY_5 to:TEST_CONNECTIONIDENTITY_6 prefix:TEST_PREFIX postfix:TEST_POSTFIX];

    
    //ダミーメッセージを各outから流す
    [rCont dummyOutput:TEST_CONNECTIONIDENTITY_3 message:TEST_MESSAGE];
    [rCont dummyOutput:TEST_CONNECTIONIDENTITY_5 message:TEST_MESSAGE];
    
    //メッセージの移動(通過)が確認できる。ダミーを介してoutからinにメッセージが届く
    STAssertTrue([rCont transitInputCount:TEST_CONNECTIONIDENTITY_4] == 1, @"not match, %d", [rCont transitInputCount:TEST_CONNECTIONIDENTITY_4]);
    STAssertTrue([rCont transitInputCount:TEST_CONNECTIONIDENTITY_6] == 1, @"not match, %d", [rCont transitInputCount:TEST_CONNECTIONIDENTITY_6]);
}


/**
 複数の接続に対して、それぞれに複数のフィルタをセット
 */
- (void) testMultiTransferSetMultiTransit {
    //1
    [messenger call:KS_ROUNDABOUTCONT withExec:KS_ROUNDABOUTCONT_CONNECT,
     [messenger tag:@"connectionTargetAddr" val:TEST_WEBSOCKETSERVER],
     [messenger tag:@"connectionId" val:TEST_CONNECTIONIDENTITY_3],
     [messenger tag:@"connectionType" val:[NSNumber numberWithInt:KS_ROUNDABOUTCONT_CONNECTION_TYPE_WEBSOCKET]],
     nil];
    
    //2
    [messenger call:KS_ROUNDABOUTCONT withExec:KS_ROUNDABOUTCONT_CONNECT,
     [messenger tag:@"connectionTargetAddr" val:TEST_WEBSOCKETSERVER],
     [messenger tag:@"connectionId" val:TEST_CONNECTIONIDENTITY_4],
     [messenger tag:@"connectionType" val:[NSNumber numberWithInt:KS_ROUNDABOUTCONT_CONNECTION_TYPE_WEBSOCKET]],
     nil];
    
    //3
    [messenger call:KS_ROUNDABOUTCONT withExec:KS_ROUNDABOUTCONT_CONNECT,
     [messenger tag:@"connectionTargetAddr" val:TEST_WEBSOCKETSERVER],
     [messenger tag:@"connectionId" val:TEST_CONNECTIONIDENTITY_5],
     [messenger tag:@"connectionType" val:[NSNumber numberWithInt:KS_ROUNDABOUTCONT_CONNECTION_TYPE_WEBSOCKET]],
     nil];
    
    //4
    [messenger call:KS_ROUNDABOUTCONT withExec:KS_ROUNDABOUTCONT_CONNECT,
     [messenger tag:@"connectionTargetAddr" val:TEST_WEBSOCKETSERVER],
     [messenger tag:@"connectionId" val:TEST_CONNECTIONIDENTITY_6],
     [messenger tag:@"connectionType" val:[NSNumber numberWithInt:KS_ROUNDABOUTCONT_CONNECTION_TYPE_WEBSOCKET]],
     nil];
    
    
    int i = 0;
    while ([m_connectionIdArray count] < 2) {
        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1.0]];
        i++;
        if (TEST_TIMELIMIT < i) {
            STFail(@"too long wait");
            break;
        }
    }
    
    //connect
    [rCont outFrom:TEST_CONNECTIONIDENTITY_3 into:TEST_CONNECTIONIDENTITY_4];
    [rCont outFrom:TEST_CONNECTIONIDENTITY_5 into:TEST_CONNECTIONIDENTITY_6];
    
    
    //transfer
    [rCont setTransferFrom:TEST_CONNECTIONIDENTITY_3 to:TEST_CONNECTIONIDENTITY_4 prefix:TEST_PREFIX postfix:TEST_POSTFIX];
    [rCont setTransferFrom:TEST_CONNECTIONIDENTITY_3 to:TEST_CONNECTIONIDENTITY_4 prefix:TEST_PREFIX postfix:TEST_POSTFIX];

    [rCont setTransferFrom:TEST_CONNECTIONIDENTITY_5 to:TEST_CONNECTIONIDENTITY_6 prefix:TEST_PREFIX postfix:TEST_POSTFIX];
    [rCont setTransferFrom:TEST_CONNECTIONIDENTITY_5 to:TEST_CONNECTIONIDENTITY_6 prefix:TEST_PREFIX postfix:TEST_POSTFIX];
    
    
    //ダミーメッセージを各outから流す
    [rCont dummyOutput:TEST_CONNECTIONIDENTITY_3 message:TEST_MESSAGE];
    [rCont dummyOutput:TEST_CONNECTIONIDENTITY_5 message:TEST_MESSAGE];
    
    //メッセージの移動(通過)が確認できる。ダミーを介してoutからinにメッセージが届く
    STAssertTrue([rCont transitInputCount:TEST_CONNECTIONIDENTITY_4] == 1, @"not match, %d", [rCont transitInputCount:TEST_CONNECTIONIDENTITY_4]);
    STAssertTrue([rCont transitInputCount:TEST_CONNECTIONIDENTITY_6] == 1, @"not match, %d", [rCont transitInputCount:TEST_CONNECTIONIDENTITY_6]);
}



@end
