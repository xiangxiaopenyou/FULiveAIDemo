//
//  FUConfigManager.m
//  FUAlgorithmDemo
//
//  Created by 项林平 on 2021/5/18.
//  Copyright © 2021 FaceUnity. All rights reserved.
//

#import "FUConfigManager.h"
#import "authpack.h"

//#import <FURenderKit/FUAIKit.h>

@implementation FUConfigManager

+ (void)initializeSDK {
    
    // 初始化 FURenderKit
    NSString *controllerPath = [[NSBundle mainBundle] pathForResource:@"controller_cpp" ofType:@"bundle"];
    NSString *controllerConfigPath = [[NSBundle mainBundle] pathForResource:@"controller_config" ofType:@"bundle"];
    FUSetupConfig *setupConfig = [[FUSetupConfig alloc] init];
    setupConfig.authPack = FUAuthPackMake(g_auth_package, sizeof(g_auth_package));
    setupConfig.controllerPath = controllerPath;
    setupConfig.controllerConfigPath = controllerConfigPath;
    
    [FURenderKit setupWithSetupConfig:setupConfig];
    [FURenderKit setLogLevel:FU_LOG_LEVEL_DEBUG];
    
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        FUDevicePerformanceLevel level = [FURenderKit devicePerformanceLevel];
        FUFaceAlgorithmConfig config = FUFaceAlgorithmConfigEnableAll;
        if (level < FUDevicePerformanceLevelHigh) {
            // 关闭所有效果
            config = FUFaceAlgorithmConfigDisableAll;
        } else if (level < FUDevicePerformanceLevelVeryHigh) {
            config = FUFaceAlgorithmConfigDisableSkinSegAndDelSpot;
        } else if (level < FUDevicePerformanceLevelExcellent) {
            config = FUFaceAlgorithmConfigDisableSkinSeg;
        }
        [FUAIKit setFaceAlgorithmConfig:config];
        // 加载人脸 AI 模型
        NSString *faceAIPath = [[NSBundle mainBundle] pathForResource:@"ai_face_processor" ofType:@"bundle"];
        [FUAIKit loadAIModeWithAIType:FUAITYPE_FACEPROCESSOR dataPath:faceAIPath];
        
        // 加载身体 AI 模型
        NSString *bodyAIPath = [[NSBundle mainBundle] pathForResource:@"ai_human_processor" ofType:@"bundle"];
        if ([FURenderKit devicePerformanceLevel] >= FUDevicePerformanceLevelHigh) {
            [FUAIKit loadAIHumanModelWithDataPath:bodyAIPath segmentationMode:FUHumanSegmentationModeGPUCommon];
        } else {
            [FUAIKit loadAIHumanModelWithDataPath:bodyAIPath segmentationMode:FUHumanSegmentationModeCPUCommon];
        }
        
        NSString *handAIPath = [[NSBundle mainBundle] pathForResource:@"ai_hand_processor" ofType:@"bundle"];
        [FUAIKit loadAIModeWithAIType:FUAITYPE_HANDGESTURE dataPath:handAIPath];
        
        NSString *path = [[NSBundle mainBundle] pathForResource:@"tongue" ofType:@"bundle"];
        [FUAIKit loadTongueMode:path];
        
        // 设置嘴巴灵活度 默认0
        float flexible = 0.5;
        [FUAIKit setFaceTrackParam:@"mouth_expression_more_flexible" value:flexible];
        
        // 设置最大人脸数量
        [FUAIKit shareKit].maxTrackFaces = 8;
        
        // 设置人脸算法质量
        [FUAIKit shareKit].faceProcessorFaceLandmarkQuality = level >= FUDevicePerformanceLevelHigh ? FUFaceProcessorFaceLandmarkQualityHigh : FUFaceProcessorFaceLandmarkQualityMedium;
        
        // 设置小脸检测是否打开
        [FUAIKit shareKit].faceProcessorDetectSmallFace = level >= FUDevicePerformanceLevelHigh;
    });
}

+ (void)onCameraChange {
    [FUAIKit resetTrackedResult];
}

+ (void)resetHumanProcessor {
    [FUAIKit resetHumanProcessor];
}

+ (BOOL)isTrackingFace {
    return [FUAIKit shareKit].trackedFacesCount > 0;
}

+ (BOOL)isTrackingBody {
    return [FUAIKit aiHumanProcessorNums] > 0;
}

+ (BOOL)isTrackingHand {
    return [FUAIKit aiHandDistinguishNums] > 0;
}

+ (BOOL)faceInfoWithName:(NSString *)name pret:(float *)pret number:(int)number {
    return [FUAIKit getRotatedFaceInfo:0 name:name pret:pret number:number];
}

@end
