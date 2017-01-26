//
//  AKQQManagerMacro.h
//  Pods
//
//  Created by 李翔宇 on 2017/1/16.
//
//

#ifndef AKQQManagerMacro_h
#define AKQQManagerMacro_h

static BOOL AKQQManagerLogState = YES;

#define AKQQManagerLogFormat(INFO, ...) [NSString stringWithFormat:(@"\n[Date:%s]\n[Time:%s]\n[File:%s]\n[Line:%d]\n[Function:%s]\n" INFO @"\n"), __DATE__, __TIME__, __FILE__, __LINE__, __PRETTY_FUNCTION__, ## __VA_ARGS__]

#if DEBUG
#define AKQQManagerLog(INFO, ...) !AKQQManagerLogState ? : NSLog((@"\n[Date:%s]\n[Time:%s]\n[File:%s]\n[Line:%d]\n[Function:%s]\n" INFO @"\n"), __DATE__, __TIME__, __FILE__, __LINE__, __PRETTY_FUNCTION__, ## __VA_ARGS__);
#else
#define AKQQManagerLog(INFO, ...)
#endif

//nil和类型判断
#define AK_QQM_Nilable_Class_Return(_obj, _nilable, _class, _stuff, ...) \
    if(!_nilable) {\
        NSParameterAssert(_obj);\
        if(!_obj) {\
            _stuff;\
            return __VA_ARGS__;\
        }\
    }\
    if(_obj) {\
        NSParameterAssert([_obj isKindOfClass:_class.class]);\
        if(![_obj isKindOfClass:_class.class]) {\
            _stuff;\
            return __VA_ARGS__;\
    }\
}

#endif /* AKQQManagerMacro_h */
