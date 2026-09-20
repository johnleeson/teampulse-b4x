import { FormationSlot } from '../types';

export type TeamSize = 5 | 7 | 9 | 11;

export const TEAM_SIZES: { size: TeamSize; label: string }[] = [
  { size: 5, label: '5v5' },
  { size: 7, label: '7v7' },
  { size: 9, label: '9v9' },
  { size: 11, label: '11v11' },
];

/** Formations keyed by name; each has exactly `teamSize` slots including GK */
export const FORMATIONS: Record<string, FormationSlot[]> = {
  // ---- 5v5 (4 outfield + GK) ----
  '1-2-1': [
    { id: 'GK', label: 'GK', x: 50, y: 88 },
    { id: 'CB', label: 'CB', x: 50, y: 68 },
    { id: 'RM', label: 'RM', x: 78, y: 42 },
    { id: 'LM', label: 'LM', x: 22, y: 42 },
    { id: 'ST', label: 'ST', x: 50, y: 18 },
  ],
  '2-1-1': [
    { id: 'GK', label: 'GK', x: 50, y: 88 },
    { id: 'CB1', label: 'CB', x: 68, y: 68 },
    { id: 'CB2', label: 'CB', x: 32, y: 68 },
    { id: 'CM', label: 'CM', x: 50, y: 42 },
    { id: 'ST', label: 'ST', x: 50, y: 18 },
  ],
  '1-1-2': [
    { id: 'GK', label: 'GK', x: 50, y: 88 },
    { id: 'CB', label: 'CB', x: 50, y: 68 },
    { id: 'CM', label: 'CM', x: 50, y: 42 },
    { id: 'ST1', label: 'ST', x: 68, y: 18 },
    { id: 'ST2', label: 'ST', x: 32, y: 18 },
  ],

  // ---- 7v7 (6 outfield + GK) ----
  '2-3-1': [
    { id: 'GK', label: 'GK', x: 50, y: 90 },
    { id: 'CB1', label: 'CB', x: 68, y: 72 },
    { id: 'CB2', label: 'CB', x: 32, y: 72 },
    { id: 'RM', label: 'RM', x: 82, y: 45 },
    { id: 'CM', label: 'CM', x: 50, y: 48 },
    { id: 'LM', label: 'LM', x: 18, y: 45 },
    { id: 'ST', label: 'ST', x: 50, y: 18 },
  ],
  '3-2-1': [
    { id: 'GK', label: 'GK', x: 50, y: 90 },
    { id: 'CB1', label: 'CB', x: 72, y: 72 },
    { id: 'CB2', label: 'CB', x: 50, y: 75 },
    { id: 'CB3', label: 'CB', x: 28, y: 72 },
    { id: 'CM1', label: 'CM', x: 65, y: 42 },
    { id: 'CM2', label: 'CM', x: 35, y: 42 },
    { id: 'ST', label: 'ST', x: 50, y: 18 },
  ],
  '2-2-2': [
    { id: 'GK', label: 'GK', x: 50, y: 90 },
    { id: 'CB1', label: 'CB', x: 68, y: 72 },
    { id: 'CB2', label: 'CB', x: 32, y: 72 },
    { id: 'CM1', label: 'CM', x: 65, y: 45 },
    { id: 'CM2', label: 'CM', x: 35, y: 45 },
    { id: 'ST1', label: 'ST', x: 65, y: 18 },
    { id: 'ST2', label: 'ST', x: 35, y: 18 },
  ],
  '3-1-2': [
    { id: 'GK', label: 'GK', x: 50, y: 90 },
    { id: 'CB1', label: 'CB', x: 72, y: 72 },
    { id: 'CB2', label: 'CB', x: 50, y: 75 },
    { id: 'CB3', label: 'CB', x: 28, y: 72 },
    { id: 'CM', label: 'CM', x: 50, y: 45 },
    { id: 'ST1', label: 'ST', x: 65, y: 18 },
    { id: 'ST2', label: 'ST', x: 35, y: 18 },
  ],

  // ---- 9v9 (8 outfield + GK) ----
  '3-4-1': [
    { id: 'GK', label: 'GK', x: 50, y: 90 },
    { id: 'CB1', label: 'CB', x: 72, y: 74 },
    { id: 'CB2', label: 'CB', x: 50, y: 78 },
    { id: 'CB3', label: 'CB', x: 28, y: 74 },
    { id: 'RM', label: 'RM', x: 85, y: 48 },
    { id: 'CM1', label: 'CM', x: 62, y: 50 },
    { id: 'CM2', label: 'CM', x: 38, y: 50 },
    { id: 'LM', label: 'LM', x: 15, y: 48 },
    { id: 'ST', label: 'ST', x: 50, y: 18 },
  ],
  '3-3-2': [
    { id: 'GK', label: 'GK', x: 50, y: 90 },
    { id: 'CB1', label: 'CB', x: 72, y: 74 },
    { id: 'CB2', label: 'CB', x: 50, y: 78 },
    { id: 'CB3', label: 'CB', x: 28, y: 74 },
    { id: 'CM1', label: 'CM', x: 72, y: 48 },
    { id: 'CM2', label: 'CM', x: 50, y: 50 },
    { id: 'CM3', label: 'CM', x: 28, y: 48 },
    { id: 'ST1', label: 'ST', x: 62, y: 18 },
    { id: 'ST2', label: 'ST', x: 38, y: 18 },
  ],
  '2-4-2': [
    { id: 'GK', label: 'GK', x: 50, y: 90 },
    { id: 'CB1', label: 'CB', x: 65, y: 74 },
    { id: 'CB2', label: 'CB', x: 35, y: 74 },
    { id: 'RM', label: 'RM', x: 85, y: 48 },
    { id: 'CM1', label: 'CM', x: 62, y: 50 },
    { id: 'CM2', label: 'CM', x: 38, y: 50 },
    { id: 'LM', label: 'LM', x: 15, y: 48 },
    { id: 'ST1', label: 'ST', x: 62, y: 18 },
    { id: 'ST2', label: 'ST', x: 38, y: 18 },
  ],
  '3-2-3': [
    { id: 'GK', label: 'GK', x: 50, y: 90 },
    { id: 'CB1', label: 'CB', x: 72, y: 74 },
    { id: 'CB2', label: 'CB', x: 50, y: 78 },
    { id: 'CB3', label: 'CB', x: 28, y: 74 },
    { id: 'CM1', label: 'CM', x: 62, y: 50 },
    { id: 'CM2', label: 'CM', x: 38, y: 50 },
    { id: 'RW', label: 'RW', x: 82, y: 22 },
    { id: 'ST', label: 'ST', x: 50, y: 16 },
    { id: 'LW', label: 'LW', x: 18, y: 22 },
  ],
  '2-3-3': [
    { id: 'GK', label: 'GK', x: 50, y: 90 },
    { id: 'CB1', label: 'CB', x: 65, y: 74 },
    { id: 'CB2', label: 'CB', x: 35, y: 74 },
    { id: 'RM', label: 'RM', x: 82, y: 48 },
    { id: 'CM', label: 'CM', x: 50, y: 50 },
    { id: 'LM', label: 'LM', x: 18, y: 48 },
    { id: 'RW', label: 'RW', x: 82, y: 22 },
    { id: 'ST', label: 'ST', x: 50, y: 16 },
    { id: 'LW', label: 'LW', x: 18, y: 22 },
  ],

  // ---- 11v11 ----
  '4-4-2': [
    { id: 'GK', label: 'GK', x: 50, y: 90 },
    { id: 'RB', label: 'RB', x: 82, y: 72 },
    { id: 'CB1', label: 'CB', x: 62, y: 75 },
    { id: 'CB2', label: 'CB', x: 38, y: 75 },
    { id: 'LB', label: 'LB', x: 18, y: 72 },
    { id: 'RM', label: 'RM', x: 82, y: 48 },
    { id: 'CM1', label: 'CM', x: 62, y: 50 },
    { id: 'CM2', label: 'CM', x: 38, y: 50 },
    { id: 'LM', label: 'LM', x: 18, y: 48 },
    { id: 'ST1', label: 'ST', x: 62, y: 22 },
    { id: 'ST2', label: 'ST', x: 38, y: 22 },
  ],
  '4-3-3': [
    { id: 'GK', label: 'GK', x: 50, y: 90 },
    { id: 'RB', label: 'RB', x: 82, y: 72 },
    { id: 'CB1', label: 'CB', x: 62, y: 75 },
    { id: 'CB2', label: 'CB', x: 38, y: 75 },
    { id: 'LB', label: 'LB', x: 18, y: 72 },
    { id: 'CDM', label: 'CDM', x: 50, y: 58 },
    { id: 'CM1', label: 'CM', x: 68, y: 45 },
    { id: 'CM2', label: 'CM', x: 32, y: 45 },
    { id: 'RW', label: 'RW', x: 82, y: 22 },
    { id: 'ST', label: 'ST', x: 50, y: 18 },
    { id: 'LW', label: 'LW', x: 18, y: 22 },
  ],
  '4-2-3-1': [
    { id: 'GK', label: 'GK', x: 50, y: 90 },
    { id: 'RB', label: 'RB', x: 82, y: 72 },
    { id: 'CB1', label: 'CB', x: 62, y: 75 },
    { id: 'CB2', label: 'CB', x: 38, y: 75 },
    { id: 'LB', label: 'LB', x: 18, y: 72 },
    { id: 'CDM1', label: 'CDM', x: 62, y: 55 },
    { id: 'CDM2', label: 'CDM', x: 38, y: 55 },
    { id: 'RM', label: 'RM', x: 82, y: 35 },
    { id: 'CAM', label: 'CAM', x: 50, y: 35 },
    { id: 'LM', label: 'LM', x: 18, y: 35 },
    { id: 'ST', label: 'ST', x: 50, y: 16 },
  ],
  '3-5-2': [
    { id: 'GK', label: 'GK', x: 50, y: 90 },
    { id: 'CB1', label: 'CB', x: 70, y: 75 },
    { id: 'CB2', label: 'CB', x: 50, y: 78 },
    { id: 'CB3', label: 'CB', x: 30, y: 75 },
    { id: 'RWB', label: 'RWB', x: 88, y: 50 },
    { id: 'CDM', label: 'CDM', x: 50, y: 58 },
    { id: 'CM1', label: 'CM', x: 66, y: 45 },
    { id: 'CM2', label: 'CM', x: 34, y: 45 },
    { id: 'LWB', label: 'LWB', x: 12, y: 50 },
    { id: 'ST1', label: 'ST', x: 62, y: 20 },
    { id: 'ST2', label: 'ST', x: 38, y: 20 },
  ],
  '3-4-3': [
    { id: 'GK', label: 'GK', x: 50, y: 90 },
    { id: 'CB1', label: 'CB', x: 70, y: 75 },
    { id: 'CB2', label: 'CB', x: 50, y: 78 },
    { id: 'CB3', label: 'CB', x: 30, y: 75 },
    { id: 'RM', label: 'RM', x: 85, y: 48 },
    { id: 'CM1', label: 'CM', x: 62, y: 50 },
    { id: 'CM2', label: 'CM', x: 38, y: 50 },
    { id: 'LM', label: 'LM', x: 15, y: 48 },
    { id: 'RW', label: 'RW', x: 78, y: 22 },
    { id: 'ST', label: 'ST', x: 50, y: 18 },
    { id: 'LW', label: 'LW', x: 22, y: 22 },
  ],
};

export const FORMATIONS_BY_SIZE: Record<TeamSize, string[]> = {
  5: ['1-2-1', '2-1-1', '1-1-2'],
  7: ['2-3-1', '3-2-1', '2-2-2', '3-1-2'],
  9: ['3-4-1', '3-3-2', '2-4-2', '3-2-3', '2-3-3'],
  11: ['4-4-2', '4-3-3', '4-2-3-1', '3-5-2', '3-4-3'],
};

export const DEFAULT_FORMATION_BY_SIZE: Record<TeamSize, string> = {
  5: '1-2-1',
  7: '2-3-1',
  9: '3-4-1',
  11: '4-4-2',
};

export function getTeamSizeForFormation(name: string): TeamSize {
  const slots = FORMATIONS[name];
  if (!slots) return 11;
  const n = slots.length as TeamSize;
  return ([5, 7, 9, 11] as TeamSize[]).includes(n) ? n : 11;
}

/** Push slots outward from pitch centre so larger markers stay clear of each other */
export function spreadSlotPosition(x: number, y: number): { x: number; y: number } {
  return {
    x: Math.min(92, Math.max(8, 50 + (x - 50) * 1.2)),
    y: Math.min(93, Math.max(10, 50 + (y - 50) * 1.16)),
  };
}

export function getFormationsForSize(size: TeamSize): string[] {
  return FORMATIONS_BY_SIZE[size] || FORMATIONS_BY_SIZE[11];
}
