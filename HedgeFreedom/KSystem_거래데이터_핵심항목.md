# K-System(영림원소프트랩) 거래데이터 연동 시 필수 핵심 항목

1. 외화 매출/매입 채권 데이터 (Invoice 기준)
   - 인보이스 번호(Invoice No)
   - 거래처명(Customer)
   - 결제 예정일(Due Date)
   - 결제일(Actual Payment Date, 선택)
2. 통화종류 (Currency)
   - USD, EUR, JPY 등 (동일 통화끼리만 매칭)
3. 금액 (Amount)
   - 입금액(Receipts), 출금액(Payments)
4. 확정 여부 (Status)
   - 예정(Planned) / 확정(Confirmed) 구분
5. 기타 참고 항목
   - 거래유형(매출/매입), 메모, ERP 고유키 등

---
- 단순 회계 장부가 아니라, 실제 자금 수지(Cash Flow) 데이터가 필요합니다.
- 위 항목이 K-System ERP에서 추출 가능한지, ERP 담당자에게 확인 필요.
- 샘플 데이터/엑셀 양식 확보 시, 자동 매칭·집계 로직 구현 가능.
