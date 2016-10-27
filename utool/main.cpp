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

bool UTF16ToUTF8(const std::u16string& utf16, std::string& outUtf8)
{
    if (utf16.empty())
    {
        outUtf8.clear();
        return true;
    }
    
    return llvm::convertUTF16ToUTF8String(utf16, outUtf8);
}

//将unicode转义字符序列转换为内存中的unicode字符串
std::string utf8_decode_utf16(const std::string &utf16_encoded, const std::vector<std::string> &ustarts)
{
    auto hasPrefixUStart = [=](const std::string &str) -> int {
        for (size_t i = 0; i < ustarts.size(); i++) {
            auto s = ustarts[i];
            if (str.length() > s.length()
                && str.substr(0, s.length()) == s) {
                return (int)s.length();
            }
        }
        return -1;
    };
    
    std::string ret = "";
    
    for (int char_index = 0; char_index < utf16_encoded.length(); char_index++) {
        
        auto ca = utf16_encoded.substr(char_index);
        auto p = hasPrefixUStart(ca);
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


int main(int argc, const char * argv[]) {
    // insert code here...
    if (argc > 1) {
        printf("decoded:\n");
        std::vector<std::string> vec;
        vec.push_back("u");
        vec.push_back("U");
        vec.push_back("\\U");
        vec.push_back("\\u");
        
        for (int i = 1; i < argc; i++) {
            printf("%s ", utf8_decode_utf16(argv[i], vec).c_str());
        }
        printf("\n");
    }
    else {
        printf("using:\n\tutool [strings] to decode\n");
    }
    return 0;
}
