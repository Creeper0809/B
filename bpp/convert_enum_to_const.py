#!/usr/bin/env python3
"""enum TokKind { EOF = 0, ... } -> const TokKind_EOF = 0; ..."""
import re
import sys

def convert_enums(content):
    def enum_to_const(match):
        enum_name = match.group(1)
        body = match.group(2)
        
        # Parse enum members
        lines = []
        for line in body.split('\n'):
            line = line.strip()
            if not line or line.startswith('//'):
                continue
            # IDENT = value,
            m = re.match(r'(\w+)\s*=\s*(\d+),?', line)
            if m:
                const_name = f"{enum_name}_{m.group(1)}"
                value = m.group(2)
                lines.append(f"const {const_name} = {value};")
        
        return '\n'.join(lines)
    
    # enum Name { ... }
    pattern = r'enum\s+(\w+)\s*\{([^}]+)\}'
    return re.sub(pattern, enum_to_const, content, flags=re.MULTILINE | re.DOTALL)

if __name__ == '__main__':
    content = sys.stdin.read()
    print(convert_enums(content))
