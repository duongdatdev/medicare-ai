export function crc16(value: string): string {
  let crc = 0xffff;
  for (const byte of Buffer.from(value, 'utf8')) {
    crc ^= byte << 8;
    for (let index = 0; index < 8; index++) crc = crc & 0x8000 ? ((crc << 1) ^ 0x1021) & 0xffff : (crc << 1) & 0xffff;
  }
  return crc.toString(16).toUpperCase().padStart(4, '0');
}

const field = (id: string, value: string) => id + String(value.length).padStart(2, '0') + value;

export function buildVietQr(input: { bin: string; accountNo: string; amount: number; content: string }): string {
  if (!/^\d{6}$/.test(input.bin)) throw new Error('Invalid bank BIN');
  if (!/^[0-9A-Za-z]{1,19}$/.test(input.accountNo)) throw new Error('Invalid account number');
  if (!Number.isInteger(input.amount) || input.amount <= 0) throw new Error('Amount must be a positive integer');
  if (!/^[0-9A-Za-z ]{1,25}$/.test(input.content)) throw new Error('Invalid transfer content');
  const merchant = field('00', 'A000000727') + field('01', field('00', input.bin) + field('01', input.accountNo)) + field('02', 'QRIBFTTA');
  const payload = field('00', '01') + field('01', '12') + field('38', merchant) + field('53', '704') + field('54', String(input.amount)) + field('58', 'VN') + field('62', field('08', input.content)) + '6304';
  return payload + crc16(payload);
}
