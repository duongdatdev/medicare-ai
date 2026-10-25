import { describe, expect, it } from 'vitest';
import { calcBill, CARD_REGEX, maskCardNumber, rateFromCard } from './billing.util.js';

describe('billing rules', () => {
  it('computes only covered services at the active card rate', () => {
    const card = { number: 'DN3490123456789', validFrom: '2026-01-01', validTo: '2026-11-12' };
    expect(calcBill(50000, true, [{ price: 100001, bhytCovered: true }, { price: 20000, bhytCovered: false }], card, new Date('2026-11-12T02:00:00Z')))
      .toEqual({ examFee: 50000, examFeeCovered: true, total: 170001, coveredBase: 150001, insuranceRate: 0.95, insuranceCovered: 142501, payable: 27500 });
  });

  it('rejects invalid card numbers and handles card levels, date range, and masking', () => {
    expect(CARD_REGEX.test('DN3490123456789')).toBe(true);
    expect(CARD_REGEX.test('DN6490123456789')).toBe(false);
    expect(rateFromCard('DN1490123456789')).toBe(1);
    expect(rateFromCard('DN4490123456789')).toBe(0.8);
    expect(maskCardNumber('DN3490123456789')).toBe('DN3********6789');
    const notYetValid = { number: 'DN3490123456789', validFrom: '2026-11-13', validTo: '2026-12-01' };
    expect(calcBill(100, true, [], notYetValid, new Date('2026-11-12T02:00:00Z')).insuranceRate).toBe(0);
  });
});
