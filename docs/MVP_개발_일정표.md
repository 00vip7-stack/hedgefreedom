# 환리스크 관리 시스템 MVP 개발 일정표

**전체 기간**: 3주 (2026-01-27 ~ 2026-02-14)
**목표**: 실제 고객 1-3개사 운영 시작

---

## 📅 Week 1: 핵심 기능 구축 (1/27 - 2/2)

### Day 1 (월) - 프로젝트 셋업
- [x] ~~폴더 구조 확정~~
- [ ] `package.json` 생성
  ```json
  {
    "dependencies": {
      "express": "^4.18.2",
      "bcryptjs": "^2.4.3",
      "express-session": "^1.17.3",
      "node-cron": "^3.0.2"
    }
  }
  ```
- [ ] `.gitignore` 설정
- [ ] 기본 `server.js` 작성 (100줄)

**산출물**: 서버 실행 가능 상태

---

### Day 2 (화) - 로그인 시스템
- [ ] `routes/auth.js` 작성
  - POST `/api/login`
  - GET `/api/profile`
  - POST `/api/logout`
- [ ] 세션 관리 설정
- [ ] 비밀번호 해싱 (bcryptjs)
- [ ] 테스트 계정 3개 생성

**테스트**:
```bash
curl -X POST http://localhost:3000/api/login \
  -H "Content-Type: application/json" \
  -d '{"username":"test","password":"1234"}'
```

---

### Day 3 (수) - 거래 입력 API
- [ ] `routes/trades.js` 작성
  - POST `/api/trades` - 거래 등록
  - GET `/api/trades` - 목록 조회
  - GET `/api/trades/:id` - 상세 조회
- [ ] 데이터 검증 (금액, 날짜 형식)
- [ ] 파일 저장 로직
  ```javascript
  data/trades/CUST-001/TR-{timestamp}.json
  ```

**테스트 데이터**:
```json
{
  "currency": "USD",
  "direction": "receive",
  "amountUSD": 100000,
  "tradeDate": "2026-01-27",
  "expectedDate": "2026-03-15"
}
```

---

### Day 4 (목) - 환율 API 연동
- [ ] `lib/fx-api.js` 작성
  ```javascript
  async function getCurrentRate(from, to) {
    const response = await fetch(
      `https://api.frankfurter.app/latest?from=${from}&to=${to}`
    );
    return response.json();
  }
  ```
- [ ] 환율 캐싱 (5분)
- [ ] 환율 히스토리 저장
  ```
  data/rates/2026-01-27_1030.json
  ```

**검증**:
```bash
node -e "require('./lib/fx-api').getCurrentRate('USD','KRW').then(console.log)"
```

---

### Day 5 (금) - 대시보드 API
- [ ] `routes/dashboard.js` 작성
  - GET `/api/dashboard/rates` - 현재 환율
  - GET `/api/dashboard/summary` - 거래 요약
  - GET `/api/dashboard/recent` - 최근 거래
- [ ] 집계 로직 (총 노출액 계산)

**예상 응답**:
```json
{
  "totalExposure": {
    "USD": 500000,
    "EUR": 200000
  },
  "activeTradesCount": 15,
  "avgRate": 1318.5
}
```

---

### Day 6-7 (주말) - 프론트엔드 기본
- [ ] `public/login.html` - 로그인 화면
- [ ] `public/dashboard.html` - 대시보드
- [ ] `public/trade-input.html` - 거래 입력 폼
- [ ] `public/css/style.css` - 통합 스타일
- [ ] Chart.js 연동 (환율 그래프)

**디자인**: 
- 반응형 (모바일 대응)
- 색상: 파란색 계열 (#2196F3)
- 폰트: Noto Sans KR

---

## 📅 Week 2: 헤지 기능 (2/3 - 2/9)

### Day 8 (월) - 헤지 계산기
- [ ] `lib/calculator-simple-hedge.js` 작성
  ```javascript
  function calculateHedgeRatio(volatility, riskTolerance) {
    // 간단 공식
    if (riskTolerance === 'low') return 0.9;
    if (riskTolerance === 'medium') return 0.7;
    return 0.5;
  }
  ```
- [ ] 변동성 계산 (30일 표준편차)
- [ ] 테스트 케이스 10개

---

### Day 9 (화) - 헤지 계약 API
- [ ] `routes/hedges.js` 작성
  - POST `/api/hedges` - 헤지 등록
  - GET `/api/hedges` - 목록
  - GET `/api/hedges/:id` - 상세
- [ ] 거래-헤지 연결 로직
- [ ] 중복 체크 (같은 거래에 여러 헤지 금지)

---

### Day 10 (수) - 손익 계산
- [ ] `lib/calculator-pnl.js` 작성
  ```javascript
  function calculatePnL(trade, hedge, actualRate) {
    const hedgedPnL = ...;
    const unhedgedPnL = ...;
    return { total, hedged, unhedged };
  }
  ```
- [ ] 만기 처리 로직
- [ ] 상태 업데이트 (active → completed)

---

### Day 11 (목) - 헤지 화면
- [ ] `public/hedge-create.html`
  - 거래 선택 드롭다운
  - 추천 비율 표시
  - 예상 손익 미리보기
- [ ] `public/hedge-result.html`
  - 만기 후 실제 손익
  - 헤지 효과 시각화

---

### Day 12 (금) - 통합 테스트
- [ ] 전체 플로우 테스트
  1. 로그인
  2. 거래 입력
  3. 헤지 계산
  4. 헤지 체결
  5. 만기 처리
  6. 손익 확인
- [ ] 버그 수정

---

### Day 13-14 (주말) - 리팩토링
- [ ] 코드 정리
- [ ] 에러 처리 강화
- [ ] 로그 추가
- [ ] 문서화 (JSDoc)

---

## 📅 Week 3: 자동화 & 배포 (2/10 - 2/14)

### Day 15 (월) - 환율 자동 수집
- [ ] `backend/scheduler.js` 작성
  ```javascript
  cron.schedule('*/5 * * * *', async () => {
    await collectFXRates();
  });
  ```
- [ ] 데이터 정리 (7일 이상 오래된 파일 삭제)
- [ ] 에러 알림 (Slack webhook)

---

### Day 16 (화) - 이메일 알림
- [ ] SendGrid 계정 생성
- [ ] 이메일 템플릿 작성
  - 환율 급변 알림
  - 만기 임박 알림 (D-3)
  - 주간 요약
- [ ] 테스트 발송

---

### Day 17 (수) - 월간 리포트
- [ ] `backend/report-generator.js` 작성
- [ ] PDF 생성 (puppeteer 또는 HTML→PDF)
- [ ] 자동 발송 스케줄러 (매월 1일)

**리포트 내용**:
1. 월간 거래 요약
2. 헤지 비율 평균
3. 총 손익
4. 다음 달 전망

---

### Day 18 (목) - Heroku 배포
- [ ] Heroku 계정 생성
- [ ] `Procfile` 작성
  ```
  web: node backend/server.js
  ```
- [ ] 환경 변수 설정
- [ ] 데이터 폴더 초기화
- [ ] 첫 배포

**배포 명령어**:
```bash
heroku login
heroku create hedgefreedom-mvp
git push heroku main
heroku open
```

---

### Day 19 (금) - 도메인 & SSL
- [ ] 도메인 구매 (hedgefreedom.com)
- [ ] Cloudflare DNS 설정
- [ ] SSL 인증서 적용
- [ ] HTTPS 리다이렉트

**최종 URL**: https://hedgefreedom.com

---

### Day 20-21 (주말) - 사용자 테스트
- [ ] 베타 테스터 3명 초대
- [ ] 사용성 테스트
  - 로그인 난이도
  - 거래 입력 편의성
  - 헤지 추천 이해도
- [ ] 피드백 수집
- [ ] 긴급 수정

---

## 📋 완료 기준 (Definition of Done)

### 기능 완료
- [ ] 모든 API 엔드포인트 작동
- [ ] 프론트엔드 모든 화면 렌더링
- [ ] 에러 없이 거래→헤지→손익 플로우 완성

### 성능
- [ ] 페이지 로딩 3초 이내
- [ ] API 응답 1초 이내
- [ ] 환율 데이터 5분 간격 업데이트

### 보안
- [ ] 비밀번호 bcrypt 해싱
- [ ] 세션 만료 (24시간)
- [ ] HTTPS 적용
- [ ] SQL Injection / XSS 방어

### 문서
- [ ] README.md (설치 가이드)
- [ ] API 문서 (Postman Collection)
- [ ] 사용자 매뉴얼 (PDF)

---

## 🚨 리스크 관리

| 리스크 | 확률 | 영향 | 대응 |
|--------|------|------|------|
| API 장애 (frankfurter) | 중 | 고 | 백업 API 준비 (exchangerate-api.com) |
| 배포 오류 | 중 | 중 | 로컬 완전 테스트 후 배포 |
| 데이터 손실 | 저 | 고 | 매일 자동 백업 (Git + Google Drive) |
| 일정 지연 | 고 | 중 | 핵심 기능 우선, 부가 기능 제외 |

---

## 💡 우선순위 (MoSCoW)

### Must Have (필수)
- 로그인
- 거래 입력
- 환율 조회
- 헤지 계산
- 손익 확인

### Should Have (중요)
- 대시보드 그래프
- 자동 환율 수집
- 이메일 알림

### Could Have (있으면 좋음)
- 엑셀 업로드
- PDF 리포트
- 모바일 앱

### Won't Have (제외)
- 26개 전체 계산기
- AI 예측
- 실시간 채팅

---

## 🎯 Launch Day (2/14)

### 오전 10시
- [ ] 최종 배포
- [ ] 모니터링 시작 (Heroku metrics)
- [ ] 고객사 3곳에 초대 이메일 발송

### 오후 2시
- [ ] 첫 사용자 로그인 확인
- [ ] 실시간 지원 대기 (카톡 채널)

### 저녁 6시
- [ ] 첫날 통계 확인
  - 로그인 횟수
  - 거래 입력 건수
  - 에러 발생 여부

---

## 📊 성공 지표 (첫 2주)

- **활성 사용자**: 3개사 이상
- **거래 입력**: 50건 이상
- **헤지 체결**: 10건 이상
- **시스템 가동률**: 99% 이상
- **평균 응답시간**: 1초 이하

---

**준비되셨습니까?** 이제 실제 코드 작성을 시작하시겠습니까?
