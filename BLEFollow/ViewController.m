//
//  ViewController.m
//  BLEFollow
//
//  Created by user on 16/11/18.
//  Copyright © 2016年 zshuo50. All rights reserved.
//

#import "ViewController.h"
#import <CoreBluetooth/CoreBluetooth.h>
#import "Masonry.h"

static NSString *const ServiceUUID1 =  @"FFF0";
static NSString *const notiyCharacteristicUUID =  @"FFF1";
static NSString *const readwriteCharacteristicUUID =  @"FFF2";
static NSString *const ServiceUUID2 =  @"FFE0";
static NSString *const readCharacteristicUUID =  @"FFE1";
static NSString * const LocalNameKey =  @"PP GUN BLE4.0";


@interface ViewController ()<CBPeripheralManagerDelegate>
{
    int serviceNum;
    //定时器
    NSTimer *timer;
}
@property(nonatomic,strong)CBPeripheralManager *MyPeripheralManager;//外围设备管理器
@property(nonatomic,strong)NSMutableArray *centralM;//存放订阅的中心设备
//@property(nonatomic,strong)CBMutableCharacteristic *myCharacterstic;//特征

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    __weak typeof(self)weakSelf = self;
 

    UIButton *openB = [UIButton buttonWithType:UIButtonTypeCustom];
    [openB setTitle:@"开启设备开始发送广播" forState:UIControlStateNormal];
    [openB setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    openB.backgroundColor = [UIColor greenColor];
    [openB addTarget:self action:@selector(open) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:openB];
    [openB mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(@100);
        make.centerX.equalTo(weakSelf.view);
        make.height.equalTo(@30);
    }];
    
    
    UIButton *updateB = [UIButton buttonWithType:UIButtonTypeCustom];
    [updateB setTitle:@"更新特征值" forState:UIControlStateNormal];
    [updateB setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    updateB.backgroundColor = [UIColor greenColor];
    [updateB addTarget:self action:@selector(UpdateCharacterisyicValue) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:updateB];
    [updateB mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(openB);
        make.top.equalTo(openB.mas_bottom).with.offset(60);
        make.height.equalTo(@30);
    }];
    
    
}

//开启设备广播
-(void)open
{
    _MyPeripheralManager = [[CBPeripheralManager alloc]initWithDelegate:self queue:nil];
}

//更新特征值
-(void)UpdateCharacterisyicValue
{
    //特征值
   // NSString *valueStr = [NSString stringWithFormat:@"%@---%@",BLEPeripheralName,[NSDate date]];
    //NSData *value = [valueStr dataUsingEncoding:NSUTF8StringEncoding];
    NSString *valueStr = [NSString stringWithFormat:@"0xFFEEDD00112233445566778899AABBCCDDEEFF00"];
    NSData *value = [self convertHexStrToData:valueStr];
    //更新特征值
  //  [_MyPeripheralManager updateValue:value forCharacteristic:_myCharacterstic onSubscribedCentrals:nil];
    NSLog(@"更新特征值");
}

#pragma mark - 私有方法
//创建服务、特征到外围设备
-(void)SetupService
{
    //characteristics字段描述
    CBUUID *CBUUIDCharacteristicUserDescriptionStringUUID = [CBUUID UUIDWithString:CBUUIDCharacteristicUserDescriptionString];
    
    /*
     可以通知的Characteristic
     properties：CBCharacteristicPropertyNotify
     permissions CBAttributePermissionsReadable
     */
    CBMutableCharacteristic *notiyCharacteristic = [[CBMutableCharacteristic alloc]initWithType:[CBUUID UUIDWithString:notiyCharacteristicUUID] properties:CBCharacteristicPropertyNotify value:nil permissions:CBAttributePermissionsReadable];
    
    /*
     可读写的characteristics
     properties：CBCharacteristicPropertyWrite | CBCharacteristicPropertyRead
     permissions CBAttributePermissionsReadable | CBAttributePermissionsWriteable
     */
    CBMutableCharacteristic *readwriteCharacteristic = [[CBMutableCharacteristic alloc]initWithType:[CBUUID UUIDWithString:readwriteCharacteristicUUID] properties:CBCharacteristicPropertyWrite | CBCharacteristicPropertyRead value:nil permissions:CBAttributePermissionsReadable | CBAttributePermissionsWriteable];
    //设置description
    CBMutableDescriptor *readwriteCharacteristicDescription1 = [[CBMutableDescriptor alloc]initWithType: CBUUIDCharacteristicUserDescriptionStringUUID value:@"name"];
    [readwriteCharacteristic setDescriptors:@[readwriteCharacteristicDescription1]];
    
    
    /*
     只读的Characteristic
     properties：CBCharacteristicPropertyRead
     permissions CBAttributePermissionsReadable
     */
    CBMutableCharacteristic *readCharacteristic = [[CBMutableCharacteristic alloc]initWithType:[CBUUID UUIDWithString:readCharacteristicUUID] properties:CBCharacteristicPropertyRead value:nil permissions:CBAttributePermissionsReadable];
    
    
    //service1初始化并加入两个characteristics
    CBMutableService *service1 = [[CBMutableService alloc]initWithType:[CBUUID UUIDWithString:ServiceUUID1] primary:YES];
    NSLog(@"%@",service1.UUID);
    
    [service1 setCharacteristics:@[notiyCharacteristic,readwriteCharacteristic]];
    
    //service2初始化并加入一个characteristics
    CBMutableService *service2 = [[CBMutableService alloc]initWithType:[CBUUID UUIDWithString:ServiceUUID2] primary:YES];
    [service2 setCharacteristics:@[readCharacteristic]];
    
    //添加后就会调用代理的- (void)peripheralManager:(CBPeripheralManager *)peripheral didAddService:(CBService *)service error:(NSError *)error
    [_MyPeripheralManager addService:service1];
    [_MyPeripheralManager addService:service2];
    
    
}

//发送数据，发送当前时间的秒数
-(BOOL)sendData:(NSTimer *)t {
    CBMutableCharacteristic *characteristic = t.userInfo;
    NSDateFormatter *dft = [[NSDateFormatter alloc]init];
    [dft setDateFormat:@"ss"];
    NSLog(@"%@",[dft stringFromDate:[NSDate date]]);
  
    //执行回应Central通知数据
    return  [_MyPeripheralManager updateValue:[[dft stringFromDate:[NSDate date]] dataUsingEncoding:NSUTF8StringEncoding] forCharacteristic:(CBMutableCharacteristic *)characteristic onSubscribedCentrals:nil];
    
}


//16进制字符串转16进制数据
- (NSData *)convertHexStrToData:(NSString *)str {
    if (!str || [str length] == 0) {
        return nil;
    }
    
    NSMutableData *hexData = [[NSMutableData alloc] initWithCapacity:8];
    NSRange range;
    if ([str length] % 2 == 0) {
        range = NSMakeRange(0, 2);
    } else {
        range = NSMakeRange(0, 1);
    }
    for (NSInteger i = range.location; i < [str length]; i += 2) {
        unsigned int anInt;
        NSString *hexCharStr = [str substringWithRange:range];
        NSScanner *scanner = [[NSScanner alloc] initWithString:hexCharStr];
        
        [scanner scanHexInt:&anInt];
        NSData *entity = [[NSData alloc] initWithBytes:&anInt length:1];
        [hexData appendData:entity];
        
        range.location += range.length;
        range.length = 2;
    }
    
    NSLog(@"hexdata: %@", hexData);
    return hexData;
}

//16进制数据转16进制字符串
- (NSString *)convertDataToHexStr:(NSData *)data {
    if (!data || [data length] == 0) {
        return @"";
    }
    NSMutableString *string = [[NSMutableString alloc] initWithCapacity:[data length]];
    
    [data enumerateByteRangesUsingBlock:^(const void *bytes, NSRange byteRange, BOOL *stop) {
        unsigned char *dataBytes = (unsigned char*)bytes;
        for (NSInteger i = 0; i < byteRange.length; i++) {
            NSString *hexStr = [NSString stringWithFormat:@"%x", (dataBytes[i]) & 0xff];
            if ([hexStr length] == 2) {
                [string appendString:hexStr];
            } else {
                [string appendFormat:@"0%@", hexStr];
            }
        }
    }];
    
    return string;
}
#pragma mark - CBCentralManagerDelegate
//外围设备状态发生变化后调用
-(void)peripheralManagerDidUpdateState:(CBPeripheralManager *)peripheral
{
    switch (peripheral.state) {
        case CBPeripheralManagerStatePoweredOn:
            NSLog(@"设备已打开");
            //添加服务
            [self SetupService];
            break;
        case CBPeripheralManagerStatePoweredOff:
            NSLog(@"设备蓝牙未打开");
            break;
        default:
            NSLog(@"此设备不支持BLE");
            break;
    }
}
//设备添加服务后的回调
-(void)peripheralManager:(CBPeripheralManager *)peripheral didAddService:(CBService *)service error:(NSError *)error
{
    if (error == nil) {
        serviceNum++;
    }
    
    //因为我们添加了2个服务，所以想两次都添加完成后才去发送广播
    if (serviceNum==2) {
        //添加服务后可以在此向外界发出通告 调用完这个方法后会调用代理的
        //(void)peripheralManagerDidStartAdvertising:(CBPeripheralManager *)peripheral error:(NSError *)error
        [_MyPeripheralManager startAdvertising:@{
                                              CBAdvertisementDataServiceUUIDsKey : @[[CBUUID UUIDWithString:ServiceUUID1],[CBUUID UUIDWithString:ServiceUUID2]],
                                              CBAdvertisementDataLocalNameKey : LocalNameKey
                                              }
         ];
        
    }
    NSLog(@"开始广播");
    
}
//开启广播的回调
-(void)peripheralManagerDidStartAdvertising:(CBPeripheralManager *)peripheral error:(NSError *)error
{
    if (error) {
        NSLog(@"启动广播过程中发生错误，错误信息：%@",error.localizedDescription);
        return;
    }
    NSLog(@"启动广播成功。。。");
}

//中心设备订阅了特征回调
-(void)peripheralManager:(CBPeripheralManager *)peripheral central:(CBCentral *)central didSubscribeToCharacteristic:(CBCharacteristic *)characteristic
{
    NSLog(@"中心设备:%@  已订阅特征:%@",central,characteristic.UUID);
    //每秒执行一次给主设备发送一个当前时间的秒数
    timer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(sendData:) userInfo:characteristic  repeats:YES];
}

//中心设备取消订阅
-(void)peripheralManager:(CBPeripheralManager *)peripheral central:(CBCentral *)central didUnsubscribeFromCharacteristic:(CBCharacteristic *)characteristic
{
    NSLog(@"中心设备：%@ 已取消订阅特征：%@",central,characteristic.UUID);
    [timer invalidate];
}

//读characteristics请求
- (void)peripheralManager:(CBPeripheralManager *)peripheral didReceiveReadRequest:(CBATTRequest *)request{
    NSLog(@"didReceiveReadRequest");
    //判断是否有读数据的权限
    if (request.characteristic.properties & CBCharacteristicPropertyRead) {
        NSData *data = request.characteristic.value;
        [request setValue:data];
        //对请求作出成功响应
        [_MyPeripheralManager respondToRequest:request withResult:CBATTErrorSuccess];
    }else{
        [_MyPeripheralManager respondToRequest:request withResult:CBATTErrorWriteNotPermitted];
    }
}


//写characteristics请求
- (void)peripheralManager:(CBPeripheralManager *)peripheral didReceiveWriteRequests:(NSArray *)requests{
    NSLog(@"didReceiveWriteRequests");
    CBATTRequest *request = requests[0];
    
    //判断是否有写数据的权限
    if (request.characteristic.properties & CBCharacteristicPropertyWrite) {
        //需要转换成CBMutableCharacteristic对象才能进行写值
        CBMutableCharacteristic *c =(CBMutableCharacteristic *)request.characteristic;
        c.value = request.value;
        [_MyPeripheralManager respondToRequest:request withResult:CBATTErrorSuccess];
    }else{
        [_MyPeripheralManager respondToRequest:request withResult:CBATTErrorWriteNotPermitted];
    }
    
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
