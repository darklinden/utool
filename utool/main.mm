//
//  main.cpp
//  utool
//
//  Created by HanShaokun on 30/5/2016.
//  Copyright © 2016 darklinden. All rights reserved.
//

#include <iostream>
#include <sstream>
#include "ConvertUTF.h"
#import <Foundation/Foundation.h>

bool UTF16ToUTF8(const std::u16string& utf16, std::string& outUtf8)
{
    if (utf16.empty())
    {
        outUtf8.clear();
        return true;
    }
    
    return llvm::convertUTF16ToUTF8String(utf16, outUtf8);
}

int hasPrefixUStart(const std::string &str, const std::vector<std::string> &ustarts){
    for (size_t i = 0; i < ustarts.size(); i++) {
        auto s = ustarts[i];
        if (str.length() > s.length()
            && str.substr(0, s.length()) == s) {
            return (int)s.length();
        }
    }
    return -1;
}

//将unicode转义字符序列转换为内存中的unicode字符串
std::string utf8_decode_utf16(const std::string &utf16_encoded, const std::vector<std::string> &ustarts)
{
    std::string ret = "";
    
    for (int char_index = 0; char_index < utf16_encoded.length(); char_index++) {
        
        auto ca = utf16_encoded.substr(char_index);
        auto p = hasPrefixUStart(ca, ustarts);
        if (p != -1 && utf16_encoded.length() >= char_index + p + 4) {
            
            std::string hex = utf16_encoded.substr(char_index + p, 4);
            
            unsigned short x;
            std::stringstream ss;
            ss << std::hex << hex;
            ss >> x;
            
            std::u16string utf16;
            utf16.push_back((char16_t)x);
            std::string outUtf8;
            UTF16ToUTF8(utf16, outUtf8);
            ret.append(outUtf8);
            
            char_index += p + 4 - 1;
        }
        else {
            ret += utf16_encoded.substr(char_index, 1);
        }
    }
    
    return ret;
}

std::string try_decode_utf8(std::vector<std::string> buff_vec)
{
    std::vector<char> chars;
    
    for (auto i = 0; i < buff_vec.size(); i++) {
        chars.push_back(atoi(buff_vec[i].c_str()));
    }
    
    char* char_arr = chars.data(); // &chars[0]
    
    
    NSData *data = [NSData dataWithBytes:(const void *)char_arr length:chars.size()];
    NSString *ret = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    
    if (ret) {
        return ret.UTF8String;
    }
    
    return "";
}

std::string try_decode_utf16(const std::vector<std::string> &buff_vec)
{
    std::vector<char> chars;
    
    if (buff_vec[0] != "255" || buff_vec[1] != "254") {
        chars.push_back((char)255);
        chars.push_back((char)254);
    }
    
    for (auto i = 0; i < buff_vec.size(); i++) {
        chars.push_back(atoi(buff_vec[i].c_str()));
    }
    
    char* char_arr = chars.data(); // &chars[0]
    
    NSData *data = [NSData dataWithBytes:(const void *)char_arr length:chars.size()];
    NSString *ret = [[NSString alloc] initWithData:data encoding:NSUnicodeStringEncoding];
    
    if (ret) {
        return ret.UTF8String;
    }
    
    return "";
}

std::string encode_utf8(const std::string &in_str)
{
    NSString *nsstr = [NSString stringWithUTF8String:in_str.c_str()];
    
    NSData *data = [nsstr dataUsingEncoding:NSUTF8StringEncoding];
    
    std::string ret = "";
    
//    if (data.length > 2) {
        const char *bytes = (const char *)data.bytes;
        
        char tmp[128];
        
        for (auto i = 0; i < data.length; i++) {
            memset(tmp, 0, 128);
            sprintf(tmp, "%u ", (uint8)bytes[i]);
            ret += tmp;
        }
//    }
    
    return ret;
}

std::string encode_utf16(const std::string &in_str)
{
    NSString *nsstr = [NSString stringWithUTF8String:in_str.c_str()];
    
    NSData *data = [nsstr dataUsingEncoding:NSUnicodeStringEncoding];
    
    std::string ret = "";
    
    if (data.length > 2) {
        
        const char *bytes = (const char *)data.bytes;
        
        NSLog(@"%u %u", (uint8)bytes[0], (uint8)bytes[1]);
        
        char tmp[128];
        
        for (auto i = 2; i < data.length; i++) {
            memset(tmp, 0, 128);
            sprintf(tmp, "%u ", (uint8)bytes[i]);
            ret += tmp;
        }
    }
    
    return ret;
}

int main(int argc, const char * argv[]) {
    
    std::vector<std::string> u_vec;
    u_vec.push_back("u");
    u_vec.push_back("U");
    u_vec.push_back("\\U");
    u_vec.push_back("\\u");
    
    if (argc > 2) {
        if (std::string(argv[1]) == "d") {
            if (hasPrefixUStart(argv[2], u_vec) != -1) {
                printf("decoded:\n");
                
                for (int i = 2; i < argc; i++) {
                    printf("%s ", utf8_decode_utf16(argv[i], u_vec).c_str());
                }
                printf("\n");
            }
            else {
                std::vector<std::string> buff_vec;
                for (int i = 2; i < argc; i++) {
                    buff_vec.push_back(argv[i]);
                }
                
                printf("try decode utf8:\n");
                printf("%s\n", try_decode_utf8(buff_vec).c_str());
                
                printf("try decode utf16:\n");
                printf("%s\n", try_decode_utf16(buff_vec).c_str());
            }
        }
        else if (std::string(argv[1]) == "e") {
            printf("try encode utf8:\n");
            for (int i = 2; i < argc; i++) {
                printf("%s ", encode_utf8(argv[i]).c_str());
            }
            printf("\n");
            
            printf("try encode utf16:\n");
            for (int i = 2; i < argc; i++) {
                printf("%s ", encode_utf16(argv[i]).c_str());
            }
            printf("\n");
        }
    }
    else {
        printf("using:\n\tutool [strings] to decode\n");
    }
    return 0;
}
