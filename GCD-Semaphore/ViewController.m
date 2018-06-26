//
//  ViewController.m
//  GCD-Semaphore
//
//  Created by chenshuang on 2018/6/26.
//  Copyright © 2018年 wenwen. All rights reserved.
//

#import "ViewController.h"
#import <AddressBook/AddressBook.h>

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
//    [self semaphore];
//    [self addLock];
//    [self getAddressBook];
    [self dispatchSignal];
}

- (void)semaphoreFunction {
    // 创建信号量，参数：信号量的初值，如果小于0则会返回NULL
    dispatch_semaphore_t dispatch_semaphore_create(long value);
    
    // 等待降低信号量，接收一个信号和时间值(多为DISPATCH_TIME_FOREVER)
    // 若信号的信号量为0，则会阻塞当前线程，直到信号量大于0或者经过输入的时间值；
    // 若信号量大于0，则会使信号量减1并返回，程序继续住下执行
    long dispatch_semaphore_wait(dispatch_semaphore_t dsema, dispatch_time_t timeout);
    
    // 提高信号量， 使信号量加1并返回
    long dispatch_semaphore_signal(dispatch_semaphore_t dsema);
}

// 保持线程同步
- (void)semaphore {
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    
    __block int j = 0;
    dispatch_async(queue, ^{
        j = 100;
        dispatch_semaphore_signal(semaphore);
    });
    
    dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
    NSLog(@"finish j = %zd", j);
}

// 给线程加锁
- (void)addLock {
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(1);
    
    for (int i = 0; i < 10; i++) {
        dispatch_async(queue, ^{
            // 相当于加锁
            dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
            NSLog(@"i = %zd semaphore = %@", i, semaphore);
            // 相当于解锁
            dispatch_semaphore_signal(semaphore);
        });
    }
}

// 获取通讯录
- (void)getAddressBook {
    //这个变量用于记录授权是否成功，即用户是否允许我们访问通讯录
    __block int tip=0;
    
    //创建通讯簿的引用
    ABAddressBookRef addressBooks=ABAddressBookCreateWithOptions(NULL, NULL);
    //创建一个初始信号量为0的信号
    dispatch_semaphore_t sema=dispatch_semaphore_create(0);
    //申请访问权限
    ABAddressBookRequestAccessWithCompletion(addressBooks, ^(bool granted, CFErrorRef error)        {
        //granted为YES是表示用户允许，否则为不允许
        if (!granted) {
            tip=1;
        }
        //发送一次信号
        dispatch_semaphore_signal(sema);
    });
    //等待信号触发
    dispatch_semaphore_wait(sema, DISPATCH_TIME_FOREVER);
    CFRelease(addressBooks);
}

// 控制并发线程数量
- (void)controlThreadCount {
    
}

// 控制并发线程数量
- (void)dispatchAsyncLimit:(dispatch_queue_t)queue limitSemaphoreCount:(NSUInteger)limitSemaphoreCount bloc:(dispatch_block_t)block {
    //控制并发数的信号量
    static dispatch_semaphore_t limitSemaphore;
    
    //专门控制并发等待的线程
    static dispatch_queue_t receiverQueue;
    
    //使用 dispatch_once而非 lazy 模式，防止可能的多线程抢占问题
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        limitSemaphore = dispatch_semaphore_create(limitSemaphoreCount);
        receiverQueue = dispatch_queue_create("receiver", DISPATCH_QUEUE_SERIAL);
    });
    
    // 如不加 receiverQueue 放在主线程会阻塞主线程
    dispatch_async(receiverQueue, ^{
        //可用信号量后才能继续，否则等待
        dispatch_semaphore_wait(limitSemaphore, DISPATCH_TIME_FOREVER);
        dispatch_async(queue, ^{
            !block ? : block();
            //在该工作线程执行完成后释放信号量
            dispatch_semaphore_signal(limitSemaphore);
        });
    });
}

- (void)dispatchSignal {
    // crate的value表示，最多几个资源可访问
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(3);
    // 队列
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    //任务1
    dispatch_async(queue, ^{
        dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
        NSLog(@"run task 1");
        sleep(1);
        NSLog(@"complete task 1");
        dispatch_semaphore_signal(semaphore);
    });
    //任务2
    dispatch_async(queue, ^{
        dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
        NSLog(@"run task 2");
        sleep(1);
        NSLog(@"complete task 2");
        dispatch_semaphore_signal(semaphore);
    });
    //任务3
    dispatch_async(queue, ^{
        dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
        NSLog(@"run task 3");
        sleep(1);
        NSLog(@"complete task 3");
        dispatch_semaphore_signal(semaphore);
    });
}

@end
