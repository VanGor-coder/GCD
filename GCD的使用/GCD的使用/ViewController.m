//
//  ViewController.m
//  GCD的使用
//
//  Created by GaoFan on 2021/3/5.
//

#import "ViewController.h"

@interface ViewController ()
@property (nonatomic,strong) UIImageView *imgV;
@property (nonatomic,strong) UIImage *img1;
@property (nonatomic,strong) UIImage *img2;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor redColor];
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    //dispatch_apply
//    [self apply];
    //
//    [self barrier];
//    [self group];
    self.imgV =[[UIImageView alloc]initWithFrame:CGRectMake(50, 100, 300, 300)];
    [self.view addSubview:self.imgV];
    [self groupTest];
}


-(void)apply{
    
    //1.获取文件夹的path
    NSString *from = @"";
    NSString *to = @"";
    
    //获得该文件夹下的所有文件
    NSArray *fileArr = [[NSFileManager defaultManager]subpathsAtPath:from];
    
    //3.遍历
    
    //for循环
    for (int i=0; i<fileArr.count; i++) {
        //第一个参数:文件路径
        //第二个参数:目标路径
        //错误信息:
        
        BOOL isSuccess = [[NSFileManager defaultManager]moveItemAtPath:[from stringByAppendingPathComponent:fileArr[i]] toPath:[to stringByAppendingPathComponent:fileArr[i]] error:nil];
        NSLog(@"%i",isSuccess);
    }
    
    //快速迭代方法
    //GCD快速迭代
    //第一个参数:迭代的次数
    //第二个参数:队列
    //会开启多条子线程和主线程一起并发执行任务
    //如果使用主队列会发生死锁
    dispatch_queue_t queue = dispatch_get_global_queue(0, 0);
    dispatch_apply(fileArr.count, queue, ^(size_t i) {
        BOOL isSuccess = [[NSFileManager defaultManager]moveItemAtPath:[from stringByAppendingPathComponent:fileArr[i]] toPath:[to stringByAppendingPathComponent:fileArr[i]] error:nil];
        NSLog(@"%i",isSuccess);
    });
}

-(void)barrier{
    dispatch_queue_t queue = dispatch_queue_create("Test", DISPATCH_QUEUE_CONCURRENT);
    
    dispatch_async(queue, ^{
        NSLog(@"1---------%@",[NSThread currentThread]);
    });
    dispatch_async(queue, ^{
        NSLog(@"2---------%@",[NSThread currentThread]);
    });
    dispatch_barrier_async(queue, ^{
        NSLog(@"++++++++++++");
    });
    dispatch_async(queue, ^{
        NSLog(@"3---------%@",[NSThread currentThread]);
    });
    dispatch_async(queue, ^{
        NSLog(@"4---------%@",[NSThread currentThread]);
    });
}

-(void)group{
    //需求:拦截多个队列中的任务
    
    //01.创建队列组
    dispatch_group_t group = dispatch_group_create();
    
    
    dispatch_queue_t queue = dispatch_queue_create("Test", DISPATCH_QUEUE_CONCURRENT);
    dispatch_queue_t queue2 = dispatch_queue_create("Test", DISPATCH_QUEUE_CONCURRENT);
    
    //02.封装任务 把任务添加到队列 监听任务的执行情况
    dispatch_group_async(group, queue, ^{
        NSLog(@"1---------%@",[NSThread currentThread]);
    });
    dispatch_group_async(group, queue, ^{
        NSLog(@"2---------%@",[NSThread currentThread]);
    });
    dispatch_group_async(group, queue, ^{
        NSLog(@"3---------%@",[NSThread currentThread]);
    });
    dispatch_group_async(group, queue2, ^{
        NSLog(@"4---------%@",[NSThread currentThread]);
    });
    dispatch_group_async(group, queue2, ^{
        NSLog(@"5---------%@",[NSThread currentThread]);
    });
    
    //03.拦截通知,当所有任务执行完毕后,进行打印操作
    //队列参数:决定该block块在哪个线程中处理(主:主线程 非主:子线程)
    //dispatch_group_notify内部是异步执行的
    dispatch_group_notify(group, queue, ^{
        NSLog(@"++++++++++++");
    });
    
    
    //如何监听
    //dispatch_group_enter和dispatch_group_leave必须成对使用
    //在该方法后面的任务会被任务组监听
    dispatch_group_enter(group);
    
    dispatch_async(queue, ^{
        
        //监听到该任务已经执行完毕
        dispatch_group_leave(group);
    });
}

-(void)groupTest{
    //需求:开子线程下载两张图片,合成图片并显示出来
    //01.创建队列组
    dispatch_group_t group = dispatch_group_create();
    
    //02.获得并发队列
    dispatch_queue_t queue = dispatch_queue_create("imageDownLoad", DISPATCH_QUEUE_CONCURRENT);
    
    //下载任务处理
    dispatch_group_async(group, queue, ^{
        NSString *urlString = @"https://gimg2.baidu.com/image_search/src=http%3A%2F%2Fa0.att.hudong.com%2F30%2F29%2F01300000201438121627296084016.jpg&refer=http%3A%2F%2Fa0.att.hudong.com&app=2002&size=f9999,10000&q=a80&n=0&g=0n&fmt=jpeg?sec=1617507160&t=b4e82f467e416f9a72286f0ed6215d1f";
        NSURL *url = [NSURL URLWithString:urlString];
        NSData *imageData = [NSData dataWithContentsOfURL:url];
        UIImage *image = [UIImage imageWithData:imageData];
        self.img1=image;
    });
    dispatch_group_async(group, queue, ^{
        NSString *urlString = @"https://gimg2.baidu.com/image_search/src=http%3A%2F%2Fa2.att.hudong.com%2F86%2F10%2F01300000184180121920108394217.jpg&refer=http%3A%2F%2Fa2.att.hudong.com&app=2002&size=f9999,10000&q=a80&n=0&g=0n&fmt=jpeg?sec=1617507160&t=05b22b9420b737d5f20978b9a85a751e";
        NSURL *url = [NSURL URLWithString:urlString];
        NSData *imageData = [NSData dataWithContentsOfURL:url];
        UIImage *image = [UIImage imageWithData:imageData];
        self.img2 = image;
    });
    dispatch_group_notify(group, queue, ^{
        //01.开始上下文
        UIGraphicsBeginImageContext(CGSizeMake(300, 300));
        //02.画图
        [self.img1 drawInRect:CGRectMake(0, 0, 150, 300)];
        [self.img2 drawInRect:CGRectMake(150, 0, 150, 300)];
        //03.根据上下文得到一张图片
        UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
        //04.关闭上下文
        UIGraphicsEndImageContext();
        //05.显示图片
        dispatch_async(dispatch_get_main_queue(), ^{
            self.imgV.image = image;
        });
    });
}
@end
