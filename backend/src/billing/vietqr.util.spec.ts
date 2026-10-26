import { describe, expect, it } from 'vitest';
import { buildVietQr, crc16 } from './vietqr.util.js';

describe('VietQR payload', () => {
  it('produces a valid CRC-protected payment string', () => {
    const payload = buildVietQr({ bin: '970422', accountNo: '123456789', amount: 27500, content: 'DACN12' });
    expect(payload).toContain('540527500');
    expect(payload).toContain('DACN12');
    expect(payload.slice(-4)).toBe(crc16(payload.slice(0, -4)));
  });

  it('rejects invalid transfer fields', () => {
    expect(() => buildVietQr({ bin: '123', accountNo: '123', amount: 1, content: 'DACN1' })).toThrow('Invalid bank BIN');
  });
});
