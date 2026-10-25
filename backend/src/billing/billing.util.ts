export const CARD_REGEX = /^[A-Z]{2}[1-5]\d{12}$/;

export interface InsuranceCard {
  number: string;
  validFrom: string;
  validTo: string;
}

export interface BillLine {
  price: number;
  bhytCovered: boolean;
}

function dateInVietnam(date: Date): string {
  return date.toLocaleDateString('en-CA', { timeZone: 'Asia/Ho_Chi_Minh' });
}

export function rateFromCard(number: string): number {
  const level = number[2];
  if (level === '3') return 0.95;
  if (level === '4') return 0.8;
  return 1;
}

export function maskCardNumber(number: string): string {
  if (number.length <= 7) return '*'.repeat(number.length);
  return number.slice(0, 3) + '*'.repeat(number.length - 7) + number.slice(-4);
}

export function calcBill(examFee: number, examFeeCovered: boolean, lines: BillLine[], card: InsuranceCard | null, appointmentDate: Date) {
  const total = examFee + lines.reduce((sum, line) => sum + line.price, 0);
  const coveredBase = (examFeeCovered ? examFee : 0) + lines.filter((line) => line.bhytCovered).reduce((sum, line) => sum + line.price, 0);
  const visitDay = dateInVietnam(appointmentDate);
  const eligible = card !== null && visitDay >= card.validFrom && visitDay <= card.validTo;
  const insuranceRate = eligible ? rateFromCard(card.number) : 0;
  const insuranceCovered = Math.round(coveredBase * insuranceRate);
  return { examFee, examFeeCovered, total, coveredBase, insuranceRate, insuranceCovered, payable: total - insuranceCovered };
}
