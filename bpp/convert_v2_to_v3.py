#!/usr/bin/env python3
"""
v2 문법을 v3 문법으로 변환하는 스크립트
"""

import re
import sys
import os

def convert_ptr_access(content):
    """ptr8[x], ptr64[x] 등을 v3 문법으로 변환"""
    # ptr8[expr] → *cast(*u8, expr)
    content = re.sub(r'ptr8\[([^\]]+)\]', r'*cast(*u8, \1)', content)
    # ptr64[expr] → *cast(*u64, expr)
    content = re.sub(r'ptr64\[([^\]]+)\]', r'*cast(*u64, \1)', content)
    # ptr16[expr] → *cast(*u16, expr)
    content = re.sub(r'ptr16\[([^\]]+)\]', r'*cast(*u16, \1)', content)
    # ptr32[expr] → *cast(*u32, expr)
    content = re.sub(r'ptr32\[([^\]]+)\]', r'*cast(*u32, \1)', content)
    return content

def remove_alias(content):
    """alias 문법 제거 (v3에서 미지원)"""
    # alias rdx : var_name; 형태 제거
    content = re.sub(r'^\s*alias\s+\w+\s*:\s*\w+\s*;.*\n', '', content, flags=re.MULTILINE)
    return content

def add_std_prefix(content):
    """import 문에 std. 접두사 추가"""
    # import io; → import std.io;
    # import hashmap; → import std.hashmap;
    stdlib_modules = ['io', 'mem', 'str', 'vec', 'hashmap', 'panic', 'file', 'arena', 'conv', 
                      'module', 'prelude', 'slice', 'string', 'string_builder', 'string_interner']
    for mod in stdlib_modules:
        content = re.sub(rf'^(\s*)import\s+{mod}\s*;', rf'\1import std.{mod};', content, flags=re.MULTILINE)
    return content

def add_function_types(content):
    """함수 파라미터에 기본 타입 추가 (간단한 경우만)"""
    # func foo(x, y) → func foo(x: u64, y: u64) (완벽하지 않음, 수동 수정 필요)
    # 이 부분은 복잡하므로 일단 주석 처리
    return content

def convert_file(filepath):
    """파일 하나를 v2 → v3로 변환"""
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()
    
    original = content
    
    # 변환 적용
    content = convert_ptr_access(content)
    content = remove_alias(content)
    content = add_std_prefix(content)
    
    # 변경사항이 있으면 저장
    if content != original:
        with open(filepath, 'w', encoding='utf-8') as f:
            f.write(content)
        return True
    return False

def main():
    if len(sys.argv) < 2:
        print("Usage: python convert_v2_to_v3.py <directory>")
        sys.exit(1)
    
    directory = sys.argv[1]
    converted = 0
    
    for root, dirs, files in os.walk(directory):
        for file in files:
            if file.endswith('.bpp'):
                filepath = os.path.join(root, file)
                if convert_file(filepath):
                    converted += 1
                    print(f"✓ {filepath}")
    
    print(f"\n변환 완료: {converted}개 파일")

if __name__ == '__main__':
    main()
