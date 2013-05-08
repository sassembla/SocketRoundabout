//
//  SocketRoundaboutTests.h
//  SocketRoundaboutTests
//
//  Created by sassembla on 2013/04/17.
//  Copyright (c) 2013年 KISSAKI Inc,. All rights reserved.
//

#import <SenTestingKit/SenTestingKit.h>
#import "KSMessenger.h"

#import "RoundaboutController.h"

#define VERSION (@"0.5.0")

#define TEST_MASTER (@"TEST_MASTER_2013/04/28_22:26:38")

#define TEST_WEBSOCKETSERVER   (@"ws://127.0.0.1:8823")

#define TEST_NOTIFICATIONSERVER  (@"notif://2013/04/29_17:52:05")
#define TEST_NOTIFICATIONSERVER_2   (@"notif://2013/05/08_18:22:35")

#define TEST_CONNECTIONIDENTITY_1 (@"roundaboutTest1")
#define TEST_CONNECTIONIDENTITY_2   (@"roundaboutTest2")

#define TEST_TIMELIMIT  (3)
#define TEST_TIMELIMIT_LONG (5)
#define TEST_REFLECTIVE_MESSAGE (@"ss@broadcastMessage:{\"message\":\"MESSAGE_2013/04/29 17:34:39\"}")

#define NNOTIF  (@"./tool/nnotif")//pwd = project-folder path.
#define NNOTIFD (@"/Users/sassembla/Library/Developer/Xcode/DerivedData/nnotifd-ahjyuqfrcnbezcaagbkmwszlhqlj/Build/Products/Debug/nnotifd.app/Contents/MacOS/nnotifd")

#define TEST_NNOTIFD_ID (@"NNOTIFD_2013/05/02 19:00:10")
#define TEST_NNOTIFD_ID_MANUAL  (@"NNOTIFD_IDENTITY")

#define TEST_NNOTIFD_LOG    (@"./nnotifd.log")

#define TEST_NNOTIF_LOG (@"./nnotif.log")


#define GLOBAL_NNOTIF   (@"/Users/sassembla/Desktop/nnotifd/tool/nnotif")

#define TEST_DISTNOTIF_MESSAGE  (@"TEST_DISTNOTIF_MESSAGE_2013/04/29_17:57:57")

@interface TestDistNotificationSender2 : NSObject @end
@implementation TestDistNotificationSender2

- (void) sendNotification:(NSString * )identity withMessage:(NSString * )message withKey:(NSString * )key {
    
    NSArray * clArray = @[@"-v", @"-o", TEST_NNOTIF_LOG, @"-t", identity, @"-k", key, @"-i", message];
    
    NSTask * task1 = [[NSTask alloc] init];
    [task1 setLaunchPath:NNOTIF];
    [task1 setArguments:clArray];
    [task1 launch];
    [task1 waitUntilExit];
}
@end


@interface TestRunNNOTIFD : NSObject @end
@implementation TestRunNNOTIFD

- (void) launchNnotifd:(NSString * )identity {
    
    NSArray * clArray = @[@"-i", identity, @"-o", TEST_NNOTIFD_LOG, @"-c", @"start"];
    
    NSTask * task1 = [[NSTask alloc] init];
    [task1 setLaunchPath:NNOTIFD];
    [task1 setArguments:clArray];
    [task1 launch];
}
@end


@interface SocketRoundaboutTests : SenTestCase {
    KSMessenger * messenger;
    RoundaboutController * rCont;
    NSMutableArray * m_connectionIdArray;
}

@end


@implementation SocketRoundaboutTests

- (void) setUp {
    [super setUp];
    
    messenger = [[KSMessenger alloc] initWithBodyID:self withSelector:@selector(receiver:) withName:TEST_MASTER];
    rCont = [[RoundaboutController alloc]initWithMaster:[messenger myNameAndMID]];
    m_connectionIdArray = [[NSMutableArray alloc]init];
}

- (void) tearDown {
    [messenger closeConnection];
    [rCont closeAllConnections];
    [rCont exit];
    [m_connectionIdArray removeAllObjects];

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
 WebSocket 1,2が接続完了後に相互接続
 */
- (void) testConnectWebSocket_1And2 {
    //1
    [messenger call:KS_ROUNDABOUTCONT withExec:KS_ROUNDABOUTCONT_CONNECT,
     [messenger tag:@"connectionTargetAddr" val:TEST_WEBSOCKETSERVER],
     [messenger tag:@"connectionId" val:TEST_CONNECTIONIDENTITY_1],
     [messenger tag:@"connectionType" val:[NSNumber numberWithInt:KS_ROUNDABOUTCONT_CONNECTION_TYPE_WEBSOCKET]],
     nil];

    //2
    [messenger call:KS_ROUNDABOUTCONT withExec:KS_ROUNDABOUTCONT_CONNECT,
     [messenger tag:@"connectionTargetAddr" val:TEST_WEBSOCKETSERVER],
     [messenger tag:@"connectionId" val:TEST_CONNECTIONIDENTITY_2],
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
    [rCont outFrom:TEST_CONNECTIONIDENTITY_1 into:TEST_CONNECTIONIDENTITY_2];
    
    //設定を取得
    NSArray * out1 = [rCont outputsOf:TEST_CONNECTIONIDENTITY_1];
    STAssertTrue([out1 count] == 1, @"not match, %d", [out1 count]);

    NSArray * in2 = [rCont inputsOf:TEST_CONNECTIONIDENTITY_2];
    STAssertTrue([in2 count] == 1, @"not match, %d", [in2 count]);
}

/**
 WebSocket 1,2が接続完了後、broadcastを開始(どこかで反射をやめる機構を用意しないとアレだが、今回は無限反射を回数で落とす。)
 コイツ自体にemit能力は無いので、WSServerへと、「接続している全Clientへとメッセージ送付」を利用する。
 */
- (void) testConnectWebSocket_1And2_Then_SendData {
    //1
    [messenger call:KS_ROUNDABOUTCONT withExec:KS_ROUNDABOUTCONT_CONNECT,
     [messenger tag:@"connectionTargetAddr" val:TEST_WEBSOCKETSERVER],
     [messenger tag:@"connectionId" val:TEST_CONNECTIONIDENTITY_1],
     [messenger tag:@"connectionType" val:[NSNumber numberWithInt:KS_ROUNDABOUTCONT_CONNECTION_TYPE_WEBSOCKET]],
     nil];
    
    //2
    [messenger call:KS_ROUNDABOUTCONT withExec:KS_ROUNDABOUTCONT_CONNECT,
     [messenger tag:@"connectionTargetAddr" val:TEST_WEBSOCKETSERVER],
     [messenger tag:@"connectionId" val:TEST_CONNECTIONIDENTITY_2],
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
    [rCont outFrom:TEST_CONNECTIONIDENTITY_1 into:TEST_CONNECTIONIDENTITY_2];
    
    /*
     ServerへとC1からbroadcastを実行。
     C1 -> Server -> C1,C2
     1,2ともに受け取るが、1のみout、2のみinを持っているので、
     ->C1 -> (SocketRoundabout) -> C2 となるようにする。
     */
    
    //debug用の直接送信
    [rCont dummyOutput:TEST_CONNECTIONIDENTITY_1 message:TEST_REFLECTIVE_MESSAGE];
    
    while ([rCont transitOutputCount:TEST_CONNECTIONIDENTITY_1] == 0) {
        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1.0]];
    }
    //C1 -> C2へと通達が行き、サーバへとinputを行ってしまうため、C1が一通受け取った時点で、待つのをやめる。
    
    //C1にメッセージが届いている。内容は、TEST_REFLECTIVE_MESSAGEのmessageの中身。
    STAssertTrue([rCont transitOutputCount:TEST_CONNECTIONIDENTITY_1] == 1, @"not match, %d", [rCont transitOutputCount:TEST_CONNECTIONIDENTITY_1]);
    
    //C2にメッセージが、C1から届く
    STAssertTrue([rCont transitInputCount:TEST_CONNECTIONIDENTITY_2] == 1, @"not match, %d", [rCont transitInputCount:TEST_CONNECTIONIDENTITY_2]);
    
    //Serverへとメッセージが届く(この部分はSRWebSocketが担保)
}

/**
 DistNotificationとWebSocketの接続
 */
- (void) testConnectionWebSocket_1And2_Reserve {
    //1
    [messenger call:KS_ROUNDABOUTCONT withExec:KS_ROUNDABOUTCONT_CONNECT,
     [messenger tag:@"connectionTargetAddr" val:TEST_NOTIFICATIONSERVER],
     [messenger tag:@"connectionId" val:TEST_CONNECTIONIDENTITY_1],
     [messenger tag:@"connectionType" val:[NSNumber numberWithInt:KS_ROUNDABOUTCONT_CONNECTION_TYPE_NOTIFICATION]],
     nil];
    
    //2
    [messenger call:KS_ROUNDABOUTCONT withExec:KS_ROUNDABOUTCONT_CONNECT,
     [messenger tag:@"connectionTargetAddr" val:TEST_WEBSOCKETSERVER],
     [messenger tag:@"connectionId" val:TEST_CONNECTIONIDENTITY_2],
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
    [rCont outFrom:TEST_CONNECTIONIDENTITY_1 into:TEST_CONNECTIONIDENTITY_2];
    
    /*
     C1へと別プロセスからDistNotificationを実行。
     other -> C1(DistNotif) -> (SocketRoundabout) -> C2(WS) となるようにする。
     */
    
    //debug用の直接送信
    //sender
    TestDistNotificationSender2 * sender = [[TestDistNotificationSender2 alloc]init];
    
    
    //送付
    [sender sendNotification:TEST_NOTIFICATIONSERVER withMessage:TEST_DISTNOTIF_MESSAGE withKey:@"message"];
    
    while ([rCont transitOutputCount:TEST_CONNECTIONIDENTITY_1] == 0) {
        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1.0]];
    }

    
    //C1にメッセージが届いている。内容は、TEST_DISTNOTIF_MESSAGE
    STAssertTrue([rCont transitOutputCount:TEST_CONNECTIONIDENTITY_1] == 1, @"not match, %d", [rCont transitOutputCount:TEST_CONNECTIONIDENTITY_1]);
    
    //C2にメッセージが、C1から届く
    STAssertTrue([rCont transitInputCount:TEST_CONNECTIONIDENTITY_2] == 1, @"not match, %d", [rCont transitInputCount:TEST_CONNECTIONIDENTITY_2]);
    
    //Serverへとメッセージが届く(この部分はSRWebSocketが担保)
}


/**
 nnotifd用Unitl NS系の文字列をesacpeしたJSONArrayに変える。
 */
- (NSString * ) jsonizedString:(NSArray * )jsonSourceArray {
    
    //add before-" and after-"
    NSMutableArray * addHeadAndTailQuote = [[NSMutableArray alloc]init];
    for (NSString * item in jsonSourceArray) {
        [addHeadAndTailQuote addObject:[NSString stringWithFormat:@"\"%@\"", item]];
    }
    
    //concat with ,
    NSString * concatted = [addHeadAndTailQuote componentsJoinedByString:@","];
    return [[NSString alloc] initWithFormat:@"%@[%@]", @"nn:", concatted];
}

/**
 DistNotifからpwdを受けて、DistNotif入力、WebSocket出力へと繋ぐ
 */
- (void) testReceivePwdNotifThenOutputToWebSocket {
    //1
    [messenger call:KS_ROUNDABOUTCONT withExec:KS_ROUNDABOUTCONT_CONNECT,
     [messenger tag:@"connectionTargetAddr" val:TEST_NOTIFICATIONSERVER],
     [messenger tag:@"connectionId" val:TEST_CONNECTIONIDENTITY_1],
     [messenger tag:@"connectionType" val:[NSNumber numberWithInt:KS_ROUNDABOUTCONT_CONNECTION_TYPE_NOTIFICATION]],
     nil];
    
    //2
    [messenger call:KS_ROUNDABOUTCONT withExec:KS_ROUNDABOUTCONT_CONNECT,
     [messenger tag:@"connectionTargetAddr" val:TEST_WEBSOCKETSERVER],
     [messenger tag:@"connectionId" val:TEST_CONNECTIONIDENTITY_2],
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
    [rCont outFrom:TEST_CONNECTIONIDENTITY_1 into:TEST_CONNECTIONIDENTITY_2];
    
    //接続送信
    //nnotifdを起動
    TestRunNNOTIFD * nnotifdRunner = [[TestRunNNOTIFD alloc]init];
    [nnotifdRunner launchNnotifd:TEST_NNOTIFD_ID];
    
    //nnotifでnnotifdにビルド信号を送り込む
    TestDistNotificationSender2 * nnotifSender = [[TestDistNotificationSender2 alloc]init];

    NSArray * execsArray = @[@"/bin/pwd", @"|", NNOTIF, @"-t", TEST_NOTIFICATIONSERVER, @"-v", @"-o", TEST_NNOTIF_LOG, @"--ignorebl"];
    
    //notifでexecuteを送り込む
    NSArray * execArray = @[@"nn@", @"-e",[self jsonizedString:execsArray]];
    NSString * exec = [execArray componentsJoinedByString:@" "];

    
    [nnotifSender sendNotification:TEST_NNOTIFD_ID withMessage:exec withKey:@"NN_DEFAULT_ROUTE"];

    i = 0;
    while ([rCont transitInputCount:TEST_CONNECTIONIDENTITY_2] == 0) {
        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1.0]];
        i++;
        if (TEST_TIMELIMIT < i) {
            STFail(@"too long wait");
            break;
        }
    }
    
    //通過すればOK
    
    //nnotifdをkillする
    NSArray * execArray2 = @[@"nn@", @"-kill"];
    NSString * exec2 = [execArray2 componentsJoinedByString:@" "];

    [nnotifSender sendNotification:TEST_NNOTIFD_ID withMessage:exec2 withKey:@"NN_DEFAULT_ROUTE"];
}

///**
// DistNotifからgradle -iを受けて、DistNotif入力、WebSocket出力へと繋ぐ
// →権限の問題か、gradle自体がエラーを出す。これ以上は追えない。
// */
//- (void) testReceiveGradleNotifThenOutputToWebSocket {
//    //1
//    [messenger call:KS_ROUNDABOUTCONT withExec:KS_ROUNDABOUTCONT_CONNECT,
//     [messenger tag:@"connectionTargetAddr" val:TEST_NOTIFICATIONSERVER],
//     [messenger tag:@"connectionId" val:TEST_CONNECTIONIDENTITY_1],
//     [messenger tag:@"connectionType" val:[NSNumber numberWithInt:KS_ROUNDABOUTCONT_CONNECTION_TYPE_NOTIFICATION]],
//     nil];
//    
//    //2
//    [messenger call:KS_ROUNDABOUTCONT withExec:KS_ROUNDABOUTCONT_CONNECT,
//     [messenger tag:@"connectionTargetAddr" val:TEST_WEBSOCKETSERVER],
//     [messenger tag:@"connectionId" val:TEST_CONNECTIONIDENTITY_2],
//     [messenger tag:@"connectionType" val:[NSNumber numberWithInt:KS_ROUNDABOUTCONT_CONNECTION_TYPE_WEBSOCKET]],
//     nil];
//    
//    int i = 0;
//    while ([m_connectionIdArray count] < 2) {
//        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1.0]];
//        i++;
//        if (TEST_TIMELIMIT < i) {
//            STFail(@"too long wait");
//            break;
//        }
//    }
//    
//    //connect
//    [rCont outFrom:TEST_CONNECTIONIDENTITY_1 into:TEST_CONNECTIONIDENTITY_2];
//    
//    //接続送信
//    //nnotifdを起動
//    TestRunNNOTIFD * nnotifdRunner = [[TestRunNNOTIFD alloc]init];
//    [nnotifdRunner launchNnotifd:TEST_NNOTIFD_ID];
//    
//    //nnotifでnnotifdにビルド信号を送り込む
//    TestDistNotificationSender2 * nnotifSender = [[TestDistNotificationSender2 alloc]init];
//    
//    
//    NSArray * execsArray = @[@"/usr/local/bin/gradle", @"-b", @"/Users/sassembla/Desktop/HelloWorld/build.gradle", @"build", @"-i", @"|", GLOBAL_NNOTIF, @"-t", TEST_NOTIFICATIONSERVER];
//    
//    //notifでexecuteを送り込む
//    NSArray * execArray = @[@"nn@", @"-e",[self jsonizedString:execsArray]];
//    NSString * exec = [execArray componentsJoinedByString:@" "];
//    
//    
//    [nnotifSender sendNotification:TEST_NNOTIFD_ID withMessage:exec withKey:@"NN_DEFAULT_ROUTE"];
//    
//    //単純に待つ
//    i = 0;
//    while ([rCont transitInputCount:TEST_CONNECTIONIDENTITY_2] == 0) {
//        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1.0]];
//        i++;
//        if (TEST_TIMELIMIT < i) {
//            STFail(@"too long wait");
//            break;
//        }
//    }
//    
//    STAssertTrue(0 < [rCont transitInputCount:TEST_CONNECTIONIDENTITY_2], @"not match, %d", [rCont transitInputCount:TEST_CONNECTIONIDENTITY_2]);
//    
//    //nnotifdをkillする
//    NSArray * execArray2 = @[@"nn@", @"-kill"];
//    NSString * exec2 = [execArray2 componentsJoinedByString:@" "];
//    
//    [nnotifSender sendNotification:TEST_NNOTIFD_ID withMessage:exec2 withKey:@"NN_DEFAULT_ROUTE"];
//}


/**
 事前にnnotifdを特定条件で立ち上げておくと動作する。
 */
- (void) testReceiveGradleNotifThenOutputToWebSocket_MANUALLY {
    //1
    [messenger call:KS_ROUNDABOUTCONT withExec:KS_ROUNDABOUTCONT_CONNECT,
     [messenger tag:@"connectionTargetAddr" val:TEST_NOTIFICATIONSERVER],
     [messenger tag:@"connectionId" val:TEST_CONNECTIONIDENTITY_1],
     [messenger tag:@"connectionType" val:[NSNumber numberWithInt:KS_ROUNDABOUTCONT_CONNECTION_TYPE_NOTIFICATION]],
     nil];
    
    //2
    [messenger call:KS_ROUNDABOUTCONT withExec:KS_ROUNDABOUTCONT_CONNECT,
     [messenger tag:@"connectionTargetAddr" val:TEST_WEBSOCKETSERVER],
     [messenger tag:@"connectionId" val:TEST_CONNECTIONIDENTITY_2],
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
    [rCont outFrom:TEST_CONNECTIONIDENTITY_1 into:TEST_CONNECTIONIDENTITY_2];
    
    
    //ここまでで、nnotifdを人力で起動させないと駄目だ -i = NNOTIFD_IDENTITY(TEST_NNOTIFD_ID_MANUAL)
    //プロセスチェックとかすれば、まあ、、
    
    //nnotifでnnotifdにビルド信号を送り込む
    TestDistNotificationSender2 * nnotifSender = [[TestDistNotificationSender2 alloc]init];
    
    //stdinを、SocketRoundaboutのNotifに向ける
    NSArray * execsArray = @[@"/usr/local/bin/gradle", @"-b", @"/Users/sassembla/Desktop/HelloWorld/build.gradle", @"build", @"-i", @"|", GLOBAL_NNOTIF, @"-t", TEST_NOTIFICATIONSERVER, @"--ignorebl"];

    //notifでexecuteを送り込む
    NSArray * execArray = @[@"nn@", @"-e",[self jsonizedString:execsArray]];
    NSString * exec = [execArray componentsJoinedByString:@" "];


    [nnotifSender sendNotification:TEST_NNOTIFD_ID_MANUAL withMessage:exec withKey:@"NN_DEFAULT_ROUTE"];

    //単純に待つ
    i = 0;
    while (i < TEST_TIMELIMIT_LONG) {
        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1.0]];
        i++;
        NSLog(@"waiting..%d", i);
        if (TEST_TIMELIMIT_LONG + TEST_TIMELIMIT < i) {
            STFail(@"too long wait");
            break;
        }
    }
    

    STAssertTrue(0 < [rCont transitInputCount:TEST_CONNECTIONIDENTITY_2], @"not match, %d", [rCont transitInputCount:TEST_CONNECTIONIDENTITY_2]);
}

/**
 手動面倒くさいので、shに纏めてみる版
 →そもテストのプロセスからnnotifdを起動しているのが駄目らしい。sudoならいいのか？とも思うが、めんどいのでパス。
 */
//- (void) testReceiveGradleNotifThenOutputToWebSocket_shelled {
//    //1
//    [messenger call:KS_ROUNDABOUTCONT withExec:KS_ROUNDABOUTCONT_CONNECT,
//     [messenger tag:@"connectionTargetAddr" val:TEST_NOTIFICATIONSERVER],
//     [messenger tag:@"connectionId" val:TEST_CONNECTIONIDENTITY_1],
//     [messenger tag:@"connectionType" val:[NSNumber numberWithInt:KS_ROUNDABOUTCONT_CONNECTION_TYPE_NOTIFICATION]],
//     nil];
//    
//    //2
//    [messenger call:KS_ROUNDABOUTCONT withExec:KS_ROUNDABOUTCONT_CONNECT,
//     [messenger tag:@"connectionTargetAddr" val:TEST_WEBSOCKETSERVER],
//     [messenger tag:@"connectionId" val:TEST_CONNECTIONIDENTITY_2],
//     [messenger tag:@"connectionType" val:[NSNumber numberWithInt:KS_ROUNDABOUTCONT_CONNECTION_TYPE_WEBSOCKET]],
//     nil];
//    
//    int i = 0;
//    while ([m_connectionIdArray count] < 2) {
//        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1.0]];
//        i++;
//        if (TEST_TIMELIMIT < i) {
//            STFail(@"too long wait");
//            break;
//        }
//    }
//    
//    //connect
//    [rCont outFrom:TEST_CONNECTIONIDENTITY_1 into:TEST_CONNECTIONIDENTITY_2];
//    
//    
//    
//    //接続送信
//    //nnotifdを起動
//    TestRunNNOTIFD * nnotifdRunner = [[TestRunNNOTIFD alloc]init];
//    [nnotifdRunner launchNnotifd:TEST_NNOTIFD_ID_MANUAL];
//
//    
//    
//    //nnotifでnnotifdにビルド信号を送り込む
//    TestDistNotificationSender2 * nnotifSender = [[TestDistNotificationSender2 alloc]init];
//    
//    //stdinを、SocketRoundaboutのNotifに向ける
//    NSArray * execsArray = @[@"/bin/sh", GLOBAL_GRADLE_NNOTIF_SHELL];//実行主の問題で、これでも不可能。
//    
//    //notifでexecuteを送り込む
//    NSArray * execArray = @[@"nn@", @"-e",[self jsonizedString:execsArray]];
//    NSString * exec = [execArray componentsJoinedByString:@" "];
//    
//    
//    [nnotifSender sendNotification:TEST_NNOTIFD_ID_MANUAL withMessage:exec withKey:@"NN_DEFAULT_ROUTE"];
//    
//    //単純に待つ
//    i = 0;
//    while ([rCont transitInputCount:TEST_CONNECTIONIDENTITY_2] == 0) {
//        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1.0]];
//        i++;
//        NSLog(@"waiting..%d", i);
//        if (TEST_TIMELIMIT < i) {
//            STFail(@"too long wait");
//            break;
//        }
//    }
//    
//    
//    STAssertTrue(0 < [rCont transitInputCount:TEST_CONNECTIONIDENTITY_2], @"not match, %d", [rCont transitInputCount:TEST_CONNECTIONIDENTITY_2]);
//    
//    //nnotifdをkillする
//    NSArray * execArray2 = @[@"nn@", @"-kill"];
//    NSString * exec2 = [execArray2 componentsJoinedByString:@" "];
//    
//    [nnotifSender sendNotification:TEST_NNOTIFD_ID_MANUAL withMessage:exec2 withKey:@"NN_DEFAULT_ROUTE"];
//}


/**
 DistNotifを出力する
 偽のIn、テスト対象としてのOutを設定して、送信直前のラインに割り込んで、送信を試す。
 */
- (void) testemitNotif {
    //偽In
    [messenger call:KS_ROUNDABOUTCONT withExec:KS_ROUNDABOUTCONT_CONNECT,
     [messenger tag:@"connectionTargetAddr" val:TEST_NOTIFICATIONSERVER],
     [messenger tag:@"connectionId" val:TEST_CONNECTIONIDENTITY_1],
     [messenger tag:@"connectionType" val:[NSNumber numberWithInt:KS_ROUNDABOUTCONT_CONNECTION_TYPE_NOTIFICATION]],
     nil];
    
    //out側
    [messenger call:KS_ROUNDABOUTCONT withExec:KS_ROUNDABOUTCONT_CONNECT,
     [messenger tag:@"connectionTargetAddr" val:TEST_NOTIFICATIONSERVER_2],
     [messenger tag:@"connectionId" val:TEST_CONNECTIONIDENTITY_2],
     [messenger tag:@"connectionType" val:[NSNumber numberWithInt:KS_ROUNDABOUTCONT_CONNECTION_TYPE_NOTIFICATION]],
     nil];
    
    
    //これらを接続
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
    [rCont outFrom:TEST_CONNECTIONIDENTITY_1 into:TEST_CONNECTIONIDENTITY_2];
    
    //接続後、接続の始点へとデータを投入
    [rCont dummyInput:TEST_CONNECTIONIDENTITY_1 message:TEST_DISTNOTIF_MESSAGE];
    

    //接続先であるTEST_CONNECTIONIDENTITY_2の送信カウンタは上がっている筈
    STAssertTrue([rCont transitInputCount:TEST_CONNECTIONIDENTITY_2] == 1, @"not match, %d", [rCont transitInputCount:TEST_CONNECTIONIDENTITY_2]);    
}




@end
