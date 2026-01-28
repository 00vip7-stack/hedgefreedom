# 환리스크 관리 시스템 MVP 구현 설계서

**목표**: 고객이 실제로 사용 가능한 최소 기능 제품 (3주 내 구축)

---

## 📋 Phase 1: 핵심 기능만 (1주차)

### 1.1 로그인 & 기업 프로필

```javascript
// backend/routes/auth.js
POST /api/login
  - 입력: { username, password }
  - 출력: { token, companyId, companyName }
  
GET /api/profile
  - 출력: { 
      companyId: "CUST-001",
      name: "삼성전자",
      currency: ["USD", "EUR", "JPY"],
      riskTolerance: "medium" // low/medium/high
    }
```

**데이터 구조**:
```
data/
  companies/
    CUST-001.json  // { username, passwordHash, profile }
    CUST-002.json
```

---

### 1.2 거래 입력 (단순화)

**필수 필드만**:
```javascript
// POST /api/trades
{
  "tradeDate": "2026-01-27",
  "currency": "USD",
  "direction": "receive",  // receive(수취) / pay(지급)
  "amountUSD": 100000,
  "expectedDate": "2026-03-15"  // 45일 후
}
```

**자동 계산 항목**:
- 현재 환율 (frankfurter.app에서 자동 조회)
- 예상 원화 금액 = amountUSD × currentRate

**화면**:
```html
<!-- public/trade-input.html -->
<form id="tradeForm">
  <input type="date" name="tradeDate" required>
  <select name="currency">
    <option value="USD">USD</option>
    <option value="EUR">EUR</option>
    <option value="JPY">JPY</option>
  </select>
  <select name="direction">
    <option value="receive">수출 (달러 수취)</option>
    <option value="pay">수입 (달러 지급)</option>
  </select>
  <input type="number" name="amountUSD" placeholder="금액 (USD)">
  <input type="date" name="expectedDate" required>
  <button>거래 등록</button>
</form>
```

---

### 1.3 간단 대시보드

**3가지 위젯만**:

1. **환율 현황** (실시간)
```javascript
// GET /api/dashboard/rates
{
  "USDKRW": { current: 1320.5, change24h: +5.2 },
  "EURKRW": { current: 1450.3, change24h: -2.1 },
  "JPYKRW": { current: 9.8, change24h: +0.3 }
}
```

2. **내 거래 요약**
```javascript
// GET /api/dashboard/summary
{
  "totalTrades": 15,
  "totalExposure": {
    "USD": 500000,  // 총 달러 노출액
    "EUR": 200000
  },
  "avgRate": {
    "USD": 1315.2  // 평균 체결 환율
  }
}
```

3. **최근 거래 목록**
```javascript
// GET /api/dashboard/recent-trades
[
  {
    "id": "TR-001",
    "date": "2026-01-25",
    "currency": "USD",
    "amount": 100000,
    "rate": 1318.5,
    "status": "active"
  }
]
```

---

## 📊 Phase 2: 헤지 기능 (2주차)

### 2.1 최적 헤지 비율 계산 (1개 계산기만)

**간단한 공식**:
```javascript
// lib/calculator-simple-hedge.js

function calculateSimpleHedge(trade, marketData) {
  // 변동성 기반 간단 공식
  const volatility = marketData.volatility30d; // 30일 변동성
  
  let hedgeRatio;
  if (volatility < 0.05) {
    hedgeRatio = 0.5;  // 낮은 변동성: 50% 헤지
  } else if (volatility < 0.10) {
    hedgeRatio = 0.7;  // 중간 변동성: 70% 헤지
  } else {
    hedgeRatio = 0.9;  // 높은 변동성: 90% 헤지
  }
  
  return {
    recommendedRatio: hedgeRatio,
    hedgeAmount: trade.amountUSD * hedgeRatio,
    reason: `30일 변동성 ${(volatility*100).toFixed(2)}%`
  };
}
```

### 2.2 헤지 계약 체결

```javascript
// POST /api/hedge/contract
{
  "tradeId": "TR-001",
  "hedgeRatio": 0.7,        // 70% 헤지
  "hedgeAmount": 70000,     // USD
  "hedgeRate": 1320.0,      // 선물환율
  "maturityDate": "2026-03-15"
}
```

**저장**:
```
data/
  hedges/
    CUST-001/
      HG-001.json  // { tradeId, hedgeRatio, hedgeRate, ... }
```

---

### 2.3 손익 계산 (만기 시)

```javascript
// lib/calculator-pnl.js

function calculatePnL(trade, hedge, actualRate) {
  // 헤지 안 한 부분
  const unhedgedAmount = trade.amountUSD * (1 - hedge.hedgeRatio);
  const unhedgedPnL = unhedgedAmount * (actualRate - trade.expectedRate);
  
  // 헤지한 부분 (선물환 고정)
  const hedgedAmount = trade.amountUSD * hedge.hedgeRatio;
  const hedgedPnL = hedgedAmount * (actualRate - hedge.hedgeRate);
  
  return {
    totalPnL: unhedgedPnL + hedgedPnL,
    hedgedPnL,
    unhedgedPnL,
    effectiveRate: (hedgedAmount * hedge.hedgeRate + unhedgedAmount * actualRate) / trade.amountUSD
  };
}
```

**화면**:
```html
<!-- 만기 후 결과 -->
<div class="pnl-result">
  <h3>거래 TR-001 결과</h3>
  <p>헤지 비율: 70%</p>
  <p>실제 환율: 1,350원 (예상 대비 +30원)</p>
  <p>총 손익: +2,100,000원</p>
  <p>헤지 효과: -210,000원 (손해)</p>
  <p class="insight">⚠️ 환율이 예상보다 높아져 헤지 손실 발생</p>
</div>
```

---

## 🔄 Phase 3: 자동화 (3주차)

### 3.1 실시간 환율 수집

```javascript
// backend/scheduler.js
const cron = require('node-cron');

// 5분마다 환율 수집
cron.schedule('*/5 * * * *', async () => {
  const rates = await fetch('https://api.frankfurter.app/latest?from=USD&to=KRW,EUR,JPY');
  const data = await rates.json();
  
  // 저장
  const filename = `data/rates/${Date.now()}.json`;
  fs.writeFileSync(filename, JSON.stringify({
    timestamp: new Date().toISOString(),
    rates: data.rates
  }));
  
  console.log('[환율 수집] 완료:', data.rates);
});
```

### 3.2 자동 알림 (환율 급변 시)

```javascript
// backend/alert-engine.js

async function checkAlerts() {
  const current = await getCurrentRate('USDKRW');
  const avg24h = await get24hAvgRate('USDKRW');
  
  const change = (current - avg24h) / avg24h;
  
  if (Math.abs(change) > 0.02) {  // 2% 이상 변동
    // 모든 활성 거래의 고객에게 알림
    const activeCustomers = await getActiveCustomers();
    
    for (const customer of activeCustomers) {
      await sendEmail({
        to: customer.email,
        subject: '⚠️ 환율 급등/급락 알림',
        body: `USD/KRW 환율이 24시간 대비 ${(change*100).toFixed(1)}% 변동했습니다.
               현재 환율: ${current}원
               헤지 전략 재검토를 권장합니다.`
      });
    }
  }
}

// 1시간마다 체크
cron.schedule('0 * * * *', checkAlerts);
```

### 3.3 월간 리포트 자동 생성

```javascript
// backend/report-generator.js

async function generateMonthlyReport(customerId, year, month) {
  const trades = await getTradesByMonth(customerId, year, month);
  const hedges = await getHedgesByMonth(customerId, year, month);
  
  const report = {
    period: `${year}-${month}`,
    summary: {
      totalTrades: trades.length,
      totalHedges: hedges.length,
      hedgeRatioAvg: hedges.reduce((s, h) => s + h.hedgeRatio, 0) / hedges.length,
      totalPnL: trades.reduce((s, t) => s + calculatePnL(t), 0)
    },
    topRisks: findTopRisks(trades),
    recommendations: generateRecommendations(trades, hedges)
  };
  
  // PDF 생성 (선택)
  const pdf = await generatePDF(report);
  
  // 이메일 발송
  await sendEmail({
    to: customer.email,
    subject: `${month}월 환리스크 관리 리포트`,
    attachments: [{ filename: 'report.pdf', content: pdf }]
  });
  
  return report;
}

// 매월 1일 00시 실행
cron.schedule('0 0 1 * *', async () => {
  const customers = await getAllCustomers();
  for (const customer of customers) {
    await generateMonthlyReport(customer.id, new Date().getFullYear(), new Date().getMonth());
  }
});
```

---

## 🗂 최종 파일 구조 (간소화)

```
hedgeBasic/
├── backend/
│   ├── server.js                 # 메인 서버 (500줄 이하)
│   ├── routes/
│   │   ├── auth.js              # 로그인/프로필
│   │   ├── trades.js            # 거래 관리
│   │   ├── hedges.js            # 헤지 관리
│   │   └── dashboard.js         # 대시보드 API
│   ├── lib/
│   │   ├── calculator-simple-hedge.js   # 간단 헤지 계산
│   │   ├── calculator-pnl.js            # 손익 계산
│   │   └── fx-api.js                    # 환율 API 호출
│   ├── scheduler.js             # 자동 작업 (환율 수집, 알림)
│   ├── report-generator.js      # 월간 리포트
│   └── package.json
│
├── public/
│   ├── index.html               # 로그인
│   ├── dashboard.html           # 대시보드
│   ├── trade-input.html         # 거래 입력
│   ├── hedge-create.html        # 헤지 체결
│   └── css/
│       └── style.css            # 통합 스타일
│
└── data/
    ├── companies/               # 기업 정보
    ├── trades/                  # 거래 데이터
    │   └── CUST-001/
    │       ├── TR-001.json
    │       └── TR-002.json
    ├── hedges/                  # 헤지 계약
    │   └── CUST-001/
    │       └── HG-001.json
    └── rates/                   # 환율 데이터
        ├── 1706342400000.json   # 타임스탬프
        └── 1706342700000.json
```

---

## 🚀 배포 계획

### Step 1: 로컬 테스트 (1일)
```bash
cd backend
npm install
node server.js

# http://localhost:3000 접속
# 테스트 계정으로 로그인
# 거래 입력 → 헤지 계산 → 결과 확인
```

### Step 2: Heroku 배포 (무료 티어)
```bash
# Procfile 생성
web: node backend/server.js

# Heroku CLI
heroku create hedgefreedom-mvp
git push heroku main

# 환경 변수 설정
heroku config:set SESSION_SECRET=prod-secret-xyz
heroku config:set NODE_ENV=production
```

### Step 3: 도메인 연결
```bash
# Cloudflare DNS 설정
hedgefreedom.com → CNAME → hedgefreedom-mvp.herokuapp.com

# SSL 자동 적용 (Heroku 기본 제공)
```

---

## 📊 데이터베이스 없이 운영하는 방법

### JSON 파일 기반 (초기 100개 거래까지)

**장점**:
- 설정 불필요
- 백업 간단 (폴더 복사)
- 버전 관리 가능 (Git)

**성능**:
```javascript
// 파일 읽기 최적화
const cache = new Map();

function getTrade(tradeId) {
  if (cache.has(tradeId)) {
    return cache.get(tradeId);
  }
  
  const data = fs.readFileSync(`data/trades/${tradeId}.json`);
  const trade = JSON.parse(data);
  
  cache.set(tradeId, trade);
  return trade;
}

// 캐시 무효화 (5분마다)
setInterval(() => cache.clear(), 300000);
```

### 확장 시점 (나중에)
- 거래 500개 초과 → MongoDB
- 실시간 협업 필요 → PostgreSQL + Redis

---

## 🎯 고객 온보딩 플로우

### Day 1: 계정 생성
```
1. 관리자가 수동으로 계정 생성
   data/companies/CUST-003.json
   {
     "username": "samsung",
     "passwordHash": "bcrypt_hash",
     "profile": {
       "name": "삼성전자",
       "email": "risk@samsung.com",
       "currencies": ["USD", "EUR"]
     }
   }

2. 고객에게 로그인 정보 전달
   URL: https://hedgefreedom.com/login
   ID: samsung
   PW: temp1234 (초기 비밀번호, 로그인 후 변경 필수)
```

### Day 2-3: 과거 거래 입력
```
1. 엑셀 파일 업로드 기능 (선택)
   POST /api/trades/bulk-upload
   - CSV 파일 파싱
   - 일괄 등록

2. 또는 수동 입력 (거래가 많지 않으면)
```

### Day 4: 첫 헤지 전략
```
1. 대시보드에서 현재 노출액 확인
2. "헤지 추천" 버튼 클릭
3. 시스템이 자동 계산한 최적 비율 확인
4. 선물환 계약 체결 (외부)
5. 시스템에 헤지 정보 입력
```

### Day 7: 첫 주간 리포트
```
자동 이메일:
- 이번 주 환율 변동 요약
- 내 거래 현황
- 헤지 효과 시뮬레이션
```

---

## 💰 비용 구조 (무료 시작)

| 항목 | 비용 | 비고 |
|-----|------|-----|
| Heroku Dyno (기본) | $0/월 | 월 1000시간 무료 |
| 도메인 | $12/년 | Cloudflare |
| frankfurter.app API | $0 | 무료 (제한 없음) |
| 이메일 (SendGrid) | $0 | 월 100통까지 무료 |
| **총계** | **$1/월** | |

### 확장 시 비용
- 고객 10개 이상 → Heroku Standard ($25/월)
- 데이터베이스 → MongoDB Atlas Free Tier
- 고급 API → 유료 전환 시 고려

---

## ✅ 3주 완료 체크리스트

### Week 1
- [ ] 로그인 기능 (bcrypt)
- [ ] 거래 입력 폼
- [ ] 환율 API 연동
- [ ] 간단 대시보드 (3위젯)

### Week 2
- [ ] 헤지 비율 계산기 (1개)
- [ ] 헤지 계약 입력
- [ ] 손익 계산 기능
- [ ] 거래 목록 화면

### Week 3
- [ ] 환율 자동 수집 (cron)
- [ ] 이메일 알림 (급변 시)
- [ ] 월간 리포트 템플릿
- [ ] Heroku 배포

---

## 📞 고객 지원 전략

### 초기 (첫 3개월)
- 카카오톡 채널로 1:1 지원
- 화면 공유로 직접 교육
- FAQ 문서 작성

### 안정기 (3개월 후)
- 유튜브 튜토리얼 영상
- 챗봇 자동 응답
- 월 1회 웨비나

---

## 🎓 핵심 원칙

1. **간단하게 시작** → 복잡한 계산기는 나중에
2. **고객 피드백** → 실제 사용자 의견 반영
3. **빠른 반복** → 2주마다 업데이트
4. **데이터 안전** → 매일 자동 백업
5. **투명성** → 모든 계산 공식 공개

---

**다음 단계**: 이 설계서를 기반으로 실제 코드 작성 시작하시겠습니까?
