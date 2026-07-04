import { HttpError } from './middleware/errorHandler.js';

/**
 * Build a SQL `SET` clause from a partial update object, mapping camelCase
 * field names to DB columns and producing positional placeholders ($1, $2, ...).
 * Returns the clause, the ordered values, and the next unused placeholder index.
 */
export function buildUpdateSet(
  columnMap: Record<string, string>,
  updates: Record<string, unknown>,
  startIndex = 1,
): { setClause: string; values: unknown[]; nextIndex: number } {
  const sets: string[] = [];
  const values: unknown[] = [];
  let index = startIndex;

  for (const [field, value] of Object.entries(updates)) {
    const column = columnMap[field];
    if (!column) continue;
    sets.push(`${column} = $${index++}`);
    values.push(value);
  }

  if (sets.length === 0) {
    throw new HttpError(400, 'No valid fields to update');
  }

  return { setClause: sets.join(', '), values, nextIndex: index };
}
