/** Return every exact UTC instant for a local calendar minute; an overlap has two and a gap has none. */
export function localInstants(date: string, time: string, timezone: string): number[] {
  const nominal = Date.parse(`${date}T${time}:00.000Z`);
  const format = new Intl.DateTimeFormat('en-CA', { timeZone: timezone, year: 'numeric', month: '2-digit', day: '2-digit', hour: '2-digit', minute: '2-digit', second: '2-digit', hourCycle: 'h23' });
  const localEpoch = (utc: number) => {
    const parts = Object.fromEntries(format.formatToParts(new Date(utc)).map(p => [p.type,p.value]));
    return Date.parse(`${parts.year}-${parts.month}-${parts.day}T${parts.hour}:${parts.minute}:${parts.second}.000Z`);
  };
  const offsets = new Set<number>();
  for (let hour = -36; hour <= 36; hour += 6) { const probe = nominal + hour * 3600000; offsets.add(localEpoch(probe) - probe); }
  return [...offsets].map(offset => nominal - offset).filter(utc => localEpoch(utc) === nominal).sort((a,b) => a-b);
}
export function localDate(utc: number, timezone: string): string {
  const parts = Object.fromEntries(new Intl.DateTimeFormat('en-CA', { timeZone: timezone, year: 'numeric', month: '2-digit', day: '2-digit' }).formatToParts(new Date(utc)).map(p => [p.type,p.value]));
  return `${parts.year}-${parts.month}-${parts.day}`;
}
