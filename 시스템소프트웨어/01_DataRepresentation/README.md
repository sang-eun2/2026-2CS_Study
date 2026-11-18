# HW1: 비트와 정수

과제 설명은 HW1_비트와정수.pdf를 읽으십시오. C11, 학부 Linux 서버를 기준으로 합니다.
PDF 9쪽에 관련 표준과 공식 문서 링크가 있습니다.


## 파일
- bytes.c: LAST4를 학번 끝 네 자리의 10진 정수로 수정 (앞의 0은 제거).
- bitops.c: set_mode의 TODO를 구현.
- casts.c: 코드 실행과 형 변환 분석. -Wsign-compare 경고는 의도된 관찰 대상.
- checked_add.c: add_checked의 TODO를 구현. 처음에는 모든 입력에 실패를 반환하는 뼈대임.
- overflow_probe.c: 선택 심화. 반드시 아래 UBSan 명령으로만 실행.

## 서버에서 컴파일·실행
gcc -std=c11 -Wall -Wextra -O0 bytes.c -o bytes
./bytes | tee bytes.txt
gcc -std=c11 -Wall -Wextra -O0 bitops.c -o bitops
./bitops | tee bitops.txt
gcc -std=c11 -Wall -Wextra -O0 casts.c -o casts
./casts | tee casts.txt
gcc -std=c11 -Wall -Wextra -O0 checked_add.c -o checked_add
./checked_add | tee checked_add.txt

## 선택 심화
gcc -std=c11 -Wall -Wextra -O1 -g -fsanitize=undefined -fno-sanitize-recover=undefined overflow_probe.c -o overflow_probe
./overflow_probe > sanitizer.txt 2>&1
cat sanitizer.txt

진단 후 0이 아닌 종료 코드는 이 실험의 정상적인 관찰 결과입니다.
보고서는 본인의 서버 실행 결과와 설명으로 작성하십시오. 제공 코드는 정답 코드가 아닙니다.
