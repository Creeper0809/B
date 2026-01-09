// os/path.b - 크로스 플랫폼 경로 처리 유틸리티
//
// Linux: '/' (ASCII 47)
// Windows: '\' (ASCII 92)
//
// 전략: 런타임에 OS 감지 후 적절한 구분자 사용

// 플랫폼 감지 (컴파일 타임 또는 런타임)
// TODO: 컴파일러가 -DWINDOWS 플래그를 전달하면 컴파일 타임 결정
//       아니면 런타임에 OS 감지

var PATH_SEPARATOR = 47; // 기본값: '/' (Linux)

// 초기화 함수 (main에서 호출)
func path_init() {
	// TODO: Windows 감지 시 PATH_SEPARATOR = 92 설정
	// 현재는 Linux 가정
	PATH_SEPARATOR = 47;
}

// 경로에서 구분자 찾기
func path_find_last_separator(path) {
	var n = cstr_len(path);
	var i = 0;
	var last = 0;
	var found = 0;
	
	while (i < n) {
		var c = ptr8[path + i];
		// Linux: '/', Windows: '\' 모두 확인
		if (c == 47 || c == 92) {
			last = i;
			found = 1;
		}
		i = i + 1;
	}
	
	if (found == 0) { return -1; }
	return last;
}

// 디렉토리 경로 길이 (구분자 포함)
func path_dir_len(path) {
	var sep_pos = path_find_last_separator(path);
	if (sep_pos == -1) { return 0; }
	return sep_pos + 1;
}

// 베이스 이름 추출 (확장자 제거)
func path_basename_no_ext(path) {
	// Returns: rax=basename_ptr, rdx=basename_len
	var n = cstr_len(path);
	var start = path;
	
	// 마지막 구분자 찾기
	var sep_pos = path_find_last_separator(path);
	if (sep_pos != -1) {
		start = path + sep_pos + 1;
	}
	
	// 마지막 '.' 찾기
	var dot = 0;
	var j = 0;
	while (ptr8[start + j] != 0) {
		if (ptr8[start + j] == 46) { dot = start + j; }
		j = j + 1;
	}
	
	var end = start + j;
	if (dot != 0) {
		// .b 또는 .bpp 확장자만 제거
		if (ptr8[dot + 1] == 98) { // 'b'
			var next = ptr8[dot + 2];
			if (next == 0) { 
				// ".b"
				end = dot; 
			} else if (next == 112 && ptr8[dot + 3] == 112 && ptr8[dot + 4] == 0) {
				// ".bpp"
				end = dot;
			}
		}
	}
	
	rax = start;
	rdx = end - start;
	return;
}

// 경로 결합 (dir + basename)
func path_join(dir, dir_len, name, name_len) {
	var total = dir_len + 1 + name_len + 1; // dir + '/' + name + '\0'
	var result = malloc(total);
	
	// dir 복사
	var i = 0;
	while (i < dir_len) {
		ptr8[result + i] = ptr8[dir + i];
		i = i + 1;
	}
	
	// 구분자 추가
	ptr8[result + i] = PATH_SEPARATOR;
	i = i + 1;
	
	// name 복사
	var j = 0;
	while (j < name_len) {
		ptr8[result + i] = ptr8[name + j];
		i = i + 1;
		j = j + 1;
	}
	
	// null terminator
	ptr8[result + i] = 0;
	
	return result;
}

// 경로 정규화 (\ → / 또는 / → \ 변환)
func path_normalize(path) {
	var n = cstr_len(path);
	var result = malloc(n + 1);
	
	var i = 0;
	while (i < n) {
		var c = ptr8[path + i];
		// Windows에서는 '/'를 '\'로, Linux에서는 '\'를 '/'로
		if (PATH_SEPARATOR == 47) { // Linux
			if (c == 92) { c = 47; } // '\' → '/'
		} else { // Windows
			if (c == 47) { c = 92; } // '/' → '\'
		}
		ptr8[result + i] = c;
		i = i + 1;
	}
	ptr8[result + i] = 0;
	
	return result;
}

// 절대 경로 판별
func path_is_absolute(path) {
	if (PATH_SEPARATOR == 47) { 
		// Linux: '/'로 시작
		return ptr8[path] == 47;
	} else {
		// Windows: 'C:\' 형식
		var c = ptr8[path];
		if ((c >= 65 && c <= 90) || (c >= 97 && c <= 122)) { // A-Z, a-z
			if (ptr8[path + 1] == 58 && ptr8[path + 2] == 92) { // ':\\'
				return 1;
			}
		}
		return 0;
	}
}

// cstr_len 유틸리티 (중복이지만 독립성을 위해)
func cstr_len(s) {
	var n = 0;
	while (ptr8[s + n] != 0) {
		n = n + 1;
	}
	return n;
}
